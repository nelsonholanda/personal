import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from 'react-query';
import axios from 'axios';
import ConfirmModal from '../components/ConfirmModal';

interface PasswordChangeForm {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
}

interface PasswordResetForm {
  email: string;
}

interface UserPasswordChangeForm {
  userId: number;
  newPassword: string;
  forceChange: boolean;
}

interface PasswordHistory {
  id: number;
  changedAt: string;
}

const PasswordManagement: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'change' | 'reset' | 'admin' | 'history'>('change');
  const [passwordChangeForm, setPasswordChangeForm] = useState<PasswordChangeForm>({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [passwordResetForm, setPasswordResetForm] = useState<PasswordResetForm>({
    email: ''
  });
  const [userPasswordForm, setUserPasswordForm] = useState<UserPasswordChangeForm>({
    userId: 0,
    newPassword: '',
    forceChange: false
  });
  const [selectedUser, setSelectedUser] = useState<number>(0);
  const [generatedPassword, setGeneratedPassword] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [confirmModalOpen, setConfirmModalOpen] = useState(false);
  const [pendingForceUserId, setPendingForceUserId] = useState<number | null>(null);

  const queryClient = useQueryClient();

  // Buscar usuários (para admin)
  const { data: users } = useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const response = await axios.get('/api/users');
      return response.data.data;
    },
    enabled: activeTab === 'admin' || activeTab === 'history'
  });

  // Verificar se precisa alterar senha
  const { data: passwordChangeRequired } = useQuery({
    queryKey: ['password-change-required'],
    queryFn: async () => {
      const response = await axios.get('/api/passwords/check-change-required');
      return response.data.data.passwordChangeRequired;
    }
  });

  // Buscar histórico de senhas
  const { data: passwordHistory, refetch: refetchHistory } = useQuery({
    queryKey: ['password-history', selectedUser],
    queryFn: async () => {
      const response = await axios.get(`/api/passwords/history/${selectedUser}`);
      return response.data.data;
    },
    enabled: activeTab === 'history' && selectedUser > 0
  });

  // Mutação para alterar senha
  const changePasswordMutation = useMutation({
    mutationFn: async (data: { currentPassword: string; newPassword: string }) => {
      const response = await axios.post('/api/passwords/change', data);
      return response.data;
    },
    onSuccess: () => {
      setMessage({ type: 'success', text: 'Senha alterada com sucesso!' });
      setPasswordChangeForm({
        currentPassword: '',
        newPassword: '',
        confirmPassword: ''
      });
    },
    onError: (error: any) => {
      setMessage({ type: 'error', text: error.response?.data?.error || 'Erro ao alterar senha' });
    }
  });

  // Mutação para solicitar reset de senha
  const requestResetMutation = useMutation({
    mutationFn: async (data: { email: string }) => {
      const response = await axios.post('/api/passwords/request-reset', data);
      return response.data;
    },
    onSuccess: (data) => {
      setMessage({ type: 'success', text: data.message });
      setPasswordResetForm({ email: '' });
    },
    onError: (error: any) => {
      setMessage({ type: 'error', text: error.response?.data?.error || 'Erro ao solicitar reset' });
    }
  });

  // Mutação para alterar senha de usuário (admin)
  const changeUserPasswordMutation = useMutation({
    mutationFn: async (data: UserPasswordChangeForm) => {
      const response = await axios.post('/api/passwords/change-user', data);
      return response.data;
    },
    onSuccess: () => {
      setMessage({ type: 'success', text: 'Senha do usuário alterada com sucesso!' });
      setUserPasswordForm({
        userId: 0,
        newPassword: '',
        forceChange: false
      });
    },
    onError: (error: any) => {
      setMessage({ type: 'error', text: error.response?.data?.error || 'Erro ao alterar senha do usuário' });
    }
  });

  // Mutação para gerar senha segura
  const generatePasswordMutation = useMutation({
    mutationFn: async (data: { length: number }) => {
      const response = await axios.post('/api/passwords/generate', data);
      return response.data;
    },
    onSuccess: (data) => {
      setGeneratedPassword(data.data.password);
    },
    onError: (error: any) => {
      setMessage({ type: 'error', text: error.response?.data?.error || 'Erro ao gerar senha' });
    }
  });

  // Mutação para forçar mudança de senha
  const forcePasswordChangeMutation = useMutation({
    mutationFn: async (userId: number) => {
      const response = await axios.post(`/api/passwords/force-change/${userId}`);
      return response.data;
    },
    onSuccess: () => {
      setMessage({ type: 'success', text: 'Usuário será obrigado a alterar a senha na próxima sessão!' });
    },
    onError: (error: any) => {
      setMessage({ type: 'error', text: error.response?.data?.error || 'Erro ao forçar mudança de senha' });
    }
  });

  // Validar senha
  const validatePassword = (password: string): string[] => {
    const errors: string[] = [];
    
    if (password.length < 8) {
      errors.push('Senha deve ter pelo menos 8 caracteres');
    }
    if (!/[A-Z]/.test(password)) {
      errors.push('Senha deve conter pelo menos uma letra maiúscula');
    }
    if (!/[a-z]/.test(password)) {
      errors.push('Senha deve conter pelo menos uma letra minúscula');
    }
    if (!/\d/.test(password)) {
      errors.push('Senha deve conter pelo menos um número');
    }
    if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
      errors.push('Senha deve conter pelo menos um caractere especial');
    }
    
    return errors;
  };

  // Copiar senha para clipboard
  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setMessage({ type: 'success', text: 'Senha copiada para a área de transferência!' });
    } catch (error) {
      setMessage({ type: 'error', text: 'Erro ao copiar senha' });
    }
  };

  // Gerar senha segura
  const handleGeneratePassword = () => {
    generatePasswordMutation.mutate({ length: 12 });
  };

  // Alterar senha
  const handleChangePassword = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (passwordChangeForm.newPassword !== passwordChangeForm.confirmPassword) {
      setMessage({ type: 'error', text: 'As senhas não coincidem' });
      return;
    }

    const errors = validatePassword(passwordChangeForm.newPassword);
    if (errors.length > 0) {
      setMessage({ type: 'error', text: errors.join(', ') });
      return;
    }

    changePasswordMutation.mutate({
      currentPassword: passwordChangeForm.currentPassword,
      newPassword: passwordChangeForm.newPassword
    });
  };

  // Solicitar reset de senha
  const handleRequestReset = (e: React.FormEvent) => {
    e.preventDefault();
    requestResetMutation.mutate({ email: passwordResetForm.email });
  };

  // Alterar senha de usuário (admin)
  const handleChangeUserPassword = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!userPasswordForm.userId) {
      setMessage({ type: 'error', text: 'Selecione um usuário' });
      return;
    }

    const errors = validatePassword(userPasswordForm.newPassword);
    if (errors.length > 0) {
      setMessage({ type: 'error', text: errors.join(', ') });
      return;
    }

    changeUserPasswordMutation.mutate(userPasswordForm);
  };

  // Forçar mudança de senha
  const handleForcePasswordChange = (userId: number) => {
    setPendingForceUserId(userId);
    setConfirmModalOpen(true);
  };

  const handleConfirmForcePasswordChange = () => {
    if (pendingForceUserId !== null) {
      forcePasswordChangeMutation.mutate(pendingForceUserId);
    }
    setConfirmModalOpen(false);
    setPendingForceUserId(null);
  };

  const handleCancelForcePasswordChange = () => {
    setConfirmModalOpen(false);
    setPendingForceUserId(null);
  };

  // Limpar mensagem após 5 segundos
  useEffect(() => {
    if (message) {
      const timer = setTimeout(() => setMessage(null), 5000);
      return () => clearTimeout(timer);
    }
  }, [message]);

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Gerenciamento de Senhas</h1>
          <p className="text-gray-600">Gerencie senhas de forma segura e eficiente</p>
        </div>

        {/* Alertas */}
        {passwordChangeRequired && (
          <div className="mb-6 bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <h3 className="text-sm font-medium text-yellow-800">
                  Alteração de senha obrigatória
                </h3>
                <div className="mt-2 text-sm text-yellow-700">
                  <p>Você precisa alterar sua senha antes de continuar.</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {message && (
          <div className={`mb-6 p-4 rounded-lg ${
            message.type === 'success' 
              ? 'bg-green-50 border border-green-200 text-green-800' 
              : 'bg-red-50 border border-red-200 text-red-800'
          }`}>
            {message.text}
          </div>
        )}

        {/* Tabs */}
        <div className="mb-6">
          <nav className="flex space-x-8">
            {['change', 'reset', 'admin', 'history'].map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab as any)}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === tab
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                {tab === 'change' && 'Alterar Senha'}
                {tab === 'reset' && 'Reset de Senha'}
                {tab === 'admin' && 'Gerenciar Usuários'}
                {tab === 'history' && 'Histórico'}
              </button>
            ))}
          </nav>
        </div>

        {/* Conteúdo das tabs */}
        <div className="bg-white rounded-lg shadow">
          {/* Tab: Alterar Senha */}
          {activeTab === 'change' && (
            <div className="p-6">
              <h2 className="text-xl font-semibold mb-6">Alterar Minha Senha</h2>
              
              <form onSubmit={handleChangePassword} className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Senha Atual
                  </label>
                  <input
                    type="password"
                    value={passwordChangeForm.currentPassword}
                    onChange={(e) => setPasswordChangeForm(prev => ({
                      ...prev,
                      currentPassword: e.target.value
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Nova Senha
                  </label>
                  <div className="relative">
                    <input
                      type={showPassword ? 'text' : 'password'}
                      value={passwordChangeForm.newPassword}
                      onChange={(e) => setPasswordChangeForm(prev => ({
                        ...prev,
                        newPassword: e.target.value
                      }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      required
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute inset-y-0 right-0 pr-3 flex items-center"
                    >
                      {showPassword ? (
                        <svg className="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21" />
                        </svg>
                      ) : (
                        <svg className="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                      )}
                    </button>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Confirmar Nova Senha
                  </label>
                  <input
                    type="password"
                    value={passwordChangeForm.confirmPassword}
                    onChange={(e) => setPasswordChangeForm(prev => ({
                      ...prev,
                      confirmPassword: e.target.value
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>

                <div className="flex items-center justify-between">
                  <button
                    type="button"
                    onClick={handleGeneratePassword}
                    className="text-sm text-blue-600 hover:text-blue-500"
                  >
                    Gerar senha segura
                  </button>
                  
                  <button
                    type="submit"
                    disabled={changePasswordMutation.isLoading}
                    className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 disabled:opacity-50"
                  >
                    {changePasswordMutation.isLoading ? 'Alterando...' : 'Alterar Senha'}
                  </button>
                </div>
              </form>

              {generatedPassword && (
                <div className="mt-4 p-4 bg-gray-50 rounded-lg">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-700">Senha gerada:</p>
                      <p className="text-lg font-mono text-gray-900">{generatedPassword}</p>
                    </div>
                    <button
                      onClick={() => copyToClipboard(generatedPassword)}
                      className="text-blue-600 hover:text-blue-500"
                    >
                      Copiar
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Tab: Reset de Senha */}
          {activeTab === 'reset' && (
            <div className="p-6">
              <h2 className="text-xl font-semibold mb-6">Solicitar Reset de Senha</h2>
              
              <form onSubmit={handleRequestReset} className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Email
                  </label>
                  <input
                    type="email"
                    value={passwordResetForm.email}
                    onChange={(e) => setPasswordResetForm(prev => ({
                      ...prev,
                      email: e.target.value
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={requestResetMutation.isLoading}
                  className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 disabled:opacity-50"
                >
                  {requestResetMutation.isLoading ? 'Enviando...' : 'Solicitar Reset'}
                </button>
              </form>
            </div>
          )}

          {/* Tab: Gerenciar Usuários (Admin) */}
          {activeTab === 'admin' && (
            <div className="p-6">
              <h2 className="text-xl font-semibold mb-6">Gerenciar Senhas de Usuários</h2>
              
              <form onSubmit={handleChangeUserPassword} className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Selecionar Usuário
                  </label>
                  <select
                    value={userPasswordForm.userId}
                    onChange={(e) => setUserPasswordForm(prev => ({
                      ...prev,
                      userId: parseInt(e.target.value)
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  >
                    <option value={0}>Selecione um usuário</option>
                    {users?.map((user: any) => (
                      <option key={user.id} value={user.id}>
                        {user.name} ({user.email}) - {user.role}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Nova Senha
                  </label>
                  <input
                    type="password"
                    value={userPasswordForm.newPassword}
                    onChange={(e) => setUserPasswordForm(prev => ({
                      ...prev,
                      newPassword: e.target.value
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>

                <div className="flex items-center">
                  <input
                    type="checkbox"
                    id="forceChange"
                    checked={userPasswordForm.forceChange}
                    onChange={(e) => setUserPasswordForm(prev => ({
                      ...prev,
                      forceChange: e.target.checked
                    }))}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                  />
                  <label htmlFor="forceChange" className="ml-2 block text-sm text-gray-900">
                    Forçar mudança de senha na próxima sessão
                  </label>
                </div>

                <div className="flex items-center justify-between">
                  <button
                    type="button"
                    onClick={handleGeneratePassword}
                    className="text-sm text-blue-600 hover:text-blue-500"
                  >
                    Gerar senha segura
                  </button>
                  
                  <button
                    type="submit"
                    disabled={changeUserPasswordMutation.isLoading}
                    className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 disabled:opacity-50"
                  >
                    {changeUserPasswordMutation.isLoading ? 'Alterando...' : 'Alterar Senha do Usuário'}
                  </button>
                </div>
              </form>

              {/* Lista de usuários com ações */}
              <div className="mt-8">
                <h3 className="text-lg font-medium mb-4">Usuários</h3>
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Nome
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Email
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Função
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Ações
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {users?.map((user: any) => (
                        <tr key={user.id}>
                          <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                            {user.name}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {user.email}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                              user.role === 'admin' ? 'bg-red-100 text-red-800' :
                              user.role === 'trainer' ? 'bg-blue-100 text-blue-800' :
                              'bg-green-100 text-green-800'
                            }`}>
                              {user.role}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                            <button
                              onClick={() => handleForcePasswordChange(user.id)}
                              disabled={forcePasswordChangeMutation.isLoading}
                              className="text-red-600 hover:text-red-900 disabled:opacity-50"
                            >
                              Forçar mudança
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* Tab: Histórico */}
          {activeTab === 'history' && (
            <div className="p-6">
              <h2 className="text-xl font-semibold mb-6">Histórico de Senhas</h2>
              
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Selecionar Usuário
                </label>
                <select
                  value={selectedUser}
                  onChange={(e) => setSelectedUser(parseInt(e.target.value))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value={0}>Selecione um usuário</option>
                  {users?.map((user: any) => (
                    <option key={user.id} value={user.id}>
                      {user.name} ({user.email})
                    </option>
                  ))}
                </select>
              </div>

              {selectedUser > 0 && passwordHistory && (
                <div>
                  <h3 className="text-lg font-medium mb-4">
                    Histórico de alterações de senha ({passwordHistory.count} registros)
                  </h3>
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Data da Alteração
                          </th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-gray-200">
                        {passwordHistory.history.map((record: PasswordHistory) => (
                          <tr key={record.id}>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {new Date(record.changedAt).toLocaleString('pt-BR')}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        <ConfirmModal
          open={confirmModalOpen}
          message="Tem certeza que deseja forçar a mudança de senha para este usuário?"
          onConfirm={handleConfirmForcePasswordChange}
          onCancel={handleCancelForcePasswordChange}
        />
      </div>
    </div>
  );
};

export default PasswordManagement; 