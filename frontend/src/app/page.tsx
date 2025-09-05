'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContextOptimized';
import dynamic from 'next/dynamic';
import BottomNav from '@/components/BottomNav';

// Live2Dコンポーネントを動的インポート（SSR無効化 + ローディング表示）
const Live2DComponent = dynamic(() => import('@/components/Live2DComponent'), {
  ssr: false,
  loading: () => (
    <div className="fixed top-4 right-4 bg-gray-100 text-gray-700 px-4 py-2 rounded-lg shadow">
      Live2Dを準備中...
    </div>
  ),
});

export default function Home() {
  const { user, isLoading } = useAuth();
  const router = useRouter();
  const [showLive2D, setShowLive2D] = useState(false);

  useEffect(() => {
    if (!isLoading && !user) {
      router.push('/login');
    }
  }, [user, isLoading, router]);

  // Live2Dを即座にロード（遅延削除）
  useEffect(() => {
    if (user) {
      setShowLive2D(true);
    }
  }, [user]);

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
    <>
      {showLive2D && <Live2DComponent />}
      <div className="flex flex-col items-center justify-center min-h-screen relative z-10 pt-16 pb-24">
        <h1 className="text-4xl font-bold mb-4">心のログ - Kokoro Log</h1>
        <p className="text-lg mb-2">ようこそ、{user.name || user.email}さん</p>
        <p className="text-gray-600 mt-4">
          下のナビゲーションからチャット機能をご利用ください
        </p>
      </div>
      <BottomNav />
    </>
  );
}