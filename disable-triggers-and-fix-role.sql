-- 트리거 비활성화하고 사용자 역할 고정

-- 1. 의심되는 트리거들 비활성화
DROP TRIGGER IF EXISTS user_roles_cache_trigger ON employees;
DROP TRIGGER IF EXISTS employee_role_change_trigger ON employees;

-- 2. 사용자 역할 강제 설정
UPDATE employees 
SET 
    user_role = 'system_admin',
    status = 'active',
    updated_at = NOW()
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- 3. 캐시도 수정
DELETE FROM user_roles_cache WHERE user_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

INSERT INTO user_roles_cache (user_id, company_id, user_role, updated_at)
VALUES (
    '41d856c2-5983-4f64-a43d-0e40f0542782',
    'c1111111-1111-1111-1111-111111111111',
    'system_admin',
    NOW()
);

-- 4. 확인
SELECT 
    '=== 트리거 비활성화 후 상태 ===' as check_type,
    e.id,
    e.user_role,
    e.status,
    e.updated_at,
    urc.user_role as cache_role
FROM employees e
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- Success message
SELECT 
    '🛑 트리거 비활성화 및 역할 고정 완료!' as message,
    'system@clockbox.dev가 system_admin으로 고정되었습니다' as details;