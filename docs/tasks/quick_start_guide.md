# ClockBox 빠른 시작 가이드

## 🚀 즉시 시작하기 위한 체크리스트

### Step 1: Supabase 프로젝트 생성 (15분)

1. [Supabase](https://supabase.com) 접속 후 새 프로젝트 생성
2. 프로젝트 설정에서 다음 정보 복사:
   - Project URL
   - Anon Key
   - Service Role Key

3. 데이터베이스 마이그레이션 실행:
```bash
cd backend
npx supabase link --project-ref your-project-ref
npx supabase db push
```

### Step 2: 환경변수 설정 (5분)

#### Frontend (.env.local)
```env
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
```

#### Mobile App (.env)
```env
EXPO_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
```

#### Backend (supabase/.env)
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
```

### Step 3: 로컬 개발 서버 실행 (5분)

터미널을 3개 열고 각각 실행:

```bash
# Terminal 1: Backend
cd backend
npx supabase start

# Terminal 2: Frontend
cd frontend
npm install
npm run dev

# Terminal 3: Mobile
cd app
npm install
npm run ios  # or npm run android
```

### Step 4: 테스트 계정 생성 (5분)

1. http://localhost:3000/signup 접속
2. 테스트 계정 생성
3. Supabase 대시보드에서 사용자 확인

### Step 5: 초기 데이터 설정 (10분)

Supabase SQL Editor에서 실행:

```sql
-- 테스트 회사 생성
INSERT INTO companies (name, business_number, subscription_plan)
VALUES ('테스트 회사', '123-45-67890', 'basic');

-- 테스트 직원 연결 (user_id는 실제 값으로 변경)
INSERT INTO employees (profile_id, company_id, user_role, employee_number)
VALUES ('your-user-id', 'company-id', 'admin', 'EMP001');

-- 기본 휴가 유형 생성
INSERT INTO leave_types (company_id, name, code, days_per_year)
VALUES 
  ('company-id', '연차', 'ANNUAL', 15),
  ('company-id', '병가', 'SICK', 3),
  ('company-id', '경조사', 'EVENT', 5);
```

---

## ⚡ 핵심 기능 테스트

### 1. 출퇴근 테스트
- 대시보드에서 출근 버튼 클릭
- 52시간 경고 확인
- 퇴근 처리

### 2. 휴가 신청 테스트
- 휴가 메뉴에서 신청
- 관리자 계정으로 승인

### 3. 실시간 기능 테스트
- 두 개의 브라우저 창 열기
- 한 곳에서 출근 처리
- 다른 창에서 실시간 업데이트 확인

---

## 🔧 자주 발생하는 문제 해결

### Supabase 연결 오류
```bash
# Supabase CLI 재설치
npm install -g supabase
```

### Next.js 빌드 오류
```bash
# 캐시 삭제 후 재빌드
rm -rf .next
npm run build
```

### Expo 실행 오류
```bash
# 캐시 클리어
npx expo start -c
```

---

## 📱 개발 도구 추천

### VS Code Extensions
- Prisma
- Tailwind CSS IntelliSense
- ESLint
- Prettier

### Chrome Extensions
- React Developer Tools
- Redux DevTools

### 모바일 테스트
- Expo Go 앱 (iOS/Android)
- iOS Simulator (Mac)
- Android Studio Emulator

---

## 🎯 첫 주 목표

- [ ] 로컬 환경 완전 구동
- [ ] 출퇴근 기능 테스트
- [ ] 컴포넌트 1개 이상 개발
- [ ] PR 1개 이상 생성

---

*궁금한 점이 있으면 [이슈](https://github.com/surfmindsm/ClockBox/issues)에 등록해주세요!*