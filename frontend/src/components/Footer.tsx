import React from 'react';

const Footer: React.FC = () => {
  return React.createElement(
    'footer',
    { style: { textAlign: 'center', padding: '1rem', background: '#f3f3f3' } },
    React.createElement(
      'p',
      null,
      `© ${new Date().getFullYear()} NH-Personal. Todos os direitos reservados.`
    )
  );
};

export default Footer; 