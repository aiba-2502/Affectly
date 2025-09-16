'use client';

import { useAuth } from '@/contexts/AuthContextOptimized';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import BottomNav from '@/components/BottomNav';
import dynamic from 'next/dynamic';
import { UserReport } from '@/types/report';
import reportService from '@/services/reportService';

// Live2Dコンポーネントを動的インポート（SSR無効化）
const Live2DContainedComponent = dynamic(() => import('@/components/Live2DContainedComponent'), {
  ssr: false,
  loading: () => (
    <div className="flex items-center justify-center h-full">
      <div className="text-gray-400 text-center">
        <div className="animate-pulse">
          <div className="w-24 h-24 bg-gray-200 rounded-full mx-auto mb-2"></div>
          <p className="text-xs">キャラクター準備中...</p>
        </div>
      </div>
    </div>
  ),
});

export default function ReportPage() {
  const { user, isLoading } = useAuth();
  const router = useRouter();
  const [showLive2D, setShowLive2D] = useState(false);
  const [activeTab, setActiveTab] = useState<'week' | 'month'>('week');
  const [reportData, setReportData] = useState<UserReport | null>(null);
  const [isLoadingData, setIsLoadingData] = useState(true);

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

  useEffect(() => {
    // レポートデータを取得
    if (user) {
      fetchReportData();
    }
  }, [user]);

  const fetchReportData = async () => {
    try {
      setIsLoadingData(true);

      // トークンをセット
      const token = localStorage.getItem('token');
      if (token) {
        reportService.setToken(token);
      }

      // APIからレポートデータを取得
      const data = await reportService.getReport();
      setReportData(data);
    } catch (error) {
      console.error('レポートデータの取得に失敗しました:', error);

      // エラー時はモックデータを表示（開発用）
      const mockData: UserReport = {
        userId: String(user?.id || ''),
        userName: user?.name || 'ユーザー',
        strengths: [
          { id: '1', title: '強み1', description: '分析中...' },
          { id: '2', title: '強み2', description: '分析中...' },
          { id: '3', title: '強み3', description: '分析中...' },
        ],
        thinkingPatterns: [
          { id: '1', title: '思考パターン1', description: '分析中...' },
          { id: '2', title: '思考パターン2', description: '分析中...' },
        ],
        values: [
          { id: '1', title: '価値観1', description: '分析中...' },
          { id: '2', title: '価値観2', description: '分析中...' },
        ],
        conversationReport: {
          week: {
            period: 'week',
            summary: '今週は主に仕事に関する悩みについて話していました。特にチームメンバーとのコミュニケーションについて深く考察し、自身のリーダーシップスタイルについて新たな気づきを得ました。',
            frequentKeywords: [
              { keyword: '仕事', count: 15 },
              { keyword: 'チーム', count: 12 },
              { keyword: 'コミュニケーション', count: 10 },
              { keyword: '成長', count: 8 },
              { keyword: '目標', count: 7 },
            ],
            emotionKeywords: [
              { emotion: '不安', keywords: ['仕事', 'プレゼン', '締切'] },
              { emotion: '喜び', keywords: ['達成', '評価', 'チーム'] },
              { emotion: '悩み', keywords: ['キャリア', '将来', '選択'] },
            ],
          },
          month: {
            period: 'month',
            summary: '今月は仕事とプライベートのバランスについて多く話していました。新しいプロジェクトへの挑戦と、自己成長への意欲が見られました。また、人間関係の改善にも取り組んでいました。',
            frequentKeywords: [
              { keyword: '成長', count: 45 },
              { keyword: '挑戦', count: 38 },
              { keyword: '仕事', count: 35 },
              { keyword: '目標', count: 30 },
              { keyword: 'バランス', count: 25 },
            ],
            emotionKeywords: [
              { emotion: '期待', keywords: ['新プロジェクト', '成長', 'チャンス'] },
              { emotion: '疲れ', keywords: ['残業', 'プレッシャー', '締切'] },
              { emotion: '満足', keywords: ['達成', '評価', '進歩'] },
            ],
          },
        },
        updatedAt: new Date().toISOString(),
      };
      setReportData(mockData);
    } finally {
      setIsLoadingData(false);
    }
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

  const currentReport = reportData?.conversationReport[activeTab];

  return (
    <div className="flex flex-col min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-4 py-3 relative z-20">
        <div className="flex justify-between items-center">
          <h1 className="text-lg font-semibold text-gray-900">レポート</h1>
        </div>
      </div>

      {/* Main Content - 2カラムレイアウト */}
      <div className="flex-1 flex relative overflow-hidden">
        {/* 左カラム - AI分析結果 */}
        <div className="w-80 lg:w-96 xl:w-[28rem] bg-white border-r border-gray-200 flex-shrink-0 overflow-y-auto">
          <div className="p-6 space-y-4">
            {/* Live2Dキャラクター表示エリア */}
            <div className="h-48 bg-gradient-to-br from-purple-50 to-pink-50 rounded-lg overflow-hidden relative">
              {showLive2D ? (
                <Live2DContainedComponent screenType="report" />
              ) : (
                <div className="flex items-center justify-center h-full">
                  <div className="text-gray-400 text-center">
                    <div className="animate-pulse">
                      <div className="w-16 h-16 bg-gray-200 rounded-full mx-auto mb-2"></div>
                      <p className="text-xs">準備中...</p>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* AI分析カード */}
            <div className="space-y-4">
              {/* 強みカード */}
              <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
                <h3 className="text-base font-semibold text-gray-900 mb-3">
                  {user.name || 'あなた'}の強み
                </h3>
                <div className="space-y-2">
                  {isLoadingData ? (
                    <div className="animate-pulse">
                      <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                      <div className="h-4 bg-gray-200 rounded w-2/3"></div>
                    </div>
                  ) : (
                    reportData?.strengths.map((strength) => (
                      <div key={strength.id} className="bg-gray-50 rounded p-3">
                        <p className="text-sm text-gray-600">{strength.description}</p>
                      </div>
                    ))
                  )}
                </div>
              </div>

              {/* 思考特徴カード */}
              <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
                <h3 className="text-base font-semibold text-gray-900 mb-3">
                  {user.name || 'あなた'}の思考特徴
                </h3>
                <div className="space-y-2">
                  {isLoadingData ? (
                    <div className="animate-pulse">
                      <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                      <div className="h-4 bg-gray-200 rounded w-2/3"></div>
                    </div>
                  ) : (
                    reportData?.thinkingPatterns.map((pattern) => (
                      <div key={pattern.id} className="bg-gray-50 rounded p-3">
                        <p className="text-sm text-gray-600">{pattern.description}</p>
                      </div>
                    ))
                  )}
                </div>
              </div>

              {/* 価値観カード */}
              <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
                <h3 className="text-base font-semibold text-gray-900 mb-3">
                  {user.name || 'あなた'}の価値観
                </h3>
                <div className="space-y-2">
                  {isLoadingData ? (
                    <div className="animate-pulse">
                      <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                      <div className="h-4 bg-gray-200 rounded w-2/3"></div>
                    </div>
                  ) : (
                    reportData?.values.map((value) => (
                      <div key={value.id} className="bg-gray-50 rounded p-3">
                        <p className="text-sm text-gray-600">{value.description}</p>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* 右カラム - 会話の要約・キーワード分析 */}
        <div className="flex-1 overflow-y-auto bg-gray-50">
          <div className="container mx-auto px-4 py-6 max-w-4xl">
            <div className="bg-white rounded-lg shadow-sm">
              {/* タブ */}
              <div className="border-b border-gray-200">
                <div className="flex">
                  <button
                    onClick={() => setActiveTab('week')}
                    className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
                      activeTab === 'week'
                        ? 'text-blue-600 border-blue-600'
                        : 'text-gray-500 border-transparent hover:text-gray-700'
                    }`}
                  >
                    今週
                  </button>
                  <button
                    onClick={() => setActiveTab('month')}
                    className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
                      activeTab === 'month'
                        ? 'text-blue-600 border-blue-600'
                        : 'text-gray-500 border-transparent hover:text-gray-700'
                    }`}
                  >
                    今月
                  </button>
                </div>
              </div>

              <div className="p-6 space-y-6">
                {/* セクション1: 会話サマリー */}
                <div>
                  <h3 className="text-base font-semibold text-gray-900 mb-3">
                    {activeTab === 'week' ? '今週' : '今月'}の会話サマリー
                  </h3>
                  {isLoadingData ? (
                    <div className="animate-pulse">
                      <div className="h-4 bg-gray-200 rounded w-full mb-2"></div>
                      <div className="h-4 bg-gray-200 rounded w-5/6 mb-2"></div>
                      <div className="h-4 bg-gray-200 rounded w-4/6"></div>
                    </div>
                  ) : (
                    <p className="text-gray-700 leading-relaxed">
                      {currentReport?.summary}
                    </p>
                  )}
                </div>

                {/* セクション2: 頻出キーワード */}
                <div>
                  <h3 className="text-base font-semibold text-gray-900 mb-3">
                    頻出キーワード
                  </h3>
                  {isLoadingData ? (
                    <div className="animate-pulse flex flex-wrap gap-2">
                      <div className="h-8 bg-gray-200 rounded-full w-20"></div>
                      <div className="h-8 bg-gray-200 rounded-full w-24"></div>
                      <div className="h-8 bg-gray-200 rounded-full w-16"></div>
                    </div>
                  ) : (
                    <div className="flex flex-wrap gap-2">
                      {currentReport?.frequentKeywords.map((item) => (
                        <span
                          key={item.keyword}
                          className="px-4 py-2 bg-blue-50 text-blue-700 rounded-full text-sm font-medium"
                        >
                          {item.keyword}
                          <span className="ml-1 text-xs text-blue-500">({item.count})</span>
                        </span>
                      ))}
                    </div>
                  )}
                </div>

                {/* セクション3: 感情とキーワードの相関 */}
                <div>
                  <h3 className="text-base font-semibold text-gray-900 mb-3">
                    感情とキーワードの相関
                  </h3>
                  {isLoadingData ? (
                    <div className="animate-pulse space-y-2">
                      <div className="h-6 bg-gray-200 rounded w-full"></div>
                      <div className="h-6 bg-gray-200 rounded w-5/6"></div>
                      <div className="h-6 bg-gray-200 rounded w-4/6"></div>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {currentReport?.emotionKeywords.map((item) => (
                        <div key={item.emotion} className="flex items-start">
                          <span className="font-medium text-gray-700 min-w-[80px]">
                            {item.emotion}
                          </span>
                          <span className="text-gray-500 mx-2">→</span>
                          <span className="text-gray-600">
                            {item.keywords.join('、')}
                          </span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <BottomNav />
    </div>
  );
}