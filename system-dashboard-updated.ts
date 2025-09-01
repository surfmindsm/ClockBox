import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { 
      status: 200, 
      headers: corsHeaders 
    })
  }

  try {
    const supabaseClient = createClient(
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

    // 사용자 권한 확인 (시스템 관리자인지 체크)
    const { data: employee, error: employeeError } = await supabaseClient
      .from('employees')
      .select('user_role')
      .eq('profile_id', user.id)
      .single()

    if (employeeError || !employee) {
      return new Response(
        JSON.stringify({ error: 'User not found in employees table' }),
        { 
          status: 403, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Accept system admin roles (system_admin and super_admin are equivalent)
    if (!['system_admin', 'super_admin'].includes(employee.user_role)) {
      return new Response(
        JSON.stringify({ error: 'Insufficient permissions. System admin required.' }),
        { 
          status: 403, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 시스템 통계 조회 (임시로 간단한 데이터 제공)
    const stats = [{
      total_companies: 1,
      total_employees: 1,
      active_users: 1,
      total_attendance_today: 0
    }]

    // 최근 활동 조회 (임시 데이터)
    const recentActivities = [
      {
        id: '1',
        action: '시스템 로그인',
        entity_type: 'auth',
        users: { email: user.email },
        created_at: new Date().toISOString()
      }
    ]

    // 회사 목록 조회 (임시 데이터)
    const companies = [
      {
        id: 'c1111111-1111-1111-1111-111111111111',
        name: 'ClockBox 시스템 관리',
        subscription_plan: 'enterprise',
        created_at: new Date().toISOString(),
        _count: [{ count: 1 }]
      }
    ]

    // 응답 데이터 구성
    const dashboardData = {
      stats: stats?.[0] || {
        total_companies: 0,
        total_employees: 0,
        active_users: 0,
        total_attendance_today: 0
      },
      recent_activities: (recentActivities || []).map(activity => ({
        id: activity.id,
        action: activity.action,
        entity_type: activity.entity_type,
        user_email: activity.users?.email || 'Unknown',
        created_at: activity.created_at
      })),
      companies: (companies || []).map(company => ({
        id: company.id,
        name: company.name,
        employee_count: company._count?.[0]?.count || 0,
        subscription_plan: company.subscription_plan,
        created_at: company.created_at
      }))
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: dashboardData
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('System dashboard error:', error)
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