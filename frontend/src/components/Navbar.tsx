import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';

const Navbar: React.FC = () => {
  const { user, logout } = useAuth();
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <nav className="bg-primary-900 shadow-lg">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <h1 className="text-xl font-bold text-white">
                <span className="text-secondary-400">NH</span> Gestão de Alunos
              </h1>
            </div>
          </div>

          <div className="hidden md:flex items-center space-x-4">
            <span className="text-gray-300">
              Olá, {user?.name || 'Treinador'}
            </span>
            <button
              onClick={logout}
              className="bg-secondary-500 hover:bg-secondary-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors"
            >
              Sair
            </button>
          </div>

          {/* Mobile menu button */}
          <div className="md:hidden flex items-center">
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="text-gray-300 hover:text-white focus:outline-none focus:text-white"
            >
              <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Mobile menu */}
      {isMenuOpen && (
        <div className="md:hidden">
          <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3 bg-primary-800">
            <div className="px-3 py-2 text-gray-300">
              Olá, {user?.name || 'Treinador'}
            </div>
            <button
              onClick={logout}
              className="w-full text-left bg-secondary-500 hover:bg-secondary-600 text-white px-3 py-2 rounded-lg text-sm font-medium transition-colors"
            >
              Sair
            </button>
          </div>
        </div>
      )}
    </nav>
  );
};

export default Navbar; 