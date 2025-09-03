'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { 
  ChevronRightIcon, 
  ChatBubbleLeftRightIcon,
  CalendarIcon,
  ChartBarIcon,
  LockClosedIcon,
  BookOpenIcon,
  SparklesIcon,
  CheckCircleIcon
} from '@heroicons/react/24/outline';

interface Feature {
  title: string;
  description: string;
  icon: string;
}

interface HowToUseStep {
  step: number;
  title: string;
  description: string;
  details: string[];
}

interface Tip {
  title: string;
  description: string;
}

interface InformationData {
  app_name: string;
  version: string;
  description: string;
  features: Feature[];
  how_to_use: HowToUseStep[];
  tips: Tip[];
  support: {
    email: string;
    faq_url: string;
    privacy_policy_url: string;
    terms_url: string;
  };
}

const getIconComponent = (iconName: string) => {
  switch (iconName) {
    case 'chat':
      return <ChatBubbleLeftRightIcon className="h-8 w-8 text-pink-500" />;
    case 'calendar':
      return <CalendarIcon className="h-8 w-8 text-purple-500" />;
    case 'chart':
      return <ChartBarIcon className="h-8 w-8 text-blue-500" />;
    case 'lock':
      return <LockClosedIcon className="h-8 w-8 text-green-500" />;
    default:
      return <SparklesIcon className="h-8 w-8 text-gray-500" />;
  }
};

export default function InformationPage() {
  const [information, setInformation] = useState<InformationData | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'features' | 'howto' | 'tips'>('features');

  useEffect(() => {
    fetchInformation();
  }, []);

  const fetchInformation = async () => {
    try {
      const response = await fetch('http://localhost:3000/api/v1/information');
      const data = await response.json();
      if (data.status === 'success') {
        setInformation(data.data);
      }
    } catch (error) {
      console.error('Failed to fetch information:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-pink-500"></div>
      </div>
    );
  }

  if (!information) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-gray-500">情報を読み込めませんでした。</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-pink-50 via-white to-purple-50">
      {/* ヘッダー */}
      <div className="bg-white shadow-sm border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center">
            <h1 className="text-4xl font-bold text-gray-900 mb-2">
              {information.app_name}
            </h1>
            <p className="text-lg text-gray-600">
              {information.description}
            </p>
            <p className="text-sm text-gray-500 mt-2">
              Version {information.version}
            </p>
          </div>
        </div>
      </div>

      {/* タブナビゲーション */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8">
        <div className="flex justify-center space-x-1 bg-gray-100 rounded-lg p-1">
          <button
            onClick={() => setActiveTab('features')}
            className={`px-6 py-2 rounded-md font-medium transition-colors ${
              activeTab === 'features'
                ? 'bg-white text-pink-600 shadow-sm'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            主な機能
          </button>
          <button
            onClick={() => setActiveTab('howto')}
            className={`px-6 py-2 rounded-md font-medium transition-colors ${
              activeTab === 'howto'
                ? 'bg-white text-pink-600 shadow-sm'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            使い方
          </button>
          <button
            onClick={() => setActiveTab('tips')}
            className={`px-6 py-2 rounded-md font-medium transition-colors ${
              activeTab === 'tips'
                ? 'bg-white text-pink-600 shadow-sm'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            ヒント
          </button>
        </div>
      </div>

      {/* コンテンツエリア */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 主な機能 */}
        {activeTab === 'features' && (
          <div className="grid md:grid-cols-2 gap-6">
            {information.features.map((feature, index) => (
              <div
                key={index}
                className="bg-white rounded-xl shadow-md hover:shadow-lg transition-shadow p-6"
              >
                <div className="flex items-start space-x-4">
                  <div className="flex-shrink-0">
                    {getIconComponent(feature.icon)}
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-gray-900 mb-2">
                      {feature.title}
                    </h3>
                    <p className="text-gray-600">
                      {feature.description}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* 使い方 */}
        {activeTab === 'howto' && (
          <div className="space-y-8">
            {information.how_to_use.map((step, index) => (
              <div
                key={index}
                className="bg-white rounded-xl shadow-md p-6"
              >
                <div className="flex items-start space-x-4">
                  <div className="flex-shrink-0">
                    <div className="w-12 h-12 bg-gradient-to-br from-pink-500 to-purple-500 rounded-full flex items-center justify-center text-white font-bold text-lg">
                      {step.step}
                    </div>
                  </div>
                  <div className="flex-1">
                    <h3 className="text-2xl font-bold text-gray-900 mb-2">
                      {step.title}
                    </h3>
                    <p className="text-gray-600 mb-4">
                      {step.description}
                    </p>
                    <div className="bg-gray-50 rounded-lg p-4">
                      <ul className="space-y-2">
                        {step.details.map((detail, idx) => (
                          <li key={idx} className="flex items-start">
                            <CheckCircleIcon className="h-5 w-5 text-green-500 mt-0.5 mr-2 flex-shrink-0" />
                            <span className="text-gray-700">{detail}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* ヒント */}
        {activeTab === 'tips' && (
          <div className="space-y-6">
            {information.tips.map((tip, index) => (
              <div
                key={index}
                className="bg-gradient-to-r from-pink-50 to-purple-50 rounded-xl p-6 border border-pink-200"
              >
                <div className="flex items-start space-x-3">
                  <BookOpenIcon className="h-6 w-6 text-pink-500 mt-1 flex-shrink-0" />
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-1">
                      {tip.title}
                    </h3>
                    <p className="text-gray-600">
                      {tip.description}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* フッター */}
      <div className="bg-gray-100 mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center text-gray-600">
            <p className="mb-4">
              お問い合わせ: {information.support.email}
            </p>
            <div className="flex justify-center space-x-6">
              <Link href={information.support.faq_url} className="hover:text-pink-600 transition-colors">
                FAQ
              </Link>
              <Link href={information.support.privacy_policy_url} className="hover:text-pink-600 transition-colors">
                プライバシーポリシー
              </Link>
              <Link href={information.support.terms_url} className="hover:text-pink-600 transition-colors">
                利用規約
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}