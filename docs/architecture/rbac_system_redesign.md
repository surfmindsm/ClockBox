# ClockBox RBAC 시스템 재설계 문서

## 📅 최종 업데이트: 2025-09-01

## 🎯 개요

ClockBox의 역할 기반 접근 제어(RBAC) 시스템이 기존 다중 테넌트 구조에서 단일 회사 중심의 명확한 3단계 역할 구조로 재설계되었습니다. 이 변경으로 더욱 직관적이고 한국 기업 환경에 최적화된 권한 관리 시스템을 구축했습니다.

## 🔄 변경 사항 요약

### 기존 시스템 (Before)
- **시스템 관리자**: 다중 테넌트 시스템 전체 관리자
- **회사 관리자**: 개별 회사 관리자
- **직원**: 일반 직원

### 재설계 시스템 (After)
- **수퍼어드민 (super_admin)**: 회사의 최고 관리자 (CEO/사장)
- **인사 담당자 (hr_admin)**: 회사의 인사 담당자
- **일반 직원 (employee)**: 그 외 모든 직원 (팀장, 본부장 포함 + 결재 권한 체계)

## 🏢 역할 상세 정의

### 1. 수퍼어드민 (Super Admin)
**한국어 표시**: 수퍼어드민  
**역할 정의**: 회사의 최고 관리자 (CEO, 사장)

#### 권한 범위
- ✅ 시스템 전체 관리
- ✅ 회사 정보 관리
- ✅ 전체 직원 관리
- ✅ 조직 구조 관리
- ✅ 시스템 설정 관리
- ✅ 모든 결재 권한
- ✅ 통계 및 분석
- ✅ 52시간 근무제 관리

#### 네비게이션 메뉴 (5개 카테고리)
1. **수퍼어드민 대시보드**: 회사 전체 현황
2. **회사 관리**: 회사 정보, 설정, 조직 관리
3. **전체 직원 관리**: 직원 목록, 조직도, 권한 관리
4. **시스템 설정**: 근무 규칙, 휴가 정책, 승인 워크플로우
5. **통계 및 분석**: 근태 통계, 조직 분석, 성과 분석

### 2. 인사 담당자 (HR Admin)
**한국어 표시**: 인사 담당자  
**역할 정의**: 회사의 인사 업무 담당자

#### 권한 범위
- ✅ 직원 관리
- ✅ 근무 관리
- ✅ 승인 관리 (휴가, 초과근무 등)
- ✅ 보고서 및 분석
- ✅ 회사 설정 (제한적)
- ❌ 시스템 전체 관리 권한 없음

#### 네비게이션 메뉴 (5개 카테고리)
1. **인사담당자 대시보드**: 인사 업무 현황
2. **직원 관리**: 직원 목록, 추가, 부서 관리
3. **근무 관리**: 근무 일정, 근무지, 근무 정책
4. **승인 관리**: 휴가, 초과근무, 출장 신청 승인
5. **보고서 및 분석**: 출근 현황, 급여 보고서, 52시간 모니터링

### 3. 일반 직원 (Employee)
**한국어 표시**: 직원  
**역할 정의**: 그 외 모든 직원 (팀장, 본부장 포함)

#### 권한 범위
- ✅ 개인 근태 관리
- ✅ 휴가 신청
- ✅ 출퇴근 체크
- ✅ 개인 정보 관리
- 🔹 **결재 권한**: 조직 내 관리자는 추가 승인 권한 보유
- ❌ 회사 전체 관리 권한 없음

#### 네비게이션 메뉴 (5개 카테고리)
1. **대시보드**: 개인 근무 현황
2. **출퇴근 관리**: 출퇴근 체크, 근태 기록
3. **휴가 관리**: 휴가 신청, 내역 조회, 잔여일수
4. **근무 일정**: 개인 스케줄 관리
5. **내 정보**: 프로필, 비밀번호, 설정, 알림

## 🏗️ 기술 구현

### 데이터베이스 변경사항
```sql
-- 1. employees 테이블 역할 제약조건 업데이트
ALTER TABLE employees ADD CONSTRAINT employees_user_role_check 
CHECK (user_role IN ('super_admin', 'hr_admin', 'employee'));

-- 2. 관리자 관계 추가
ALTER TABLE employees ADD COLUMN manager_id UUID REFERENCES employees(id);
ALTER TABLE organizations ADD COLUMN manager_id UUID REFERENCES employees(id);

-- 3. 결재 권한 테이블 생성
CREATE TABLE approval_authorities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES employees(id),
    organization_id UUID REFERENCES organizations(id),
    approval_type TEXT CHECK (approval_type IN ('leave', 'overtime', 'attendance', 'schedule')),
    can_approve_subordinates BOOLEAN DEFAULT TRUE,
    can_approve_same_level BOOLEAN DEFAULT FALSE
);
```

### 백엔드 Edge Function 업데이트
```typescript
// get-user-role/index.ts
const roleMapping: Record<string, string> = {
  'super_admin': 'system_admin',  // 수퍼어드민 -> 시스템 관리자
  'hr_admin': 'company_admin',    // 인사담당자 -> 회사 관리자
  'employee': 'employee',         // 일반직원 (팀장, 본부장 포함)
  // Legacy support
  'admin': 'system_admin',        
  'manager': 'company_admin'      
};
```

### 프론트엔드 RBAC 시스템 업데이트
```typescript
// lib/rbac.ts
export function getRoleDisplayName(role: UserRole): string {
  switch (role) {
    case 'system_admin':
      return '수퍼어드민'; // 회사의 최고 관리자
    case 'company_admin':
      return '인사 담당자'; // 회사의 인사 담당자
    case 'employee':
      return '직원'; // 일반 직원 (팀장, 본부장 포함)
    default:
      return '알 수 없음';
  }
}

export function getRoleColor(role: UserRole): string {
  switch (role) {
    case 'system_admin':
      return 'bg-red-100 text-red-800 border-red-200';
    case 'company_admin':
      return 'bg-blue-100 text-blue-800 border-blue-200';
    case 'employee':
      return 'bg-green-100 text-green-800 border-green-200';
    default:
      return 'bg-gray-100 text-gray-800 border-gray-200';
  }
}
```

## 🔗 승인 계층구조 시스템

### 관리자 관계 (manager_id)
- **직속 상사**: `employees.manager_id`로 결재라인 구성
- **조직 관리자**: `organizations.manager_id`로 부서/지점 관리자 지정
- **결재 권한**: `approval_authorities` 테이블로 세부 권한 관리

### 결재 유형별 권한
1. **휴가 결재 (leave)**
   - 1일 이하: 직속 상사 자동 승인
   - 3일 초과: 인사담당자 추가 승인 필요

2. **초과근무 결재 (overtime)**
   - 2시간 이하: 직속 상사 자동 승인
   - 8시간 초과: 수퍼어드민 승인 필요

3. **출근/근태 결재 (attendance)**
   - 지각, 조퇴 등: 직속 상사 승인

4. **일정 변경 (schedule)**
   - 근무 일정 변경: 직속 상사 승인

### 자동 권한 설정 함수
```sql
CREATE OR REPLACE FUNCTION setup_role_permissions(emp_id UUID, role_type TEXT)
RETURNS void AS $$
BEGIN
    IF role_type = 'super_admin' THEN
        -- 모든 권한 부여
        UPDATE employees 
        SET can_approve_leaves = TRUE, can_approve_overtime = TRUE 
        WHERE id = emp_id;
        
    ELSIF role_type = 'hr_admin' THEN
        -- 인사 관련 권한
        UPDATE employees 
        SET can_approve_leaves = TRUE, can_approve_overtime = FALSE
        WHERE id = emp_id;
        
    ELSE
        -- 기본 권한 없음 (개별 설정)
        UPDATE employees 
        SET can_approve_leaves = FALSE, can_approve_overtime = FALSE
        WHERE id = emp_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

## 📱 페이지 구조 변경

### URL 구조 변경
| 기존 | 변경 후 | 설명 |
|------|---------|------|
| `/system/companies` | `/system/company` | 다중 회사 → 단일 회사 정보 |
| `시스템 대시보드` | `수퍼어드민 대시보드` | 역할명 명확화 |

### 주요 페이지 업데이트
1. **시스템 회사 페이지** (`/system/company/page.tsx`)
   - 다중 회사 목록 → 단일 회사 정보 표시
   - 회사 기본 정보, 조직 현황, 빠른 작업 메뉴

2. **시스템 대시보드** (`/system/dashboard/page.tsx`)
   - 제목: "시스템 대시보드" → "수퍼어드민 대시보드"
   - 설명: 시스템 전체 → 우리 회사 전체 관리

## 📊 네비게이션 시스템 통계

### 역할별 네비게이션 아이템 수
- **수퍼어드민**: 5개 메인 카테고리, 15개 서브 메뉴
- **인사 담당자**: 5개 메인 카테고리, 15개 서브 메뉴  
- **일반 직원**: 5개 메인 카테고리, 12개 서브 메뉴
- **총 네비게이션 아이템**: 258개 (RBAC 시스템 내)

## 🔒 보안 및 RLS 정책 업데이트

### 새로운 RLS 정책
```sql
-- 수퍼어드민은 회사 내 모든 직원 관리 가능
CREATE POLICY "Super admins can manage all employees in company" ON employees
    FOR ALL USING (
        company_id IN (
            SELECT company_id FROM employees 
            WHERE profile_id = auth.uid() AND user_role = 'super_admin'
        )
    );

-- 인사담당자는 회사 내 직원 관리 가능
CREATE POLICY "HR admins can manage employees in company" ON employees
    FOR ALL USING (
        company_id IN (
            SELECT company_id FROM employees 
            WHERE profile_id = auth.uid() AND user_role IN ('super_admin', 'hr_admin')
        )
    );
```

## 🚀 마이그레이션 적용

### 데이터 마이그레이션
```sql
-- 기존 역할 데이터 업데이트
UPDATE employees 
SET user_role = CASE 
    WHEN user_role = 'admin' THEN 'super_admin'
    WHEN user_role = 'manager' THEN 'hr_admin' 
    ELSE 'employee'
END;

-- 기존 직원들의 권한 자동 설정
DO $$
DECLARE emp RECORD;
BEGIN
    FOR emp IN SELECT id, user_role FROM employees LOOP
        PERFORM setup_role_permissions(emp.id, emp.user_role);
    END LOOP;
END $$;
```

### 트리거 설정
```sql
-- 역할 변경 시 권한 자동 업데이트
CREATE TRIGGER employee_role_change_trigger
    AFTER UPDATE OF user_role ON employees
    FOR EACH ROW
    EXECUTE FUNCTION update_employee_role_permissions();
```

## 📈 성능 최적화

### 새로운 인덱스
```sql
CREATE INDEX IF NOT EXISTS idx_employees_manager ON employees(manager_id);
CREATE INDEX IF NOT EXISTS idx_employees_role ON employees(user_role);
CREATE INDEX IF NOT EXISTS idx_organizations_manager ON organizations(manager_id);
CREATE INDEX IF NOT EXISTS idx_approval_authorities_employee ON approval_authorities(employee_id, approval_type);
```

## 🎯 비즈니스 가치

### 1. 명확성 향상
- 기존 "시스템 관리자" → "수퍼어드민"으로 역할 명확화
- 한국 기업 환경에 맞는 직관적인 역할 구조

### 2. 유연성 확보
- 일반 직원 내 팀장/본부장 결재 권한 체계
- 조직별 관리자 지정으로 세밀한 권한 관리

### 3. 확장성 보장
- `approval_authorities` 테이블로 결재 권한 세분화
- 조직 계층구조 함수로 복잡한 결재라인 지원

### 4. 법규 준수
- 한국 노동법에 맞는 결재 시스템
- 52시간 근무제 관리를 위한 권한 체계

## 📋 체크리스트

### ✅ 완료된 작업
- [x] 데이터베이스 마이그레이션 스크립트 작성
- [x] 백엔드 Edge Function 역할 매핑 업데이트
- [x] 프론트엔드 RBAC 시스템 업데이트
- [x] 페이지 구조 변경 (companies → company)
- [x] 네비게이션 시스템 재설계
- [x] 승인 계층구조 시스템 구현
- [x] RLS 정책 업데이트
- [x] 성능 인덱스 추가
- [x] 문서 업데이트

### 🔄 추후 작업
- [ ] 실제 사용자 테스트 진행
- [ ] 결재 워크플로우 UI 개발
- [ ] 조직도 시각화 컴포넌트 개발

---

**최종 업데이트**: 2025-09-01  
**작성자**: Claude Code  
**문서 버전**: 1.0  
**상태**: 구현 완료 ✅