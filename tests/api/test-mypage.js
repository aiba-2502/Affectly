// マイページ機能のテスト

async function testMyPageFeatures() {
  console.log('=== Testing MyPage Features ===\n');
  
  const testUser = {
    email: `test${Date.now()}@example.com`,
    password: 'password123',
    name: 'Initial Name'
  };
  
  // 1. ユーザー作成とログイン
  console.log('1. Creating test user...');
  const signupResponse = await fetch('http://localhost:3000/api/v1/auth/signup', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(testUser)
  });
  
  if (!signupResponse.ok) {
    console.error('Failed to create user');
    return;
  }
  
  const signupData = await signupResponse.json();
  const token = signupData.token;
  console.log('✅ User created with token');
  
  // 2. ユーザー情報取得
  console.log('\n2. Getting user info...');
  const getUserResponse = await fetch('http://localhost:3000/api/v1/users/me', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  const userData = await getUserResponse.json();
  console.log('User info:', userData);
  
  // 3. ユーザー情報更新（名前とメール）
  console.log('\n3. Updating user profile...');
  const updateResponse = await fetch('http://localhost:3000/api/v1/users/me', {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      name: 'Updated Name',
      email: testUser.email // メールは同じ
    })
  });
  
  if (updateResponse.ok) {
    const updateData = await updateResponse.json();
    console.log('✅ Profile updated:', updateData.user);
  } else {
    const errorData = await updateResponse.json();
    console.log('❌ Update failed:', errorData);
  }
  
  // 4. パスワード変更テスト
  console.log('\n4. Testing password change...');
  const passwordUpdateResponse = await fetch('http://localhost:3000/api/v1/users/me', {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      name: 'Updated Name',
      email: testUser.email,
      current_password: testUser.password,
      password: 'newPassword123'
    })
  });
  
  if (passwordUpdateResponse.ok) {
    console.log('✅ Password changed successfully');
    
    // 新しいパスワードでログインテスト
    const newLoginResponse = await fetch('http://localhost:3000/api/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: testUser.email,
        password: 'newPassword123'
      })
    });
    
    if (newLoginResponse.ok) {
      console.log('✅ Login with new password successful');
    } else {
      console.log('❌ Login with new password failed');
    }
  } else {
    const errorData = await passwordUpdateResponse.json();
    console.log('❌ Password change failed:', errorData);
  }
  
  console.log('\n=== MyPage Features Test Complete ===');
}

testMyPageFeatures().catch(console.error);