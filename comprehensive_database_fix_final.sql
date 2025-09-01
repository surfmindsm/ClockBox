-- 데이터베이스 전체 문제 수정 스크립트 (최종 버전)
-- 이전 분석을 바탕으로 알려진 모든 문제들을 수정합니다

-- ========================================
-- 1. 중복 데이터 정리 (최우선)
-- ========================================

-- 1.1 중복 employees 레코드 정리 - 가장 최근 것만 남기고 삭제
DO $$
DECLARE
    duplicate_record RECORD;
    oldest_id UUID;
BEGIN
    -- 중복된 profile_id들을 찾아서 처리
    FOR duplicate_record IN 
        SELECT profile_id, COUNT(*) as cnt
        FROM employees 
        GROUP BY profile_id 
        HAVING COUNT(*) > 1
    LOOP
        -- 가장 오래된 레코드의 ID를 찾아서 삭제 (최신 것만 유지)
        SELECT id INTO oldest_id
        FROM employees 
        WHERE profile_id = duplicate_record.profile_id
        ORDER BY updated_at ASC
        LIMIT 1;
        
        DELETE FROM employees WHERE id = oldest_id;
        
        RAISE NOTICE '중복 제거: profile_id=%, 삭제된 employee_id=%', duplicate_record.profile_id, oldest_id;
    END LOOP;
END $$;

-- 1.2 user_roles_cache 중복 제거 (있다면)
DELETE FROM user_roles_cache 
WHERE ctid NOT IN (
    SELECT MIN(ctid) 
    FROM user_roles_cache 
    GROUP BY user_id
);

-- ========================================
-- 2. 시스템 관리자 계정 강제 수정
-- ========================================

-- 2.1 system@clockbox.dev 계정의 역할 강제 설정
UPDATE employees 
SET 
    user_role = 'system_admin',
    updated_at = NOW()
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- 2.2 user_roles_cache 동기화
DELETE FROM user_roles_cache 
WHERE user_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

INSERT INTO user_roles_cache (user_id, company_id, user_role, updated_at)
SELECT 
    profile_id,
    company_id,
    user_role,
    NOW()
FROM employees 
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
ON CONFLICT (user_id) DO UPDATE SET
    user_role = EXCLUDED.user_role,
    company_id = EXCLUDED.company_id,
    updated_at = NOW();

-- ========================================
-- 3. 데이터 일관성 수정
-- ========================================

-- 3.1 모든 employees에 대해 user_roles_cache 동기화
INSERT INTO user_roles_cache (user_id, company_id, user_role, updated_at)
SELECT 
    e.profile_id,
    e.company_id,
    e.user_role,
    NOW()
FROM employees e
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE urc.user_id IS NULL
ON CONFLICT (user_id) DO NOTHING;

-- 3.2 employees와 cache 간 불일치 수정 (employees가 우선)
UPDATE user_roles_cache 
SET 
    user_role = e.user_role,
    company_id = e.company_id,
    updated_at = NOW()
FROM employees e
WHERE user_roles_cache.user_id = e.profile_id
  AND user_roles_cache.user_role != e.user_role;

-- ========================================
-- 4. 트리거 정리 (문제 발생 시 비활성화)
-- ========================================

-- 4.1 문제가 되는 트리거들 비활성화 (이미 비활성화되어 있을 수 있음)
DROP TRIGGER IF EXISTS user_roles_cache_trigger ON employees;
DROP TRIGGER IF EXISTS employee_role_change_trigger ON employees;

-- 4.2 새로운 안전한 동기화 트리거 생성
CREATE OR REPLACE FUNCTION sync_user_roles_cache()
RETURNS TRIGGER AS $$
BEGIN
    -- employees 테이블 변경 시 user_roles_cache 동기화
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        INSERT INTO user_roles_cache (user_id, company_id, user_role, updated_at)
        VALUES (NEW.profile_id, NEW.company_id, NEW.user_role, NOW())
        ON CONFLICT (user_id) DO UPDATE SET
            user_role = EXCLUDED.user_role,
            company_id = EXCLUDED.company_id,
            updated_at = EXCLUDED.updated_at;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM user_roles_cache WHERE user_id = OLD.profile_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성 (옵션 - 문제가 계속되면 주석 처리)
-- CREATE TRIGGER employees_sync_cache
--     AFTER INSERT OR UPDATE OR DELETE ON employees
--     FOR EACH ROW EXECUTE FUNCTION sync_user_roles_cache();

-- ========================================
-- 5. 누락된 데이터 정리
-- ========================================

-- 5.1 orphaned employees 제거 (auth.users에 없는 employees)
DELETE FROM employees 
WHERE profile_id NOT IN (
    SELECT id FROM auth.users
);

-- 5.2 orphaned user_roles_cache 제거
DELETE FROM user_roles_cache 
WHERE user_id NOT IN (
    SELECT id FROM auth.users
);

-- ========================================
-- 6. 데이터 검증 및 요약
-- ========================================

-- 6.1 최종 상태 확인
SELECT 
    '=== 수정 완료 후 상태 ===' as status,
    COUNT(*) as total_employees,
    COUNT(DISTINCT profile_id) as unique_users,
    COUNT(CASE WHEN user_role = 'system_admin' THEN 1 END) as system_admins
FROM employees;

-- 6.2 시스템 관리자 최종 확인
SELECT 
    '=== 시스템 관리자 최종 상태 ===' as status,
    e.id,
    e.user_role as employee_role,
    urc.user_role as cache_role,
    e.updated_at
FROM employees e
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- 6.3 중복 레코드 확인 (있으면 안됨)
SELECT 
    '=== 중복 레코드 체크 (0이어야 함) ===' as status,
    profile_id,
    COUNT(*) as count
FROM employees 
GROUP BY profile_id 
HAVING COUNT(*) > 1;

-- ========================================
-- 7. 성공 메시지
-- ========================================

SELECT 
    '🎉 데이터베이스 수정 완료!' as message,
    NOW() as completed_at,
    'system@clockbox.dev는 이제 system_admin 역할로 고정되었습니다.' as details;