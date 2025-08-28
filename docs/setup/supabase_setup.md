# Supabase 프로젝트 설정 완료 가이드

## ✅ 완료된 작업

### 1. 프로젝트 생성
- **프로젝트 ID**: apmgoboqnodhroqvetjx
- **URL**: https://apmgoboqnodhroqvetjx.supabase.co
- **리전**: ap-northeast-2 (Seoul)
- **데이터베이스 비밀번호**: Surfmind2025!

### 2. 환경변수 설정 완료
- ✅ Frontend (.env.local)
- ✅ App (.env)
- ✅ Backend (.env)

## 📋 즉시 실행 필요 작업

### Step 1: 데이터베이스 마이그레이션 (5분)

1. [SQL Editor 열기](https://supabase.com/dashboard/project/apmgoboqnodhroqvetjx/sql/new)

2. **첫 번째 마이그레이션 실행** (전체 복사하여 실행):
   - `backend/supabase/migrations/00001_initial_schema.sql` 내용 전체 복사
   - SQL Editor에 붙여넣기
   - Run 버튼 클릭

3. **두 번째 마이그레이션 실행**:
   - `backend/supabase/migrations/00002_rls_policies.sql` 내용 전체 복사
   - SQL Editor에 붙여넣기
   - Run 버튼 클릭

### Step 2: Authentication 설정 (2분)

1. [Authentication 설정](https://supabase.com/dashboard/project/apmgoboqnodhroqvetjx/auth/providers) 접속

2. Email 설정:
   - Email Auth 활성화 확인
   - Confirm Email 비활성화 (개발 단계)
   - Email Templates 한국어로 수정

### Step 3: Storage 버킷 생성 (2분)

1. [Storage](https://supabase.com/dashboard/project/apmgoboqnodhroqvetjx/storage/buckets) 접속

2. 버킷 생성:
   ```
   - avatars (프로필 사진)
   - documents (문서 파일)
   - contracts (전자 계약서)
   ```

### Step 4: Edge Functions 배포 (5분)

```bash
# Backend 폴더에서 실행
cd /Users/crom/workspace_surfmind/ClockBox/backend

# Supabase CLI 로그인 (브라우저 열림)
npx supabase login

# 프로젝트 연결
npx supabase link --project-ref apmgoboqnodhroqvetjx --password Surfmind2025!

# Functions 배포
npx supabase functions deploy clock-in
```

### Step 5: 테스트 계정 생성 (3분)

1. Frontend 실행:
```bash
cd /Users/crom/workspace_surfmind/ClockBox/frontend
npm run dev
```

2. http://localhost:3000/signup 접속하여 회원가입

3. [Authentication](https://supabase.com/dashboard/project/apmgoboqnodhroqvetjx/auth/users)에서 사용자 확인

### Step 6: 테스트 데이터 입력 (3분)

SQL Editor에서 실행 (YOUR_USER_ID를 실제 값으로 변경):

```sql
-- 1. 테스트 회사 생성
INSERT INTO companies (name, business_number, subscription_plan)
VALUES ('서프마인드', '123-45-67890', 'enterprise')
RETURNING id; -- 이 ID를 복사

-- 2. 프로필 확인/생성 (YOUR_USER_ID는 Auth Users에서 확인)
INSERT INTO profiles (id, email, full_name, phone)
VALUES (
    'YOUR_USER_ID',
    'your-email@example.com',
    '홍길동',
    '010-1234-5678'
) ON CONFLICT (id) DO UPDATE
SET full_name = '홍길동', phone = '010-1234-5678';

-- 3. 직원 연결 (YOUR_USER_ID와 COMPANY_ID 사용)
INSERT INTO employees (
    profile_id,
    company_id,
    user_role,
    employee_number,
    department,
    position,
    hire_date
) VALUES (
    'YOUR_USER_ID',
    'COMPANY_ID',
    'admin',
    'EMP001',
    '개발팀',
    'CEO',
    '2024-01-01'
);

-- 4. 기본 휴가 유형 생성
INSERT INTO leave_types (company_id, name, code, days_per_year)
VALUES 
    ('COMPANY_ID', '연차', 'ANNUAL', 15),
    ('COMPANY_ID', '병가', 'SICK', 3),
    ('COMPANY_ID', '경조사', 'EVENT', 5),
    ('COMPANY_ID', '보상휴가', 'COMP', 0);

-- 5. 조직 생성
INSERT INTO organizations (
    company_id,
    name,
    type,
    address,
    gps_lat,
    gps_lng,
    gps_radius
) VALUES (
    'COMPANY_ID',
    '서프마인드 본사',
    'headquarters',
    '서울시 강남구 테헤란로 123',
    37.5665,
    126.9780,
    100
);
```

## 🧪 동작 테스트

### 1. 로그인 테스트
- http://localhost:3000/login
- 생성한 계정으로 로그인
- 대시보드 접근 확인

### 2. RLS 테스트
```sql
-- RLS가 활성화되었는지 확인
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

### 3. Realtime 테스트
- Supabase Dashboard > Realtime
- attendance_records 테이블 구독
- 출퇴근 기록 시 실시간 업데이트 확인

## 🚨 문제 해결

### 마이그레이션 오류
- Foreign Key 제약: 참조 테이블이 먼저 생성되었는지 확인
- 권한 오류: Service Role Key 사용

### 로그인 실패
- Email 확인 비활성화 확인
- profiles 테이블에 레코드 생성 확인
- RLS 정책 확인

### Edge Functions 오류
- Environment Variables 설정 확인
- CORS 설정 확인
- Logs 확인: Dashboard > Functions > Logs

## 📊 모니터링

- [Database](https://supabase.com/dashboard/project/apmgoboqnodhroqvetjx/database/tables)
- [API Logs](https://supabase.com/dashboard/project/apmgoboqnodhroqvetjx/logs/edge-logs)
- [Auth Logs](https://supabase.com/dashboard/project/apmgoboqnodhroqvetjx/logs/auth-logs)

## 🎯 다음 단계

1. Frontend 컴포넌트 개발
2. Mobile 앱 화면 구현
3. 추가 Edge Functions 개발
4. 카카오톡 API 연동
5. 프로덕션 배포 준비