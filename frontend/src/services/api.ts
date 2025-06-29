const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

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

class ApiService {
  private getHeaders(): HeadersInit {
    const token = localStorage.getItem('token');
    return {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
    };
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const url = `${API_BASE_URL}${endpoint}`;
    const response = await fetch(url, {
      ...options,
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
    }

    return response.json();
  }

  // Auth endpoints
  async login(email: string, password: string): Promise<LoginResponse> {
    return this.request<LoginResponse>('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
  }

  async getCurrentUser(): Promise<User> {
    return this.request<User>('/api/auth/me');
  }

  // Dashboard statistics
  async getDashboardStats(): Promise<DashboardStats> {
    return this.request<DashboardStats>('/api/dashboard/stats');
  }

  // Client management
  async getClients() {
    return this.request('/api/client-management/clients');
  }

  async createClient(clientData: any) {
    return this.request('/api/client-management/clients', {
      method: 'POST',
      body: JSON.stringify(clientData),
    });
  }

  async updateClient(id: number, clientData: any) {
    return this.request(`/api/client-management/clients/${id}`, {
      method: 'PUT',
      body: JSON.stringify(clientData),
    });
  }

  async deleteClient(id: number) {
    return this.request(`/api/client-management/clients/${id}`, {
      method: 'DELETE',
    });
  }

  // Payments
  async getPayments() {
    return this.request('/api/payments');
  }

  async createPayment(paymentData: any) {
    return this.request('/api/payments', {
      method: 'POST',
      body: JSON.stringify(paymentData),
    });
  }

  async updatePayment(id: number, paymentData: any) {
    return this.request(`/api/payments/${id}`, {
      method: 'PUT',
      body: JSON.stringify(paymentData),
    });
  }

  async deletePayment(id: number) {
    return this.request(`/api/payments/${id}`, {
      method: 'DELETE',
    });
  }

  // Recent activity
  async getRecentActivity(): Promise<RecentActivity[]> {
    const response = await this.request<{ data: RecentActivity[] }>('/api/dashboard/recent-activity');
    return response.data || [];
  }

  // Upcoming sessions
  async getUpcomingSessions(): Promise<UpcomingSession[]> {
    const response = await this.request<{ data: UpcomingSession[] }>('/api/dashboard/upcoming-sessions');
    return response.data || [];
  }
}

export const apiService = new ApiService(); 