import React from 'react';
import { useAuth } from '../contexts/AuthContext';

const Home: React.FC = () => {
  const { user } = useAuth();

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 to-primary-100">
      {/* Hero Section */}
      <div className="relative overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
          <div className="text-center">
            <h1 className="text-5xl font-bold text-primary-900 mb-6">
              <span className="text-secondary-600">NH</span> Gestão de Alunos
            </h1>
            <p className="text-xl text-primary-700 mb-10 max-w-3xl mx-auto leading-relaxed">
              Ferramentas completas para gestão de alunos e personal trainers. 
              Simplifique sua rotina e foque no que realmente importa: seus clientes.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <button className="bg-secondary-600 text-white px-8 py-4 rounded-lg text-lg font-semibold hover:bg-secondary-700 transition-colors shadow-lg hover:shadow-xl">
                Começar Agora
              </button>
              <button className="border-2 border-secondary-600 text-secondary-700 px-8 py-4 rounded-lg text-lg font-semibold hover:bg-secondary-600 hover:text-white transition-colors bg-white">
                Saiba Mais
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-primary-900 mb-6">
              Tudo que você precisa para gerenciar seu negócio
            </h2>
            <p className="text-xl text-primary-700 max-w-3xl mx-auto leading-relaxed">
              Ferramentas completas e intuitivas para gestão de alunos e personal trainers
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Gestão de Clientes */}
            <div className="bg-white p-8 rounded-xl shadow-lg border border-primary-100 hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
              <div className="w-14 h-14 bg-primary-100 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-primary-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-primary-900 mb-3">Gestão de Clientes</h3>
              <p className="text-primary-700 leading-relaxed">
                Cadastre e gerencie seus clientes com informações completas, histórico de treinos e progressos detalhados.
              </p>
            </div>

            {/* Controle Financeiro */}
            <div className="bg-white p-8 rounded-xl shadow-lg border border-primary-100 hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
              <div className="w-14 h-14 bg-secondary-100 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-secondary-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-primary-900 mb-3">Controle Financeiro</h3>
              <p className="text-primary-700 leading-relaxed">
                Acompanhe pagamentos, gere relatórios financeiros e controle receitas de forma organizada e transparente.
              </p>
            </div>

            {/* Planos de Treino */}
            <div className="bg-white p-8 rounded-xl shadow-lg border border-primary-100 hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
              <div className="w-14 h-14 bg-primary-100 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-primary-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-primary-900 mb-3">Planos de Treino</h3>
              <p className="text-primary-700 leading-relaxed">
                Crie e personalize planos de treino específicos para cada cliente com exercícios detalhados e progressivos.
              </p>
            </div>

            {/* Acompanhamento de Progresso */}
            <div className="bg-white p-8 rounded-xl shadow-lg border border-primary-100 hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
              <div className="w-14 h-14 bg-secondary-100 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-secondary-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-primary-900 mb-3">Acompanhamento de Progresso</h3>
              <p className="text-primary-700 leading-relaxed">
                Monitore o progresso dos seus clientes com gráficos interativos e relatórios detalhados de evolução.
              </p>
            </div>

            {/* Agendamento */}
            <div className="bg-white p-8 rounded-xl shadow-lg border border-primary-100 hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
              <div className="w-14 h-14 bg-primary-100 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-primary-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-primary-900 mb-3">Agendamento</h3>
              <p className="text-primary-700 leading-relaxed">
                Organize sua agenda, agende sessões e gerencie horários de forma eficiente e sem conflitos.
              </p>
            </div>

            {/* Relatórios */}
            <div className="bg-white p-8 rounded-xl shadow-lg border border-primary-100 hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
              <div className="w-14 h-14 bg-secondary-100 rounded-xl flex items-center justify-center mb-6">
                <svg className="w-7 h-7 text-secondary-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-primary-900 mb-3">Relatórios Detalhados</h3>
              <p className="text-primary-700 leading-relaxed">
                Gere relatórios completos sobre performance, financeiro e progresso dos clientes com visualizações claras.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="bg-gradient-to-r from-primary-700 to-primary-800 py-20">
        <div className="max-w-4xl mx-auto text-center px-4 sm:px-6 lg:px-8">
          <h2 className="text-4xl font-bold text-white mb-6">
            Pronto para transformar seu negócio?
          </h2>
          <p className="text-xl text-primary-100 mb-10 max-w-2xl mx-auto leading-relaxed">
            Junte-se a centenas de profissionais que já estão usando nossa plataforma para otimizar seus resultados
          </p>
          <button className="bg-secondary-600 text-white px-10 py-4 rounded-lg text-lg font-semibold hover:bg-secondary-700 transition-colors shadow-lg hover:shadow-xl">
            Começar Gratuitamente
          </button>
        </div>
      </div>
    </div>
  );
};

export default Home; 