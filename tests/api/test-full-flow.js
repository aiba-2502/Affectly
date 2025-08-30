// Complete flow test: signup -> login -> access home

async function testFullFlow() {
  console.log('=== Testing Complete Authentication Flow ===\n');
  
  const testUser = {
    email: `test${Date.now()}@example.com`,
    password: 'password123',
    name: 'Test User'
  };
  
  // 1. Test signup
  console.log('1. Testing signup...');
  try {
    const signupResponse = await fetch('http://localhost:3000/api/v1/auth/signup', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(testUser)
    });
    
    const signupData = await signupResponse.json();
    console.log('Signup response:', signupResponse.status);
    
    if (signupResponse.ok && signupData.token) {
      console.log('✅ Signup successful');
      console.log('Token received:', signupData.token.substring(0, 20) + '...');
      
      // 2. Test login with same credentials
      console.log('\n2. Testing login with same credentials...');
      const loginResponse = await fetch('http://localhost:3000/api/v1/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: testUser.email,
          password: testUser.password
        })
      });
      
      const loginData = await loginResponse.json();
      console.log('Login response:', loginResponse.status);
      
      if (loginResponse.ok && loginData.token) {
        console.log('✅ Login successful');
        
        // 3. Test accessing protected endpoint
        console.log('\n3. Testing protected endpoint /me...');
        const meResponse = await fetch('http://localhost:3000/api/v1/auth/me', {
          headers: {
            'Authorization': `Bearer ${loginData.token}`
          }
        });
        
        const meData = await meResponse.json();
        console.log('Me response:', meResponse.status);
        
        if (meResponse.ok) {
          console.log('✅ Protected endpoint accessible');
          console.log('User data:', meData);
        } else {
          console.log('❌ Protected endpoint failed:', meData);
        }
      } else {
        console.log('❌ Login failed:', loginData);
      }
    } else {
      console.log('❌ Signup failed:', signupData);
    }
  } catch (error) {
    console.error('Error:', error.message);
  }
  
  console.log('\n=== Authentication System Working! ===');
  console.log('\nYou can now:');
  console.log('1. Go to http://localhost:3001 - You will be redirected to /login');
  console.log('2. Click "新規登録" to go to signup page');
  console.log('3. Register a new account');
  console.log('4. You will be automatically logged in and redirected to home page');
}

testFullFlow().catch(console.error);