-- 사용자 역할을 되돌리는 트리거나 프로세스 확인 (최종 버전)

-- 1. employees 테이블의 트리거 확인
SELECT 
    '=== employees 테이블 트리거 ===' as check_type,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'employees'
ORDER BY trigger_name;

-- 2. user_roles_cache 관련 트리거 확인  
SELECT 
    '=== user_roles_cache 트리거 ===' as check_type,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'user_roles_cache'
ORDER BY trigger_name;

-- 3. 현재 사용자 상태 확인
SELECT 
    '=== 현재 사용자 상태 ===' as check_type,
    e.id,
    e.user_role,
    e.updated_at,
    urc.user_role as cache_role,
    urc.updated_at as cache_updated_at
FROM employees e
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- 4. employees 테이블에서 이 사용자의 모든 레코드 확인
SELECT 
    '=== 사용자의 모든 employee 레코드 ===' as check_type,
    id,
    profile_id,
    user_role,
    status,
    created_at,
    updated_at
FROM employees
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
ORDER BY updated_at DESC;