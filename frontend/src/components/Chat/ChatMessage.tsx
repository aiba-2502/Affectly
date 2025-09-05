'use client';

import React, { useMemo } from 'react';
import { ChatMessage as ChatMessageType } from '@/types/chat';
import { UserCircleIcon } from '@heroicons/react/24/solid';
import DOMPurify from 'dompurify';

interface ChatMessageProps {
  message: ChatMessageType;
}

export const ChatMessage: React.FC<ChatMessageProps> = ({ message }) => {
  const isUser = message.role === 'user';
  
  // XSS対策：メッセージ内容をサニタイズ
  const sanitizedContent = useMemo(() => {
    // DOMPurifyでHTMLタグを除去し、安全なテキストのみを残す
    return DOMPurify.sanitize(message.content, { 
      ALLOWED_TAGS: [], // すべてのHTMLタグを除去
      ALLOWED_ATTR: [], // すべての属性を除去
      KEEP_CONTENT: true // テキストコンテンツは保持
    });
  }, [message.content]);
  
  return (
    <div className={`flex gap-3 mb-6 ${isUser ? 'flex-row-reverse' : ''}`}>
      {/* アバター */}
      <div className="flex-shrink-0">
        {isUser ? (
          <div className="w-8 h-8 bg-gray-600 rounded-full flex items-center justify-center">
            <UserCircleIcon className="w-6 h-6 text-white" />
          </div>
        ) : (
          <div className="w-8 h-8 bg-gradient-to-br from-green-400 to-blue-500 rounded-full flex items-center justify-center">
            <span className="text-white text-xs font-bold">AI</span>
          </div>
        )}
      </div>
      
      {/* メッセージ内容 - レスポンシブ対応で幅を調整 */}
      <div className={`flex-1 ${isUser ? 'text-right' : ''}`}>
        <div className={`inline-block ${isUser ? 'text-left' : ''}`} 
             style={{ maxWidth: 'calc(100% - 48px)' }}>
          <div className={`rounded-lg px-4 py-2 ${
            isUser 
              ? 'bg-gray-100 text-gray-900' 
              : 'bg-white/90 backdrop-blur-sm text-gray-900 shadow-sm'
          }`}>
            <p className="text-[15px] leading-relaxed whitespace-pre-wrap break-words">
              {sanitizedContent}
            </p>
          </div>
          
          {/* タイムスタンプ */}
          <div className={`text-xs text-gray-500 mt-1 ${isUser ? 'text-right' : ''}`}>
            {new Date(message.created_at).toLocaleTimeString('ja-JP', {
              hour: '2-digit',
              minute: '2-digit'
            })}
          </div>
        </div>
      </div>
    </div>
  );
};