'use client';

import { useAuth } from '@/contexts/AuthContextOptimized';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import BottomNav from '@/components/BottomNav';
import { HistoryList } from '@/components/History/HistoryList';
import dynamic from 'next/dynamic';
import { PlusIcon } from '@heroicons/react/24/outline';
import { useChatStore } from '@/stores/chatStore';

// Live2Dコンポーネントを動的インポート（SSR無効化）
const Live2DComponent = dynamic(() => import('@/components/Live2DComponent'), {
  ssr: false,
  loading: () => (
    <div className="fixed top-4 right-4 bg-gray-100 text-gray-700 px-4 py-2 rounded-lg shadow">
      Live2Dを準備中...
    </div>
  ),
});

export default function HistoryPage() {
  const { user, isLoading } = useAuth();
  const router = useRouter();
  const { newSession } = useChatStore();
  const [showLive2D, setShowLive2D] = useState(false);

  useEffect(() => {
    if (!isLoading && !user) {
      router.push('/login');
    }
  }, [user, isLoading, router]);

  useEffect(() => {
    // Live2Dを遅延ロード
    if (user) {
      const timer = setTimeout(() => {
        setShowLive2D(true);
      }, 500);
      return () => clearTimeout(timer);
    }
  }, [user]);

  const handleNewChat = () => {
    newSession();
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
    <div className="flex flex-col min-h-screen bg-gray-50">
      {/* Live2D Character - 背景として表示 */}
      {showLive2D && <Live2DComponent />}
      
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-4 py-3 relative z-20">
        <div className="max-w-4xl mx-auto flex justify-between items-center">
          <h1 className="text-lg font-semibold text-gray-900">チャット履歴</h1>
          <button
            onClick={handleNewChat}
            className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors flex items-center gap-2"
            title="新しいチャット"
          >
            <PlusIcon className="w-5 h-5" />
            <span className="text-sm">新規チャット</span>
          </button>
        </div>
      </div>

      {/* History List Container */}
      <div className="flex-1 overflow-y-auto pb-24 relative z-10">
        <div className="max-w-4xl mx-auto p-4">
          <HistoryList />
        </div>
      </div>

      <BottomNav />
    </div>
  );
}