-- 현재 시스템 관리자 상태 상세 확인
SELECT 
    '=== employees 테이블 ===' as table_name,
    e.id,
    e.profile_id,
    e.user_role,
    e.company_id,
    e.status,
    e.can_approve_leaves,
    e.can_approve_overtime,
    e.created_at,
    e.updated_at
FROM employees e
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

SELECT 
    '=== profiles 테이블 ===' as table_name,
    p.id,
    p.email,
    p.full_name,
    p.created_at,
    p.updated_at
FROM profiles p
WHERE p.id = '41d856c2-5983-4f64-a43d-0e40f0542782' 
   OR p.email = 'system@clockbox.dev';

SELECT 
    '=== user_roles_cache 테이블 ===' as table_name,
    urc.user_id,
    urc.company_id,
    urc.user_role,
    urc.updated_at
FROM user_roles_cache urc
WHERE urc.user_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- 모든 employees 레코드 확인 (혹시 중복이 있는지)
SELECT 
    '=== 모든 관련 employees ===' as table_name,
    e.id,
    e.profile_id,
    e.user_role,
    e.employee_number,
    e.status,
    p.email
FROM employees e
LEFT JOIN profiles p ON e.profile_id = p.id
WHERE p.email = 'system@clockbox.dev'
   OR e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';