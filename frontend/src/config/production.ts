export const productionConfig = {
  apiUrl: process.env.REACT_APP_API_URL || 'http://localhost:3001/api',
  environment: 'production',
  version: '1.0.0',
  appName: 'NH Gestão de Alunos',
  appDescription: 'Sistema de Gestão para Personal Trainers',
  
  // Configurações de Analytics
  analytics: {
    enabled: true,
    trackingId: process.env.REACT_APP_GA_TRACKING_ID,
  },
  
  // Configurações de Monitoramento
  monitoring: {
    sentryDsn: process.env.REACT_APP_SENTRY_DSN,
  },
  
  // Configurações de Performance
  performance: {
    enableSourceMaps: false,
    enableInlineRuntime: false,
  },
  
  // Configurações de Segurança
  security: {
    enableHttps: true,
    enableCsp: true,
  }
}; 