-- ====================================
-- Fix Duplicate Employee Records
-- ====================================
-- 중복된 employee 레코드를 정리하고 하나만 남김

-- 1. 현재 중복 상태 확인
SELECT 
    '=== 중복 레코드 확인 ===' as check_type,
    e.id,
    e.profile_id,
    e.user_role,
    e.employee_number,
    e.status,
    e.created_at,
    e.updated_at,
    p.email
FROM employees e
LEFT JOIN profiles p ON e.profile_id = p.id
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
ORDER BY e.created_at;

-- 2. 더 완전한 레코드 확인 (employee_number가 있는 것을 우선)
SELECT 
    '=== 유지할 레코드 (SA001) ===' as action_type,
    e.id,
    e.profile_id,
    e.user_role,
    e.employee_number,
    e.status,
    e.department,
    e.position,
    e.can_approve_leaves,
    e.can_approve_overtime
FROM employees e
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
  AND e.employee_number = 'SA001';

-- 3. 중복 레코드 삭제 (employee_number가 null인 것)
DELETE FROM employees 
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
  AND employee_number IS NULL;

-- 4. 남은 레코드가 올바르게 설정되어 있는지 확인 및 업데이트
UPDATE employees 
SET 
    user_role = 'system_admin',
    status = 'active',
    can_approve_leaves = TRUE,
    can_approve_overtime = TRUE,
    updated_at = NOW()
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
  AND employee_number = 'SA001';

-- 5. user_roles_cache도 업데이트
INSERT INTO user_roles_cache (user_id, company_id, user_role, updated_at)
SELECT 
    e.profile_id,
    e.company_id,
    'system_admin',
    NOW()
FROM employees e
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
  AND e.employee_number = 'SA001'
ON CONFLICT (user_id) 
DO UPDATE SET
    user_role = 'system_admin',
    company_id = EXCLUDED.company_id,
    updated_at = NOW();

-- 6. 최종 확인
SELECT 
    '=== 최종 결과 확인 ===' as check_type,
    e.id,
    e.profile_id,
    e.user_role,
    e.employee_number,
    e.status,
    e.can_approve_leaves,
    e.can_approve_overtime,
    urc.user_role as cache_role,
    p.email
FROM employees e
LEFT JOIN profiles p ON e.profile_id = p.id
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- 7. 중복 레코드가 모두 제거되었는지 확인
SELECT 
    '=== 중복 체크 ===' as check_type,
    COUNT(*) as record_count,
    'Should be 1' as expected
FROM employees 
WHERE profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782';

-- Success message
SELECT 
    '🎉 중복 레코드 정리 완료!' as message,
    'system@clockbox.dev 사용자의 중복 레코드가 제거되었습니다' as details;