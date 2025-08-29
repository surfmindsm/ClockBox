-- 새 사용자 설정을 위한 SQL
-- admin@clockbox.test 사용자를 위한 조직 및 직원 데이터 생성

-- 1. 회사 생성 (이미 있다면 무시)
INSERT INTO companies (id, name, business_number, industry, subscription_plan, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440000', '클락박스', '123-45-67890', 'IT', 'enterprise', NOW())
ON CONFLICT (id) DO NOTHING;

-- 2. 조직 생성 (이미 있다면 무시)
INSERT INTO organizations (id, company_id, name, type, address, gps_lat, gps_lng, created_at) VALUES
('550e8400-e29b-41d4-a716-446655441000', '550e8400-e29b-41d4-a716-446655440000', 'IT부서', 'department', '서울시 강남구 테헤란로 123', 37.4979, 127.0276, NOW())
ON CONFLICT (id) DO NOTHING;

-- 3. 역할 생성 (이미 있다면 무시)
INSERT INTO roles (id, company_id, name, description, level, created_at) VALUES
('550e8400-e29b-41d4-a716-446655443000', '550e8400-e29b-41d4-a716-446655440000', '관리자', 'System Administrator', 5, NOW())
ON CONFLICT (id) DO NOTHING;

-- 4. 실제 로그인한 사용자 ID를 여기에 입력하세요
-- Supabase Dashboard > Authentication > Users에서 사용자 ID를 확인하고 아래 줄을 수정하세요
-- 예: '실제_사용자_ID_여기에_입력'을 복사한 실제 ID로 변경

-- 5. 직원 레코드 생성 (사용자 ID를 실제 값으로 변경해야 함)
INSERT INTO employees (
    id, profile_id, company_id, organization_id, role_id, 
    employee_number, department, position, user_role,
    hire_date, status, created_at
) VALUES
('550e8400-e29b-41d4-a716-446655444000', '실제_사용자_ID_여기에_입력', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655441000', '550e8400-e29b-41d4-a716-446655443000', 'ADM001', 'IT', '관리자', 'admin', '2025-08-29', 'active', NOW())
ON CONFLICT (id) DO NOTHING;

-- 6. 오늘 일정 생성 (사용자 ID를 실제 값으로 변경해야 함)
INSERT INTO schedules (id, employee_id, date, start_time, end_time, break_minutes, created_at) VALUES
('550e8400-e29b-41d4-a716-446655445000', '550e8400-e29b-41d4-a716-446655444000', '2025-08-29', '09:00:00', '18:00:00', 60, NOW())
ON CONFLICT (id) DO NOTHING;

-- 실행 전에 반드시:
-- 1. Supabase Dashboard에서 실제 사용자 ID 확인
-- 2. 위의 '실제_사용자_ID_여기에_입력'을 실제 ID로 변경
-- 3. 날짜를 현재 날짜로 변경