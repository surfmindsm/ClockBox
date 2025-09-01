-- 간단한 데이터베이스 진단 스크립트

-- ========================================
-- 1. 기본 데이터 확인
-- ========================================

-- 1.1 중복 employees 레코드 확인 (핵심 문제)
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

-- 1.2 현재 시스템 관리자 상태
SELECT 
    '=== 시스템 관리자 상태 ===' as check_type,
    e.id,
    e.profile_id,
    u.email,
    e.user_role,
    e.status,
    e.updated_at
FROM employees e
LEFT JOIN auth.users u ON e.profile_id = u.id
WHERE u.email = 'system@clockbox.dev'
ORDER BY e.updated_at DESC;

-- 1.3 user_roles_cache 상태
SELECT 
    '=== user_roles_cache 상태 ===' as check_type,
    urc.user_id,
    u.email,
    urc.user_role,
    urc.updated_at
FROM user_roles_cache urc
LEFT JOIN auth.users u ON urc.user_id = u.id
WHERE u.email = 'system@clockbox.dev';

-- ========================================
-- 2. 데이터 불일치 확인
-- ========================================

-- 2.1 employees vs user_roles_cache 불일치
SELECT 
    '=== 역할 불일치 확인 ===' as check_type,
    e.profile_id,
    u.email,
    e.user_role as employee_role,
    urc.user_role as cache_role,
    CASE WHEN e.user_role != urc.user_role THEN 'MISMATCH' ELSE 'OK' END as status
FROM employees e
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
LEFT JOIN auth.users u ON e.profile_id = u.id
WHERE e.user_role != urc.user_role OR urc.user_role IS NULL
ORDER BY u.email;

-- ========================================
-- 3. 테이블 기본 정보
-- ========================================

-- 3.1 companies 테이블 상태
SELECT 
    '=== companies 테이블 ===' as check_type,
    COUNT(*) as total_companies,
    COUNT(CASE WHEN onboarding_completed = true THEN 1 END) as completed_onboarding,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_companies
FROM companies;

-- 3.2 employees 테이블 요약
SELECT 
    '=== employees 테이블 요약 ===' as check_type,
    COUNT(*) as total_employees,
    COUNT(DISTINCT profile_id) as unique_users,
    COUNT(CASE WHEN user_role = 'system_admin' THEN 1 END) as system_admins,
    COUNT(CASE WHEN user_role = 'super_admin' THEN 1 END) as super_admins,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_employees
FROM employees;

-- ========================================
-- 4. 트리거 상태 (간단히)
-- ========================================

-- 4.1 employees 테이블 트리거
SELECT 
    '=== employees 트리거 ===' as check_type,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'employees'
ORDER BY trigger_name;

-- ========================================
-- 5. 문제 요약
-- ========================================

-- 5.1 orphaned 레코드 확인
SELECT '=== orphaned employees (auth.users 없음) ===' as check_type, COUNT(*) as count
FROM employees e 
LEFT JOIN auth.users u ON e.profile_id = u.id 
WHERE u.id IS NULL;

-- 5.2 missing cache 레코드
SELECT '=== cache 누락된 employees ===' as check_type, COUNT(*) as count
FROM employees e
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE urc.user_id IS NULL;

-- 진단 완료
SELECT 
    '=== 진단 완료 ===' as check_type,
    NOW() as completed_at;