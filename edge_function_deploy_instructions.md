# Edge Function 배포 가이드

## 🚀 get-user-role 함수 배포 필요

수정된 Edge Function을 배포해야 시스템 관리자 로그인 문제가 완전히 해결됩니다.

## 배포 방법

### 방법 1: Supabase CLI 사용

```bash
# 프로젝트 디렉토리로 이동
cd /Users/admin/Desktop/workspace/clockbox/backend

# Supabase 로그인 (토큰 필요)
supabase login

# 함수 배포
supabase functions deploy get-user-role --project-ref zqkcuezwtpymnagqmrjk
```

### 방법 2: Supabase Dashboard 사용 (권장)

1. [Supabase Dashboard](https://supabase.com/dashboard) 접속
2. ClockBox 프로젝트 선택
3. 좌측 메뉴에서 **Edge Functions** 클릭
4. **get-user-role** 함수 선택
5. **Deploy** 버튼 클릭
6. 로컬 파일에서 업데이트된 코드 복사/붙여넣기

### 방법 3: 인증 토큰 설정 후 CLI 사용

```bash
# 환경변수로 토큰 설정
export SUPABASE_ACCESS_TOKEN="your-access-token"

# 또는 직접 토큰과 함께 로그인
supabase login --token your-access-token

# 배포
supabase functions deploy get-user-role --project-ref zqkcuezwtpymnagqmrjk
```

## 📝 수정된 내용 요약

이전 Edge Function 문제:
- `.single()` 사용 시 중복 레코드로 인한 에러 발생
- 에러 핸들러에서 기본값 'employee' 반환

현재 수정된 내용:
- `.limit(1)` + `.order('updated_at', { ascending: false })` 사용
- 가장 최근 레코드를 안전하게 가져옴
- 배열 처리 로직 추가

## ✅ 배포 후 확인사항

1. 브라우저에서 완전히 로그아웃
2. `system@clockbox.dev`로 재로그인  
3. 시스템 관리자 대시보드 화면 확인
4. 브라우저 콘솔에서 역할이 `system_admin`으로 나오는지 확인

## 🔧 문제 발생 시

배포 후에도 문제가 지속되면:
1. 브라우저 캐시 완전 삭제
2. 시크릿/프라이빗 브라우저 모드에서 테스트
3. Edge Function 로그 확인 (Supabase Dashboard > Edge Functions > Logs)

---

**중요**: 데이터베이스 수정은 이미 완료되었으므로, Edge Function 배포만 하면 모든 문제가 해결됩니다.