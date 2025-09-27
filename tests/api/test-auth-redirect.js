// 認証なしでアクセスした場合のテスト
async function testNoAuth() {
  console.log('Testing access without authentication...');
  
  const response = await fetch('http://localhost:3002');
  console.log('Status:', response.status);
  console.log('URL:', response.url);
  
  const text = await response.text();
  
  // リダイレクトされているか確認
  if (text.includes('/login') || response.url.includes('/login')) {
    console.log('✅ Redirected to login page as expected');
  } else if (text.includes('Loading')) {
    console.log('⏳ Shows loading state');
  } else {
    console.log('❌ Not redirected to login page');
    console.log('Response preview:', text.substring(0, 500));
  }
}

testNoAuth().catch(console.error);