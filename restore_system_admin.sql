-- 서프마인드 회사 ID 확인
SELECT id, name FROM companies WHERE name LIKE '%서프마인드%' OR name LIKE '%SurfMind%';

-- system@clockbox.dev 계정 복구 (서프마인드 회사 ID를 적절히 변경)
INSERT INTO employees (
  id,
  profile_id, 
  full_name,
  email,
  user_role,
  company_id,
  status,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  '41d856c2-5983-4f64-a43d-0e40f0542782'::uuid,
  '시스템 관리자',
  'system@clockbox.dev',
  'super_admin',
  (SELECT id FROM companies WHERE name LIKE '%서프마인드%' OR name LIKE '%SurfMind%' LIMIT 1),
  'active',
  now(),
  now()
);

-- 복구 확인
SELECT id, profile_id, full_name, email, user_role, company_id, status 
FROM employees 
WHERE email = 'system@clockbox.dev';