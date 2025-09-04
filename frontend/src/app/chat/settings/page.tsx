'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useChatStore } from '@/stores/chatStore';
import { ArrowLeftIcon } from '@heroicons/react/24/outline';

export default function ChatSettingsPage() {
  const { user, isLoading } = useAuth();
  const router = useRouter();
  const { settings, updateSettings } = useChatStore();
  const [localSettings, setLocalSettings] = useState(settings);

  useEffect(() => {
    if (!isLoading && !user) {
      router.push('/login');
    }
  }, [user, isLoading, router]);

  const handleSave = () => {
    updateSettings(localSettings);
    router.push('/chat');
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
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm px-4 py-3 flex items-center">
        <button
          onClick={() => router.push('/chat')}
          className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors mr-3"
        >
          <ArrowLeftIcon className="w-5 h-5" />
        </button>
        <h1 className="text-xl font-bold text-gray-800">チャット設定</h1>
      </div>

      {/* Settings Form */}
      <div className="p-4 max-w-2xl mx-auto">
        <div className="bg-white rounded-lg shadow p-6 space-y-6">
          
          {/* Model Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              AIモデル
            </label>
            <select
              value={localSettings.model}
              onChange={(e) => setLocalSettings({ ...localSettings, model: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="gpt-4o-mini">GPT-4o Mini (高速・低コスト)</option>
              <option value="gpt-4o">GPT-4o (高性能)</option>
              <option value="gpt-4-turbo">GPT-4 Turbo</option>
              <option value="gpt-3.5-turbo">GPT-3.5 Turbo</option>
            </select>
          </div>

          {/* Temperature */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              応答のランダム性 (Temperature): {localSettings.temperature}
            </label>
            <input
              type="range"
              min="0"
              max="2"
              step="0.1"
              value={localSettings.temperature}
              onChange={(e) => setLocalSettings({ ...localSettings, temperature: parseFloat(e.target.value) })}
              className="w-full"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>正確</span>
              <span>バランス</span>
              <span>創造的</span>
            </div>
          </div>

          {/* Max Tokens */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              最大トークン数
            </label>
            <input
              type="number"
              value={localSettings.max_tokens}
              onChange={(e) => setLocalSettings({ ...localSettings, max_tokens: parseInt(e.target.value) })}
              min="100"
              max="4000"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <p className="text-xs text-gray-500 mt-1">応答の最大長を制限します（100-4000）</p>
          </div>

          {/* System Prompt */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              システムプロンプト（オプション）
            </label>
            <textarea
              value={localSettings.system_prompt}
              onChange={(e) => setLocalSettings({ ...localSettings, system_prompt: e.target.value })}
              rows={4}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="AIアシスタントの振る舞いをカスタマイズできます..."
            />
          </div>

          {/* API Key */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              APIキー（オプション）
            </label>
            <input
              type="password"
              value={localSettings.api_key || ''}
              onChange={(e) => setLocalSettings({ ...localSettings, api_key: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="独自のAPIキーを使用する場合"
            />
            <p className="text-xs text-gray-500 mt-1">空欄の場合はデフォルトのAPIキーが使用されます</p>
          </div>

          {/* Save Button */}
          <div className="flex justify-end gap-3">
            <button
              onClick={() => router.push('/chat')}
              className="px-4 py-2 text-gray-700 bg-gray-200 hover:bg-gray-300 rounded-lg transition-colors"
            >
              キャンセル
            </button>
            <button
              onClick={handleSave}
              className="px-4 py-2 bg-blue-500 text-white hover:bg-blue-600 rounded-lg transition-colors"
            >
              保存
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}