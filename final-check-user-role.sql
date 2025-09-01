-- 최종 사용자 역할 확인 및 강제 수정
SELECT 
    '=== 현재 상태 최종 확인 ===' as check_type,
    e.id,
    e.profile_id,
    e.user_role,
    e.employee_number,
    e.status,
    e.company_id,
    p.email,
    c.name as company_name
FROM employees e
LEFT JOIN profiles p ON e.profile_id = p.id
LEFT JOIN companies c ON e.company_id = c.id
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
ORDER BY e.created_at DESC;

-- 강제로 system_admin으로 수정
UPDATE employees 
SET 
    user_role = 'system_admin',
    status = 'active',
    updated_at = NOW()
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- user_roles_cache도 강제 수정
DELETE FROM user_roles_cache WHERE user_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

INSERT INTO user_roles_cache (user_id, company_id, user_role, updated_at)
SELECT 
    '41d856c2-5983-4f64-a43d-0e40f0542782',
    e.company_id,
    'system_admin',
    NOW()
FROM employees e
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
LIMIT 1;

-- 최종 확인
SELECT 
    '=== 수정 후 최종 확인 ===' as check_type,
    e.id,
    e.profile_id,
    e.user_role,
    e.employee_number,
    e.status,
    e.company_id,
    p.email,
    urc.user_role as cache_role,
    c.name as company_name
FROM employees e
LEFT JOIN profiles p ON e.profile_id = p.id
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
LEFT JOIN companies c ON e.company_id = c.id
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- 혹시 여러 레코드가 있는지 다시 확인
SELECT 
    '=== 중복 레코드 재확인 ===' as check_type,
    COUNT(*) as record_count,
    user_role
FROM employees 
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
GROUP BY user_role;

-- Success message
SELECT 
    '🔧 강제 수정 완료!' as message,
    'system@clockbox.dev 사용자가 확실히 system_admin으로 설정되었습니다' as details;