-- ====================================
-- N차 조직장 레벨 시스템 마이그레이션
-- Supabase 대시보드 > SQL Editor에서 실행
-- ====================================

-- 1. organization_managers 테이블에 manager_level 컬럼 추가
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'organization_managers' AND column_name = 'manager_level'
    ) THEN
        ALTER TABLE organization_managers ADD COLUMN manager_level INTEGER DEFAULT 1 CHECK (manager_level BETWEEN 1 AND 3);
        
        -- 기존 데이터는 1차 조직장으로 설정
        UPDATE organization_managers SET manager_level = 1 WHERE manager_level IS NULL;
        
        -- NOT NULL 제약조건 추가
        ALTER TABLE organization_managers ALTER COLUMN manager_level SET NOT NULL;
        
        RAISE NOTICE 'manager_level 컬럼이 추가되었습니다.';
    ELSE
        RAISE NOTICE 'manager_level 컬럼이 이미 존재합니다.';
    END IF;
END $$;

-- 2. 유니크 제약조건 수정 (같은 조직에서 레벨별로 다른 조직장 허용)
DO $$
BEGIN
    -- 기존 유니크 제약조건 삭제 (있다면)
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'organization_managers_organization_id_employee_id_key'
        AND table_name = 'organization_managers'
    ) THEN
        ALTER TABLE organization_managers 
        DROP CONSTRAINT organization_managers_organization_id_employee_id_key;
        RAISE NOTICE '기존 유니크 제약조건이 삭제되었습니다.';
    END IF;

    -- 새로운 유니크 제약조건 추가 (조직 + 레벨별로 하나의 조직장만)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'unique_organization_manager_level'
        AND table_name = 'organization_managers'
    ) THEN
        ALTER TABLE organization_managers 
        ADD CONSTRAINT unique_organization_manager_level 
        UNIQUE (organization_id, manager_level);
        RAISE NOTICE '새로운 유니크 제약조건이 추가되었습니다.';
    END IF;
END $$;

-- 3. 기존 is_primary_manager 컬럼 의미 변경 (1차 조직장 여부로 사용)
DO $$
BEGIN
    -- is_primary_manager를 manager_level = 1과 동기화
    UPDATE organization_managers 
    SET is_primary_manager = (manager_level = 1);
    
    RAISE NOTICE 'is_primary_manager가 1차 조직장 기준으로 업데이트되었습니다.';
END $$;

-- 4. N차 조직장 조회 RPC 함수 생성
CREATE OR REPLACE FUNCTION get_nth_managers_for_organization(org_id UUID, level_filter INTEGER DEFAULT NULL)
RETURNS TABLE (
    manager_id UUID,
    employee_id UUID,
    manager_level INTEGER,
    employee_name TEXT,
    employee_email TEXT,
    is_primary_manager BOOLEAN,
    assigned_at TIMESTAMPTZ
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
    SELECT 
        om.id as manager_id,
        om.employee_id,
        om.manager_level,
        p.full_name as employee_name,
        p.email as employee_email,
        om.is_primary_manager,
        om.created_at as assigned_at
    FROM organization_managers om
    JOIN employees e ON e.id = om.employee_id
    JOIN profiles p ON p.id = e.profile_id
    WHERE om.organization_id = org_id
    AND (level_filter IS NULL OR om.manager_level = level_filter)
    ORDER BY om.manager_level ASC, om.created_at ASC;
$$;

-- 5. 조직장 레벨 할당 RPC 함수 생성
CREATE OR REPLACE FUNCTION assign_nth_manager_for_admin(
    org_id UUID, 
    emp_id UUID, 
    level_num INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    existing_manager_id UUID;
BEGIN
    -- 유효성 검사: 레벨은 1-3만 허용
    IF level_num < 1 OR level_num > 3 THEN
        RAISE EXCEPTION 'manager_level은 1, 2, 3만 허용됩니다.';
    END IF;

    -- 같은 조직의 같은 레벨에 기존 조직장이 있는지 확인
    SELECT id INTO existing_manager_id
    FROM organization_managers
    WHERE organization_id = org_id AND manager_level = level_num;

    -- 기존 조직장이 있으면 삭제
    IF existing_manager_id IS NOT NULL THEN
        DELETE FROM organization_managers WHERE id = existing_manager_id;
    END IF;

    -- 새 조직장 할당
    INSERT INTO organization_managers (
        organization_id,
        employee_id,
        manager_level,
        is_primary_manager,
        assigned_by,
        created_at
    ) VALUES (
        org_id,
        emp_id,
        level_num,
        level_num = 1,  -- 1차 조직장만 primary로 설정
        (SELECT id FROM employees WHERE profile_id = auth.uid() LIMIT 1),
        NOW()
    );

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '조직장 할당 실패: %', SQLERRM;
        RETURN FALSE;
END $$;

-- 6. 조직장 레벨 해제 RPC 함수 생성  
CREATE OR REPLACE FUNCTION remove_nth_manager_for_admin(
    org_id UUID, 
    level_num INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- 해당 조직의 해당 레벨 조직장 삭제
    DELETE FROM organization_managers
    WHERE organization_id = org_id AND manager_level = level_num;

    IF NOT FOUND THEN
        RAISE EXCEPTION '해당 레벨의 조직장이 존재하지 않습니다.';
        RETURN FALSE;
    END IF;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '조직장 해제 실패: %', SQLERRM;
        RETURN FALSE;
END $$;

-- 7. 요청자 기준 N차 조직장 찾기 RPC 함수 생성
CREATE OR REPLACE FUNCTION get_nth_managers_for_requester(
    requester_employee_id UUID,
    max_level INTEGER DEFAULT 3
)
RETURNS TABLE (
    level_num INTEGER,
    manager_employee_id UUID,
    manager_name TEXT,
    manager_email TEXT,
    organization_name TEXT
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
    WITH requester_org AS (
        SELECT organization_id
        FROM employees
        WHERE id = requester_employee_id
    )
    SELECT 
        om.manager_level as level_num,
        om.employee_id as manager_employee_id,
        p.full_name as manager_name,
        p.email as manager_email,
        o.name as organization_name
    FROM organization_managers om
    JOIN employees e ON e.id = om.employee_id
    JOIN profiles p ON p.id = e.profile_id
    JOIN organizations o ON o.id = om.organization_id
    WHERE om.organization_id = (SELECT organization_id FROM requester_org)
    AND om.manager_level <= max_level
    ORDER BY om.manager_level ASC;
$$;

-- 8. 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_organization_managers_level ON organization_managers(organization_id, manager_level);
CREATE INDEX IF NOT EXISTS idx_organization_managers_employee ON organization_managers(employee_id);

-- 9. 테스트 데이터 (선택사항 - 필요시 실행)
-- 첫 번째 조직에 샘플 N차 조직장 데이터 추가
/*
DO $$
DECLARE
    first_org_id UUID;
    first_emp_id UUID;
    second_emp_id UUID;
    third_emp_id UUID;
BEGIN
    -- 첫 번째 조직 ID 가져오기
    SELECT id INTO first_org_id FROM organizations ORDER BY created_at LIMIT 1;
    
    -- 직원 ID들 가져오기 (조직장이 될 수 있는 직원들)
    SELECT id INTO first_emp_id FROM employees 
    WHERE organization_id = first_org_id AND user_role != 'super_admin' 
    ORDER BY created_at LIMIT 1;
    
    SELECT id INTO second_emp_id FROM employees 
    WHERE organization_id = first_org_id AND user_role != 'super_admin' 
    AND id != first_emp_id
    ORDER BY created_at LIMIT 1 OFFSET 1;
    
    SELECT id INTO third_emp_id FROM employees 
    WHERE organization_id = first_org_id AND user_role != 'super_admin' 
    AND id NOT IN (first_emp_id, second_emp_id)
    ORDER BY created_at LIMIT 1 OFFSET 2;

    -- N차 조직장 할당 (기존 데이터 삭제 후)
    DELETE FROM organization_managers WHERE organization_id = first_org_id;
    
    IF first_emp_id IS NOT NULL THEN
        PERFORM assign_nth_manager_for_admin(first_org_id, first_emp_id, 1);
        RAISE NOTICE '1차 조직장 할당 완료: %', first_emp_id;
    END IF;
    
    IF second_emp_id IS NOT NULL THEN
        PERFORM assign_nth_manager_for_admin(first_org_id, second_emp_id, 2);
        RAISE NOTICE '2차 조직장 할당 완료: %', second_emp_id;
    END IF;
    
    IF third_emp_id IS NOT NULL THEN
        PERFORM assign_nth_manager_for_admin(first_org_id, third_emp_id, 3);
        RAISE NOTICE '3차 조직장 할당 완료: %', third_emp_id;
    END IF;
END $$;
*/

-- 마이그레이션 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '====================================';
    RAISE NOTICE 'N차 조직장 레벨 시스템 마이그레이션 완료!';
    RAISE NOTICE '====================================';
    RAISE NOTICE '생성된 함수들:';
    RAISE NOTICE '- get_nth_managers_for_organization(org_id, level_filter)';
    RAISE NOTICE '- assign_nth_manager_for_admin(org_id, emp_id, level_num)'; 
    RAISE NOTICE '- remove_nth_manager_for_admin(org_id, level_num)';
    RAISE NOTICE '- get_nth_managers_for_requester(requester_employee_id, max_level)';
    RAISE NOTICE '====================================';
END $$;