const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');

// Configurar a URL do banco de dados
const databaseURL = 'mysql://admin:Rdms95gn!@personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com:3306/personal_trainer_db';
process.env.DATABASE_URL = databaseURL;

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: databaseURL,
    },
  },
});

async function createAdminUser() {
  try {
    console.log('🔐 Conectando ao banco de dados...');
    await prisma.$connect();
    
    // Verificar se o usuário já existe
    const existingUser = await prisma.user.findUnique({
      where: { email: 'nholanda@nhpersonal.com' }
    });

    if (existingUser) {
      console.log('⚠️ Usuário nholanda já existe!');
      console.log('📝 Atualizando senha e perfil...');
      
      // Atualizar senha
      const hashedPassword = await bcrypt.hash('P10r1988!', 12);
      
      await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          passwordHash: hashedPassword,
          role: 'admin',
          name: 'Nelson Holanda',
          phone: '+55 11 99999-9999',
          isActive: true,
          updatedAt: new Date()
        }
      });
      
      console.log('✅ Usuário nholanda atualizado com sucesso!');
    } else {
      console.log('👤 Criando usuário administrador nholanda...');
      
      // Criar hash da senha
      const hashedPassword = await bcrypt.hash('P10r1988!', 12);
      
      // Criar usuário administrador
      const adminUser = await prisma.user.create({
        data: {
          name: 'Nelson Holanda',
          email: 'nholanda@nhpersonal.com',
          passwordHash: hashedPassword,
          role: 'admin',
          phone: '+55 11 99999-9999',
          birthDate: new Date('1988-10-01'),
          gender: 'male',
          height: 1.75,
          weight: 80.0,
          isActive: true,
          passwordChangedAt: new Date(),
          createdAt: new Date(),
          updatedAt: new Date()
        }
      });
      
      console.log('✅ Usuário administrador criado com sucesso!');
      console.log(`🆔 ID: ${adminUser.id}`);
    }
    
    // Criar perfil de treinador para o administrador
    const adminUser = await prisma.user.findUnique({
      where: { email: 'nholanda@nhpersonal.com' }
    });
    
    if (adminUser) {
      const existingTrainerProfile = await prisma.trainerProfile.findUnique({
        where: { userId: adminUser.id }
      });
      
      if (!existingTrainerProfile) {
        console.log('🏋️ Criando perfil de treinador...');
        
        await prisma.trainerProfile.create({
          data: {
            userId: adminUser.id,
            specialization: 'Personal Trainer, Treinamento Funcional, Musculação',
            experienceYears: 15,
            certifications: 'CREF - Conselho Regional de Educação Física\nEspecialização em Treinamento Funcional\nCertificação em Nutrição Esportiva',
            bio: 'Personal Trainer com mais de 15 anos de experiência, especializado em treinamento funcional e musculação. Formado em Educação Física e com diversas certificações na área.',
            hourlyRate: 150.00,
            availability: JSON.stringify({
              monday: { morning: true, afternoon: true, evening: true },
              tuesday: { morning: true, afternoon: true, evening: true },
              wednesday: { morning: true, afternoon: true, evening: true },
              thursday: { morning: true, afternoon: true, evening: true },
              friday: { morning: true, afternoon: true, evening: false },
              saturday: { morning: true, afternoon: false, evening: false },
              sunday: { morning: false, afternoon: false, evening: false }
            }),
            createdAt: new Date(),
            updatedAt: new Date()
          }
        });
        
        console.log('✅ Perfil de treinador criado com sucesso!');
      } else {
        console.log('⚠️ Perfil de treinador já existe!');
      }
    }
    
    // Criar dados iniciais do sistema
    await createInitialData(prisma);
    
    console.log('');
    console.log('🎉 Configuração do sistema concluída!');
    console.log('=====================================');
    console.log('👤 Usuário: nholanda@nhpersonal.com');
    console.log('🔑 Senha: P10r1988!');
    console.log('👑 Perfil: Administrador');
    console.log('🏋️ Perfil: Personal Trainer');
    console.log('');
    console.log('💡 Use essas credenciais para acessar o sistema!');
    
  } catch (error) {
    console.error('❌ Erro ao criar usuário administrador:', error);
  } finally {
    await prisma.$disconnect();
  }
}

async function createInitialData(prisma) {
  console.log('📊 Criando dados iniciais do sistema...');
  
  // Criar métodos de pagamento
  const paymentMethods = [
    { name: 'Dinheiro', description: 'Pagamento em dinheiro' },
    { name: 'PIX', description: 'Transferência via PIX' },
    { name: 'Cartão de Crédito', description: 'Pagamento com cartão de crédito' },
    { name: 'Cartão de Débito', description: 'Pagamento com cartão de débito' },
    { name: 'Transferência Bancária', description: 'Transferência bancária' }
  ];
  
  for (const method of paymentMethods) {
    const existing = await prisma.paymentMethod.findFirst({
      where: { name: method.name }
    });
    
    if (!existing) {
      await prisma.paymentMethod.create({
        data: method
      });
    }
  }
  
  // Criar planos de pagamento padrão
  const paymentPlans = [
    {
      name: 'Plano Básico',
      description: '3 sessões por semana',
      price: 300.00,
      durationWeeks: 4,
      sessionsPerWeek: 3
    },
    {
      name: 'Plano Intermediário',
      description: '4 sessões por semana',
      price: 400.00,
      durationWeeks: 4,
      sessionsPerWeek: 4
    },
    {
      name: 'Plano Avançado',
      description: '5 sessões por semana',
      price: 500.00,
      durationWeeks: 4,
      sessionsPerWeek: 5
    }
  ];
  
  for (const plan of paymentPlans) {
    const existing = await prisma.paymentPlan.findFirst({
      where: { name: plan.name }
    });
    
    if (!existing) {
      await prisma.paymentPlan.create({
        data: plan
      });
    }
  }
  
  console.log('✅ Dados iniciais criados com sucesso!');
}

// Executar o script
createAdminUser().catch(console.error); 