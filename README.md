# ClockBox - 통합 근태·인력관리 시스템

한국 시장에 최적화된 종합 근태관리 SaaS 솔루션

## 🚀 프로젝트 구조

```
ClockBox/
├── backend/        # Supabase 백엔드
├── frontend/       # Next.js 웹 애플리케이션  
├── app/           # React Native 모바일 앱
└── docs/          # 프로젝트 문서 및 PRD
```

## 🛠 기술 스택

- **Backend**: Supabase (PostgreSQL, Auth, Realtime, Edge Functions)
- **Frontend**: Next.js 14, TypeScript, Tailwind CSS
- **Mobile**: React Native (Expo), TypeScript
- **Infrastructure**: Vercel, Supabase Cloud

## 📋 주요 기능

### 핵심 기능
- ✅ 52시간 근무제 자동 차단 및 모니터링
- ✅ GPS/WiFi 기반 출퇴근 인증
- ✅ 실시간 근태 현황 대시보드
- ✅ 다단계 휴가 승인 워크플로우
- ✅ 한국형 급여 계산 (연장/야간/휴일 수당)

### 한국 시장 특화
- 📱 카카오톡 알림톡 연동
- 💼 더존/영림원/SAP 연동
- 📊 법정 리포트 자동 생성
- 🔐 개인정보보호법 준수

## 🚀 시작하기

### 1. Backend (Supabase) 설정

```bash
cd backend

# Supabase CLI 로그인
npx supabase login

# 로컬 개발 서버 시작
npx supabase start

# 데이터베이스 마이그레이션
npx supabase db push

# Edge Functions 배포
npx supabase functions deploy
```

### 2. Frontend (Next.js) 실행

```bash
cd frontend

# 의존성 설치
npm install

# 환경변수 설정 (.env.local)
cp .env.local.example .env.local

# 개발 서버 시작
npm run dev
```

### 3. Mobile App (React Native) 실행

```bash
cd app

# 의존성 설치
npm install

# iOS 실행
npm run ios

# Android 실행
npm run android
```

## 📦 환경 변수 설정

### Frontend (.env.local)
```
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Mobile App (.env)
```
EXPO_PUBLIC_SUPABASE_URL=your_supabase_url
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 📚 프로젝트 문서

- [기능명세서](docs/functional_specification.md)
- [메인 PRD](docs/prd/main_prd_main.md)
- [한국 시장 분석](docs/PRD심층분석.md)

## 🔐 보안 및 컴플라이언스

- 52시간 근무제 실시간 모니터링
- 개인정보보호법 준수 (3년 데이터 보관)
- Row Level Security (RLS) 적용
- End-to-End 암호화

## 📱 지원 플랫폼

- Web: Chrome, Firefox, Safari, Edge (최신 2버전)
- iOS: 14.0+
- Android: 8.0+ (API Level 26+)

## 🤝 기여하기

프로젝트 기여는 다음 git submodule 저장소에서 가능합니다:
- Backend: https://github.com/surfmindsm/clockbox-backend
- Frontend: https://github.com/surfmindsm/clockbox-frontend  
- App: https://github.com/surfmindsm/clockbox-app

## 📄 라이선스

Copyright © 2024 Surfmind. All rights reserved.