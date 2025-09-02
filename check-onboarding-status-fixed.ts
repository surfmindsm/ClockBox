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
    const authHeader = req.headers.get('authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Missing or invalid authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    
    // Create Supabase clients
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: { headers: { Authorization: `Bearer ${token}` } }
      }
    )

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // Get current user
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token or user not found' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('Checking onboarding status for user:', user.id)

    // Check if user has employee record with company
    // Handle multiple records by taking the most recent one
    const { data: employees, error: employeeError } = await supabaseAdmin
      .from('employees')
      .select(`
        id,
        user_role,
        company_id,
        companies (
          id,
          name,
          onboarding_completed,
          industry,
          created_at
        )
      `)
      .eq('profile_id', user.id)
      .order('updated_at', { ascending: false })
      .limit(1)

    if (employeeError) {
      console.error('Employee fetch error:', employeeError)
      throw employeeError
    }

    // Get the first (most recent) employee record
    const employee = employees && employees.length > 0 ? employees[0] : null

    // If no employee record, user needs onboarding
    if (!employee || !employee.company_id) {
      return new Response(
        JSON.stringify({
          needsOnboarding: true,
          reason: 'no_company',
          message: 'User has no company association'
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if company onboarding is completed
    const company = employee.companies
    if (!company || !company.onboarding_completed) {
      return new Response(
        JSON.stringify({
          needsOnboarding: true,
          reason: 'incomplete_onboarding',
          message: 'Company onboarding not completed',
          company: company ? {
            id: company.id,
            name: company.name,
            industry: company.industry,
            created_at: company.created_at
          } : null
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if user is system_admin (first user should be system admin)
    if (!['system_admin', 'super_admin'].includes(employee.user_role)) {
      // For first time setup, promote first user to system_admin
      const { error: updateError } = await supabaseAdmin
        .from('employees')
        .update({ 
          user_role: 'system_admin',
          updated_at: new Date().toISOString() 
        })
        .eq('id', employee.id)
      
      if (updateError) {
        console.error('Failed to promote user to system_admin:', updateError)
      } else {
        console.log('✅ Promoted user to system_admin:', user.id)
        // Update employee object for response
        employee.user_role = 'system_admin'
      }
    }

    // Onboarding is complete
    return new Response(
      JSON.stringify({
        needsOnboarding: false,
        company: {
          id: company.id,
          name: company.name,
          industry: company.industry,
          created_at: company.created_at
        },
        employee: {
          id: employee.id,
          role: employee.user_role
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Check onboarding status error:', error)
    return new Response(
      JSON.stringify({
        error: error.message,
        message: 'Failed to check onboarding status'
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})