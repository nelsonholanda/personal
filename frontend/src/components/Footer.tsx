import React from 'react';

const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-100 border-t border-gray-200 py-4 mt-auto">
      <div className="container mx-auto px-4 text-center">
        <div className="text-center text-gray-400 text-sm">
          © {new Date().getFullYear()} NH Gestão de Alunos. Todos os direitos reservados.
        </div>
      </div>
    </footer>
  );
};

export default Footer; 