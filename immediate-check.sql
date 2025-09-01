-- 즉시 상태 확인
SELECT 
    '=== 현재 실제 상태 ===' as check_type,
    e.id,
    e.user_role,
    e.status,
    e.updated_at,
    urc.user_role as cache_role
FROM employees e
LEFT JOIN user_roles_cache urc ON e.profile_id = urc.user_id
WHERE e.profile_id = '41d856c2-5983-4f64-a43d-0e40f0542782'
ORDER BY e.updated_at DESC;