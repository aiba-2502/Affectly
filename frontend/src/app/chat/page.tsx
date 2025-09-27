'use client';

import { useAuth } from '@/contexts/AuthContextOptimized';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import BottomNav from '@/components/BottomNav';
import { ChatContainer } from '@/components/Chat/ChatContainer';
import { useChatStore } from '@/stores/chatStore';
import { PlusIcon } from '@heroicons/react/24/outline';
import AnalysisNotification from '@/components/AnalysisNotification';
import { useNotificationStore } from '@/stores/notificationStore';
import reportService from '@/services/reportService';
import { logger } from '@/utils/logger';

export default function ChatPage() {
  const { user, isLoading } = useAuth();
  const router = useRouter();
  const { newSession, sessionId } = useChatStore();
  const { showAnalysisNotification, dismissNotification, checkAndShowNotification } = useNotificationStore();

  useEffect(() => {
    if (!isLoading && !user) {
      router.push('/login');
    }
  }, [user, isLoading, router]);

  // AI分析通知のチェック（メッセージ送信後）
  useEffect(() => {
    const checkAnalysisStatus = async () => {
      if (user) {
        try {
          const token = localStorage.getItem('access_token');
          if (token) {
            reportService.setToken(token);
            const response = await reportService.getReport();

            if ('needsAnalysis' in response) {
              checkAndShowNotification(response.needsAnalysis);
            }
          }
        } catch (error) {
          logger.error('Failed to check analysis status:', error);
        }
      }
    };

    // セッション変更時にもチェック
    if (sessionId) {
      // メッセージ送信後にチェックするため、少し遅延
      const timer = setTimeout(checkAnalysisStatus, 2000);
      return () => clearTimeout(timer);
    }
  }, [user, sessionId, checkAndShowNotification]);

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
    <div className="flex flex-col min-h-screen">
      <AnalysisNotification
        show={showAnalysisNotification}
        onClose={dismissNotification}
      />
      {/* Header - ChatGPT風のシンプルなヘッダー */}
      <div className="bg-white/75 backdrop-blur-sm border-b border-gray-200 px-4 py-3 relative z-20">
        <div className="max-w-4xl mx-auto flex justify-between items-center">
          <h1 className="text-lg font-semibold text-gray-900">心のログ</h1>
          <div className="flex gap-2">
            <button
              onClick={newSession}
              className="flex items-center gap-1 px-3 py-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
              title="新しいチャット"
            >
              <span className="text-sm">新規チャット</span>
              <PlusIcon className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Chat Container */}
      <div className="flex-1 overflow-hidden">
        <ChatContainer />
      </div>

      <BottomNav />
    </div>
  );
}