/**
 * 感情の英語名を日本語に変換するマッピング
 * バックエンドが英語を返した場合のフォールバック用
 */
export const emotionTranslations: Record<string, string> = {
  // Basic emotions
  'joy': '喜び',
  'sadness': '悲しみ',
  'anger': '怒り',
  'fear': '恐れ',
  'surprise': '驚き',
  'disgust': '嫌悪',

  // Complex emotions
  'trust': '信頼',
  'anticipation': '期待',
  'love': '愛',
  'anxiety': '不安',
  'frustration': 'イライラ',
  'relief': '安心',
  'gratitude': '感謝',
  'pride': '誇り',
  'guilt': '罪悪感',
  'shame': '恥',
  'hope': '希望',
  'disappointment': '失望',
  'contentment': '満足',
  'loneliness': '孤独',

  // Additional emotions
  'discomfort': '不快',
  'confusion': '困惑',
  'excitement': '興奮',
  'calmness': '落ち着き',
  'determination': '決意',
  'optimism': '楽観',
  'pessimism': '悲観',
  'confidence': '自信',
  'doubt': '疑念',
  'empathy': '共感',
  'compassion': '思いやり',
  'jealousy': '嫉妬',
  'envy': '羨望',
  'curiosity': '好奇心',
  'boredom': '退屈'
};

/**
 * 感情名を日本語に変換（すでに日本語の場合はそのまま返す）
 * @param emotion 感情名（英語または日本語）
 * @returns 日本語の感情名
 */
export function translateEmotion(emotion: string): string {
  // すでに日本語の場合はそのまま返す
  if (/[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]/.test(emotion)) {
    return emotion;
  }

  // 英語の場合は変換（見つからない場合は元の値を返す）
  return emotionTranslations[emotion.toLowerCase()] || emotion;
}

/**
 * 感情キーワードリストの感情名を日本語に変換
 */
export function translateEmotionKeywords(emotionKeywords: Array<{emotion: string; keywords: string[]}>): Array<{emotion: string; keywords: string[]}> {
  return emotionKeywords.map(item => ({
    ...item,
    emotion: translateEmotion(item.emotion)
  }));
}