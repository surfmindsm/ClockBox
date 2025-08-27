# clockbox - 통합 근태·인력관리 시스템 PRD (Main Document)

## 1. 제품 개요
### 1.1 제품명
clockbox (출·근태 관리 솔루션)

### 1.2 제품 비전
기업의 모든 근무형태와 인사 운영방식을 지원하는 **통합 근태·인력관리 플랫폼**.  
효율성과 법규 준수, 직관적 사용자 경험을 결합해 **건강한 근무 문화**와 **생산성 향상**을 동시에 실현한다.

### 1.3 제품 미션
- 근태 기록의 **정확성과 투명성** 확보  
- 다양한 근무제도(주 52시간제, 유연·교대근무, 재택 등) 완벽 지원  
- **직원·관리자 모두 간편한 접근성과 사용성** 제공  
- **국내외 법규 및 개인정보 보호** 기준을 철저히 준수  

---

## 2. 타겟 사용자
- **Primary**: HR 담당자, 관리자, 사업장 책임자  
- **Secondary**: 일반 직원 (정규직, 계약직, 파트타임, 재택근무자 등)  
- **기업 규모**: 스타트업부터 대기업까지  

---

## 3. 핵심 기능 영역 (메뉴 기반)

### 3.1 시작하기
- 관리자/직원 시작 가이드  
- 회원가입, 회사 생성, 직장 합류  
- 관리자 모드 ↔ 직원 모드 전환  
- FAQ  

### 3.2 계정
- 계정 설정 (비밀번호/이메일/언어 변경, 탈퇴 등)  
- 앱/웹 버전 관리  
- 계정 FAQ  

### 3.3 조직/지점
- 관리 단위 변경  
- 출퇴근 장소 등록(좌표/WiFi)  
- 지점 추가/설정, 본조직 지정  
- 조직/지점 FAQ  

### 3.4 직무
- 직무 생성 및 편집 (직무명, 설명, 필수 자격요건)
- 직급별 권한 매트릭스 설정
- 직무별 근무시간 및 출퇴근 정책 연결
- 직무 변경 이력 관리  

### 3.5 직원
- 직원 등록/수정/탈퇴 (기본정보, 소속, 직무배정)
- 권한 부여, 근로규칙(소정/최대) 설정  
- 합류코드 전송, 기기 초기화  
- 직원 비활성화/삭제  
- 검색 및 필터 (이름, 부서, 직무별)
- 직원 프로필 관리 (사진, 연락처, 입사일)
- 직원 FAQ  

### 3.6 근무일정
- 근무일정 유형/템플릿 관리 (정규, 교대, 유연, 재택)  
- 근무일정 추가/수정/삭제  
- 휴게시간, 외근지, 간주근로 설정  
- 반복 스케줄 패턴 설정 (주간/월간 단위)
- 근무일정 확정/조회 및 직원별 배정
- 엑셀 업로드/다운로드  
- 일정 변경 승인 워크플로우
- 다양한 근무제 운영(연장, 대체, 재택)  

### 3.7 출퇴근기록
- 출퇴근 기록 (GPS, WiFi, QR코드 인증)
- 무일정 근무 기록 및 승인 요청
- 휴게시간 자동/수동 기록
- 근무상황 실시간 조회 및 모니터링
- 누락 기록 보정 요청 및 승인 처리
- 지각/조퇴/결근 자동 분류 및 알림
- 대리출근 방지 및 위치 검증
- 엑셀 업로드/다운로드  
- 출퇴근 FAQ  

### 3.8 휴가
- 휴가 그룹/유형 관리 (연차, 병가, 경조, 보상)
- 근속연수별 휴가 자동 발생 규칙 설정
- 보상휴가 자동 적립 (초과근무, 휴일근무)
- 휴가 신청·승인 프로세스 (다단계 승인)
- 휴가 잔액 실시간 조회 및 관리
- 휴가 사용 패턴 분석 및 리포트
- 법정 의무 휴가 준수 관리
- 휴가 데이터 다운로드  
- 휴가 FAQ  

### 3.9 요청
- 승인권한 및 규칙 설정 (단계별, 자동승인 조건)
- 근무일정 변경 요청 (시간, 지점, 유형 수정)
- 출퇴근 기록 보정 요청 (누락, 오기록 수정)
- 휴가 신청 및 승인 처리
- 기기 변경, 근무지 외 출퇴근 요청  
- 커스텀 요청 유형 (증명서 발급, 비용처리, 기타)
- 요청 상태 추적 및 이력 관리
- 요청 FAQ  

### 3.10 리포트
- 기본 리포트 항목 (출근률, 근무시간, 휴가사용률)
- 실시간 대시보드 (부서별, 직원별 현황)
- 리포트 스케줄링 및 자동 생성
- 사용자 정의 리포트 설정
- 데이터 필터링 및 그룹화 기능
- 엑셀/PDF 다운로드 및 인쇄
- 리포트 공유 및 배포 기능  

### 3.11 마감 및 정산
- 월별/일별 근무시간 마감 처리
- 급여정산 데이터 생성 및 검증
- 연장근무/야간근무/휴일근무 수당 계산
- 주휴수당 자동 계산
- 최저임금 준수 검증
- 근로자의 날 등 법정공휴일 처리
- 급여명세서 생성 및 배포
- ERP/회계 시스템 연동  

### 3.12 메시지
- 메시지 발송, 자동화 규칙 설정  
- 공지사항, 근태 알림, 미승인 요청 알림  
- 조직 관리자 대상 안내, 급여명세서  
- 메시지 FAQ  

### 3.13 전자계약
- 계약서 템플릿 관리 (근로계약서, 변경계약서 등)
- 계약서 작성 및 전송 기능
- 전자서명 및 인증 처리
- 계약 상태 추적 및 이력 관리
- 법정 문서 자동 생성 (연차휴가 촉진서 등)
- 계약 FAQ  

### 3.14 회사 설정
- 회사 프로필 및 기본 설정  
- 알림, 권한, 조직/지점/직원/근무일정 관리  
- 출퇴근기록, 휴게시간, 휴가, 스케줄, 요청, 메시지, 전자계약, 리포트, 급여, 보안 등 세부 설정  
- 고급 옵션, 결제/연동, 지원 관리  
- 카카오워크 연동, 회사방침 마크다운 사용  

---

## 4. 기술 아키텍처 및 개발 요구사항

### 4.1 기술 스택
**프론트엔드:**
- Web: React.js + TypeScript, Tailwind CSS
- Mobile: React Native (iOS/Android)
- State Management: Redux Toolkit

**백엔드:**
- API: Node.js + Express.js + TypeScript
- Database: PostgreSQL (주DB) + Redis (캐시)
- Authentication: JWT + refresh token
- File Storage: AWS S3

**인프라:**
- Cloud: AWS (EC2, RDS, S3, CloudFront)
- Container: Docker + Docker Compose
- CI/CD: GitHub Actions
- Monitoring: CloudWatch + DataDog

### 4.2 보안 요구사항
- **인증**: JWT 기반 토큰 인증 + 2FA 옵션
- **데이터 암호화**: AES-256 (저장), TLS 1.3 (전송)
- **접근 제어**: RBAC (Role-Based Access Control)
- **개인정보**: GDPR/개인정보보호법 준수, 데이터 마스킹
- **로그 관리**: 모든 사용자 활동 로그 기록 및 감사

### 4.3 플랫폼 지원
- **웹브라우저**: Chrome, Firefox, Safari, Edge (최신 2버전)
- **모바일**: iOS 14+, Android 8.0+ (API 26+)
- **반응형**: 모바일 우선 설계 (Mobile-First)

### 4.4 성능 요구사항
- **응답시간**: API 응답 < 500ms, 페이지 로딩 < 3초
- **동시접속**: 1,000명 동시 사용자 지원
- **가용성**: 99.9% 업타임 보장
- **확장성**: 수평 확장 가능한 마이크로서비스 구조

### 4.5 외부 연동
- **ERP 연동**: REST API 기반 실시간 데이터 동기화
- **캘린더**: Google Calendar, Outlook 연동
- **메신저**: Slack, Microsoft Teams 봇
- **지도**: Google Maps API (위치 인증)
- **알림**: Firebase FCM (푸시), SendGrid (이메일)  

---

## 5. 비즈니스 모델
- **Basic Plan**: 근태/출퇴근/휴가 관리  
- **Standard Plan**: 근무일정, 요청, 리포트, 메시지 포함  
- **Enterprise Plan**: 고급 보안, 전자계약, 대규모/다국어 지원  
- **부가 서비스**: 연동 패키지, 커스텀 개발  

---

## 6. 데이터베이스 설계 (개요)

### 6.1 핵심 엔티티
```sql
-- 회사 정보
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    business_number VARCHAR(50),
    industry VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 (통합 계정)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 조직/지점
CREATE TABLE organizations (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id),
    parent_id INTEGER REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50), -- 'headquarters', 'branch', 'department'
    gps_lat DECIMAL(10,8),
    gps_lng DECIMAL(11,8),
    wifi_ssid VARCHAR(100)
);

-- 직무
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    permissions JSONB,
    work_hours INTEGER DEFAULT 8
);

-- 직원
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    company_id INTEGER REFERENCES companies(id),
    organization_id INTEGER REFERENCES organizations(id),
    role_id INTEGER REFERENCES roles(id),
    employee_number VARCHAR(50),
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'active'
);

-- 근무일정
CREATE TABLE schedules (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_minutes INTEGER DEFAULT 0,
    work_type VARCHAR(50), -- 'regular', 'overtime', 'remote'
    status VARCHAR(20) DEFAULT 'confirmed'
);

-- 출퇴근 기록
CREATE TABLE attendance_records (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    schedule_id INTEGER REFERENCES schedules(id),
    clock_in TIMESTAMP,
    clock_out TIMESTAMP,
    break_start TIMESTAMP,
    break_end TIMESTAMP,
    location_verified BOOLEAN DEFAULT false,
    work_hours DECIMAL(4,2),
    overtime_hours DECIMAL(4,2) DEFAULT 0,
    status VARCHAR(20) -- 'normal', 'late', 'early_leave', 'absent'
);

-- 휴가 관리
CREATE TABLE leave_types (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id),
    name VARCHAR(100) NOT NULL,
    days_per_year INTEGER,
    is_paid BOOLEAN DEFAULT true
);

CREATE TABLE leave_balances (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    leave_type_id INTEGER REFERENCES leave_types(id),
    year INTEGER NOT NULL,
    total_days DECIMAL(3,1),
    used_days DECIMAL(3,1) DEFAULT 0,
    remaining_days DECIMAL(3,1)
);

CREATE TABLE leave_requests (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    leave_type_id INTEGER REFERENCES leave_types(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days_requested DECIMAL(3,1),
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    approved_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 6.2 인덱스 전략
```sql
-- 성능 최적화를 위한 주요 인덱스
CREATE INDEX idx_employees_company ON employees(company_id);
CREATE INDEX idx_attendance_employee_date ON attendance_records(employee_id, DATE(clock_in));
CREATE INDEX idx_schedules_employee_date ON schedules(employee_id, date);
CREATE INDEX idx_leave_requests_employee ON leave_requests(employee_id, status);
```

## 7. API 설계 (개요)

### 7.1 인증 API
```
POST /api/auth/login
POST /api/auth/logout
POST /api/auth/refresh
POST /api/auth/forgot-password
```

### 7.2 직원 관리 API
```
GET    /api/employees          # 직원 목록 조회
POST   /api/employees          # 신규 직원 등록
GET    /api/employees/{id}     # 특정 직원 상세 조회
PUT    /api/employees/{id}     # 직원 정보 수정
DELETE /api/employees/{id}     # 직원 삭제
```

### 7.3 출퇴근 API
```
POST   /api/attendance/clock-in    # 출근 기록
POST   /api/attendance/clock-out   # 퇴근 기록
GET    /api/attendance/status      # 현재 근무 상태
GET    /api/attendance/history     # 출퇴근 이력
POST   /api/attendance/correction  # 출퇴근 보정 요청
```

### 7.4 휴가 API
```
GET    /api/leave/balance         # 휴가 잔액 조회
POST   /api/leave/request         # 휴가 신청
GET    /api/leave/requests        # 휴가 신청 목록
PUT    /api/leave/requests/{id}   # 휴가 승인/반려
```

### 7.5 리포트 API
```
GET    /api/reports/attendance    # 출근 통계
GET    /api/reports/overtime      # 초과근무 통계
GET    /api/reports/leave         # 휴가 사용 현황
```

## 8. 화면 구성 및 사용자 플로우

### 8.1 주요 화면 구성
1. **로그인/회원가입**: 이메일 기반 인증
2. **대시보드**: 개인/관리자별 맞춤 정보
3. **출퇴근**: 원터치 체크인/아웃
4. **일정 관리**: 캘린더 형태의 스케줄 관리
5. **휴가 신청**: 직관적인 휴가 신청 폼
6. **승인 관리**: 대기중인 승인 건 관리
7. **리포트**: 그래프 기반 통계 대시보드
8. **설정**: 개인/회사 설정 관리

### 8.2 반응형 설계
- **모바일**: 터치 친화적 UI, 스와이프 제스처
- **태블릿**: 분할 화면, 확장된 정보 표시
- **데스크톱**: 다중 패널, 키보드 단축키

## 9. 성공 지표 (KPI)

### 9.1 기술적 지표
- API 응답시간 < 500ms
- 앱 크래시율 < 0.1%
- 출퇴근 기록 성공률 > 99.5%
- 시스템 가용성 > 99.9%

### 9.2 비즈니스 지표  
- MAU (Monthly Active Users)
- 고객 유지율 > 90% (연간)
- ARPU (Average Revenue Per User)
- NPS (Net Promoter Score) > 50
- 사용자 만족도 > 4.5/5  

---

## 10. 개발 단계별 로드맵

### 10.1 Phase 1: 핵심 기능 (3개월)
- 사용자 인증 시스템
- 기본 출퇴근 기록
- 직원 관리
- 간단한 리포트

### 10.2 Phase 2: 확장 기능 (3개월)  
- 근무일정 관리
- 휴가 신청/승인
- 요청 워크플로우
- 모바일 앱

### 10.3 Phase 3: 고급 기능 (3개월)
- 전자계약
- 급여정산 연동
- 고급 리포트
- 외부 시스템 연동

## 11. 문서 관리 원칙
- 본 문서는 **clockbox 메인 PRD**이며, 개발의 기준이 된다.
- 각 기능별 세부 사항은 별도 PRD 문서로 작성한다.
- 모든 팀(기획/디자인/개발/운영)은 이 문서를 공통 기준으로 사용한다.
- 기술 변경사항은 별도 기술문서에서 관리한다.  
