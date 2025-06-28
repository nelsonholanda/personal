import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from 'react-query';
import { toast } from 'react-hot-toast';
import {
  DollarSign,
  Calendar,
  CheckCircle,
  XCircle,
  Clock,
  Plus,
  Search,
  Filter,
  Download,
  Eye,
  Edit,
  CreditCard,
  Banknote
} from 'lucide-react';
import axios from 'axios';

interface Payment {
  id: number;
  amount: number;
  paymentDate: string;
  dueDate: string;
  status: 'pending' | 'paid' | 'overdue' | 'cancelled';
  paymentReference?: string;
  notes?: string;
  paymentMethod: {
    id: number;
    name: string;
  };
  clientSubscription: {
    id: number;
    paymentPlan: {
      name: string;
      price: number;
    };
    clientManagement: {
      client: {
        id: number;
        name: string;
        email: string;
      };
    };
  };
  installments: Array<{
    id: number;
    installmentNumber: number;
    amount: number;
    dueDate: string;
    paymentDate?: string;
    status: 'pending' | 'paid' | 'overdue' | 'cancelled';
  }>;
}

interface PaymentMethod {
  id: number;
  name: string;
  description?: string;
}

interface PaymentPlan {
  id: number;
  name: string;
  description?: string;
  price: number;
  durationWeeks: number;
  sessionsPerWeek: number;
}

const Payments: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [clientFilter, setClientFilter] = useState<string>('all');
  const [showAddPayment, setShowAddPayment] = useState(false);
  const [selectedPayment, setSelectedPayment] = useState<Payment | null>(null);

  const queryClient = useQueryClient();

  // Fetch payments
  const { data: paymentsData, isLoading: paymentsLoading } = useQuery(
    ['payments', statusFilter, clientFilter],
    async () => {
      const params = new URLSearchParams();
      if (statusFilter !== 'all') params.append('status', statusFilter);
      if (clientFilter !== 'all') params.append('clientId', clientFilter);
      
      const response = await axios.get(`/api/payments?${params.toString()}`);
      return response.data.data;
    }
  );

  // Fetch payment methods
  const { data: paymentMethods } = useQuery(
    'paymentMethods',
    async () => {
      const response = await axios.get('/api/payments/methods');
      return response.data.data;
    }
  );

  // Fetch payment plans
  const { data: paymentPlans } = useQuery(
    'paymentPlans',
    async () => {
      const response = await axios.get('/api/payments/plans');
      return response.data.data;
    }
  );

  // Mark payment as paid mutation
  const markAsPaidMutation = useMutation(
    async ({ paymentId, paymentDate, paymentReference }: {
      paymentId: number;
      paymentDate?: string;
      paymentReference?: string;
    }) => {
      await axios.put(`/api/payments/${paymentId}/mark-paid`, {
        paymentDate,
        paymentReference
      });
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries('payments');
        toast.success('Pagamento marcado como pago!');
      },
      onError: () => {
        toast.error('Erro ao marcar pagamento como pago');
      }
    }
  );

  // Filter payments based on search term
  const filteredPayments = paymentsData?.payments?.filter((payment: Payment) =>
    payment.clientSubscription.clientManagement.client.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    payment.paymentReference?.toLowerCase().includes(searchTerm.toLowerCase())
  ) || [];

  // Get status badge
  const getStatusBadge = (status: string) => {
    const statusConfig = {
      paid: { color: 'bg-green-100 text-green-800', icon: CheckCircle },
      pending: { color: 'bg-yellow-100 text-yellow-800', icon: Clock },
      overdue: { color: 'bg-red-100 text-red-800', icon: XCircle },
      cancelled: { color: 'bg-gray-100 text-gray-800', icon: XCircle }
    };

    const config = statusConfig[status as keyof typeof statusConfig];
    const Icon = config.icon;

    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
        <Icon className="w-3 h-3 mr-1" />
        {status === 'paid' && 'Pago'}
        {status === 'pending' && 'Pendente'}
        {status === 'overdue' && 'Em Atraso'}
        {status === 'cancelled' && 'Cancelado'}
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

  // Format date
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR');
  };

  // Handle mark as paid
  const handleMarkAsPaid = (payment: Payment) => {
    const paymentDate = prompt('Data do pagamento (DD/MM/AAAA):', formatDate(new Date()));
    const paymentReference = prompt('Referência do pagamento (opcional):');
    
    if (paymentDate) {
      const [day, month, year] = paymentDate.split('/');
      const formattedDate = `${year}-${month}-${day}`;
      
      markAsPaidMutation.mutate({
        paymentId: payment.id,
        paymentDate: formattedDate,
        paymentReference
      });
    }
  };

  if (paymentsLoading) {
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
          <h1 className="text-2xl font-bold text-gray-900">Gestão de Pagamentos</h1>
          <p className="text-gray-600">Acompanhe e gerencie os pagamentos dos seus clientes</p>
        </div>
        <button
          onClick={() => setShowAddPayment(true)}
          className="btn btn-primary"
        >
          <Plus className="w-4 h-4 mr-2" />
          Novo Pagamento
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
                  placeholder="Buscar pagamentos..."
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
                <option value="paid">Pagos</option>
                <option value="pending">Pendentes</option>
                <option value="overdue">Em Atraso</option>
                <option value="cancelled">Cancelados</option>
              </select>
              <select
                value={clientFilter}
                onChange={(e) => setClientFilter(e.target.value)}
                className="input"
              >
                <option value="all">Todos os Clientes</option>
                {/* Add client options here */}
              </select>
              <button className="btn btn-outline">
                <Filter className="w-4 h-4 mr-2" />
                Filtros
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Payments Table */}
      <div className="card">
        <div className="card-body p-0">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Cliente
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Plano
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Valor
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Vencimento
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Forma de Pagamento
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Ações
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredPayments.map((payment: Payment) => (
                  <tr key={payment.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {payment.clientSubscription.clientManagement.client.name}
                        </div>
                        <div className="text-sm text-gray-500">
                          {payment.clientSubscription.clientManagement.client.email}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {payment.clientSubscription.paymentPlan.name}
                      </div>
                      <div className="text-sm text-gray-500">
                        {formatCurrency(payment.clientSubscription.paymentPlan.price)}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {formatCurrency(payment.amount)}
                      </div>
                      {payment.installments.length > 1 && (
                        <div className="text-xs text-gray-500">
                          {payment.installments.length}x de {formatCurrency(payment.amount / payment.installments.length)}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {formatDate(payment.dueDate)}
                      </div>
                      {payment.paymentDate && (
                        <div className="text-xs text-gray-500">
                          Pago em: {formatDate(payment.paymentDate)}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(payment.status)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        {payment.paymentMethod.name === 'PIX' && (
                          <Banknote className="w-4 h-4 text-green-600 mr-2" />
                        )}
                        {payment.paymentMethod.name.includes('Cartão') && (
                          <CreditCard className="w-4 h-4 text-blue-600 mr-2" />
                        )}
                        <span className="text-sm text-gray-900">
                          {payment.paymentMethod.name}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex space-x-2">
                        <button
                          onClick={() => setSelectedPayment(payment)}
                          className="text-primary-600 hover:text-primary-900"
                          title="Ver detalhes"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        {payment.status === 'pending' && (
                          <button
                            onClick={() => handleMarkAsPaid(payment)}
                            className="text-green-600 hover:text-green-900"
                            title="Marcar como pago"
                          >
                            <CheckCircle className="w-4 h-4" />
                          </button>
                        )}
                        <button
                          onClick={() => {/* Handle edit */}}
                          className="text-blue-600 hover:text-blue-900"
                          title="Editar"
                        >
                          <Edit className="w-4 h-4" />
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
      {paymentsData?.pagination && (
        <div className="flex items-center justify-between">
          <div className="text-sm text-gray-700">
            Mostrando {((paymentsData.pagination.page - 1) * paymentsData.pagination.limit) + 1} a{' '}
            {Math.min(paymentsData.pagination.page * paymentsData.pagination.limit, paymentsData.pagination.total)} de{' '}
            {paymentsData.pagination.total} resultados
          </div>
          <div className="flex space-x-2">
            <button className="btn btn-outline btn-sm">Anterior</button>
            <button className="btn btn-outline btn-sm">Próximo</button>
          </div>
        </div>
      )}

      {/* Payment Details Modal */}
      {selectedPayment && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold">Detalhes do Pagamento</h2>
              <button
                onClick={() => setSelectedPayment(null)}
                className="text-gray-500 hover:text-gray-700"
              >
                <XCircle className="w-6 h-6" />
              </button>
            </div>
            
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Cliente</label>
                  <p className="text-sm text-gray-900">
                    {selectedPayment.clientSubscription.clientManagement.client.name}
                  </p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Plano</label>
                  <p className="text-sm text-gray-900">
                    {selectedPayment.clientSubscription.paymentPlan.name}
                  </p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Valor</label>
                  <p className="text-sm text-gray-900">
                    {formatCurrency(selectedPayment.amount)}
                  </p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Status</label>
                  <div className="mt-1">
                    {getStatusBadge(selectedPayment.status)}
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Vencimento</label>
                  <p className="text-sm text-gray-900">
                    {formatDate(selectedPayment.dueDate)}
                  </p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Forma de Pagamento</label>
                  <p className="text-sm text-gray-900">
                    {selectedPayment.paymentMethod.name}
                  </p>
                </div>
              </div>

              {selectedPayment.paymentReference && (
                <div>
                  <label className="block text-sm font-medium text-gray-700">Referência</label>
                  <p className="text-sm text-gray-900">{selectedPayment.paymentReference}</p>
                </div>
              )}

              {selectedPayment.notes && (
                <div>
                  <label className="block text-sm font-medium text-gray-700">Observações</label>
                  <p className="text-sm text-gray-900">{selectedPayment.notes}</p>
                </div>
              )}

              {selectedPayment.installments.length > 1 && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Parcelas</label>
                  <div className="space-y-2">
                    {selectedPayment.installments.map((installment) => (
                      <div key={installment.id} className="flex justify-between items-center p-2 bg-gray-50 rounded">
                        <span className="text-sm">
                          Parcela {installment.installmentNumber} - {formatCurrency(installment.amount)}
                        </span>
                        <div className="flex items-center space-x-2">
                          <span className="text-xs text-gray-500">
                            {formatDate(installment.dueDate)}
                          </span>
                          {getStatusBadge(installment.status)}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Payments; 