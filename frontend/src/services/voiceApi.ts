import axios, { AxiosError } from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

interface VoiceGenerationResponse {
  audioUrl?: string;
  audioData?: string;
  error?: string;
}

export class VoiceService {
  private static audioCache = new Map<string, string>();
  private static currentAudio: HTMLAudioElement | null = null;

  /**
   * テキストを音声に変換して再生
   * @param text 読み上げるテキスト
   * @param options オプション設定
   * @returns Audio要素のインスタンス
   */
  static async playVoice(
    text: string,
    options?: {
      volume?: number;
      playbackRate?: number;
      onEnded?: () => void;
      onError?: (error: Error) => void;
    }
  ): Promise<HTMLAudioElement> {
    try {
      // 空のテキストは処理しない
      if (!text.trim()) {
        throw new Error('読み上げるテキストが空です');
      }

      // 既存の再生を停止
      if (this.currentAudio) {
        this.currentAudio.pause();
        this.currentAudio = null;
      }

      // キャッシュチェック
      const cacheKey = text;
      let audioUrl: string;

      if (this.audioCache.has(cacheKey)) {
        audioUrl = this.audioCache.get(cacheKey)!;
      } else {
        // 音声生成API呼び出し（バックエンド経由）
        audioUrl = await this.generateVoice(text);

        // キャッシュに保存（最大10件）
        if (this.audioCache.size >= 10) {
          const firstKey = this.audioCache.keys().next().value;
          this.audioCache.delete(firstKey);
        }
        this.audioCache.set(cacheKey, audioUrl);
      }

      // 音声を再生
      this.currentAudio = new Audio(audioUrl);

      // デフォルト値または環境変数から設定値を取得
      const defaultVolume = parseFloat(process.env.NEXT_PUBLIC_VOICE_VOLUME || '0.8');
      const defaultPlaybackRate = parseFloat(process.env.NEXT_PUBLIC_VOICE_PLAYBACK_RATE || '1.0');

      this.currentAudio.volume = options?.volume ?? defaultVolume;
      this.currentAudio.playbackRate = options?.playbackRate ?? defaultPlaybackRate;

      // イベントハンドラの設定
      if (options?.onEnded) {
        this.currentAudio.onended = options.onEnded;
      }

      if (options?.onError) {
        this.currentAudio.onerror = () => {
          options.onError!(new Error('音声再生中にエラーが発生しました'));
        };
      }

      await this.currentAudio.play();
      return this.currentAudio;
    } catch (error) {
      console.error('音声再生エラー:', error);
      throw error;
    }
  }

  /**
   * 音声生成APIを呼び出し（バックエンド経由）
   */
  private static async generateVoice(text: string): Promise<string> {
    try {
      const response = await axios.post<VoiceGenerationResponse>(
        `${API_URL}/api/v1/voices/generate`,
        { text },
        {
          headers: {
            'Content-Type': 'application/json',
          },
          timeout: 30000,
        }
      );

      // レスポンスから音声URLまたはBase64データを取得
      if (response.data.audioUrl) {
        // URLが返される場合
        return response.data.audioUrl;
      } else if (response.data.audioData) {
        // Base64データが返される場合
        return `data:audio/wav;base64,${response.data.audioData}`;
      } else if (response.data.error) {
        throw new Error(response.data.error);
      } else {
        throw new Error('音声データが取得できませんでした');
      }
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const axiosError = error as AxiosError<VoiceGenerationResponse>;

        if (axiosError.response?.data?.error) {
          throw new Error(axiosError.response.data.error);
        } else if (axiosError.response?.status === 500) {
          throw new Error('サーバーエラーが発生しました');
        } else if (axiosError.response?.status === 400) {
          throw new Error('リクエストパラメータが不正です');
        }

        throw new Error(`API呼び出しエラー: ${axiosError.message}`);
      }

      throw error;
    }
  }

  /**
   * 現在再生中の音声を停止
   */
  static stopVoice(): void {
    if (this.currentAudio) {
      this.currentAudio.pause();
      this.currentAudio = null;
    }
  }

  /**
   * キャッシュをクリア
   */
  static clearCache(): void {
    this.audioCache.clear();
  }
}