-- 데이터베이스 전체 진단 및 문제점 파악 스크립트

-- ========================================
-- 1. 데이터 무결성 문제 체크
-- ========================================

-- 1.1 중복 employees 레코드 확인
SELECT 
    '=== 중복 employees 레코드 ===' as check_type,
    profile_id, 
    COUNT(*) as record_count,
    STRING_AGG(id::text, ', ') as employee_ids,
    STRING_AGG(user_role, ', ') as roles,
    STRING_AGG(status, ', ') as statuses
FROM employees 
GROUP BY profile_id 
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

-- 1.2 orphaned 레코드들 (foreign key 관계가 깨진 것들)
SELECT '=== employees without valid profile_id ===' as check_type, COUNT(*) as count
FROM employees e 
LEFT JOIN auth.users u ON e.profile_id = u.id 
WHERE u.id IS NULL;

SELECT '=== employees without valid company_id ===' as check_type, COUNT(*) as count
FROM employees e 
LEFT JOIN companies c ON e.company_id = c.id 
WHERE c.id IS NULL AND e.company_id IS NOT NULL;

-- 1.3 user_roles_cache와 employees 불일치
SELECT 
    '=== 역할 불일치 (employees vs cache) ===' as check_type,
    e.profile_id,
    e.user_role as employee_role,
    urc.user_role as cache_role,
    CASE WHEN e.user_role != urc.user_role THEN 'MISMATCH' ELSE 'OK' END as status
FROM employees e
FULL OUTER JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE e.user_role != urc.user_role OR e.profile_id IS NULL OR urc.user_id IS NULL;

-- ========================================
-- 2. 테이블별 데이터 상태 확인
-- ========================================

-- 2.1 모든 테이블의 레코드 수
SELECT 
    '=== 테이블별 레코드 수 ===' as check_type,
    schemaname,
    relname as tablename,
    n_tup_ins - n_tup_del as record_count
FROM pg_stat_user_tables 
ORDER BY record_count DESC;

-- 2.2 companies 테이블 상태
SELECT 
    '=== companies 상태 ===' as check_type,
    id,
    name,
    onboarding_completed,
    status,
    created_at,
    updated_at
FROM companies 
ORDER BY created_at;

-- 2.3 employees 전체 상태
SELECT 
    '=== 모든 employees 상태 ===' as check_type,
    e.id,
    e.profile_id,
    u.email,
    e.user_role,
    e.status,
    e.company_id,
    c.name as company_name,
    e.created_at,
    e.updated_at
FROM employees e
LEFT JOIN auth.users u ON e.profile_id = u.id
LEFT JOIN companies c ON e.company_id = c.id
ORDER BY e.updated_at DESC;

-- 2.4 user_roles_cache 상태
SELECT 
    '=== user_roles_cache 상태 ===' as check_type,
    urc.user_id,
    u.email,
    urc.user_role,
    urc.company_id,
    c.name as company_name,
    urc.updated_at
FROM user_roles_cache urc
LEFT JOIN auth.users u ON urc.user_id = u.id
LEFT JOIN companies c ON urc.company_id = c.id
ORDER BY urc.updated_at DESC;

-- ========================================
-- 3. 트리거 및 제약조건 상태 확인
-- ========================================

-- 3.1 모든 트리거 확인
SELECT 
    '=== 활성화된 트리거 ===' as check_type,
    trigger_name,
    event_object_table,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 3.2 제약조건 상태 확인
SELECT 
    '=== 제약조건 상태 ===' as check_type,
    conname as constraint_name,
    conrelid::regclass as table_name,
    contype as constraint_type,
    CASE contype
        WHEN 'f' THEN 'Foreign Key'
        WHEN 'p' THEN 'Primary Key'
        WHEN 'u' THEN 'Unique'
        WHEN 'c' THEN 'Check'
        WHEN 'x' THEN 'Exclusion'
        ELSE 'Other'
    END as constraint_description
FROM pg_constraint
WHERE connamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY conrelid::regclass, contype;

-- 3.3 Foreign Key 검증 (참조 무결성 체크)
SELECT 
    '=== FK 참조 무결성 문제 ===' as check_type,
    'employees.profile_id → auth.users.id' as relation,
    COUNT(e.id) as broken_references
FROM employees e
LEFT JOIN auth.users u ON e.profile_id = u.id
WHERE u.id IS NULL;

SELECT 
    '=== FK 참조 무결성 문제 ===' as check_type,
    'employees.company_id → companies.id' as relation,
    COUNT(e.id) as broken_references
FROM employees e
LEFT JOIN companies c ON e.company_id = c.id
WHERE e.company_id IS NOT NULL AND c.id IS NULL;

-- ========================================
-- 4. 데이터 일관성 문제 확인
-- ========================================

-- 4.1 비정상적인 데이터 값들
SELECT 
    '=== 비어있는 필수 필드 ===' as check_type,
    'companies' as table_name,
    COUNT(*) as empty_name_count
FROM companies 
WHERE name IS NULL OR TRIM(name) = '';

SELECT 
    '=== 비어있는 필수 필드 ===' as check_type,
    'employees' as table_name,
    COUNT(*) as empty_role_count
FROM employees 
WHERE user_role IS NULL OR TRIM(user_role) = '';

-- 4.2 날짜 일관성 문제
SELECT 
    '=== 날짜 일관성 문제 ===' as check_type,
    table_name,
    COUNT(*) as future_dates
FROM (
    SELECT 'companies' as table_name FROM companies WHERE created_at > NOW()
    UNION ALL
    SELECT 'employees' as table_name FROM employees WHERE created_at > NOW()
    UNION ALL
    SELECT 'user_roles_cache' as table_name FROM user_roles_cache WHERE updated_at > NOW()
) sub
GROUP BY table_name;

-- ========================================
-- 5. RLS 정책 확인
-- ========================================

-- 5.1 RLS 정책 상태
SELECT 
    '=== RLS 정책 상태 ===' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    (SELECT COUNT(*) FROM pg_policy WHERE polrelid = pg_class.oid) as policy_count
FROM pg_tables
JOIN pg_class ON pg_class.relname = pg_tables.tablename
WHERE schemaname = 'public'
ORDER BY tablename;

-- 5.2 구체적인 정책들
SELECT 
    '=== RLS 정책 세부사항 ===' as check_type,
    schemaname,
    tablename,
    policyname,
    cmd,
    roles,
    qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ========================================
-- 6. 성능 및 인덱스 문제
-- ========================================

-- 6.1 인덱스 상태
SELECT 
    '=== 인덱스 상태 ===' as check_type,
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 6.2 테이블 크기 정보
SELECT 
    '=== 테이블 크기 ===' as check_type,
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(('public.' || tablename)::regclass)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(('public.' || tablename)::regclass) DESC;

-- ========================================
-- 7. 감사 로그 및 기록 확인
-- ========================================

-- 7.1 audit_logs 테이블 상태 (있는 경우)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'audit_logs') THEN
        EXECUTE 'SELECT 
            ''=== audit_logs 상태 ==='' as check_type,
            COUNT(*) as total_logs,
            COUNT(DISTINCT entity_type) as entity_types,
            MIN(created_at) as oldest_log,
            MAX(created_at) as newest_log
        FROM audit_logs';
    ELSE
        SELECT '=== audit_logs 테이블 없음 ===' as check_type, 0 as count;
    END IF;
END $$;

-- ========================================
-- 최종 요약
-- ========================================

SELECT 
    '=== 진단 완료 ===' as check_type,
    NOW() as completed_at,
    '위의 결과를 검토하여 문제점들을 파악하고 수정이 필요합니다' as next_action;