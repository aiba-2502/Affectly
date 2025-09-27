// Complete authentication flow test

async function testAuthFlow() {
  console.log('=== Testing Authentication Flow ===\n');
  
  // 1. Test accessing home without auth (should redirect)
  console.log('1. Testing home page without authentication...');
  const homeResponse = await fetch('http://localhost:3002');
  const homeText = await homeResponse.text();
  
  if (homeText.includes('Loading')) {
    console.log('✅ Shows loading state (client-side will redirect)');
  }
  
  // 2. Test login endpoint
  console.log('\n2. Testing login endpoint...');
  try {
    const loginResponse = await fetch('http://localhost:3000/api/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'password123'
      })
    });
    
    console.log('Login response status:', loginResponse.status);
    const loginData = await loginResponse.json();
    console.log('Login response:', JSON.stringify(loginData, null, 2));
    
    if (loginResponse.status === 401) {
      console.log('⚠️ User not found (expected for new setup)');
    }
  } catch (error) {
    console.error('Login error:', error.message);
  }
  
  // 3. Test signup endpoint
  console.log('\n3. Testing signup endpoint...');
  try {
    const signupResponse = await fetch('http://localhost:3000/api/v1/auth/signup', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User'
      })
    });
    
    console.log('Signup response status:', signupResponse.status);
    const signupData = await signupResponse.json();
    console.log('Signup response:', JSON.stringify(signupData, null, 2));
    
    if (signupResponse.ok && signupData.token) {
      console.log('✅ Signup successful, token received');
      
      // 4. Test /me endpoint with token
      console.log('\n4. Testing /me endpoint with token...');
      const meResponse = await fetch('http://localhost:3000/api/v1/auth/me', {
        headers: {
          'Authorization': `Bearer ${signupData.token}`
        }
      });
      
      console.log('Me response status:', meResponse.status);
      const meData = await meResponse.json();
      console.log('Me response:', JSON.stringify(meData, null, 2));
      
      if (meResponse.ok) {
        console.log('✅ Authentication working correctly');
      }
    }
  } catch (error) {
    console.error('Signup error:', error.message);
  }
  
  console.log('\n=== Test Complete ===');
}

testAuthFlow().catch(console.error);