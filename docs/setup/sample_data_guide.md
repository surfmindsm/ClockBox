# ClockBox 샘플 데이터 가이드

## 개요

ClockBox 시스템의 개발 및 테스트를 위한 샘플 데이터가 준비되어 있습니다. 이 문서는 각 컴포넌트별 샘플 데이터의 위치와 사용법을 설명합니다.

## 샘플 데이터 위치

### 1. Backend (Supabase)
- **파일**: `backend/supabase/migrations/00003_sample_data.sql`
- **설명**: Supabase 데이터베이스에 삽입할 수 있는 샘플 데이터
- **포함 데이터**:
  - 조직 정보 (3개 회사)
  - 사용자 및 직원 데이터 (5명)
  - 출퇴근 기록 (최근 30일)
  - 휴가 신청 및 잔여 휴가
  - 근무 일정 및 교대 근무
  - 알림 및 승인 워크플로우
  - 감사 로그 및 시스템 설정

### 2. Frontend (Next.js)
- **파일**: `frontend/lib/mock-data.ts`
- **설명**: 프론트엔드 개발용 TypeScript Mock 데이터
- **포함 데이터**:
  - 사용자 인터페이스
  - 대시보드 통계
  - 차트 데이터
  - 실시간 출퇴근 현황
  - 부서별 통계

### 3. Mobile App (React Native)
- **파일**: `app/services/mockData.ts`
- **설명**: 모바일 앱 개발용 TypeScript Mock 데이터
- **포함 데이터**:
  - 사용자 프로필
  - 빠른 작업 메뉴
  - 출퇴근 이력
  - 위치 기반 서비스
  - 푸시 알림 데이터

## 샘플 데이터 특징

### 조직 구성
- **테크스타트업** (org_001): IT 스타트업, 유연근무제
- **글로벌제조** (org_002): 제조업, 3교대 근무
- **스마트솔루션** (org_003): 솔루션 업체

### 직원 구성
- **김관리자** (admin): 시스템 관리자
- **이매니저** (manager): IT 부서 매니저
- **박직원** (employee): IT 개발자, 유연근무
- **최사원** (employee): 마케팅 담당자
- **정기술자** (employee): 생산직 기술자, 교대근무

### 시나리오별 데이터

#### 52시간 근무제 테스트
- 박직원: 이번 주 34.75시간 근무 (정상)
- 최사원: 이번 주 36시간 근무 (정상)
- 48시간 경고 알림 샘플 포함

#### 교대근무 테스트
- 정기술자: 주간 교대 (08:00-16:00)
- 3교대 시스템 (주간/오후/야간)

#### 휴가 관리 테스트
- 연차, 병가, 출산휴가 등 다양한 휴가 유형
- 승인/대기/반려 상태별 샘플

#### 위치 기반 출퇴근
- 본사: 강남구 테헤란로 (GPS 좌표 포함)
- 지점: 서초구 강남대로
- 재택근무 옵션

## 데이터 로딩 방법

### Backend 데이터베이스
```bash
# Supabase CLI를 통한 마이그레이션 실행
cd backend
supabase db reset
supabase migration up
```

### Frontend 개발 서버
```bash
cd frontend
npm run dev
# Mock 데이터가 자동으로 로드됩니다
```

### Mobile App 개발
```bash
cd app
npm start
# Mock 데이터가 자동으로 로드됩니다
```

## 테스트 시나리오

### 1. 일반 출퇴근 플로우
- 박직원으로 로그인
- 08:30 출근 체크 (오피스)
- 점심시간 1시간 포함
- 18:00 퇴근 체크

### 2. 초과근무 시나리오
- 최사원으로 로그인
- 야근 신청 후 20:00까지 근무
- 52시간 경고 시스템 테스트

### 3. 교대근무 시나리오
- 정기술자로 로그인
- 주간 교대 (08:00-16:00)
- 공장 위치에서 출퇴근 체크

### 4. 휴가 관리 시나리오
- 연차 신청 및 승인 프로세스
- 병가 신청 및 대기 상태
- 휴가 잔여일수 확인

### 5. 관리자 기능
- 김관리자로 로그인
- 전체 직원 출퇴근 현황 확인
- 휴가 승인/반려 처리
- 52시간 모니터링 대시보드

## 환경별 설정

### 개발 환경 (Development)
- Mock 데이터 사용
- API 호출 시뮬레이션 (1-2초 지연)
- 에러 시뮬레이션 (5% 확률)

### 스테이징 환경 (Staging)
- Supabase 샘플 데이터 사용
- 실제 API 호출
- 카카오톡 알림 테스트 모드

### 프로덕션 환경 (Production)
- 실제 사용자 데이터
- Mock 데이터 비활성화

## 데이터 초기화

### 전체 데이터 초기화
```sql
-- 모든 테이블 데이터 삭제 (주의: 복구 불가)
TRUNCATE TABLE 
  audit_logs, notifications, weekly_hours, 
  leave_balances, leave_requests, attendance_records,
  employee_schedules, employees, work_schedules,
  user_profiles, organizations, organization_settings
CASCADE;
```

### 샘플 데이터 재생성
```bash
# Backend
cd backend/supabase
psql -f migrations/00003_sample_data.sql

# 또는 Supabase 대시보드에서 SQL Editor 사용
```

## 주의사항

1. **비밀번호**: 모든 샘플 사용자의 비밀번호는 `password123`
2. **이메일**: 실제 이메일 주소가 아니므로 이메일 전송 테스트 불가
3. **전화번호**: 더미 데이터이므로 SMS 테스트 불가
4. **GPS 좌표**: 강남/서초 지역 실제 좌표 사용
5. **날짜**: 2024년 1월 기준으로 설정됨 (필요시 업데이트 필요)

## 문제 해결

### 데이터 로딩 오류
- Supabase 연결 상태 확인
- RLS 정책 활성화 확인
- 환경변수 설정 확인

### Mock API 응답 없음
- 네트워크 시뮬레이션 설정 확인
- Mock 데이터 import 경로 확인

### 위치 기반 기능 테스트
- GPS 권한 허용 확인
- 개발 도구에서 위치 시뮬레이션 사용

## 추가 데이터 생성

필요에 따라 추가 샘플 데이터 생성:

```typescript
// 새로운 직원 추가
const newEmployee = {
  id: 'emp_006',
  name: '신직원',
  department: 'Sales',
  // ... 기타 속성
};
```

## 연락처

샘플 데이터 관련 문의:
- 개발팀 슬랙 채널: #clockbox-dev
- 이슈 트래커: GitHub Issues