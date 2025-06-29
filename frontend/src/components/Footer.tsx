import React from 'react';

const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-100 border-t border-gray-200 py-4 mt-auto">
      <div className="container mx-auto px-4 text-center">
        <p className="text-gray-600 text-sm">
          © {new Date().getFullYear()} NH-Personal. Todos os direitos reservados.
        </p>
      </div>
    </footer>
  );
};

export default Footer; 