import { useEffect, useState } from 'react';

interface AnalysisModalProps {
  isOpen: boolean;
  onClose?: () => void;
}

/**
 * AI分析中に表示するモーダルコンポーネント
 * 画面遷移を防止し、分析の進捗を表示します
 */
const AnalysisModal = ({ isOpen, onClose }: AnalysisModalProps) => {
  const [remainingTime, setRemainingTime] = useState(60);
  const [elapsedTime, setElapsedTime] = useState(0);

  useEffect(() => {
    if (isOpen) {
      setRemainingTime(60);
      setElapsedTime(0);

      const timer = setInterval(() => {
        setRemainingTime(prev => Math.max(0, prev - 1));
        setElapsedTime(prev => prev + 1);
      }, 1000);

      return () => clearInterval(timer);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  // プログレスバーの幅を計算（最大60秒）
  const progressPercentage = Math.min((elapsedTime / 60) * 100, 100);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* 背景オーバーレイ（クリック無効） */}
      <div
        className="absolute inset-0 bg-black bg-opacity-50 backdrop-blur-sm"
        onClick={(e) => e.preventDefault()}
      />

      {/* モーダル本体 */}
      <div className="relative bg-white rounded-lg p-8 max-w-md w-full mx-4 shadow-2xl">
        <div className="flex items-center mb-4">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mr-3"></div>
          <h3 className="text-lg font-bold text-gray-900">AI分析中...</h3>
        </div>

        {/* プログレスバー */}
        <div className="w-full bg-gray-200 rounded-full h-2 mb-4 overflow-hidden">
          <div
            className="bg-gradient-to-r from-blue-500 to-blue-600 h-2 rounded-full transition-all duration-1000 ease-out"
            style={{width: `${progressPercentage}%`}}
          >
            <div className="h-full bg-white/30 animate-pulse" />
          </div>
        </div>

        <p className="text-sm text-gray-600 mb-3">
          あなたの会話履歴を分析しています。
        </p>
        <p className="text-sm text-gray-600 mb-4">
          この処理には通常30～60秒程度かかります。
          しばらくお待ちください...
        </p>

        {remainingTime > 0 && (
          <p className="text-xs text-gray-500 text-center">
            予想残り時間: 約{remainingTime}秒
          </p>
        )}

        {/* 分析中のヒント */}
        <div className="mt-6 p-4 bg-blue-50 rounded-lg">
          <p className="text-xs text-blue-800">
            💡 分析のヒント: AIは以下の観点からあなたの会話を分析しています
          </p>
          <ul className="text-xs text-blue-700 mt-2 space-y-1 ml-4">
            <li>• あなたの強みと特性</li>
            <li>• 思考パターンの傾向</li>
            <li>• 大切にしている価値観</li>
            <li>• 感情とキーワードの関連性</li>
          </ul>
        </div>

        {/* エラー時や長時間経過時の対応（オプション） */}
        {elapsedTime > 90 && onClose && (
          <button
            onClick={onClose}
            className="mt-4 w-full px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition text-sm"
          >
            分析をキャンセル
          </button>
        )}
      </div>
    </div>
  );
};

export default AnalysisModal;