-- system@clockbox.dev 사용자를 super_admin으로 승격
UPDATE employees 
SET user_role = 'super_admin'
WHERE email = 'system@clockbox.dev';

-- 확인
SELECT id, email, full_name, user_role, company_id, organization_id 
FROM employees 
WHERE email = 'system@clockbox.dev';