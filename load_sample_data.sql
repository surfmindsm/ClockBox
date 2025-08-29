-- Load sample data for ClockBox with actual user ID
-- Run this in Supabase SQL Editor

-- Insert sample company
INSERT INTO companies (id, name, business_number, industry, subscription_plan, created_at) VALUES
('550e8400-e29b-41d4-a716-446655442001', '테크스타트업', '123-45-67890', 'IT', 'enterprise', NOW())
ON CONFLICT (id) DO NOTHING;

-- Insert user profile for the created admin user
INSERT INTO profiles (id, email, full_name, created_at) VALUES
('550e8400-e29b-41d4-a716-446655442000', 'admin@techstartup.com', '김관리자', NOW())
ON CONFLICT (id) DO NOTHING;

-- Insert sample organizations under the company
INSERT INTO organizations (id, company_id, name, type, address, gps_lat, gps_lng, created_at) VALUES
('550e8400-e29b-41d4-a716-446655442002', '550e8400-e29b-41d4-a716-446655442001', '본사', 'headquarters', '서울시 강남구 테헤란로 123', 37.4979, 127.0276, NOW()),
('550e8400-e29b-41d4-a716-446655442003', '550e8400-e29b-41d4-a716-446655442001', 'IT부서', 'department', '서울시 강남구 테헤란로 123', 37.4979, 127.0276, NOW())
ON CONFLICT (id) DO NOTHING;

-- Insert roles first
INSERT INTO roles (id, company_id, name, description, level, created_at) VALUES
('550e8400-e29b-41d4-a716-446655442004', '550e8400-e29b-41d4-a716-446655442001', '관리자', 'System Administrator', 5, NOW()),
('550e8400-e29b-41d4-a716-446655442005', '550e8400-e29b-41d4-a716-446655442001', '매니저', 'Department Manager', 4, NOW()),
('550e8400-e29b-41d4-a716-446655442006', '550e8400-e29b-41d4-a716-446655442001', '사원', 'Employee', 2, NOW())
ON CONFLICT (id) DO NOTHING;

-- Insert sample employees using correct schema
INSERT INTO employees (
    id, profile_id, company_id, organization_id, role_id, 
    employee_number, department, position, user_role,
    hire_date, status, created_at
) VALUES
('550e8400-e29b-41d4-a716-446655442007', '550e8400-e29b-41d4-a716-446655442000', '550e8400-e29b-41d4-a716-446655442001', '550e8400-e29b-41d4-a716-446655442003', '550e8400-e29b-41d4-a716-446655442004', 'ADM001', 'IT', '관리자', 'admin', '2023-01-01', 'active', NOW())
ON CONFLICT (id) DO NOTHING;

-- Insert sample schedule for today
INSERT INTO schedules (id, employee_id, date, start_time, end_time, break_minutes, created_at) VALUES
('550e8400-e29b-41d4-a716-446655442008', '550e8400-e29b-41d4-a716-446655442007', '2025-08-28', '09:00:00', '18:00:00', 60, NOW())
ON CONFLICT (id) DO NOTHING;

-- Sample data loaded successfully! 
-- You can now login with:
-- Email: admin@techstartup.com
-- Password: password123