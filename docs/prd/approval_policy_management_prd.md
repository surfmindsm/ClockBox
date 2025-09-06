# 승인 정책 관리 PRD (Product Requirements Document)

## 1. 개요

### 1.1 목적
조직별 승인 정책을 중앙에서 통합 관리하고, 승인 템플릿을 생성하여 휴가/근무/워크플로우 정책에 일괄 적용할 수 있는 관리자 전용 시스템을 구축한다.

### 1.2 배경
- 현재 조직별로 개별 결재라인이 설정되어 있으나, 전사 차원의 통합 관리 기능이 부족
- 다양한 휴가 유형, 근무 정책별로 서로 다른 승인 프로세스가 필요
- 승인 정책 변경 시 일괄 적용 및 템플릿 재사용 기능 필요

### 1.3 범위
- 승인 템플릿 생성 및 관리
- 조직별 승인 정책 설정 및 변경
- 휴가/근무 정책별 승인 워크플로우 관리
- 참조자 설정 및 알림 관리
- 요청자별 차등 승인 프로세스

## 2. 기능 요구사항

### 2.1 승인 템플릿 관리

#### 2.1.1 템플릿 생성
- **기능**: 재사용 가능한 승인 템플릿 생성
- **구성 요소**:
  - 템플릿명 (필수)
  - 승인 단계 설정 (1~5단계)
  - 승인자 유형 선택:
    - n차 조직장 (1차, 2차, 3차...)
    - 특정 조직 (조직도 탐색 기능)
    - 특정 구성원
  - 참조 대상 설정
  - 요청자별 승인 옵션
  - 변경 허용 옵션

#### 2.1.2 승인 단계 설정
```
승인자 유형:
- 1차 조직장: 요청자 소속 조직의 직속 상위 조직장
- 2차 조직장: 1차 조직장의 상위 조직장
- 3차 조직장: 2차 조직장의 상위 조직장
- 특정 조직: 지정된 조직의 구성원 중 아무나 (조직 단위 승인)
- 특정 구성원: 개별 지정된 구성원
```

#### 2.1.3 참조자 설정
- **기능**: 승인 프로세스에 참여하지 않고 알림만 받는 대상 설정
- **알림 옵션**:
  - 요청 시 알림
  - 완료 시에만 알림
  - 알림 없음 (참조만)
- **참조 대상**:
  - 특정 조직 (하위 조직 포함 옵션)
  - 특정 구성원

### 2.2 승인 정책 관리

#### 2.2.1 정책 현황 조회
- **화면 구성**:
  - 휴가 정책별 승인 설정 현황
  - 근무 정책별 승인 설정 현황
  - 워크플로우 양식별 승인 설정 현황
- **필터 기능**:
  - 승인자별 필터
  - 참조자별 필터
  - 변경 허용 여부 필터
  - 요청자별 승인 설정 여부 필터
- **검색 기능**:
  - 양식명/정책명으로 검색

#### 2.2.2 템플릿 일괄 적용
- **선택 옵션**:
  - 개별 정책 선택 적용
  - 전체 정책 일괄 적용 (모든 정책 체크박스)
- **적용 확인**:
  - 적용 대상 정책 목록 표시
  - 기존 설정과 새 설정 비교 미리보기
  - 최종 확인 후 적용

#### 2.2.3 승인 정책 개별 수정
- **직접 편집**: 템플릿 없이 개별 정책의 승인 단계 직접 수정
- **일괄 변경**: 선택된 여러 정책에 동일한 승인 설정 적용

### 2.3 고급 기능

#### 2.3.1 요청자별 승인
- **차등 승인**: 요청자의 직급/조직에 따른 다른 승인 프로세스
- **조건 설정**:
  - 일반 구성원: 1차 조직장 승인
  - 조직장: HR 승인
  - 임원: 대표이사 승인
- **예외 처리**: 특정 구성원 또는 조직에 대한 승인 면제

#### 2.3.2 변경 허용 옵션
- **구성원 편집 권한**: 요청자가 승인 단계를 직접 수정할 수 있는 권한
- **제한 사항**: 설정된 승인자 범위 내에서만 변경 허용

## 3. 데이터베이스 설계

### 3.1 기존 테이블 확장

#### approval_lines 테이블 확장
```sql
ALTER TABLE approval_lines ADD COLUMN IF NOT EXISTS template_name TEXT;
ALTER TABLE approval_lines ADD COLUMN IF NOT EXISTS is_template BOOLEAN DEFAULT FALSE;
ALTER TABLE approval_lines ADD COLUMN IF NOT EXISTS allow_modification BOOLEAN DEFAULT FALSE;
ALTER TABLE approval_lines ADD COLUMN IF NOT EXISTS requester_based_approval BOOLEAN DEFAULT FALSE;
```

#### 새 테이블: approval_templates
```sql
CREATE TABLE approval_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    template_name TEXT NOT NULL,
    description TEXT,
    step_count INTEGER NOT NULL DEFAULT 1,
    allow_modification BOOLEAN DEFAULT FALSE,
    requester_based_approval BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES employees(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 새 테이블: approval_policies
```sql
CREATE TABLE approval_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    policy_type TEXT NOT NULL CHECK (policy_type IN ('leave', 'work', 'workflow')),
    policy_name TEXT NOT NULL, -- 연차, 병가, 외근, 재택근무 등
    policy_id TEXT, -- 외부 정책 ID (leave_types.id 등)
    template_id UUID REFERENCES approval_templates(id),
    line_id UUID REFERENCES approval_lines(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 새 테이블: approval_references
```sql
CREATE TABLE approval_references (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    line_id UUID NOT NULL REFERENCES approval_lines(id) ON DELETE CASCADE,
    reference_type TEXT NOT NULL CHECK (reference_type IN ('organization', 'employee')),
    reference_id UUID NOT NULL, -- organization_id 또는 employee_id
    notification_type TEXT NOT NULL DEFAULT 'all' CHECK (notification_type IN ('none', 'request', 'complete', 'all')),
    include_sub_orgs BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.2 정책 적용 규칙

#### 우선순위
1. 특정 정책별 개별 설정 (approval_policies)
2. 조직별 기본 승인 라인 (approval_lines)
3. 회사 기본 승인 라인

#### 요청자별 승인 조건 처리
```sql
CREATE TABLE approval_requester_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    line_id UUID NOT NULL REFERENCES approval_lines(id) ON DELETE CASCADE,
    condition_type TEXT NOT NULL CHECK (condition_type IN ('role', 'organization', 'employee')),
    condition_value TEXT NOT NULL, -- role 이름, organization_id, employee_id
    target_line_id UUID NOT NULL REFERENCES approval_lines(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 4. API 설계

### 4.1 승인 템플릿 API

#### GET /api/approval/templates
- 승인 템플릿 목록 조회
- 필터: 회사별, 활성화 여부

#### POST /api/approval/templates
- 새 승인 템플릿 생성
- 권한: company_admin 이상

#### PUT /api/approval/templates/{id}
- 승인 템플릿 수정
- 권한: company_admin 이상

#### DELETE /api/approval/templates/{id}
- 승인 템플릿 삭제
- 사용 중인 템플릿은 비활성화만 가능

### 4.2 승인 정책 API

#### GET /api/approval/policies
- 회사의 모든 승인 정책 현황 조회
- 필터: 정책 유형, 승인자, 참조자

#### POST /api/approval/policies/bulk-apply
- 선택된 정책들에 템플릿 일괄 적용
- 권한: company_admin 이상

#### PUT /api/approval/policies/bulk-update
- 선택된 정책들의 승인 설정 일괄 변경
- 권한: company_admin 이상

### 4.3 조직도 API

#### GET /api/organizations/tree
- 회사 전체 조직도 트리 구조 조회
- 하위 조직 포함 여부 옵션

## 5. UI/UX 설계

### 5.1 메뉴 구조
```
설정 (Settings)
├── 승인 정책 관리 (Approval Policy Management)
│   ├── 승인 정책 현황 (Policy Overview)
│   └── 승인 템플릿 (Templates)
```

### 5.2 주요 화면

#### 5.2.1 승인 정책 관리 메인 화면
- **레이아웃**: 탭 구조 (휴가 정책 / 근무 정책 / 워크플로우)
- **테이블**: 정책명, 승인 단계, 참조자, 옵션 (변경허용, 요청자별승인)
- **액션**: 개별 편집, 체크박스 선택, 일괄 작업
- **필터/검색**: 상단 필터 바 + 검색창

#### 5.2.2 승인 템플릿 관리 화면
- **목록**: 템플릿 카드 형식 또는 테이블
- **생성**: 모달 또는 별도 페이지에서 단계적 설정
- **미리보기**: 템플릿 적용 시 결과 미리보기

#### 5.2.3 승인 단계 설정 화면
- **시각적 플로우**: 단계별 연결선으로 표시
- **드래그 앤 드롭**: 단계 순서 변경
- **승인자 선택**: 드롭다운 + 조직도 팝업
- **참조자 설정**: 별도 섹션으로 구분

## 6. 권한 관리

### 6.1 접근 권한
- **승인 정책 관리 권한**: 전체 기능 접근
- **개별 권한**: 
  - 근무 유형 및 정책 설정 권한 → 근무 승인만 관리
  - 연차 정책 및 촉진 관리 권한 → 휴가 승인만 관리
  - 맞춤 휴가 관리 권한 → 특정 휴가 유형만 관리

### 6.2 권한별 기능 제한
```typescript
interface ApprovalPolicyPermissions {
  canManageAllPolicies: boolean;        // 모든 승인 정책 관리
  canManageWorkApproval: boolean;       // 근무 승인 정책
  canManageLeaveApproval: boolean;      // 휴가 승인 정책
  canManageWorkflowApproval: boolean;   // 워크플로우 승인 정책
  canCreateTemplates: boolean;          // 승인 템플릿 생성
  canBulkApply: boolean;               // 일괄 적용
}
```

## 7. 구현 우선순위

### Phase 1 (필수 기능)
1. 승인 템플릿 CRUD
2. 기본 승인 정책 관리 화면
3. 조직별 승인 라인 설정
4. 템플릿 개별 적용

### Phase 2 (고급 기능)
1. 일괄 적용 기능
2. 참조자 설정 및 알림
3. 필터 및 검색 기능
4. 요청자별 승인 설정

### Phase 3 (최적화)
1. 승인 정책 미리보기
2. 변경 이력 관리
3. 템플릿 복사/가져오기
4. 고급 조건 설정

## 8. 테스트 시나리오

### 8.1 기본 시나리오
1. 승인 템플릿 생성 및 저장
2. 휴가 정책에 템플릿 적용
3. 승인 워크플로우 정상 동작 확인
4. 템플릿 수정 시 적용된 정책 업데이트 확인

### 8.2 예외 시나리오
1. 승인자가 조직에서 제외된 경우 처리
2. 순환 참조 승인 라인 방지
3. 권한 없는 사용자의 접근 차단
4. 사용 중인 템플릿 삭제 시 처리

## 9. 성공 지표
- 승인 정책 설정 소요 시간 80% 단축
- 정책 변경 시 일괄 적용률 90% 이상
- 승인 워크플로우 오류율 5% 이하
- 관리자 사용성 만족도 4.5점 이상 (5점 만점)