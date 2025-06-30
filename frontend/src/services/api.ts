const API_BASE_URL = process.env.REACT_APP_API_URL || '/api';

// TypeScript interfaces
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

interface User {
  id: number;
  name: string;
  email: string;
  role: string;
}

interface LoginResponse {
  token: string;
  user: User;
}

export const api = {
  // Configuração base
  baseURL: API_BASE_URL,
  
  // Headers padrão
  headers: {
    'Content-Type': 'application/json',
  },

  // Função para fazer requisições
  async request(endpoint: string, options: RequestInit = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const token = localStorage.getItem('token');
    
    const config: RequestInit = {
      ...options,
      headers: {
        ...this.headers,
        ...options.headers,
        ...(token && { Authorization: `Bearer ${token}` }),
      },
    };

    try {
      const response = await fetch(url, config);
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error('API request failed:', error);
      throw error;
    }
  },

  // Métodos HTTP
  get: (endpoint: string) => api.request(endpoint),
  
  post: (endpoint: string, data: any) => 
    api.request(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  
  put: (endpoint: string, data: any) => 
    api.request(endpoint, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),
  
  delete: (endpoint: string) => 
    api.request(endpoint, {
      method: 'DELETE',
    }),

  // Auth endpoints
  async login(email: string, password: string): Promise<LoginResponse> {
    return api.post('/auth/login', { email, password });
  },

  async getCurrentUser(): Promise<User> {
    return api.get('/auth/me');
  },

  // Dashboard statistics
  async getDashboardStats(): Promise<DashboardStats> {
    return api.get('/dashboard/stats');
  },

  // Client management
  async getClients() {
    return api.get('/client-management/clients');
  },

  async createClient(clientData: any) {
    return api.post('/client-management/clients', clientData);
  },

  async updateClient(id: number, clientData: any) {
    return api.put(`/client-management/clients/${id}`, clientData);
  },

  async deleteClient(id: number) {
    return api.delete(`/client-management/clients/${id}`);
  },

  // Payments
  async getPayments() {
    return api.get('/payments');
  },

  async createPayment(paymentData: any) {
    return api.post('/payments', paymentData);
  },

  async updatePayment(id: number, paymentData: any) {
    return api.put(`/payments/${id}`, paymentData);
  },

  async deletePayment(id: number) {
    return api.delete(`/payments/${id}`);
  },

  // Recent activity
  async getRecentActivity(): Promise<RecentActivity[]> {
    const response = await api.get('/dashboard/recent-activity');
    return response.data || [];
  },

  // Upcoming sessions
  async getUpcomingSessions(): Promise<UpcomingSession[]> {
    const response = await api.get('/dashboard/upcoming-sessions');
    return response.data || [];
  }
};

export default api; 