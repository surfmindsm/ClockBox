import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
}

interface CompanyData {
  name: string
  business_number?: string
  industry?: string
  subscription_plan?: 'basic' | 'standard' | 'enterprise'
  settings?: {
    address?: string
    phone?: string
    email?: string
    website?: string
    description?: string
    admin_name?: string
    admin_email?: string
  }
}

interface Database {
  public: {
    Tables: {
      companies: {
        Row: {
          id: string
          name: string
          business_number: string | null
          industry: string | null
          subscription_plan: string
          settings: any
          created_at: string
          created_by: string | null
          updated_at: string
        }
        Insert: {
          name: string
          business_number?: string
          industry?: string
          subscription_plan?: string
          settings?: any
          created_by?: string
        }
        Update: {
          name?: string
          business_number?: string
          industry?: string
          subscription_plan?: string
          settings?: any
        }
      }
    }
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient<Database>(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // JWT 토큰에서 사용자 정보 추출
    const authHeader = req.headers.get('authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log('User authenticated:', user.id, user.email)

    // 사용자 권한 확인 - 직접 employees 테이블 조회 (중복 레코드 처리)
    const { data: employees, error: roleError } = await supabaseClient
      .from('employees')
      .select('user_role')
      .eq('profile_id', user.id)
      .order('updated_at', { ascending: false })
      .limit(1)

    console.log('User role check:', { userId: user.id, employees, roleError })

    if (roleError) {
      console.error('Error getting user role:', roleError)
      return new Response(
        JSON.stringify({ error: 'Failed to check user permissions', details: roleError.message }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const userRole = employees && employees.length > 0 ? employees[0].user_role : null

    // Accept both system_admin and super_admin (for backward compatibility)
    if (!userRole || !['system_admin', 'super_admin'].includes(userRole)) {
      console.log('Access denied. Required: system_admin or super_admin, Got:', userRole)
      return new Response(
        JSON.stringify({ error: 'Insufficient permissions. System admin required.', userRole }),
        { 
          status: 403, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log('Permission check passed for user:', user.id, 'role:', userRole)

    const method = req.method
    const url = new URL(req.url)

    if (method === 'GET') {
      // 회사 목록 조회 또는 특정 회사 조회
      const companyId = url.searchParams.get('id')
      
      if (companyId) {
        // 특정 회사 조회 - 단순화된 쿼리
        const { data: company, error } = await supabaseClient
          .from('companies')
          .select('*')
          .eq('id', companyId)
          .single()

        if (error) {
          console.error('Error fetching company:', error)
          return new Response(
            JSON.stringify({ error: 'Failed to fetch company' }),
            { 
              status: 500, 
              headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
            }
          )
        }

        // 직원 수와 조직 수를 별도로 조회
        const { count: employeeCount } = await supabaseClient
          .from('employees')
          .select('*', { count: 'exact', head: true })
          .eq('company_id', companyId)

        const { count: organizationCount } = await supabaseClient
          .from('organizations')
          .select('*', { count: 'exact', head: true })
          .eq('company_id', companyId)
          .then(result => result)
          .catch(() => ({ count: 0 })) // organizations 테이블이 없을 수 있음

        return new Response(
          JSON.stringify({ 
            success: true, 
            data: {
              ...company,
              employee_count: employeeCount || 0,
              organization_count: organizationCount || 0
            }
          }),
          { 
            status: 200, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      } else {
        // 전체 회사 목록 조회 - 단순화된 쿼리
        const { data: companies, error } = await supabaseClient
          .from('companies')
          .select('*')
          .order('created_at', { ascending: false })

        if (error) {
          console.error('Error fetching companies:', error)
          return new Response(
            JSON.stringify({ error: 'Failed to fetch companies' }),
            { 
              status: 500, 
              headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
            }
          )
        }

        // 각 회사의 직원 수를 별도로 조회
        const companiesWithCounts = await Promise.all(
          companies.map(async (company) => {
            const { count: employeeCount } = await supabaseClient
              .from('employees')
              .select('*', { count: 'exact', head: true })
              .eq('company_id', company.id)

            const { count: organizationCount } = await supabaseClient
              .from('organizations')
              .select('*', { count: 'exact', head: true })
              .eq('company_id', company.id)
              .then(result => result)
              .catch(() => ({ count: 0 }))

            return {
              ...company,
              employee_count: employeeCount || 0,
              organization_count: organizationCount || 0
            }
          })
        )

        return new Response(
          JSON.stringify({ 
            success: true, 
            data: companiesWithCounts,
            total: companiesWithCounts.length
          }),
          { 
            status: 200, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }
    }

    if (method === 'POST') {
      // 새 회사 생성
      const body = await req.json()
      const companyData: CompanyData = body

      // 필수 필드 검증
      if (!companyData.name || companyData.name.trim() === '') {
        return new Response(
          JSON.stringify({ error: 'Company name is required' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // 사업자등록번호 중복 체크
      if (companyData.business_number) {
        const { data: existingCompany } = await supabaseClient
          .from('companies')
          .select('id')
          .eq('business_number', companyData.business_number)
          .single()

        if (existingCompany) {
          return new Response(
            JSON.stringify({ error: 'Business number already exists' }),
            { 
              status: 409, 
              headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
            }
          )
        }
      }

      const { data: newCompany, error } = await supabaseClient
        .from('companies')
        .insert({
          name: companyData.name.trim(),
          business_number: companyData.business_number || null,
          industry: companyData.industry || null,
          subscription_plan: companyData.subscription_plan || 'basic',
          settings: companyData.settings || {},
          created_by: user.id
        })
        .select()
        .single()

      if (error) {
        console.error('Error creating company:', error)
        return new Response(
          JSON.stringify({ error: 'Failed to create company' }),
          { 
            status: 500, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // 감사 로그 기록 (audit_logs 테이블이 있는 경우만)
      try {
        await supabaseClient
          .from('audit_logs')
          .insert({
            user_id: user.id,
            action: 'CREATE',
            entity_type: 'company',
            entity_id: newCompany.id,
            new_values: newCompany
          })
      } catch (auditError) {
        console.warn('Audit log failed:', auditError)
      }

      console.log('Company created successfully:', newCompany.id, newCompany.name)

      return new Response(
        JSON.stringify({ 
          success: true, 
          data: newCompany,
          message: 'Company created successfully'
        }),
        { 
          status: 201, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (method === 'PUT') {
      // 회사 정보 수정
      const body = await req.json()
      const companyId = url.searchParams.get('id')

      if (!companyId) {
        return new Response(
          JSON.stringify({ error: 'Company ID is required' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // 기존 회사 정보 조회
      const { data: existingCompany, error: fetchError } = await supabaseClient
        .from('companies')
        .select('*')
        .eq('id', companyId)
        .single()

      if (fetchError || !existingCompany) {
        return new Response(
          JSON.stringify({ error: 'Company not found' }),
          { 
            status: 404, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      const updateData: any = {}
      
      if (body.name !== undefined) updateData.name = body.name.trim()
      if (body.business_number !== undefined) updateData.business_number = body.business_number || null
      if (body.industry !== undefined) updateData.industry = body.industry || null
      if (body.subscription_plan !== undefined) updateData.subscription_plan = body.subscription_plan
      if (body.settings !== undefined) updateData.settings = { ...existingCompany.settings, ...body.settings }

      // 사업자등록번호 중복 체크 (자신 제외)
      if (updateData.business_number && updateData.business_number !== existingCompany.business_number) {
        const { data: duplicateCompany } = await supabaseClient
          .from('companies')
          .select('id')
          .eq('business_number', updateData.business_number)
          .neq('id', companyId)
          .single()

        if (duplicateCompany) {
          return new Response(
            JSON.stringify({ error: 'Business number already exists' }),
            { 
              status: 409, 
              headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
            }
          )
        }
      }

      const { data: updatedCompany, error: updateError } = await supabaseClient
        .from('companies')
        .update(updateData)
        .eq('id', companyId)
        .select()
        .single()

      if (updateError) {
        console.error('Error updating company:', updateError)
        return new Response(
          JSON.stringify({ error: 'Failed to update company' }),
          { 
            status: 500, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // 감사 로그 기록 (audit_logs 테이블이 있는 경우만)
      try {
        await supabaseClient
          .from('audit_logs')
          .insert({
            user_id: user.id,
            action: 'UPDATE',
            entity_type: 'company',
            entity_id: companyId,
            old_values: existingCompany,
            new_values: updatedCompany
          })
      } catch (auditError) {
        console.warn('Audit log failed:', auditError)
      }

      console.log('Company updated successfully:', companyId)

      return new Response(
        JSON.stringify({ 
          success: true, 
          data: updatedCompany,
          message: 'Company updated successfully'
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (method === 'DELETE') {
      // 회사 삭제 (소프트 삭제 또는 하드 삭제)
      const companyId = url.searchParams.get('id')
      const force = url.searchParams.get('force') === 'true'

      if (!companyId) {
        return new Response(
          JSON.stringify({ error: 'Company ID is required' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // 회사 존재 확인
      const { data: company, error: fetchError } = await supabaseClient
        .from('companies')
        .select('*')
        .eq('id', companyId)
        .single()

      if (fetchError || !company) {
        return new Response(
          JSON.stringify({ error: 'Company not found' }),
          { 
            status: 404, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // 관련 데이터 확인
      const { data: employees } = await supabaseClient
        .from('employees')
        .select('id')
        .eq('company_id', companyId)

      if (employees && employees.length > 0 && !force) {
        return new Response(
          JSON.stringify({ 
            error: 'Cannot delete company with employees', 
            message: `Company has ${employees.length} employees. Use force=true to delete anyway.`,
            employee_count: employees.length
          }),
          { 
            status: 409, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // 회사 삭제 (CASCADE로 관련 데이터도 함께 삭제됨)
      const { error: deleteError } = await supabaseClient
        .from('companies')
        .delete()
        .eq('id', companyId)

      if (deleteError) {
        console.error('Error deleting company:', deleteError)
        return new Response(
          JSON.stringify({ error: 'Failed to delete company' }),
          { 
            status: 500, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // 감사 로그 기록 (audit_logs 테이블이 있는 경우만)
      try {
        await supabaseClient
          .from('audit_logs')
          .insert({
            user_id: user.id,
            action: 'DELETE',
            entity_type: 'company',
            entity_id: companyId,
            old_values: company
          })
      } catch (auditError) {
        console.warn('Audit log failed:', auditError)
      }

      console.log('Company deleted successfully:', companyId)

      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Company deleted successfully'
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 지원하지 않는 메서드
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { 
        status: 405, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})