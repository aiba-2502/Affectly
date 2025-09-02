'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';

export default function MyPage() {
  const { user, isLoading, checkAuth } = useAuth();
  const router = useRouter();
  
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (!isLoading && !user) {
      router.push('/login');
    } else if (user) {
      setName(user.name || '');
      setEmail(user.email || '');
    }
  }, [user, isLoading, router]);

  const handleSave = async () => {
    setMessage('');
    setError('');
    setIsSaving(true);

    // パスワード変更の場合、確認
    if (newPassword && newPassword !== confirmPassword) {
      setError('新しいパスワードが一致しません');
      setIsSaving(false);
      return;
    }

    try {
      const token = localStorage.getItem('token');
      const updateData: any = {
        name,
        email,
      };

      // パスワード変更が必要な場合
      if (currentPassword && newPassword) {
        updateData.current_password = currentPassword;
        updateData.password = newPassword;
      }

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'}/api/v1/users/me`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(updateData),
      });

      if (response.ok) {
        const data = await response.json();
        localStorage.setItem('user', JSON.stringify(data.user));
        await checkAuth();
        setMessage('プロフィールを更新しました');
        setIsEditing(false);
        setCurrentPassword('');
        setNewPassword('');
        setConfirmPassword('');
      } else {
        const errorData = await response.json();
        setError(errorData.error || 'プロフィールの更新に失敗しました');
      }
    } catch {
      setError('サーバーに接続できませんでした');
    } finally {
      setIsSaving(false);
    }
  };

  const handleCancel = () => {
    if (user) {
      setName(user.name || '');
      setEmail(user.email || '');
    }
    setCurrentPassword('');
    setNewPassword('');
    setConfirmPassword('');
    setIsEditing(false);
    setMessage('');
    setError('');
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl">Loading...</div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-2xl mx-auto px-4">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex justify-between items-center mb-6">
            <h1 className="text-2xl font-bold text-gray-900">マイページ</h1>
            {!isEditing && (
              <button
                onClick={() => setIsEditing(true)}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
              >
                編集
              </button>
            )}
          </div>

          {message && (
            <div className="mb-4 p-3 bg-green-100 text-green-700 rounded">
              {message}
            </div>
          )}

          {error && (
            <div className="mb-4 p-3 bg-red-100 text-red-700 rounded">
              {error}
            </div>
          )}

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                ユーザー名
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                disabled={!isEditing}
                className={`w-full px-3 py-2 text-black border rounded-md ${
                  isEditing 
                    ? 'border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500' 
                    : 'bg-gray-100 border-gray-200'
                }`}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                メールアドレス
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={!isEditing}
                className={`w-full px-3 py-2 text-black border rounded-md ${
                  isEditing 
                    ? 'border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500' 
                    : 'bg-gray-100 border-gray-200'
                }`}
              />
            </div>

            {isEditing && (
              <>
                <div className="border-t pt-4 mt-6">
                  <h3 className="text-lg font-medium text-gray-900 mb-4">
                    パスワード変更（任意）
                  </h3>
                  
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        現在のパスワード
                      </label>
                      <input
                        type="password"
                        value={currentPassword}
                        onChange={(e) => setCurrentPassword(e.target.value)}
                        className="w-full px-3 py-2 text-black border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="パスワードを変更する場合のみ入力"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        新しいパスワード
                      </label>
                      <input
                        type="password"
                        value={newPassword}
                        onChange={(e) => setNewPassword(e.target.value)}
                        className="w-full px-3 py-2 text-black border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="6文字以上"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        新しいパスワード（確認）
                      </label>
                      <input
                        type="password"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        className="w-full px-3 py-2 text-black border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="もう一度入力"
                      />
                    </div>
                  </div>
                </div>

                <div className="flex justify-end space-x-3 pt-4">
                  <button
                    onClick={handleCancel}
                    disabled={isSaving}
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded hover:bg-gray-50 disabled:opacity-50"
                  >
                    キャンセル
                  </button>
                  <button
                    onClick={handleSave}
                    disabled={isSaving}
                    className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
                  >
                    {isSaving ? '保存中...' : '保存'}
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}