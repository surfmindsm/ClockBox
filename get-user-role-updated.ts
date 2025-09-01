import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get authorization header
    const authHeader = req.headers.get('authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Missing or invalid authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    
    // Create Supabase client with user token
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: {
            Authorization: `Bearer ${token}`
          }
        }
      }
    )

    // Create admin client to bypass RLS
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Get current user
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token or user not found' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('Getting user role for:', user.id, user.email)

    // Use service role to bypass RLS and get employee data
    const { data: employee, error: employeeError } = await supabaseAdmin
      .from('employees')
      .select('user_role, company_id, department, position')
      .eq('profile_id', user.id)
      .single()

    if (employeeError) {
      console.error('Employee fetch error:', employeeError)
      // Default to employee role if no record found
      return new Response(
        JSON.stringify({
          user_id: user.id,
          email: user.email,
          user_role: 'employee',
          mapped_role: 'employee',
          company_id: null,
          department: null,
          position: null,
          source: 'default'
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 역할 이름을 그대로 사용 (매핑 없이)
    let mappedRole = employee.user_role

    console.log('✅ User role retrieved:', {
      user_id: user.id,
      email: user.email,
      db_role: employee.user_role,
      mapped_role: mappedRole
    })

    return new Response(
      JSON.stringify({
        user_id: user.id,
        email: user.email,
        user_role: employee.user_role,
        mapped_role: mappedRole,
        company_id: employee.company_id,
        department: employee.department,
        position: employee.position,
        source: 'database'
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Get user role error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        message: 'Failed to get user role'
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})