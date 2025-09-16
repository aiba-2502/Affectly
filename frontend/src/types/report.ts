export interface UserStrength {
  id: string;
  title: string;
  description: string;
}

export interface UserThinkingPattern {
  id: string;
  title: string;
  description: string;
}

export interface UserValue {
  id: string;
  title: string;
  description: string;
}

export interface KeywordCount {
  keyword: string;
  count: number;
}

export interface EmotionKeyword {
  emotion: string;
  keywords: string[];
}

export interface ConversationReport {
  period: 'week' | 'month';
  summary: string;
  frequentKeywords: KeywordCount[];
  emotionKeywords: EmotionKeyword[];
}

export interface UserReport {
  userId: string;
  userName: string;
  strengths: UserStrength[];
  thinkingPatterns: UserThinkingPattern[];
  values: UserValue[];
  conversationReport: {
    week: ConversationReport;
    month: ConversationReport;
  };
  updatedAt: string;
}