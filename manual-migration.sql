-- ====================================
-- 승인 정책 관리 시스템 수동 마이그레이션
-- Supabase 대시보드 > SQL Editor에서 실행
-- ====================================

-- 1. approval_lines 테이블 확장
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'approval_lines' AND column_name = 'template_name'
    ) THEN
        ALTER TABLE approval_lines ADD COLUMN template_name TEXT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'approval_lines' AND column_name = 'is_template'
    ) THEN
        ALTER TABLE approval_lines ADD COLUMN is_template BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'approval_lines' AND column_name = 'allow_modification'
    ) THEN
        ALTER TABLE approval_lines ADD COLUMN allow_modification BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'approval_lines' AND column_name = 'requester_based_approval'
    ) THEN
        ALTER TABLE approval_lines ADD COLUMN requester_based_approval BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- 2. 승인 템플릿 테이블 생성
CREATE TABLE IF NOT EXISTS public.approval_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    template_name TEXT NOT NULL,
    description TEXT,
    step_count INTEGER NOT NULL DEFAULT 1 CHECK (step_count BETWEEN 1 AND 5),
    allow_modification BOOLEAN DEFAULT FALSE,
    requester_based_approval BOOLEAN DEFAULT FALSE,
    template_config JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES employees(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_template_name_per_company UNIQUE(company_id, template_name)
);

-- 3. 승인 정책 테이블 생성
CREATE TABLE IF NOT EXISTS public.approval_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    policy_type TEXT NOT NULL CHECK (policy_type IN ('leave', 'work')),
    policy_name TEXT NOT NULL,
    policy_key TEXT NOT NULL,
    policy_category TEXT,
    template_id UUID REFERENCES approval_templates(id),
    line_id UUID REFERENCES approval_lines(id),
    priority INTEGER DEFAULT 0,
    conditions JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_policy_per_company UNIQUE(company_id, policy_type, policy_key)
);

-- 4. 승인 참조자 테이블 생성
CREATE TABLE IF NOT EXISTS public.approval_references (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    line_id UUID NOT NULL REFERENCES approval_lines(id) ON DELETE CASCADE,
    reference_type TEXT NOT NULL CHECK (reference_type IN ('organization', 'employee')),
    reference_id UUID NOT NULL,
    notification_type TEXT NOT NULL DEFAULT 'all' CHECK (notification_type IN ('none', 'request', 'complete', 'all')),
    include_sub_orgs BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. 승인 단계 유형 확장 테이블 생성
CREATE TABLE IF NOT EXISTS public.approval_step_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    step_id UUID NOT NULL REFERENCES approval_steps(id) ON DELETE CASCADE,
    approver_type TEXT NOT NULL CHECK (approver_type IN ('nth_manager', 'organization', 'employee', 'role')),
    approver_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    fallback_config JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_approval_templates_company ON approval_templates(company_id);
CREATE INDEX IF NOT EXISTS idx_approval_templates_active ON approval_templates(company_id, is_active) WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_approval_policies_company ON approval_policies(company_id);
CREATE INDEX IF NOT EXISTS idx_approval_policies_type ON approval_policies(company_id, policy_type);
CREATE INDEX IF NOT EXISTS idx_approval_policies_key ON approval_policies(company_id, policy_key);
CREATE INDEX IF NOT EXISTS idx_approval_policies_active ON approval_policies(company_id, is_active) WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_approval_references_line ON approval_references(line_id);
CREATE INDEX IF NOT EXISTS idx_approval_step_types_step ON approval_step_types(step_id);

-- 7. 기본 휴가 정책 데이터 삽입
INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '연차',
    'annual_leave',
    'standard'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'annual_leave'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '병가',
    'sick_leave',
    'standard'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'sick_leave'
);

-- 법정 휴가 (의무 제공)
INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '반차/시간 단위 연차',
    'half_day_annual_leave',
    'mandatory'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'half_day_annual_leave'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '출산휴가',
    'maternity_leave',
    'mandatory'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'maternity_leave'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '육아휴직',
    'childcare_leave',
    'mandatory'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'childcare_leave'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '배우자 출산휴가',
    'paternity_leave',
    'mandatory'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'paternity_leave'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '산재 요양휴가',
    'industrial_accident_leave',
    'mandatory'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'industrial_accident_leave'
);

-- 법정 외/복리후생 휴가 (회사 자율)
INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '경조사 휴가',
    'family_event_leave',
    'welfare'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'family_event_leave'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '무급휴가',
    'unpaid_leave',
    'welfare'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'unpaid_leave'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '공가',
    'public_duty_leave',
    'welfare'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'public_duty_leave'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '리프레시 휴가',
    'refresh_leave',
    'welfare'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'refresh_leave'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'leave',
    '생리휴가',
    'menstrual_leave',
    'welfare'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'menstrual_leave'
);

-- 8. 승인 완료 후 일정 반영을 위한 추가 테이블들
CREATE TABLE IF NOT EXISTS public.leave_schedule_impacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leave_request_id UUID NOT NULL REFERENCES leave_requests(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id),
    impact_date DATE NOT NULL,
    original_schedule_id UUID REFERENCES work_schedules(id),
    impact_type TEXT NOT NULL CHECK (impact_type IN ('blocked', 'modified', 'cancelled')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'applied', 'reverted')),
    applied_at TIMESTAMPTZ,
    reverted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 승인 단계 인스턴스 테이블 (실제 승인 진행 상태)
CREATE TABLE IF NOT EXISTS public.approval_step_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    approval_id UUID NOT NULL REFERENCES approvals(id) ON DELETE CASCADE,
    step_order INTEGER NOT NULL,
    approver_id UUID REFERENCES employees(id),
    delegate_id UUID REFERENCES employees(id),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'skipped')),
    action_date TIMESTAMPTZ,
    comment TEXT,
    auto_approved BOOLEAN DEFAULT FALSE,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    deadline_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 승인과 승인 정책 연결 테이블
ALTER TABLE approvals ADD COLUMN IF NOT EXISTS policy_applied UUID REFERENCES approval_policies(id);
ALTER TABLE approvals ADD COLUMN IF NOT EXISTS auto_schedule_update BOOLEAN DEFAULT TRUE;

-- 9. 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_leave_schedule_impacts_request ON leave_schedule_impacts(leave_request_id);
CREATE INDEX IF NOT EXISTS idx_leave_schedule_impacts_employee ON leave_schedule_impacts(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_schedule_impacts_date ON leave_schedule_impacts(impact_date);
CREATE INDEX IF NOT EXISTS idx_approval_step_instances_approval ON approval_step_instances(approval_id);
CREATE INDEX IF NOT EXISTS idx_approval_step_instances_approver ON approval_step_instances(approver_id);

-- 10. 기본 근무 정책 데이터 삽입
INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'work',
    '외근',
    'field_work',
    'work_type'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'field_work'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'work',
    '재택근무',
    'remote_work',
    'work_type'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'remote_work'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'work',
    '근무',
    'regular_work',
    'work_type'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'regular_work'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'work',
    '원격 근무',
    'remote_work_extended',
    'work_type'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'remote_work_extended'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'work',
    '출장',
    'business_trip',
    'work_type'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'business_trip'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'work',
    '연장 근무',
    'overtime_work',
    'work_type'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'overtime_work'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'work',
    '휴일 근무',
    'holiday_work',
    'work_type'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'holiday_work'
);

INSERT INTO approval_policies (company_id, policy_type, policy_name, policy_key, policy_category)
SELECT DISTINCT 
    c.id,
    'work',
    '야간 근무',
    'night_work',
    'work_type'
FROM companies c
WHERE NOT EXISTS (
    SELECT 1 FROM approval_policies ap
    WHERE ap.company_id = c.id AND ap.policy_key = 'night_work'
);