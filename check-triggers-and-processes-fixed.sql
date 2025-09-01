-- 사용자 역할을 되돌리는 트리거나 프로세스 확인

-- 1. employees 테이블의 트리거 확인
SELECT 
    '=== employees 테이블 트리거 ===' as check_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'employees'
ORDER BY trigger_name;

-- 2. user_roles_cache 관련 트리거 확인  
SELECT 
    '=== user_roles_cache 트리거 ===' as check_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
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

-- 4. audit_logs 테이블 구조 확인
SELECT 
    '=== audit_logs 테이블 컬럼 ===' as check_type,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'audit_logs'
ORDER BY ordinal_position;

-- 5. audit_logs에서 최근 변경 이력 확인 (사용 가능한 컬럼만)
SELECT 
    '=== 최근 변경 이력 ===' as check_type,
    action,
    entity_type,
    entity_id,
    created_at
FROM audit_logs 
WHERE entity_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
   OR entity_id IN (
       SELECT id::text FROM employees 
       WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
   )
ORDER BY created_at DESC
LIMIT 10;