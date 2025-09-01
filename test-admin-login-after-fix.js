// Test system admin login after RLS fix
const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = 'https://apmgoboqnodhroqvetjx.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFwbWdvYm9xbm9kaHJvcXZldGp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzNzk3ODYsImV4cCI6MjA3MTk1NTc4Nn0.ZBVePeC3wDsTQLckCb8yLA7EEdhKjN-zUva9qJzAm4I'

const supabase = createClient(supabaseUrl, supabaseAnonKey)

async function testSystemAdminLogin() {
  try {
    console.log('🧪 Testing system admin login after RLS fix...')
    
    // Login as system admin
    console.log('1. Logging in as system@clockbox.dev...')
    const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
      email: 'system@clockbox.dev',
      password: 'System123!'
    })
    
    if (loginError) {
      console.error('❌ Login failed:', loginError.message)
      return
    }
    
    console.log('✅ Login successful!')
    
    // Get user info
    console.log('2. Getting user info...')
    const { data: { user } } = await supabase.auth.getUser()
    console.log('📋 User:', {
      id: user.id,
      email: user.email
    })
    
    // Test employee data fetch - this should work now
    console.log('3. Fetching employee data (testing RLS fix)...')
    const { data: employee, error: employeeError } = await supabase
      .from('employees')
      .select('user_role, company_id, department, position')
      .eq('profile_id', user.id)
      .single()
    
    if (employeeError) {
      console.error('❌ RLS Error (should be fixed):', employeeError)
      return
    }
    
    console.log('✅ Employee data retrieved successfully!')
    console.log('📋 Employee:', employee)
    
    // Role mapping test
    const roleMapping = {
      'admin': 'system_admin',
      'manager': 'company_admin', 
      'employee': 'employee',
      'system_admin': 'system_admin'
    }
    
    const mappedRole = roleMapping[employee.user_role] || 'employee'
    console.log(`🔄 Role mapping: ${employee.user_role} -> ${mappedRole}`)
    
    if (mappedRole === 'system_admin') {
      console.log('🎉 SUCCESS: System admin login and role detection working!')
      console.log('✅ RLS infinite recursion fixed!')
      console.log('✅ System admin should now see system admin screens')
    } else {
      console.log('⚠️  WARNING: Role mapping issue - expected system_admin')
    }
    
    // Sign out
    await supabase.auth.signOut()
    console.log('👋 Signed out')
    
  } catch (error) {
    console.error('❌ Test failed:', error.message)
  }
}

testSystemAdminLogin()