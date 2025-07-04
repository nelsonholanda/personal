import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from 'react-query';
import { toast } from 'react-hot-toast';
import {
  CheckCircle,
  XCircle,
  Clock,
  Plus,
  Search,
  Filter,
  Eye,
  Edit,
  Trash2
} from 'lucide-react';
import axios from 'axios';

interface Client {
  id: number;
  client: {
    id: number;
    name: string;
    email: string;
    phone: string;
    profileImageUrl?: string;
  };
  status: 'active' | 'inactive' | 'suspended' | 'completed';
  weeklySessions: number;
  sessionDurationMinutes: number;
  startDate: string;
  endDate?: string;
  notes?: string;
  financialStats: {
    totalPaid: number;
    totalPending: number;
    totalOverdue: number;
  };
}

const ClientManagement: React.FC = () => {
  const [selectedClients, setSelectedClients] = useState<number[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const queryClient = useQueryClient();

  // Fetch clients
  const { data: clientsData, isLoading: clientsLoading } = useQuery(
    ['clients', statusFilter],
    async () => {
      const response = await axios.get(`/api/client-management?status=${statusFilter === 'all' ? '' : statusFilter}`);
      return response.data.data;
    }
  );

  // Filter clients based on search term
  const filteredClients = clientsData?.clients?.filter((client: Client) =>
    client.client.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    client.client.email.toLowerCase().includes(searchTerm.toLowerCase())
  ) || [];

  // Handle client selection
  const handleClientSelect = (clientId: number) => {
    setSelectedClients(prev =>
      prev.includes(clientId)
        ? prev.filter(id => id !== clientId)
        : [...prev, clientId]
    );
  };

  // Handle select all
  const handleSelectAll = () => {
    if (selectedClients.length === filteredClients.length) {
      setSelectedClients([]);
    } else {
      setSelectedClients(filteredClients.map((client: Client) => client.id));
    }
  };

  // Bulk actions mutations
  const bulkStatusMutation = useMutation(
    async ({ clientIds, status }: { clientIds: number[]; status: string }) => {
      await Promise.all(
        clientIds.map(id => axios.put(`/api/client-management/${id}`, { status }))
      );
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries('clients');
        setSelectedClients([]);
        toast.success('Clientes atualizados com sucesso!');
      },
      onError: () => {
        toast.error('Erro ao atualizar clientes');
      }
    }
  );

  // Get status badge
  const getStatusBadge = (status: string) => {
    const statusConfig = {
      active: { color: 'bg-green-100 text-green-800', icon: CheckCircle },
      inactive: { color: 'bg-gray-100 text-gray-800', icon: XCircle },
      suspended: { color: 'bg-yellow-100 text-yellow-800', icon: Clock },
      completed: { color: 'bg-blue-100 text-blue-800', icon: CheckCircle }
    };

    const config = statusConfig[status as keyof typeof statusConfig];
    const Icon = config.icon;

    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
        <Icon className="w-3 h-3 mr-1" />
        {status === 'active' && 'Ativo'}
        {status === 'inactive' && 'Inativo'}
        {status === 'suspended' && 'Suspenso'}
        {status === 'completed' && 'Concluído'}
      </span>
    );
  };

  // Format currency
  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(value);
  };

  if (clientsLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Gestão de Clientes</h1>
          <p className="text-gray-600">Gerencie seus alunos e acompanhe pagamentos</p>
        </div>
        <button
          className="btn btn-primary"
        >
          <Plus className="w-4 h-4 mr-2" />
          Adicionar Cliente
        </button>
      </div>

      {/* Filters and Search */}
      <div className="card">
        <div className="card-body">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                <input
                  type="text"
                  placeholder="Buscar clientes..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="input pl-10"
                />
              </div>
            </div>
            <div className="flex gap-2">
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="input"
              >
                <option value="all">Todos os Status</option>
                <option value="active">Ativos</option>
                <option value="inactive">Inativos</option>
                <option value="suspended">Suspensos</option>
                <option value="completed">Concluídos</option>
              </select>
              <button className="btn btn-outline">
                <Filter className="w-4 h-4 mr-2" />
                Filtros
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Bulk Actions */}
      {selectedClients.length > 0 && (
        <div className="card bg-blue-50 border-blue-200">
          <div className="card-body">
            <div className="flex items-center justify-between">
              <p className="text-blue-800">
                {selectedClients.length} cliente(s) selecionado(s)
              </p>
              <div className="flex gap-2">
                <button
                  onClick={() => bulkStatusMutation.mutate({ clientIds: selectedClients, status: 'active' })}
                  className="btn btn-success btn-sm"
                >
                  Marcar como Ativo
                </button>
                <button
                  onClick={() => bulkStatusMutation.mutate({ clientIds: selectedClients, status: 'inactive' })}
                  className="btn btn-warning btn-sm"
                >
                  Marcar como Inativo
                </button>
                <button
                  onClick={() => setSelectedClients([])}
                  className="btn btn-outline btn-sm"
                >
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Clients Table */}
      <div className="card">
        <div className="card-body p-0">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left">
                    <input
                      type="checkbox"
                      checked={selectedClients.length === filteredClients.length && filteredClients.length > 0}
                      onChange={handleSelectAll}
                      className="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Cliente
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Aulas/Semana
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Pagamentos
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Ações
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredClients.map((client: Client) => (
                  <tr key={client.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <input
                        type="checkbox"
                        checked={selectedClients.includes(client.id)}
                        onChange={() => handleClientSelect(client.id)}
                        className="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                      />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="flex-shrink-0 h-10 w-10">
                          <img
                            className="h-10 w-10 rounded-full"
                            src={client.client.profileImageUrl || '/default-avatar.png'}
                            alt={client.client.name}
                          />
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">
                            {client.client.name}
                          </div>
                          <div className="text-sm text-gray-500">
                            {client.client.email}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(client.status)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {client.weeklySessions}x por semana
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm">
                        <div className="text-green-600">
                          Pago: {formatCurrency(client.financialStats.totalPaid)}
                        </div>
                        <div className="text-yellow-600">
                          Pendente: {formatCurrency(client.financialStats.totalPending)}
                        </div>
                        {client.financialStats.totalOverdue > 0 && (
                          <div className="text-red-600">
                            Atraso: {formatCurrency(client.financialStats.totalOverdue)}
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex space-x-2">
                        <button className="text-primary-600 hover:text-primary-900">
                          <Eye className="w-4 h-4" />
                        </button>
                        <button className="text-blue-600 hover:text-blue-900">
                          <Edit className="w-4 h-4" />
                        </button>
                        <button className="text-red-600 hover:text-red-900">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Pagination */}
      {clientsData?.pagination && (
        <div className="flex items-center justify-between">
          <div className="text-sm text-gray-700">
            Mostrando {((clientsData.pagination.page - 1) * clientsData.pagination.limit) + 1} a{' '}
            {Math.min(clientsData.pagination.page * clientsData.pagination.limit, clientsData.pagination.total)} de{' '}
            {clientsData.pagination.total} resultados
          </div>
          <div className="flex space-x-2">
            <button className="btn btn-outline btn-sm">Anterior</button>
            <button className="btn btn-outline btn-sm">Próximo</button>
          </div>
        </div>
      )}
    </div>
  );
};

export default ClientManagement; 