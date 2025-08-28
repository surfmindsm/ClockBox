# ClockBox 기능명세서 (Functional Specification)

## 1. 시스템 아키텍처 개요

### 1.1 기술 스택
- **Backend**: Supabase (PostgreSQL, Auth, Realtime, Storage, Edge Functions)
- **Frontend**: Next.js 14 (App Router, Server Components, TypeScript)
- **Mobile**: React Native (Expo, TypeScript)
- **Infrastructure**: Vercel (Frontend), Supabase Cloud (Backend), AWS S3 (Additional Storage)

### 1.2 시스템 구성도
```
┌──────────────────────────────────────────────────────┐
│                    Client Layer                      │
├─────────────────────┬────────────────────────────────┤
│   Web (Next.js)     │    Mobile (React Native)       │
│   - SSR/SSG         │    - iOS/Android              │
│   - Server Actions  │    - Push Notifications       │
│   - Tailwind CSS    │    - Biometric Auth          │
└─────────────────────┴────────────────────────────────┘
                              │
                    ┌─────────┴──────────┐
                    │   API Gateway       │
                    │   (Supabase)        │
                    └─────────┬──────────┘
                              │
┌──────────────────────────────────────────────────────┐
│                  Backend Services                    │
├──────────────────────────────────────────────────────┤
│  Supabase Core Services                             │
│  ├─ Auth (JWT, OAuth, MFA)                          │
│  ├─ Database (PostgreSQL + Row Level Security)       │
│  ├─ Realtime (WebSocket for live updates)           │
│  ├─ Storage (Files, Images)                         │
│  └─ Edge Functions (Business Logic)                 │
├──────────────────────────────────────────────────────┤
│  External Services                                  │
│  ├─ KakaoTalk API (알림톡)                          │
│  ├─ Google Maps API (위치 인증)                      │
│  ├─ SendGrid (이메일)                               │
│  └─ ERP Integrations (더존, 영림원, SAP)            │
└──────────────────────────────────────────────────────┘
```

## 2. 백엔드 (Supabase) 기능명세

### 2.1 데이터베이스 스키마

#### 2.1.1 인증 및 사용자 관리
```sql
-- Supabase Auth를 확장한 profiles 테이블
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 회사 정보
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    business_number TEXT UNIQUE,
    industry TEXT,
    subscription_plan TEXT DEFAULT 'basic',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id)
);

-- 직원 정보 (profiles와 companies 연결)
CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES profiles(id),
    company_id UUID REFERENCES companies(id),
    employee_number TEXT,
    department TEXT,
    position TEXT,
    role TEXT DEFAULT 'employee', -- admin, manager, employee
    hire_date DATE,
    status TEXT DEFAULT 'active',
    work_settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(profile_id, company_id)
);
```

#### 2.1.2 근태 관리
```sql
-- 근무 일정
CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES employees(id),
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_minutes INT DEFAULT 60,
    work_type TEXT DEFAULT 'office', -- office, remote, hybrid
    location JSONB, -- {lat, lng, address}
    status TEXT DEFAULT 'confirmed',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(employee_id, date)
);

-- 출퇴근 기록
CREATE TABLE attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES employees(id),
    schedule_id UUID REFERENCES schedules(id),
    clock_in TIMESTAMPTZ,
    clock_in_location JSONB,
    clock_out TIMESTAMPTZ,
    clock_out_location JSONB,
    work_hours DECIMAL(4,2),
    overtime_hours DECIMAL(4,2) DEFAULT 0,
    status TEXT, -- normal, late, early_leave, absent
    verification_method TEXT, -- gps, wifi, qr, manual
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 52시간 근무제 모니터링
CREATE TABLE weekly_work_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES employees(id),
    week_start DATE NOT NULL,
    regular_hours DECIMAL(4,2) DEFAULT 0,
    overtime_hours DECIMAL(4,2) DEFAULT 0,
    total_hours DECIMAL(4,2) DEFAULT 0,
    warning_sent BOOLEAN DEFAULT FALSE,
    blocked BOOLEAN DEFAULT FALSE,
    
    UNIQUE(employee_id, week_start)
);
```

#### 2.1.3 휴가 관리
```sql
-- 휴가 유형
CREATE TABLE leave_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    days_per_year DECIMAL(3,1),
    is_paid BOOLEAN DEFAULT TRUE,
    auto_approval BOOLEAN DEFAULT FALSE,
    require_document BOOLEAN DEFAULT FALSE,
    
    UNIQUE(company_id, code)
);

-- 휴가 잔액
CREATE TABLE leave_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES employees(id),
    leave_type_id UUID REFERENCES leave_types(id),
    year INT NOT NULL,
    total_days DECIMAL(3,1),
    used_days DECIMAL(3,1) DEFAULT 0,
    remaining_days DECIMAL(3,1),
    expiry_date DATE,
    
    UNIQUE(employee_id, leave_type_id, year)
);

-- 휴가 신청
CREATE TABLE leave_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES employees(id),
    leave_type_id UUID REFERENCES leave_types(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days_requested DECIMAL(3,1),
    reason TEXT,
    status TEXT DEFAULT 'pending',
    approved_by UUID REFERENCES employees(id),
    approved_at TIMESTAMPTZ,
    documents JSONB, -- [{url, name, type}]
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.2 Row Level Security (RLS) 정책

```sql
-- 직원은 자신의 정보만 조회/수정
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Employees can view own attendance" ON attendance_records
    FOR SELECT USING (employee_id = auth.uid());

CREATE POLICY "Managers can view team attendance" ON attendance_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM employees 
            WHERE id = auth.uid() 
            AND role IN ('manager', 'admin')
            AND company_id = (
                SELECT company_id FROM employees 
                WHERE id = attendance_records.employee_id
            )
        )
    );

-- 52시간 근무제 자동 차단
CREATE POLICY "Block overtime exceeding 52 hours" ON attendance_records
    FOR INSERT WITH CHECK (
        (SELECT total_hours FROM weekly_work_hours 
         WHERE employee_id = NEW.employee_id 
         AND week_start = date_trunc('week', NEW.clock_in::date)) < 52
    );
```

### 2.3 Supabase Edge Functions

#### 2.3.1 출퇴근 처리
```typescript
// supabase/functions/clock-in/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { employee_id, location, verification_type } = await req.json()
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // 1. 위치 검증
  const isValidLocation = await verifyLocation(location, employee_id)
  if (!isValidLocation) {
    return new Response(JSON.stringify({ error: '허가된 근무지가 아닙니다' }), {
      status: 403
    })
  }

  // 2. 52시간 체크
  const weeklyHours = await checkWeeklyHours(employee_id)
  if (weeklyHours >= 52) {
    return new Response(JSON.stringify({ error: '주 52시간 초과로 출근할 수 없습니다' }), {
      status: 403
    })
  }

  // 3. 출근 기록
  const { data, error } = await supabase
    .from('attendance_records')
    .insert({
      employee_id,
      clock_in: new Date().toISOString(),
      clock_in_location: location,
      verification_method: verification_type
    })

  // 4. 실시간 알림
  await supabase
    .channel(`employee:${employee_id}`)
    .send({
      type: 'broadcast',
      event: 'clock_in',
      payload: { message: '출근 처리되었습니다', time: new Date() }
    })

  return new Response(JSON.stringify(data), {
    headers: { "Content-Type": "application/json" }
  })
})
```

#### 2.3.2 휴가 승인 워크플로우
```typescript
// supabase/functions/approve-leave/index.ts
serve(async (req) => {
  const { request_id, approver_id, action } = await req.json()
  
  // 1. 권한 확인
  const hasPermission = await checkApprovalPermission(approver_id, request_id)
  if (!hasPermission) {
    return new Response(JSON.stringify({ error: '승인 권한이 없습니다' }), {
      status: 403
    })
  }

  // 2. 휴가 잔액 확인 (승인 시)
  if (action === 'approve') {
    const hasBalance = await checkLeaveBalance(request_id)
    if (!hasBalance) {
      return new Response(JSON.stringify({ error: '휴가 잔액이 부족합니다' }), {
        status: 400
      })
    }
  }

  // 3. 승인/반려 처리
  const { data, error } = await supabase
    .from('leave_requests')
    .update({
      status: action === 'approve' ? 'approved' : 'rejected',
      approved_by: approver_id,
      approved_at: new Date().toISOString()
    })
    .eq('id', request_id)

  // 4. 휴가 잔액 차감 (승인 시)
  if (action === 'approve') {
    await deductLeaveBalance(request_id)
  }

  // 5. 카카오톡 알림 전송
  await sendKakaoNotification(request_id, action)

  return new Response(JSON.stringify(data))
})
```

### 2.4 Realtime 구독

```typescript
// 실시간 출퇴근 현황 모니터링
const channel = supabase.channel('attendance-monitor')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'attendance_records',
    filter: `company_id=eq.${company_id}`
  }, (payload) => {
    console.log('Attendance update:', payload)
    updateDashboard(payload)
  })
  .subscribe()

// 52시간 경고 알림
const warningChannel = supabase.channel('overtime-warning')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'weekly_work_hours',
    filter: 'total_hours.gte.48'
  }, (payload) => {
    if (payload.new.total_hours >= 48 && !payload.new.warning_sent) {
      sendOvertimeWarning(payload.new.employee_id)
    }
  })
  .subscribe()
```

## 3. 프론트엔드 (Next.js) 기능명세

### 3.1 프로젝트 구조
```
frontend/
├── app/
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   ├── signup/page.tsx
│   │   └── forgot-password/page.tsx
│   ├── (dashboard)/
│   │   ├── layout.tsx
│   │   ├── page.tsx (대시보드)
│   │   ├── attendance/
│   │   │   ├── page.tsx (출퇴근 관리)
│   │   │   └── clock/page.tsx (출퇴근 체크)
│   │   ├── schedule/
│   │   │   ├── page.tsx (일정 관리)
│   │   │   └── [id]/page.tsx
│   │   ├── leave/
│   │   │   ├── page.tsx (휴가 관리)
│   │   │   └── request/page.tsx
│   │   ├── employees/
│   │   │   ├── page.tsx (직원 관리)
│   │   │   └── [id]/page.tsx
│   │   └── reports/
│   │       └── page.tsx (리포트)
│   ├── api/
│   │   ├── auth/[...supabase]/route.ts
│   │   └── webhooks/
│   │       └── kakao/route.ts
│   └── layout.tsx
├── components/
│   ├── ui/ (shadcn/ui components)
│   ├── attendance/
│   │   ├── ClockInButton.tsx
│   │   ├── AttendanceCalendar.tsx
│   │   └── OvertimeAlert.tsx
│   ├── schedule/
│   │   ├── ScheduleCalendar.tsx
│   │   └── ShiftPatternSelector.tsx
│   └── dashboard/
│       ├── StatsCard.tsx
│       ├── RealtimeAttendance.tsx
│       └── WeeklyHoursChart.tsx
├── lib/
│   ├── supabase/
│   │   ├── client.ts
│   │   ├── server.ts
│   │   └── middleware.ts
│   ├── hooks/
│   │   ├── useAttendance.ts
│   │   ├── useRealtime.ts
│   │   └── use52HourCheck.ts
│   └── utils/
│       ├── date.ts
│       ├── validation.ts
│       └── korean-holidays.ts
└── types/
    └── database.types.ts
```

### 3.2 주요 페이지 및 컴포넌트

#### 3.2.1 출퇴근 체크 페이지
```typescript
// app/(dashboard)/attendance/clock/page.tsx
'use client'

import { useEffect, useState } from 'react'
import { useSupabase } from '@/lib/supabase/client'
import { useGeolocation } from '@/lib/hooks/useGeolocation'
import { ClockInButton } from '@/components/attendance/ClockInButton'
import { OvertimeAlert } from '@/components/attendance/OvertimeAlert'

export default function ClockPage() {
  const { location, error: geoError } = useGeolocation()
  const [weeklyHours, setWeeklyHours] = useState(0)
  const [isClocked, setIsClocked] = useState(false)
  
  // 52시간 체크
  useEffect(() => {
    checkWeeklyWorkHours()
  }, [])

  const handleClockIn = async () => {
    if (weeklyHours >= 52) {
      alert('주 52시간 초과로 출근할 수 없습니다')
      return
    }
    
    const response = await fetch('/api/attendance/clock-in', {
      method: 'POST',
      body: JSON.stringify({ location })
    })
    
    if (response.ok) {
      setIsClocked(true)
      // 실시간 업데이트
      broadcastClockIn()
    }
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center">
      {weeklyHours >= 48 && <OvertimeAlert hours={weeklyHours} />}
      
      <ClockInButton
        onClock={handleClockIn}
        disabled={!location || weeklyHours >= 52}
        isClocked={isClocked}
      />
      
      <div className="mt-8 text-center">
        <p>이번 주 근무시간: {weeklyHours}시간 / 52시간</p>
        <progress value={weeklyHours} max={52} />
      </div>
    </div>
  )
}
```

#### 3.2.2 실시간 대시보드
```typescript
// app/(dashboard)/page.tsx
import { Suspense } from 'react'
import { RealtimeAttendance } from '@/components/dashboard/RealtimeAttendance'
import { WeeklyHoursChart } from '@/components/dashboard/WeeklyHoursChart'
import { StatsCards } from '@/components/dashboard/StatsCards'

export default async function DashboardPage() {
  return (
    <div className="container mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6">대시보드</h1>
      
      {/* 실시간 통계 카드 */}
      <Suspense fallback={<div>Loading stats...</div>}>
        <StatsCards />
      </Suspense>
      
      {/* 실시간 출퇴근 현황 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
        <RealtimeAttendance />
        <WeeklyHoursChart />
      </div>
      
      {/* 52시간 위험 직원 목록 */}
      <OvertimeRiskEmployees />
    </div>
  )
}
```

### 3.3 Server Actions

```typescript
// app/actions/attendance.ts
'use server'

import { createServerClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function clockIn(location: Location) {
  const supabase = createServerClient()
  
  // 1. 현재 사용자 확인
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Unauthorized')
  
  // 2. 52시간 체크
  const { data: weeklyHours } = await supabase
    .from('weekly_work_hours')
    .select('total_hours')
    .eq('employee_id', user.id)
    .single()
  
  if (weeklyHours?.total_hours >= 52) {
    throw new Error('52시간 초과')
  }
  
  // 3. 출근 처리
  const { data, error } = await supabase.rpc('clock_in', {
    p_location: location,
    p_verification: 'gps'
  })
  
  if (error) throw error
  
  // 4. 페이지 재검증
  revalidatePath('/attendance')
  
  return data
}

export async function requestLeave(request: LeaveRequest) {
  const supabase = createServerClient()
  
  // 트랜잭션으로 처리
  const { data, error } = await supabase.rpc('request_leave_with_balance_check', {
    p_request: request
  })
  
  if (error) throw error
  
  // 승인자에게 알림 전송
  await sendApprovalNotification(data.approver_id)
  
  revalidatePath('/leave')
  return data
}
```

## 4. 모바일 앱 (React Native) 기능명세

### 4.1 프로젝트 구조
```
app/
├── app.json (Expo 설정)
├── src/
│   ├── screens/
│   │   ├── Auth/
│   │   │   ├── LoginScreen.tsx
│   │   │   └── BiometricSetup.tsx
│   │   ├── Home/
│   │   │   ├── HomeScreen.tsx
│   │   │   └── QuickActions.tsx
│   │   ├── Attendance/
│   │   │   ├── ClockScreen.tsx
│   │   │   └── AttendanceHistory.tsx
│   │   └── Leave/
│   │       └── LeaveRequestScreen.tsx
│   ├── components/
│   │   ├── ClockButton/
│   │   │   ├── index.tsx
│   │   │   └── styles.ts
│   │   └── PushNotification/
│   │       └── handler.ts
│   ├── navigation/
│   │   ├── AppNavigator.tsx
│   │   └── AuthNavigator.tsx
│   ├── services/
│   │   ├── supabase.ts
│   │   ├── biometric.ts
│   │   ├── location.ts
│   │   └── notification.ts
│   └── hooks/
│       ├── useAuth.ts
│       ├── useLocation.ts
│       └── usePushNotification.ts
├── android/ (Android 설정)
└── ios/ (iOS 설정)
```

### 4.2 주요 기능 구현

#### 4.2.1 생체인증 로그인
```typescript
// src/services/biometric.ts
import * as LocalAuthentication from 'expo-local-authentication'
import * as SecureStore from 'expo-secure-store'

export async function authenticateWithBiometric() {
  const hasHardware = await LocalAuthentication.hasHardwareAsync()
  if (!hasHardware) return false
  
  const result = await LocalAuthentication.authenticateAsync({
    promptMessage: 'ClockBox 로그인',
    cancelLabel: '취소',
    fallbackLabel: '비밀번호 사용'
  })
  
  if (result.success) {
    // 저장된 토큰으로 자동 로그인
    const token = await SecureStore.getItemAsync('auth_token')
    return await loginWithToken(token)
  }
  
  return false
}
```

#### 4.2.2 GPS 기반 출퇴근
```typescript
// src/screens/Attendance/ClockScreen.tsx
import { useState, useEffect } from 'react'
import * as Location from 'expo-location'
import { supabase } from '@/services/supabase'

export default function ClockScreen() {
  const [location, setLocation] = useState(null)
  const [isWithinRange, setIsWithinRange] = useState(false)
  
  useEffect(() => {
    getCurrentLocation()
  }, [])
  
  const getCurrentLocation = async () => {
    const { status } = await Location.requestForegroundPermissionsAsync()
    if (status !== 'granted') return
    
    const currentLocation = await Location.getCurrentPositionAsync({
      accuracy: Location.Accuracy.High
    })
    
    setLocation(currentLocation.coords)
    
    // 회사 위치와 거리 계산
    const distance = calculateDistance(
      currentLocation.coords,
      companyLocation
    )
    
    setIsWithinRange(distance <= 100) // 100m 이내
  }
  
  const handleClockIn = async () => {
    if (!isWithinRange) {
      Alert.alert('출근 불가', '회사 근처에서만 출근할 수 있습니다')
      return
    }
    
    const { data, error } = await supabase.rpc('mobile_clock_in', {
      location: {
        lat: location.latitude,
        lng: location.longitude
      }
    })
    
    if (error) {
      Alert.alert('오류', error.message)
    } else {
      // 성공 애니메이션
      showSuccessAnimation()
    }
  }
  
  return (
    <View style={styles.container}>
      <AnimatedClockButton
        onPress={handleClockIn}
        disabled={!isWithinRange}
      />
      
      {!isWithinRange && (
        <Text style={styles.warning}>
          회사에서 {distance}m 떨어져 있습니다
        </Text>
      )}
    </View>
  )
}
```

#### 4.2.3 푸시 알림
```typescript
// src/services/notification.ts
import * as Notifications from 'expo-notifications'

// 알림 설정
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true
  })
})

export async function registerForPushNotifications() {
  const { status } = await Notifications.requestPermissionsAsync()
  if (status !== 'granted') return
  
  const token = await Notifications.getExpoPushTokenAsync()
  
  // Supabase에 토큰 저장
  await supabase.from('push_tokens').upsert({
    user_id: userId,
    token: token.data,
    platform: Platform.OS
  })
  
  return token
}

// 알림 수신 처리
export function setupNotificationListeners() {
  // 알림 수신
  Notifications.addNotificationReceivedListener(notification => {
    console.log('Notification received:', notification)
  })
  
  // 알림 클릭
  Notifications.addNotificationResponseReceivedListener(response => {
    const { screen, params } = response.notification.request.content.data
    
    // 해당 화면으로 네비게이션
    navigation.navigate(screen, params)
  })
}
```

## 5. 인프라 및 배포

### 5.1 배포 아키텍처
```yaml
# 프로덕션 환경
production:
  frontend:
    platform: Vercel
    domain: clockbox.com
    regions: [icn1] # 서울 리전
    env:
      - NEXT_PUBLIC_SUPABASE_URL
      - NEXT_PUBLIC_SUPABASE_ANON_KEY
  
  backend:
    platform: Supabase Cloud (Pro Plan)
    database: PostgreSQL 14
    regions: [ap-northeast-2] # 서울
    features:
      - Point-in-time Recovery
      - Daily Backups
      - Read Replicas
      - Custom Domain
  
  mobile:
    ios:
      distribution: App Store
      testflight: true
    android:
      distribution: Google Play
      internal_testing: true
  
  monitoring:
    - Vercel Analytics
    - Supabase Dashboard
    - Sentry (Error Tracking)
    - LogRocket (Session Replay)
```

### 5.2 CI/CD Pipeline
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: |
          npm test
          npm run test:e2e
  
  deploy-frontend:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Vercel
        run: vercel deploy --prod
  
  deploy-supabase:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy Migrations
        run: supabase db push
      - name: Deploy Functions
        run: supabase functions deploy
  
  deploy-mobile:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Build and Submit to Stores
        run: |
          eas build --platform all
          eas submit --platform all
```

### 5.3 보안 설정

#### 5.3.1 환경 변수 관리
```typescript
// .env.production
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx # Server-side only
KAKAO_API_KEY=xxx
GOOGLE_MAPS_API_KEY=xxx
SENTRY_DSN=xxx
```

#### 5.3.2 보안 헤더 설정
```typescript
// next.config.js
module.exports = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY'
          },
          {
            key: 'Content-Security-Policy',
            value: "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline' *.supabase.co"
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff'
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin'
          }
        ]
      }
    ]
  }
}
```

## 6. 외부 서비스 연동

### 6.1 카카오톡 알림톡
```typescript
// supabase/functions/send-kakao-notification/index.ts
import { serve } from "https://deno.land/std/http/server.ts"

const KAKAO_API_URL = 'https://kapi.kakao.com/v2/api/talk/memo/default/send'

serve(async (req) => {
  const { user_id, template_id, variables } = await req.json()
  
  // 카카오톡 알림톡 전송
  const response = await fetch(KAKAO_API_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${KAKAO_API_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      template_id,
      template_args: JSON.stringify(variables)
    })
  })
  
  return new Response(JSON.stringify(await response.json()))
})
```

### 6.2 ERP 연동 (더존)
```typescript
// supabase/functions/sync-douzone/index.ts
serve(async (req) => {
  const { sync_type, company_id } = await req.json()
  
  if (sync_type === 'payroll') {
    // 1. ClockBox에서 근태 데이터 조회
    const attendance = await getMonthlyAttendance(company_id)
    
    // 2. 더존 형식으로 변환
    const douzoneFormat = convertToDouzone(attendance)
    
    // 3. Excel 파일 생성
    const excelBuffer = await generateExcel(douzoneFormat)
    
    // 4. S3에 업로드
    const url = await uploadToS3(excelBuffer)
    
    // 5. 더존 API 호출 또는 다운로드 링크 제공
    return new Response(JSON.stringify({ 
      download_url: url,
      message: '더존 급여 데이터가 생성되었습니다'
    }))
  }
})
```

## 7. 성능 최적화

### 7.1 데이터베이스 최적화
```sql
-- 인덱스 생성
CREATE INDEX idx_attendance_employee_date 
  ON attendance_records(employee_id, DATE(clock_in));

CREATE INDEX idx_weekly_hours_employee_week 
  ON weekly_work_hours(employee_id, week_start);

-- Materialized View for 대시보드
CREATE MATERIALIZED VIEW dashboard_stats AS
SELECT 
  company_id,
  DATE(clock_in) as date,
  COUNT(DISTINCT employee_id) as total_employees,
  COUNT(CASE WHEN status = 'late' THEN 1 END) as late_count,
  AVG(work_hours) as avg_work_hours
FROM attendance_records
GROUP BY company_id, DATE(clock_in);

-- 자동 새로고침
CREATE OR REPLACE FUNCTION refresh_dashboard_stats()
RETURNS trigger AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY dashboard_stats;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

### 7.2 Next.js 최적화
```typescript
// 정적 생성 + ISR
export async function generateStaticParams() {
  const companies = await getCompanies()
  return companies.map(company => ({
    id: company.id
  }))
}

export const revalidate = 3600 // 1시간마다 재생성

// React Query로 캐싱
const { data, error } = useQuery({
  queryKey: ['attendance', date],
  queryFn: fetchAttendance,
  staleTime: 5 * 60 * 1000, // 5분
  cacheTime: 10 * 60 * 1000 // 10분
})
```

## 8. 모니터링 및 로깅

### 8.1 에러 트래킹 (Sentry)
```typescript
// lib/sentry.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  integrations: [
    new Sentry.BrowserTracing(),
    new Sentry.Replay()
  ],
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0.1
})

// 커스텀 에러 로깅
export function logError(error: Error, context?: any) {
  Sentry.captureException(error, {
    contexts: {
      custom: context
    }
  })
}
```

### 8.2 사용자 행동 분석
```typescript
// Analytics 이벤트
export function trackEvent(event: string, properties?: any) {
  // Vercel Analytics
  if (typeof window !== 'undefined' && window.va) {
    window.va('event', { name: event, ...properties })
  }
  
  // Google Analytics
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('event', event, properties)
  }
}

// 사용 예시
trackEvent('clock_in', {
  method: 'gps',
  location: 'office',
  time: new Date()
})
```

## 9. 테스트 전략

### 9.1 단위 테스트
```typescript
// __tests__/attendance.test.ts
import { calculateWeeklyHours, check52HourLimit } from '@/lib/attendance'

describe('52시간 근무제 체크', () => {
  test('52시간 초과 시 차단', () => {
    const hours = 53
    expect(check52HourLimit(hours)).toBe(false)
  })
  
  test('48시간 이상 시 경고', () => {
    const hours = 49
    const result = check52HourLimit(hours)
    expect(result.warning).toBe(true)
  })
})
```

### 9.2 E2E 테스트
```typescript
// e2e/clock-in.spec.ts
import { test, expect } from '@playwright/test'

test('출퇴근 플로우', async ({ page }) => {
  // 로그인
  await page.goto('/login')
  await page.fill('[name=email]', 'test@example.com')
  await page.fill('[name=password]', 'password')
  await page.click('button[type=submit]')
  
  // 출근 체크
  await page.goto('/attendance/clock')
  await page.click('#clock-in-button')
  
  // 성공 확인
  await expect(page.locator('.success-message')).toBeVisible()
})
```

## 10. 마이그레이션 및 버전 관리

### 10.1 데이터베이스 마이그레이션
```bash
# Supabase Migration
supabase migration new add_52hour_monitoring
supabase db push
supabase db reset # 개발환경

# 프로덕션 배포
supabase db push --db-url $PRODUCTION_DB_URL
```

### 10.2 버전 관리 전략
```json
// package.json
{
  "version": "1.0.0",
  "releases": {
    "1.0.0": "MVP - 기본 출퇴근, 휴가",
    "1.1.0": "52시간 근무제 모니터링",
    "1.2.0": "카카오톡 연동",
    "2.0.0": "ERP 연동 및 급여 정산"
  }
}
```

이 기능명세서는 ClockBox 시스템의 전체 기술 구현을 정의하며, Supabase, Next.js, React Native를 활용한 현대적인 아키텍처로 한국 노동법 준수와 사용자 경험을 모두 만족시키는 솔루션입니다.