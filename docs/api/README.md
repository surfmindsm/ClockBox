# ClockBox API Documentation

ClockBox는 한국 시장을 위한 포괄적인 근태 관리 시스템입니다.

## 🚀 Quick Start

### 1. API Base URL
```
Production:  https://apmgoboqnodhroqvetjx.supabase.co/functions/v1
Development: http://localhost:54321/functions/v1
```

### 2. Authentication
모든 API 요청은 Bearer 토큰 인증이 필요합니다.

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     https://apmgoboqnodhroqvetjx.supabase.co/functions/v1/clock-in
```

### 3. Rate Limiting
- API 엔드포인트: IP당 분당 1000회
- 인증 엔드포인트: IP당 분당 10회

## 📋 API Documentation

### Interactive Documentation
- **Swagger UI**: [API Explorer](./openapi.yml)
- **Postman Collection**: Coming soon

### Core Endpoints

#### 출퇴근 관리 (Attendance)
- `POST /clock-in` - 출근 처리 + 52시간 근무제 확인
- `POST /clock-out` - 퇴근 처리 + 근무시간 계산
- `POST /validate-location` - 근무지 위치 검증

#### 52시간 근무제 준수 (Compliance)
- `POST /calculate-weekly-hours` - 주간 근무시간 계산
- 자동 경고: 48시간, 50시간, 52시간 차단

#### 휴가 관리 (Leave Management)  
- `POST /approve-leave` - 휴가 승인/반려
- 한국 법정 휴가 지원: 출산휴가(100일), 배우자출산휴가(20일), 육아휴직(18개월)

#### 메시징 연동 (Messaging)
- `POST /send-kakao-notification` - 카카오톡 비즈니스 메시지
- 26개 메시지 템플릿 지원

#### ERP 연동 (ERP Integration)
- `POST /sync-douzone` - 더존 SmartA 연동
- `POST /sync-sap` - SAP Korea HCM 연동
- `POST /sync-younglimwon` - 영림원 K-System 연동

#### 보고서 (Reporting)
- `POST /generate-report` - 종합 보고서 생성
- 지원 형식: PDF, Excel, JSON

## 🇰🇷 한국 노동법 준수

### 52시간 근무제
```json
{
  "weekly_hours": 45.5,
  "status": "warning",
  "compliance": {
    "within_limit": true,
    "hours_remaining": 6.5,
    "next_warning_at": 48
  }
}
```

### 근무 상태 분류
- `normal`: 48시간 미만 (정상)
- `warning`: 48-50시간 (경고)
- `critical`: 50-52시간 (위험)
- `blocked`: 52시간 초과 (차단)

### 한국 법정 휴가 유형
```json
{
  "leave_types": {
    "annual": "연차",
    "sick": "병가", 
    "maternity": "출산휴가 (100일)",
    "paternity": "배우자출산휴가 (20일)",
    "childcare": "육아휴직 (18개월)"
  }
}
```

## 📍 위치 기반 출퇴근

### GPS 검증
```json
{
  "location": {
    "lat": 37.5665,
    "lng": 126.9780,
    "accuracy": 5
  },
  "validation": {
    "valid": true,
    "matched_site": "본사",
    "distance": 12.5
  }
}
```

### WiFi 검증
```json
{
  "wifi_info": {
    "ssid": "CompanyWiFi",
    "bssid": "aa:bb:cc:dd:ee:ff"
  }
}
```

## 🔔 알림 시스템

### 카카오톡 비즈니스 메시지
26개 템플릿 지원:
- 출퇴근 확인
- 52시간 경고 (48h, 50h, 52h)
- 휴가 승인/반려
- 급여명세서 알림

### 메시지 예시
```json
{
  "recipient_id": "user-uuid",
  "template_name": "overtime_warning_48h",
  "data": {
    "employee_name": "김철수",
    "current_hours": 48.5,
    "remaining_hours": 3.5
  }
}
```

## 🔗 ERP 시스템 연동

### 더존 SmartA
- Excel 파일 형식으로 데이터 변환
- 급여/근태 데이터 자동 동기화
- 한국 급여체계 완벽 매핑

### SAP Korea HCM
- 전용 미들웨어를 통한 연동
- 실시간 데이터 동기화
- 대기업 환경 최적화

### 영림원 K-System
- MES 시스템 통합 지원
- 제조업 특화 기능
- 3교대 근무 패턴 지원

## 📊 보고서 생성

### 지원 보고서 유형
```json
{
  "report_types": [
    "attendance",    // 근태 보고서
    "leave",         // 휴가 보고서  
    "overtime",      // 초과근무 보고서
    "payroll",       // 급여 보고서
    "compliance"     // 법규준수 보고서
  ]
}
```

### 한국어 형식 지원
- 날짜: 2024년 8월 28일
- 시간: 09시 00분
- 금액: 1,234,567원
- 기간: 2024.08.01 ~ 2024.08.31

## 🔒 보안 및 개인정보보호

### 보안 기능
- JWT 기반 인증
- Rate Limiting
- IP 기반 접근 제한
- 요청 로깅 및 감사

### 개인정보보호법 준수
- 데이터 암호화 (전송/저장)
- 접근 권한 관리 (RBAC)
- 감사 로그 3년 보관
- 자동 데이터 삭제

## 📱 멀티플랫폼 지원

### 웹 (Next.js)
- 반응형 디자인
- PWA 지원
- 오프라인 모드

### 모바일 (React Native)
- iOS/Android 네이티브
- 생체 인증 (Face ID/Touch ID)
- 푸시 알림
- GPS 자동 출퇴근

## 🛠️ 개발자 도구

### SDK 및 라이브러리
```bash
# JavaScript/TypeScript
npm install @clockbox/api-client

# React Native
npm install @clockbox/react-native
```

### 테스트 환경
```bash
# Local development
supabase start
npm run dev

# Test endpoints
npm run test:api
```

## 📞 지원 및 문의

### 기술 지원
- 📧 Email: support@clockbox.app
- 📝 GitHub Issues: [Issues](https://github.com/surfmindsm/clockbox/issues)
- 📖 문서: [Documentation](../README.md)

### 비즈니스 문의
- 📞 전화: +82-2-XXXX-XXXX
- 📧 Email: business@clockbox.app
- 🌐 웹사이트: https://clockbox.app

## 📄 라이선스

ClockBox API는 Proprietary License 하에 제공됩니다.

---

*마지막 업데이트: 2025-08-28*