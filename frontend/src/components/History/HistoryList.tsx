'use client';

import React, { useEffect, useState } from 'react';
import { ChatSession } from '@/types/chat';
import { chatApi } from '@/services/chatApi';
import { useRouter } from 'next/navigation';
import { useChatStore } from '@/stores/chatStore';
import { 
  ChatBubbleLeftRightIcon,
  ClockIcon,
  ChevronRightIcon
} from '@heroicons/react/24/outline';

export const HistoryList: React.FC = () => {
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();
  const { setSessionId, setMessages } = useChatStore();

  useEffect(() => {
    loadSessions();
  }, []);

  const loadSessions = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const token = localStorage.getItem('token');
      if (token) {
        chatApi.setToken(token);
        const response = await chatApi.getChatSessions();
        setSessions(response.sessions);
      }
    } catch (error) {
      console.error('Failed to load sessions:', error);
      setError('履歴の読み込みに失敗しました');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSessionClick = async (sessionId: string) => {
    try {
      // セッションIDを設定
      setSessionId(sessionId);
      
      // メッセージを読み込む
      const token = localStorage.getItem('token');
      if (token) {
        chatApi.setToken(token);
        const response = await chatApi.getMessages(sessionId);
        setMessages(response.messages);
      }
      
      // チャット画面に遷移
      router.push('/chat');
    } catch (error) {
      console.error('Failed to load session:', error);
      setError('セッションの読み込みに失敗しました');
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffTime = Math.abs(now.getTime() - date.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return `今日 ${date.toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })}`;
    } else if (diffDays === 1) {
      return `昨日 ${date.toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })}`;
    } else if (diffDays < 7) {
      return `${diffDays}日前`;
    } else {
      return date.toLocaleDateString('ja-JP', { 
        year: 'numeric', 
        month: '2-digit', 
        day: '2-digit' 
      });
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-gray-500">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto mb-2"></div>
          <p>履歴を読み込み中...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <div className="text-red-500 mb-4">{error}</div>
        <button
          onClick={loadSessions}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
        >
          再読み込み
        </button>
      </div>
    );
  }

  if (sessions.length === 0) {
    return (
      <div className="text-center py-12">
        <ChatBubbleLeftRightIcon className="w-16 h-16 text-gray-300 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-600 mb-2">
          まだチャット履歴がありません
        </h3>
        <p className="text-gray-500 mb-6">
          新しい会話を始めてみましょう
        </p>
        <button
          onClick={() => router.push('/chat')}
          className="px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
        >
          チャットを開始
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {sessions.map((session) => (
        <button
          key={session.session_id}
          onClick={() => handleSessionClick(session.session_id)}
          className="w-full text-left bg-white hover:bg-gray-50 rounded-lg p-4 transition-colors border border-gray-200 hover:border-gray-300 group"
        >
          <div className="flex items-start justify-between">
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-2">
                <ChatBubbleLeftRightIcon className="w-4 h-4 text-gray-400 flex-shrink-0" />
                <span className="text-xs text-gray-500">
                  {session.message_count} メッセージ
                </span>
              </div>
              
              <p className="text-sm text-gray-800 line-clamp-2 mb-2">
                {session.preview || '会話の内容がありません'}
              </p>
              
              <div className="flex items-center gap-1 text-xs text-gray-500">
                <ClockIcon className="w-3 h-3" />
                <span>{formatDate(session.last_message_at)}</span>
              </div>
            </div>
            
            <ChevronRightIcon className="w-5 h-5 text-gray-400 group-hover:text-gray-600 flex-shrink-0 ml-2" />
          </div>
        </button>
      ))}
    </div>
  );
};