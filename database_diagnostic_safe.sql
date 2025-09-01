-- 안전한 데이터베이스 진단 스크립트 (스키마 확인 후)

-- ========================================
-- 0. 테이블 스키마 먼저 확인
-- ========================================

-- 0.1 companies 테이블 컬럼들
SELECT 
    '=== companies 테이블 컬럼 ===' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'companies' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 0.2 employees 테이블 컬럼들
SELECT 
    '=== employees 테이블 컬럼 ===' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'employees' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 0.3 user_roles_cache 테이블 컬럼들
SELECT 
    '=== user_roles_cache 테이블 컬럼 ===' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_roles_cache' AND table_schema = 'public'
ORDER BY ordinal_position;

-- ========================================
-- 1. 핵심 문제 진단
-- ========================================

-- 1.1 중복 employees 레코드 확인 (가장 중요한 문제)
SELECT 
    '=== 중복 employees 레코드 ===' as check_type,
    profile_id, 
    COUNT(*) as record_count,
    STRING_AGG(id::text, ', ') as employee_ids,
    STRING_AGG(user_role, ', ') as roles
FROM employees 
GROUP BY profile_id 
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

-- 1.2 시스템 관리자 상태 확인
SELECT 
    '=== 시스템 관리자 employees 레코드 ===' as check_type,
    e.id,
    e.profile_id,
    e.user_role,
    e.created_at,
    e.updated_at
FROM employees e
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
ORDER BY e.updated_at DESC;

-- 1.3 user_roles_cache에서 시스템 관리자
SELECT 
    '=== 시스템 관리자 cache 레코드 ===' as check_type,
    user_id,
    user_role,
    company_id,
    updated_at
FROM user_roles_cache
WHERE user_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- 1.4 auth.users에서 해당 사용자
SELECT 
    '=== auth.users 정보 ===' as check_type,
    id,
    email,
    created_at,
    updated_at
FROM auth.users
WHERE id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- ========================================
-- 2. 전체적인 데이터 상태
-- ========================================

-- 2.1 employees 테이블 요약
SELECT 
    '=== employees 테이블 요약 ===' as check_type,
    COUNT(*) as total_employees,
    COUNT(DISTINCT profile_id) as unique_users,
    COUNT(CASE WHEN user_role = 'system_admin' THEN 1 END) as system_admins,
    COUNT(CASE WHEN user_role = 'super_admin' THEN 1 END) as super_admins,
    COUNT(CASE WHEN user_role = 'employee' THEN 1 END) as employees
FROM employees;

-- 2.2 user_roles_cache 테이블 요약  
SELECT 
    '=== user_roles_cache 테이블 요약 ===' as check_type,
    COUNT(*) as total_cache_records,
    COUNT(CASE WHEN user_role = 'system_admin' THEN 1 END) as system_admins,
    COUNT(CASE WHEN user_role = 'super_admin' THEN 1 END) as super_admins,
    COUNT(CASE WHEN user_role = 'employee' THEN 1 END) as employees
FROM user_roles_cache;

-- 2.3 companies 기본 정보 (컬럼명 확인 후)
SELECT 
    '=== companies 기본 정보 ===' as check_type,
    COUNT(*) as total_companies
FROM companies;

-- ========================================
-- 3. 데이터 무결성 확인
-- ========================================

-- 3.1 orphaned employees (auth.users 없음)
SELECT 
    '=== orphaned employees ===' as check_type,
    COUNT(*) as count
FROM employees e 
LEFT JOIN auth.users u ON e.profile_id = u.id 
WHERE u.id IS NULL;

-- 3.2 cache 없는 employees
SELECT 
    '=== cache 누락된 employees ===' as check_type,
    COUNT(*) as count
FROM employees e
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE urc.user_id IS NULL;

-- 3.3 employees 없는 cache
SELECT 
    '=== employees 없는 cache ===' as check_type,
    COUNT(*) as count
FROM user_roles_cache urc
LEFT JOIN employees e ON urc.user_id = e.profile_id
WHERE e.profile_id IS NULL;

-- ========================================
-- 4. 트리거 상태 확인
-- ========================================

-- 4.1 employees 테이블 트리거들
SELECT 
    '=== employees 트리거 ===' as check_type,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'employees'
ORDER BY trigger_name;

-- ========================================
-- 5. 진단 완료
-- ========================================

SELECT 
    '=== 진단 완료 ===' as check_type,
    NOW() as completed_at,
    'schema check -> duplicate records -> data integrity -> triggers' as checked_items;