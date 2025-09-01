-- ====================================
-- Fix System Admin User Role
-- ====================================
-- This script checks and fixes the system admin user role

-- 1. 먼저 현재 상태 확인
SELECT 
    '=== 현재 시스템 관리자 상태 ===' as check_type,
    e.id as employee_id,
    e.profile_id,
    e.user_role,
    e.company_id,
    e.status,
    p.email,
    c.name as company_name
FROM employees e
LEFT JOIN profiles p ON e.profile_id = p.id  
LEFT JOIN companies c ON e.company_id = c.id
WHERE p.email = 'system@clockbox.dev'
   OR e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- 2. 시스템 관리자 역할 수정
UPDATE employees 
SET 
    user_role = 'system_admin',
    updated_at = NOW()
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
   OR profile_id IN (
       SELECT id FROM profiles WHERE email = 'system@clockbox.dev'
   );

-- 3. user_roles_cache 테이블도 업데이트
UPDATE user_roles_cache 
SET 
    user_role = 'system_admin',
    updated_at = NOW()
WHERE user_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
   OR user_id IN (
       SELECT id FROM profiles WHERE email = 'system@clockbox.dev'
   );

-- 4. 변경 후 상태 확인
SELECT 
    '=== 수정 후 시스템 관리자 상태 ===' as check_type,
    e.id as employee_id,
    e.profile_id,
    e.user_role,
    e.company_id,
    e.status,
    p.email,
    c.name as company_name,
    urc.user_role as cache_role
FROM employees e
LEFT JOIN profiles p ON e.profile_id = p.id  
LEFT JOIN companies c ON e.company_id = c.id
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE p.email = 'system@clockbox.dev'
   OR e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- 5. 권한 설정도 업데이트
UPDATE employees 
SET 
    can_approve_leaves = TRUE,
    can_approve_overtime = TRUE
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
   OR profile_id IN (
       SELECT id FROM profiles WHERE email = 'system@clockbox.dev'
   );

-- 6. 최종 검증
SELECT 
    '=== 최종 검증 ===' as check_type,
    'User ID: ' || e.profile_id as info,
    'Email: ' || p.email as email_info,
    'Role: ' || e.user_role as role_info,
    'Cache Role: ' || urc.user_role as cache_role_info,
    'Can Approve: ' || e.can_approve_leaves as approval_info
FROM employees e
LEFT JOIN profiles p ON e.profile_id = p.id  
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE p.email = 'system@clockbox.dev'
   OR e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- Success message
SELECT 
    '🎉 시스템 관리자 역할 수정 완료!' as message,
    'system@clockbox.dev 사용자가 system_admin 역할로 설정되었습니다' as details;