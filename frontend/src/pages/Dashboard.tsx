import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { apiService } from '../services/api';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';

interface DashboardStats {
  activeClients: number;
  monthlyRevenue: number;
  todaySessions: number;
  pendingPayments: number;
}

interface RecentActivity {
  id: number;
  type: string;
  description: string;
  timestamp: string;
}

interface UpcomingSession {
  id: number;
  clientName: string;
  date: string;
  time: string;
  status: string;
}

const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [stats, setStats] = useState<DashboardStats>({
    activeClients: 0,
    monthlyRevenue: 0,
    todaySessions: 0,
    pendingPayments: 0
  });
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);
  const [upcomingSessions, setUpcomingSessions] = useState<UpcomingSession[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      
      // Carregar estatísticas
      const statsData = await apiService.getDashboardStats();
      setStats(statsData);
      
      // Carregar atividade recente
      const activityData = await apiService.getRecentActivity();
      setRecentActivity(activityData);
      
      // Carregar próximas sessões
      const sessionsData = await apiService.getUpcomingSessions();
      setUpcomingSessions(sessionsData);
      
    } catch (error: any) {
      console.error('Erro ao carregar dados do dashboard:', error);
      toast.error('Erro ao carregar dados do dashboard');
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(value);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR');
  };

  const formatTime = (timeString: string) => {
    return timeString.substring(0, 5);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-lg shadow-md p-6 border-l-4 border-primary-600">
        <h1 className="text-3xl font-bold text-primary-900 mb-4">
          Bem-vindo de volta, {user?.name || 'Treinador'}!
        </h1>
        <p className="text-gray-600">
          Gerencie seus clientes, acompanhe progressos e controle pagamentos em um só lugar.
        </p>
      </div>

      {/* Estatísticas Rápidas */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6 border-t-4 border-primary-500">
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-primary-100">
              <svg className="w-6 h-6 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
              </svg>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Clientes Ativos</p>
              <p className="text-2xl font-bold text-primary-900">{stats.activeClients}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6 border-t-4 border-secondary-500">
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-secondary-100">
              <svg className="w-6 h-6 text-secondary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
              </svg>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Receita do Mês</p>
              <p className="text-2xl font-bold text-secondary-900">{formatCurrency(stats.monthlyRevenue)}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6 border-t-4 border-primary-500">
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-primary-100">
              <svg className="w-6 h-6 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Sessões Hoje</p>
              <p className="text-2xl font-bold text-primary-900">{stats.todaySessions}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6 border-t-4 border-secondary-500">
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-secondary-100">
              <svg className="w-6 h-6 text-secondary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
              </svg>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Pagamentos Pendentes</p>
              <p className="text-2xl font-bold text-secondary-900">{stats.pendingPayments}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Conteúdo Principal */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Atividade Recente */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-primary-900 mb-4">Atividade Recente</h3>
          <div className="space-y-4">
            {recentActivity.length > 0 ? (
              recentActivity.map((activity) => (
                <div key={activity.id} className="flex items-center p-3 bg-gray-50 rounded-lg">
                  <div className="w-2 h-2 bg-primary-500 rounded-full mr-3"></div>
                  <div>
                    <p className="text-sm font-medium text-gray-900">{activity.description}</p>
                    <p className="text-xs text-gray-500">{formatDate(activity.timestamp)}</p>
                  </div>
                </div>
              ))
            ) : (
              <div className="flex items-center p-3 bg-gray-50 rounded-lg">
                <div className="w-2 h-2 bg-primary-500 rounded-full mr-3"></div>
                <div>
                  <p className="text-sm font-medium text-gray-900">Nenhuma atividade recente</p>
                  <p className="text-xs text-gray-500">Comece adicionando clientes e criando planos de treino</p>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Ações Rápidas */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-primary-900 mb-4">Ações Rápidas</h3>
          <div className="space-y-3">
            <button 
              onClick={() => navigate('/clients')}
              className="w-full text-left p-4 bg-primary-50 hover:bg-primary-100 rounded-lg transition-colors"
            >
              <div className="flex items-center">
                <svg className="w-5 h-5 text-primary-600 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
                <div>
                  <h4 className="font-medium text-primary-900">Adicionar Novo Cliente</h4>
                  <p className="text-sm text-primary-700">Cadastrar um novo cliente</p>
                </div>
              </div>
            </button>

            <button 
              onClick={() => navigate('/payments')}
              className="w-full text-left p-4 bg-secondary-50 hover:bg-secondary-100 rounded-lg transition-colors"
            >
              <div className="flex items-center">
                <svg className="w-5 h-5 text-secondary-600 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
                <div>
                  <h4 className="font-medium text-secondary-900">Gerenciar Pagamentos</h4>
                  <p className="text-sm text-secondary-700">Controlar receitas e pagamentos</p>
                </div>
              </div>
            </button>

            <button 
              onClick={() => navigate('/profile')}
              className="w-full text-left p-4 bg-primary-50 hover:bg-primary-100 rounded-lg transition-colors"
            >
              <div className="flex items-center">
                <svg className="w-5 h-5 text-primary-600 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
                <div>
                  <h4 className="font-medium text-primary-900">Editar Perfil</h4>
                  <p className="text-sm text-primary-700">Atualizar informações pessoais</p>
                </div>
              </div>
            </button>
          </div>
        </div>
      </div>

      {/* Próximas Sessões */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <h3 className="text-lg font-semibold text-primary-900 mb-4">Próximas Sessões</h3>
        {upcomingSessions.length > 0 ? (
          <div className="space-y-4">
            {upcomingSessions.map((session) => (
              <div key={session.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div>
                  <h4 className="font-medium text-gray-900">{session.clientName}</h4>
                  <p className="text-sm text-gray-600">
                    {formatDate(session.date)} às {formatTime(session.time)}
                  </p>
                </div>
                <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                  session.status === 'confirmed' 
                    ? 'bg-green-100 text-green-800' 
                    : 'bg-yellow-100 text-yellow-800'
                }`}>
                  {session.status === 'confirmed' ? 'Confirmado' : 'Pendente'}
                </span>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8">
            <svg className="w-12 h-12 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <p className="text-gray-500">Nenhuma sessão agendada</p>
            <p className="text-sm text-gray-400">Comece agendando suas primeiras sessões</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Dashboard; 