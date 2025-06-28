-- NH-Personal Database Initialization Script

USE personal_trainer_db;

-- Users table (Personal Trainers and Clients)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('trainer', 'client', 'admin') DEFAULT 'client',
    phone VARCHAR(20),
    birth_date DATE,
    gender ENUM('male', 'female', 'other'),
    height DECIMAL(5,2), -- in cm
    weight DECIMAL(5,2), -- in kg
    profile_image_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    password_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Personal Trainer Profiles
CREATE TABLE IF NOT EXISTS trainer_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    specialization TEXT,
    experience_years INT,
    certifications TEXT,
    bio TEXT,
    hourly_rate DECIMAL(10,2),
    availability JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Client Profiles
CREATE TABLE IF NOT EXISTS client_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    fitness_goals TEXT,
    medical_conditions TEXT,
    emergency_contact VARCHAR(255),
    emergency_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Client Management (Gestão de Alunos)
CREATE TABLE IF NOT EXISTS client_management (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trainer_id INT NOT NULL,
    client_id INT NOT NULL,
    status ENUM('active', 'inactive', 'suspended', 'completed') DEFAULT 'active',
    start_date DATE NOT NULL,
    end_date DATE,
    weekly_sessions INT DEFAULT 3, -- Quantas aulas por semana
    session_duration_minutes INT DEFAULT 60,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (trainer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_trainer_client (trainer_id, client_id)
);

-- Payment Plans (Planos de Pagamento)
CREATE TABLE IF NOT EXISTS payment_plans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    duration_weeks INT NOT NULL,
    sessions_per_week INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Client Subscriptions (Assinaturas dos Clientes)
CREATE TABLE IF NOT EXISTS client_subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_management_id INT NOT NULL,
    payment_plan_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_sessions INT NOT NULL,
    sessions_used INT DEFAULT 0,
    status ENUM('active', 'completed', 'cancelled', 'expired') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (client_management_id) REFERENCES client_management(id) ON DELETE CASCADE,
    FOREIGN KEY (payment_plan_id) REFERENCES payment_plans(id) ON DELETE CASCADE
);

-- Payment Methods (Formas de Pagamento)
CREATE TABLE IF NOT EXISTS payment_methods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments (Pagamentos)
CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_subscription_id INT NOT NULL,
    payment_method_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    due_date DATE NOT NULL,
    status ENUM('pending', 'paid', 'overdue', 'cancelled') DEFAULT 'pending',
    payment_reference VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (client_subscription_id) REFERENCES client_subscriptions(id) ON DELETE CASCADE,
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id) ON DELETE CASCADE
);

-- Payment Installments (Parcelas)
CREATE TABLE IF NOT EXISTS payment_installments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payment_id INT NOT NULL,
    installment_number INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    payment_date DATE,
    status ENUM('pending', 'paid', 'overdue', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE
);

-- Training Plans
CREATE TABLE IF NOT EXISTS training_plans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trainer_id INT NOT NULL,
    client_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    duration_weeks INT,
    status ENUM('active', 'completed', 'paused', 'cancelled') DEFAULT 'active',
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (trainer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Workouts
CREATE TABLE IF NOT EXISTS workouts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    training_plan_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    duration_minutes INT,
    difficulty_level ENUM('beginner', 'intermediate', 'advanced'),
    day_of_week INT, -- 1=Monday, 7=Sunday
    order_in_plan INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (training_plan_id) REFERENCES training_plans(id) ON DELETE CASCADE
);

-- Exercises
CREATE TABLE IF NOT EXISTS exercises (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    muscle_groups JSON,
    equipment_needed JSON,
    difficulty_level ENUM('beginner', 'intermediate', 'advanced'),
    video_url VARCHAR(500),
    image_url VARCHAR(500),
    instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Workout Exercises (Many-to-Many relationship)
CREATE TABLE IF NOT EXISTS workout_exercises (
    id INT AUTO_INCREMENT PRIMARY KEY,
    workout_id INT NOT NULL,
    exercise_id INT NOT NULL,
    sets INT,
    reps INT,
    duration_seconds INT,
    rest_seconds INT,
    weight_kg DECIMAL(5,2),
    order_in_workout INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
);

-- Workout Sessions (Client's actual workout logs)
CREATE TABLE IF NOT EXISTS workout_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    workout_id INT NOT NULL,
    session_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    status ENUM('planned', 'in_progress', 'completed', 'skipped') DEFAULT 'planned',
    notes TEXT,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE
);

-- Exercise Logs (Individual exercise performance)
CREATE TABLE IF NOT EXISTS exercise_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    workout_session_id INT NOT NULL,
    exercise_id INT NOT NULL,
    sets_completed INT,
    reps_completed INT,
    duration_seconds INT,
    weight_kg DECIMAL(5,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (workout_session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
);

-- Progress Tracking
CREATE TABLE IF NOT EXISTS progress_measurements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    measurement_date DATE NOT NULL,
    weight_kg DECIMAL(5,2),
    body_fat_percentage DECIMAL(4,2),
    muscle_mass_kg DECIMAL(5,2),
    chest_cm DECIMAL(5,2),
    waist_cm DECIMAL(5,2),
    hips_cm DECIMAL(5,2),
    biceps_cm DECIMAL(5,2),
    thighs_cm DECIMAL(5,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Appointments/Sessions
CREATE TABLE IF NOT EXISTS appointments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trainer_id INT NOT NULL,
    client_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    type ENUM('consultation', 'training', 'assessment', 'follow_up'),
    status ENUM('scheduled', 'confirmed', 'completed', 'cancelled', 'no_show') DEFAULT 'scheduled',
    notes TEXT,
    location VARCHAR(255),
    is_online BOOLEAN DEFAULT FALSE,
    meeting_link VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (trainer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Messages/Chat
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    message_text TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('appointment', 'workout', 'message', 'progress', 'payment', 'system'),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Financial Reports (Relatórios Financeiros)
CREATE TABLE IF NOT EXISTS financial_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trainer_id INT NOT NULL,
    report_date DATE NOT NULL,
    total_received DECIMAL(12,2) DEFAULT 0,
    total_pending DECIMAL(12,2) DEFAULT 0,
    total_overdue DECIMAL(12,2) DEFAULT 0,
    active_clients INT DEFAULT 0,
    total_sessions INT DEFAULT 0,
    report_data JSON, -- Dados detalhados do relatório
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trainer_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Password History (Histórico de senhas para segurança)
CREATE TABLE IF NOT EXISTS password_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Insert default admin user (nholanda)
-- Password: rdms95gn (encrypted with bcrypt, cost 12)
INSERT INTO users (name, email, password_hash, role, is_active) VALUES 
('nholanda', 'admin@nhpersonal.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj2ZxQQxqK8e', 'admin');

-- Insert default payment methods
INSERT INTO payment_methods (name, description) VALUES
('Dinheiro', 'Pagamento em dinheiro'),
('PIX', 'Transferência via PIX'),
('Cartão de Crédito', 'Pagamento com cartão de crédito'),
('Cartão de Débito', 'Pagamento com cartão de débito'),
('Transferência Bancária', 'Transferência bancária'),
('Boleto Bancário', 'Pagamento via boleto');

-- Insert default payment plans
INSERT INTO payment_plans (name, description, price, duration_weeks, sessions_per_week) VALUES
('Plano Básico', '1 aula por semana', 150.00, 4, 1),
('Plano Intermediário', '2 aulas por semana', 250.00, 4, 2),
('Plano Avançado', '3 aulas por semana', 350.00, 4, 3),
('Plano Premium', '4 aulas por semana', 450.00, 4, 4),
('Plano Personalizado', 'Aulas personalizadas', 200.00, 4, 1);

-- Insert some sample exercises
INSERT INTO exercises (name, description, muscle_groups, equipment_needed, difficulty_level, instructions) VALUES
('Push-ups', 'Classic bodyweight exercise for chest and triceps', '["chest", "triceps", "shoulders"]', '["none"]', 'beginner', 'Start in plank position, lower body until chest nearly touches ground, push back up'),
('Squats', 'Fundamental lower body exercise', '["quadriceps", "glutes", "hamstrings"]', '["none"]', 'beginner', 'Stand with feet shoulder-width apart, lower body as if sitting back, return to standing'),
('Deadlift', 'Compound exercise for posterior chain', '["hamstrings", "glutes", "lower_back"]', '["barbell", "weights"]', 'intermediate', 'Stand with feet hip-width apart, grip bar, lift by extending hips and knees'),
('Bench Press', 'Classic chest exercise', '["chest", "triceps", "shoulders"]', '["barbell", "bench", "weights"]', 'intermediate', 'Lie on bench, lower bar to chest, press back up'),
('Pull-ups', 'Upper body pulling exercise', '["back", "biceps", "shoulders"]', '["pull_up_bar"]', 'intermediate', 'Hang from bar, pull body up until chin over bar, lower with control');

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_password_reset_token ON users(password_reset_token);
CREATE INDEX idx_client_management_trainer ON client_management(trainer_id);
CREATE INDEX idx_client_management_client ON client_management(client_id);
CREATE INDEX idx_client_management_status ON client_management(status);
CREATE INDEX idx_payments_subscription ON payments(client_subscription_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payment_installments_payment ON payment_installments(payment_id);
CREATE INDEX idx_payment_installments_status ON payment_installments(status);
CREATE INDEX idx_training_plans_trainer ON training_plans(trainer_id);
CREATE INDEX idx_training_plans_client ON training_plans(client_id);
CREATE INDEX idx_workouts_plan ON workouts(training_plan_id);
CREATE INDEX idx_workout_sessions_client ON workout_sessions(client_id);
CREATE INDEX idx_workout_sessions_date ON workout_sessions(session_date);
CREATE INDEX idx_appointments_trainer ON appointments(trainer_id);
CREATE INDEX idx_appointments_client ON appointments(client_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_financial_reports_trainer ON financial_reports(trainer_id);
CREATE INDEX idx_financial_reports_date ON financial_reports(report_date);
CREATE INDEX idx_password_history_user ON password_history(user_id); 