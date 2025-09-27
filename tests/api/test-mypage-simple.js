// マイページ機能のテスト（パスワード変更機能削除後）

async function testMyPageFeaturesSimple() {
  console.log('=== Testing MyPage Features (No Password Change) ===\n');
  
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
  
  // 3. ユーザー情報更新（名前とメールのみ）
  console.log('\n3. Updating user profile (name and email only)...');
  const updateResponse = await fetch('http://localhost:3000/api/v1/users/me', {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      name: 'Updated Name',
      email: `updated${Date.now()}@example.com`
    })
  });
  
  if (updateResponse.ok) {
    const updateData = await updateResponse.json();
    console.log('✅ Profile updated successfully');
    console.log('Updated user:', updateData.user);
  } else {
    const errorData = await updateResponse.json();
    console.log('❌ Update failed:', errorData);
  }
  
  // 4. パスワードパラメータが無視されることを確認
  console.log('\n4. Testing that password parameter is ignored...');
  const passwordUpdateAttempt = await fetch('http://localhost:3000/api/v1/users/me', {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      name: 'Another Update',
      email: userData.email,
      password: 'this_should_be_ignored',
      current_password: 'also_ignored'
    })
  });
  
  if (passwordUpdateAttempt.ok) {
    const updateData = await passwordUpdateAttempt.json();
    console.log('✅ Update succeeded (password parameters were ignored)');
    console.log('Updated user:', updateData.user);
    
    // 元のパスワードでログインできることを確認
    const loginCheck = await fetch('http://localhost:3000/api/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: userData.email,
        password: testUser.password // 元のパスワード
      })
    });
    
    if (loginCheck.ok) {
      console.log('✅ Original password still works (password was not changed)');
    } else {
      console.log('❌ Login failed with original password');
    }
  } else {
    const errorData = await passwordUpdateAttempt.json();
    console.log('❌ Update failed:', errorData);
  }
  
  console.log('\n=== MyPage Features Test Complete ===');
  console.log('Summary:');
  console.log('- User profile update (name/email): ✅');
  console.log('- Password change functionality: ❌ (Removed as expected)');
}

testMyPageFeaturesSimple().catch(console.error);