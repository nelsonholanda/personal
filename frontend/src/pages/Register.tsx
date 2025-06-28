import React from 'react';

const Register: React.FC = () => {
  return React.createElement(
    'div',
    { style: { display: 'flex', flexDirection: 'column', alignItems: 'center', marginTop: '5rem' } },
    [
      React.createElement('h2', { key: 'title' }, 'Cadastro'),
      React.createElement(
        'form',
        { 
          key: 'form',
          style: { display: 'flex', flexDirection: 'column', gap: '1rem', width: '300px' }
        },
        [
          React.createElement('input', { key: 'name', type: 'text', placeholder: 'Nome completo' }),
          React.createElement('input', { key: 'email', type: 'email', placeholder: 'Email' }),
          React.createElement('input', { key: 'password', type: 'password', placeholder: 'Senha' }),
          React.createElement('input', { key: 'confirm', type: 'password', placeholder: 'Confirmar senha' }),
          React.createElement('button', { key: 'submit', type: 'submit' }, 'Cadastrar')
        ]
      )
    ]
  );
};

export default Register; 