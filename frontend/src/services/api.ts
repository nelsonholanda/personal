const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

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
  async login(email: string, password: string) {
    return this.request('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
  }

  async getCurrentUser() {
    return this.request('/api/auth/me');
  }

  // Dashboard statistics
  async getDashboardStats() {
    const response = await this.request('/api/dashboard/stats');
    return response;
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
  async getRecentActivity() {
    const response = await this.request<any>('/api/dashboard/recent-activity');
    return response.data || [];
  }

  // Upcoming sessions
  async getUpcomingSessions() {
    const response = await this.request<any>('/api/dashboard/upcoming-sessions');
    return response.data || [];
  }
}

export const apiService = new ApiService(); 