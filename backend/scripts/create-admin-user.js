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

    // Apagar todos os usuários que não são admin
    await prisma.user.deleteMany({ where: { role: { not: 'admin' } } });
    // Apagar também o usuário nholanda@nhpersonal.com se existir
    await prisma.user.deleteMany({ where: { email: 'nholanda@nhpersonal.com' } });

    // Verificar se o usuário admin 'nholanda' já existe
    let adminUser = await prisma.user.findFirst({ where: { name: 'nholanda', role: 'admin' } });

    if (adminUser) {
      // Atualizar senha
      const hashedPassword = await bcrypt.hash('P10r1988!', 12);
      await prisma.user.update({
        where: { id: adminUser.id },
        data: {
          passwordHash: hashedPassword,
          isActive: true,
          updatedAt: new Date(),
        },
      });
      console.log('✅ Usuário admin "nholanda" atualizado com sucesso!');
    } else {
      // Criar usuário admin
      const hashedPassword = await bcrypt.hash('P10r1988!', 12);
      adminUser = await prisma.user.create({
        data: {
          name: 'nholanda',
          passwordHash: hashedPassword,
          role: 'admin',
          isActive: true,
          passwordChangedAt: new Date(),
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      });
      console.log('✅ Usuário admin "nholanda" criado com sucesso!');
    }

    // Criar perfil de treinador para o admin se não existir
    const existingTrainerProfile = await prisma.trainerProfile.findUnique({ where: { userId: adminUser.id } });
    if (!existingTrainerProfile) {
      await prisma.trainerProfile.create({
        data: {
          userId: adminUser.id,
          specialization: 'Personal Trainer, Treinamento Funcional, Musculação',
          experienceYears: 15,
          certifications: 'CREF, Especialização em Treinamento Funcional, Certificação em Nutrição Esportiva',
          bio: 'Administrador e Personal Trainer do sistema.',
          hourlyRate: 150.00,
          availability: JSON.stringify({}),
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      });
      console.log('✅ Perfil de treinador para admin criado com sucesso!');
    }

    // Criar dados iniciais do sistema (caso queira manter)
    // await createInitialData(prisma);

    console.log('🎉 Configuração do admin concluída!');
    console.log('=====================================');
    console.log('👤 Usuário: nholanda (admin)');
    console.log('💡 Use essas credenciais para acessar o sistema!');
  } catch (error) {
    console.error('❌ Erro ao criar usuário administrador:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createAdminUser(); 