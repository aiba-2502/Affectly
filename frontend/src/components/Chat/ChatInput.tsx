'use client';

import React, { useState, KeyboardEvent, useRef, useEffect } from 'react';
import { PaperAirplaneIcon } from '@heroicons/react/24/solid';
import { PlusIcon } from '@heroicons/react/24/outline';
import { useChatStore } from '@/stores/chatStore';

interface ChatInputProps {
  onSend: (message: string) => void;
  disabled?: boolean;
  placeholder?: string;
}

export const ChatInput: React.FC<ChatInputProps> = ({
  onSend,
  disabled = false,
  placeholder = "メッセージを入力..."
}) => {
  const [message, setMessage] = useState('');
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const { newSession } = useChatStore();

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 200)}px`;
    }
  }, [message]);

  const handleSend = () => {
    if (message.trim() && !disabled) {
      onSend(message);
      setMessage('');
    }
  };

  const handleKeyPress = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="fixed bottom-24 left-0 right-0 bg-transparent z-20">
      <div className="px-6 sm:px-8 md:px-12 lg:px-16 py-3">
        <div className="max-w-3xl mx-auto">
          <div className="flex items-end gap-3">
            {/* 新規チャットボタン */}
            <button
              onClick={newSession}
              className="p-3 rounded-full bg-[var(--color-primary)]/90 hover:bg-[var(--color-primary)] text-white shadow-lg transition-all hover:scale-105 duration-200"
              title="新規チャット"
              aria-label="新規チャット"
            >
              <PlusIcon className="w-5 h-5" />
            </button>

            <div className="flex-1 relative">
            <textarea
              ref={textareaRef}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder={placeholder}
              disabled={disabled}
              className="w-full resize-none rounded-lg border border-gray-300 bg-white/70 backdrop-blur-sm px-4 py-3 pr-12 focus:outline-none focus:border-gray-500 text-gray-900 placeholder-gray-500 text-[15px] leading-6 max-h-[200px] overflow-y-auto shadow-md"
              rows={1}
              style={{ 
                minHeight: '48px'
              }}
            />
            
            {/* 送信ボタン */}
            <button
              onClick={handleSend}
              disabled={disabled || !message.trim()}
              className={`absolute right-2 bottom-2 p-2 rounded-md transition-all ${
                message.trim()
                  ? 'text-gray-700 hover:bg-gray-100'
                  : 'text-gray-400 cursor-not-allowed'
              }`}
              aria-label="送信"
            >
              <PaperAirplaneIcon className="w-5 h-5 rotate-0" />
            </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};