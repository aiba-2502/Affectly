'use client';

import { useEffect, useState } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';
import { useRouter } from 'next/navigation';

interface AnalysisNotificationProps {
  show: boolean;
  onClose: () => void;
}

const AnalysisNotification = ({ show, onClose }: AnalysisNotificationProps) => {
  const [isVisible, setIsVisible] = useState(false);
  const [isExiting, setIsExiting] = useState(false);
  const router = useRouter();

  useEffect(() => {
    if (show) {
      // 少し遅らせてアニメーションを開始
      setTimeout(() => setIsVisible(true), 100);

      // 20秒後に自動的に閉じる
      const timer = setTimeout(() => {
        handleClose();
      }, 20000);

      return () => clearTimeout(timer);
    }
  }, [show]);

  const handleClose = () => {
    setIsExiting(true);
    setTimeout(() => {
      setIsVisible(false);
      setIsExiting(false);
      onClose();
    }, 300);
  };

  const handleNavigateToReport = () => {
    handleClose();
    router.push('/report');
  };

  if (!show && !isVisible) return null;

  return (
    <div
      className={`fixed top-20 right-4 z-50 transition-all duration-300 transform ${
        isVisible && !isExiting ? 'translate-x-0 opacity-100' : 'translate-x-full opacity-0'
      }`}
    >
      <div className="bg-white border border-gray-200 rounded-lg shadow-lg">
        <div className="px-4 py-3 flex items-center gap-3">
          <span className="text-sm font-medium text-gray-900">AI分析可能です</span>
          <button
            onClick={handleNavigateToReport}
            className="text-sm text-blue-600 hover:text-blue-700 underline"
          >
            レポート画面へ
          </button>
          <button
            onClick={handleClose}
            className="ml-2 text-gray-400 hover:text-gray-600"
            aria-label="閉じる"
          >
            <XMarkIcon className="h-4 w-4" />
          </button>
        </div>
        {/* プログレスバー */}
        <div className="h-0.5 bg-gray-100">
          <div
            className="h-full bg-blue-500 transition-all"
            style={{
              animation: isVisible && !isExiting ? 'progress 20s linear' : 'none'
            }}
          />
        </div>
      </div>

      <style jsx>{`
        @keyframes progress {
          from {
            width: 100%;
          }
          to {
            width: 0%;
          }
        }
      `}</style>
    </div>
  );
};

export default AnalysisNotification;