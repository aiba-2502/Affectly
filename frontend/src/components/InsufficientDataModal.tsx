'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

interface InsufficientDataModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentMessageCount: number;
  requiredMessageCount: number;
}

const InsufficientDataModal: React.FC<InsufficientDataModalProps> = ({
  isOpen,
  onClose,
  currentMessageCount,
  requiredMessageCount
}) => {
  const [isVisible, setIsVisible] = useState(false);
  const router = useRouter();

  useEffect(() => {
    if (isOpen) {
      setIsVisible(true);
    } else {
      const timer = setTimeout(() => setIsVisible(false), 300);
      return () => clearTimeout(timer);
    }
  }, [isOpen]);

  const handleGoToChat = () => {
    onClose();
    router.push('/chat');
  };

  if (!isVisible) return null;

  const remainingMessages = requiredMessageCount - currentMessageCount;

  return (
    <div
      className={`fixed inset-0 z-50 flex items-center justify-center transition-opacity duration-300 ${
        isOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'
      }`}
    >
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal Content */}
      <div className={`relative bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 transform transition-all duration-300 ${
        isOpen ? 'scale-100 translate-y-0' : 'scale-95 translate-y-4'
      }`}>
        <div className="p-8">
          {/* Icon */}
          <div className="flex justify-center mb-6">
            <div className="w-20 h-20 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full flex items-center justify-center animate-pulse">
              <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
          </div>

          {/* Title */}
          <h2 className="text-2xl font-bold text-gray-900 text-center mb-4">
            分析データが不足しています
          </h2>

          {/* Message */}
          <div className="space-y-4 mb-6">
            <p className="text-gray-600 text-center">
              AI分析を実行するには、もう少しチャット記録が必要です。
            </p>
            <p className="text-sm text-gray-600 text-center">
              AIキャラクターとの対話記録が多いほど、より精度の高い分析結果をお届けします。
            </p>
          </div>

          {/* Actions */}
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="flex-1 py-3 px-4 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition-colors"
            >
              閉じる
            </button>
            <button
              onClick={handleGoToChat}
              className="flex-1 py-3 px-4 bg-[var(--color-primary)] text-white rounded-lg font-medium hover:bg-[var(--color-primary-hover)] transition-colors flex items-center justify-center gap-2"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
              チャットを続ける
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default InsufficientDataModal;