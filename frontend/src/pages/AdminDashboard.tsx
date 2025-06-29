import React from 'react';
import { useAuth } from '../contexts/AuthContext';

const AdminDashboard: React.FC = () => {
  const { user } = useAuth();

  return (
    <div className="max-w-5xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-6 text-primary-900">Painel de Administração</h1>
      <p className="mb-8 text-gray-700">Bem-vindo, {user?.name}! Aqui você pode gerenciar todos os personais, permissões e visualizar estatísticas do sistema.</p>
      {/* Aqui virão os componentes de gestão de personais, usuários e estatísticas globais */}
      <div className="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 className="text-xl font-semibold mb-4">Estatísticas Globais</h2>
        {/* Placeholder para estatísticas */}
        <div className="text-gray-500">(Em breve: total de personais, clientes, usuários ativos, etc)</div>
      </div>
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-xl font-semibold mb-4">Gestão de Personais</h2>
        {/* Placeholder para CRUD de personais */}
        <div className="text-gray-500">(Em breve: lista, criação, edição, ativação/desativação, reset de senha, etc)</div>
      </div>
    </div>
  );
};

export default AdminDashboard; 