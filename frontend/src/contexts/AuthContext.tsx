import React, { createContext, useContext, useState, useEffect } from 'react';

interface User {
  name: string;
  email: string;
  phone?: string;
  specialization?: string;
  bio?: string;
  // Add more fields as needed
}

interface AuthContextType {
  isAuthenticated: boolean;
  user: User | null;
  loading: boolean;
  login: (token: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate restoring user from localStorage/token
    const token = localStorage.getItem('token');
    if (token) {
      // Simulate fetching user info
      setTimeout(() => {
        setUser({ name: 'Demo User', email: 'demo@example.com', phone: '', specialization: '', bio: '' });
        setIsAuthenticated(true);
        setLoading(false);
      }, 500);
    } else {
      setLoading(false);
    }
  }, []);

  async function login(token: string) {
    localStorage.setItem('token', token);
    setLoading(true);
    // Simulate API call to fetch user info
    await new Promise((resolve) => setTimeout(resolve, 500));
    setUser({ name: 'Demo User', email: 'demo@example.com', phone: '', specialization: '', bio: '' });
    setIsAuthenticated(true);
    setLoading(false);
  }

  function logout() {
    localStorage.removeItem('token');
    setIsAuthenticated(false);
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ isAuthenticated, user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
} 