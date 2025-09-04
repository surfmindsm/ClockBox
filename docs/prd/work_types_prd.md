# 근무 유형 관리 시스템 PRD

## 1. 개요

ClockBox 근무 유형 관리 시스템은 다양한 근무 형태를 지원하는 유연한 근태 관리 솔루션입니다. 한국 근로기준법(52시간 근무제)을 준수하며, 고정근무, 시차근무, 선택적근무, 교대근무 등 4가지 주요 근무 유형을 지원합니다.

## 2. 주요 기능

### 2.1 근무 유형 분류
- **고정근무**: 일정한 출퇴근 시간을 가진 표준 근무 형태
- **시차근무**: 출근 시간을 조정할 수 있는 유연한 근무 형태  
- **선택적근무**: 코어타임 외 자유로운 근무시간 선택
- **교대근무**: 3교대, 4교대 등 교대 시스템

### 2.2 고정근무 상세 설정

#### 2.2.1 기본 설정 ("일하는 방식" 탭)

**근무 요일 및 시간**
- 근무 요일 선택 (월~일)
- 주휴일 설정 (1주마다 부여하는 유급 휴일)
- 근무 주기 시작 요일 (기본: 월요일)
- 기본 출근시간 및 근무시간 설정
- 추천 휴게시간 관리 (복수 설정 가능)

**1일 기준 시간 설정**
- 비례계산: (1주간 총 일하는 시간 / 40) × 8
- 직접 입력: 고정 시간 설정 (예: 8시간)
- 주휴시간 및 휴가 1일 기준시간 산정 기준

**연장근무 설정**
- 연장근무 최소 입력 시간 제한
- 연장근무 입력 단위 (5분, 15분, 30분, 60분)
- 입력 단위 미달 시 처리 방식 (올림/내림)

**근무기록 설정**
- 자동 근무 기록: 출근시간에 맞춰 자동 기록 생성
- 실시간 출퇴근 기록: PC/모바일 기기 실시간 기록
- 기록 정책 관리: 정시 출퇴근 설정 및 정책
- 기본 퇴근 설정: 구성원 편의 기능

#### 2.2.2 요일별 설정 ("요일별 설정" 탭)

**기본 개념**
- 기본 설정과 다른 근무시간이 필요한 특정 요일 관리
- 예시: 금요일만 6시간 단축근무, 임신기 단축근로 등

**요일별 스케줄 관리**
- 적용 요일 선택 (복수 선택 가능)
- 해당 요일의 출근시간 및 근무시간 설정
- 해당 요일의 휴게시간 설정
- 다른 설정과 적용일 중복 방지 검증

#### 2.2.3 기록 정책 관리

**정시 설정**
- 정시 출퇴근 인정 범위 (정시만 인정 ~ 120분)
- 출근 기록 시각을 반영한 정시 퇴근 설정
- 정시 출근 시간보다 이른 출근 기록 허용 여부

**기록 설정**
- 출근 기록 제한 없음 (기본)
- 실시간 근무 기록 정책

**기본 퇴근 설정**
- 기본 퇴근 방식: 지금 퇴근 vs 정시 퇴근
- 근무 기록 확인: 항상 확인 vs 건너뛰기
- 세콤/ADT 캡스 연동 지원

## 3. 기술 구조

### 3.1 데이터베이스 스키마

```sql
-- 근무 유형 테이블
CREATE TABLE work_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  type work_type_category NOT NULL,
  description TEXT,
  company_id UUID REFERENCES companies(id),
  organization_id UUID REFERENCES organizations(id),
  settings JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 근무 유형 카테고리 ENUM
CREATE TYPE work_type_category AS ENUM (
  '고정근무',
  '시차근무', 
  '선택적근무',
  '교대근무'
);
```

### 3.2 고정근무 설정 데이터 구조

```typescript
interface FixedWorkSettings {
  // 기본 근무 설정
  work_days: string[]                    // 근무 요일
  weekly_holiday: string                 // 주휴일
  default_start_time: string             // 기본 출근시간
  default_work_hours: number             // 기본 근무시간
  break_times: BreakTime[]               // 휴게시간들
  
  // 연장근무 설정
  overtime_min_input_time: number | null      // 최소 입력시간
  overtime_input_unit: number | null          // 입력 단위
  overtime_unit_shortfall_handling: 'round_up' | 'round_down'
  
  // 근무기록 설정
  auto_work_record: boolean              // 자동 근무 기록
  realtime_attendance_record: boolean    // 실시간 출퇴근 기록
  record_policy_settings: RecordPolicySettings
  
  // 요일별 설정
  day_specific_schedules?: DaySpecificSchedule[]
  daily_standard_hours?: DailyStandardHours
}

interface RecordPolicySettings {
  punctuality_range: 'exact' | number         // 정시 인정 범위
  early_checkin_allowed: boolean              // 이른 출근 허용
  follow_checkin_time_for_checkout: boolean   // 출근시각 반영 퇴근
  default_checkout_method: 'current_time' | 'punctual_time'
  work_record_confirmation: 'always_confirm' | 'skip'
}

interface DaySpecificSchedule {
  id: string
  apply_days: string[]        // 적용 요일들
  start_time: string          // 출근시간
  work_hours: number          // 근무시간
  break_times: BreakTime[]    // 휴게시간들
}

interface BreakTime {
  start_time: string    // 시작시간
  end_time: string      // 종료시간  
  duration: number      // 지속시간(분)
}
```

## 4. 사용자 경험 (UX)

### 4.1 탭 기반 네비게이션
- **일하는 방식**: 전체적인 근무 정책과 연장근무, 1일 기준시간 설정
- **요일별 설정**: 특정 요일에 다른 근무시간이 필요할 때 추가 설정

### 4.2 모달 기반 상세 설정
- **요일별 설정 모달**: 적용일, 근무시간, 휴게시간 설정
- **기록 정책 관리 모달**: 정시 설정 및 기록 정책
- **기본 퇴근 설정 모달**: 퇴근 방식 및 기록 확인 방식

### 4.3 실시간 계산 및 피드백
- 실제 근무시간 자동 계산 (근무시간 - 휴게시간)
- 설정 충돌 방지 (요일별 설정 중복 경고)
- 한국 근로기준법 준수 가이드

## 5. 법적 준수사항

### 5.1 근로기준법 준수
- 주 52시간 근무제 자동 체크
- 휴게시간 법정 기준 안내
- 연장근무 한도 모니터링

### 5.2 데이터 보안
- 근무시간 데이터 3년 보존
- 개인정보보호법 준수
- 접근권한 기반 데이터 제어

## 6. 통합 및 확장성

### 6.1 다른 근무 유형 확장 준비
- 시차근무, 선택적근무, 교대근무 템플릿 구조 준비
- 공통 인터페이스 설계로 일관성 유지

### 6.2 외부 시스템 연동
- 급여 시스템 연동을 위한 표준화된 데이터 구조
- ERP 시스템 (Douzone, SAP) 연동 준비
- KakaoTalk 알림 서비스 연동

## 7. 현재 구현 상태

### 7.1 완료된 기능
- ✅ 고정근무 유형 완전 구현
- ✅ 탭 기반 설정 UI
- ✅ 요일별 설정 모달
- ✅ 기록 정책 관리 모달
- ✅ 기본 퇴근 설정 모달
- ✅ 데이터베이스 스키마
- ✅ API 클라이언트 구현
- ✅ 권한 기반 접근 제어

### 7.2 향후 개발 예정
- 🔄 시차근무 유형 구현
- 🔄 선택적근무 유형 구현  
- 🔄 교대근무 유형 구현
- 🔄 조직별 근무 유형 할당 시스템
- 🔄 근무시간 준수 모니터링 대시보드

## 8. 성능 및 확장성 고려사항

### 8.1 데이터 최적화
- JSONB 필드 활용한 유연한 설정 저장
- 인덱스 최적화를 통한 빠른 검색
- Row Level Security(RLS) 정책 적용

### 8.2 사용자 경험 최적화
- 실시간 설정 변경 피드백
- 직관적인 UI/UX 디자인
- 모바일 반응형 지원

이 PRD는 ClockBox 근무 유형 관리 시스템의 핵심 기능과 구현 사항을 정의하며, 향후 개발 로드맵의 기준점 역할을 합니다.