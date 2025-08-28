# ClockBox 샘플 데이터 로드 가이드

## 개요
ClockBox 프로젝트의 샘플 데이터를 Supabase 데이터베이스에 로드하는 방법을 안내합니다.

## 방법 1: 클라우드 Supabase Dashboard 사용 (권장)

### 1. Supabase 프로젝트 접속
1. [Supabase Dashboard](https://supabase.com/dashboard) 접속
2. ClockBox 프로젝트 선택 (apmgoboqnodhroqvetjx)

### 2. 기존 스키마 확인
1. 좌측 메뉴에서 **Table Editor** 클릭
2. 기존 테이블들이 있는지 확인:
   - organizations
   - user_profiles  
   - employees
   - attendance_records
   - leave_requests
   - 기타 테이블들

### 3. 샘플 데이터 로드
1. 좌측 메뉴에서 **SQL Editor** 클릭
2. 새 쿼리 생성
3. `backend/supabase/seed.sql` 파일의 내용을 복사
4. SQL Editor에 붙여넣기
5. **Run** 버튼 클릭하여 실행

### 4. 데이터 로드 확인
1. **Table Editor**로 돌아가기
2. 각 테이블을 클릭하여 데이터가 로드되었는지 확인:
   - `organizations`: 3개 회사 (테크스타트업, 글로벌제조, 스마트솔루션)
   - `employees`: 5명 직원
   - `attendance_records`: 최근 출퇴근 기록
   - `leave_requests`: 휴가 신청 내역

## 방법 2: Supabase CLI 사용 (로컬 환경)

### 1. 전제조건
- Docker Desktop 설치 및 실행
- Supabase CLI 설치 완료

### 2. 로컬 Supabase 서버 시작
```bash
cd backend
export PATH="$HOME/bin:$PATH"
supabase start
```

### 3. 데이터베이스 리셋 및 시드 로드
```bash
# 데이터베이스 리셋 (마이그레이션 + 시드 데이터 자동 로드)
supabase db reset

# 또는 시드 데이터만 로드
supabase seed run
```

### 4. 로컬 Studio 접속
- 브라우저에서 `http://localhost:54323` 접속
- 로컬 Supabase Studio에서 데이터 확인

## 방법 3: psql 직접 연결 (고급)

### 1. 데이터베이스 연결 정보 확인
Supabase Dashboard → Settings → Database → Connection String

### 2. psql로 연결
```bash
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres"
```

### 3. SQL 파일 실행
```sql
\i backend/supabase/seed.sql
```

## 로드되는 샘플 데이터 상세

### 조직 (Organizations)
- **테크스타트업**: IT 스타트업, 유연근무제
- **글로벌제조**: 제조업, 3교대 시스템
- **스마트솔루션**: 솔루션 개발업체

### 직원 (Employees)
1. **김관리자** (admin@techstartup.com)
   - 역할: 관리자 (admin)
   - 부서: IT
   
2. **이매니저** (manager@techstartup.com)
   - 역할: 매니저 (manager)
   - 부서: IT
   
3. **박직원** (employee1@techstartup.com)
   - 역할: 직원 (employee)
   - 부서: IT
   - 유연근무제
   
4. **최사원** (employee2@techstartup.com)
   - 역할: 직원 (employee)
   - 부서: Marketing
   
5. **정기술자** (employee3@globalmanuf.com)
   - 역할: 직원 (employee)
   - 부서: Production
   - 3교대 근무

### 출퇴근 기록 (Attendance Records)
- 최근 7일간의 출퇴근 기록
- 정상근무, 지각, 야근, 재택근무 등 다양한 시나리오
- 52시간 근무제 테스트를 위한 시간 계산

### 휴가 관리 (Leave Management)
- 연차, 병가, 출산휴가 등 다양한 휴가 유형
- 승인/대기/반려 상태별 샘플
- 휴가 잔여일수 관리

### 주간 근무시간 추적
- 52시간 근무제 모니터링
- 초과근무 시간 계산
- 경고 시스템 테스트 데이터

## 테스트 계정

### 1. 관리자 계정
```
이메일: admin@techstartup.com
비밀번호: password123
역할: 관리자 (admin)
회사: 테크스타트업
```

### 2. 매니저 계정
```
이메일: manager@techstartup.com
비밀번호: password123
역할: 매니저 (manager)
회사: 테크스타트업
```

### 3. 일반 직원 계정
```
이메일: employee1@techstartup.com
비밀번호: password123
이름: 박직원 (IT 주임)
회사: 테크스타트업
```

```
이메일: employee2@techstartup.com
비밀번호: password123
이름: 최사원 (마케팅 사원)
회사: 테크스타트업
```

### 4. 제조업 직원 계정
```
이메일: employee3@globalmanuf.com
비밀번호: password123
이름: 정기술자 (생산 기술자)
회사: 글로벌제조 (3교대 근무)
```

**주의**: 이 계정들로 Supabase Auth를 통해 실제 로그인이 가능합니다.

### 3. 52시간 근무제 테스트
- 박직원: 이번 주 34.75시간 (정상)
- 최사원: 이번 주 36시간 (정상)
- 48시간 경고 알림 테스트

## 문제 해결

### 1. "relation does not exist" 오류
- 마이그레이션이 실행되지 않았을 가능성
- 먼저 모든 마이그레이션을 실행: `supabase migration up`

### 2. "duplicate key value" 오류
- 이미 데이터가 존재하는 경우
- 기존 데이터 삭제 후 재시도 또는 ON CONFLICT 사용

### 3. RLS(Row Level Security) 오류
- RLS 정책이 활성화된 경우 데이터 접근 제한
- 관리자 권한으로 데이터 삽입 필요

## 데이터 초기화

### 모든 샘플 데이터 삭제
```sql
-- 주의: 모든 데이터가 삭제됩니다
TRUNCATE TABLE 
  audit_logs, notifications, weekly_hours, 
  leave_balances, leave_requests, attendance_records,
  employee_schedules, employees, work_schedules,
  user_profiles, organizations, organization_settings
CASCADE;
```

### 샘플 데이터 재로드
```sql
-- seed.sql 파일 내용을 다시 실행
\i backend/supabase/seed.sql
```

## 다음 단계

1. **인증 설정**: Supabase Auth에 실제 사용자 계정 생성
2. **RLS 정책 테스트**: 데이터 접근 권한 확인
3. **API 테스트**: Edge Functions과 연동 테스트
4. **프론트엔드 연결**: Next.js 앱에서 데이터 확인

## 참고 링크

- [Supabase Dashboard](https://supabase.com/dashboard)
- [Supabase CLI 문서](https://supabase.com/docs/guides/cli)
- [PostgreSQL 문서](https://www.postgresql.org/docs/)
- [ClockBox 샘플 데이터 가이드](./sample_data_guide.md)