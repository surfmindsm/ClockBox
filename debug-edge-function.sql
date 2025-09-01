-- Edge Function 직접 테스트용 SQL
-- 이것은 Edge Function이 데이터베이스에서 실제로 어떤 데이터를 가져오는지 확인하는 쿼리입니다

-- Edge Function과 동일한 쿼리 실행
SELECT 
    'Edge Function 쿼리 시뮬레이션' as test_type,
    e.user_role,
    e.company_id,
    e.department,
    e.position,
    e.profile_id,
    e.status,
    p.email
FROM employees e
LEFT JOIN profiles p ON e.profile_id = p.id
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
ORDER BY e.updated_at DESC;

-- 혹시 여러 레코드가 있는지 확인
SELECT 
    'employees 테이블 전체 확인' as test_type,
    COUNT(*) as total_count,
    e.user_role,
    e.status
FROM employees e
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
GROUP BY e.user_role, e.status;