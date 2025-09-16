'use client';

import { useEffect, useRef, useCallback } from 'react';
import { LAppWavFileHandler } from '@/lib/live2d/demo/lappwavfilehandler';
import { LAppDelegate } from '@/lib/live2d/demo/lappdelegate';

// LAppDelegateの内部構造の型定義
interface DelegateWithSubdelegates {
  _subdelegates: {
    getSize: () => number;
    at: (index: number) => {
      getLive2DManager: () => {
        getModel: (index: number) => {
          setLipSyncValue: (value: number) => void;
        } | null;
      } | null;
    };
  };
}

export function useLipSyncHandler() {
  const wavFileHandlerRef = useRef<LAppWavFileHandler | null>(null);
  const isLipSyncingRef = useRef<boolean>(false);
  const updateIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const audioStartTimeRef = useRef<number>(0);
  const previousRmsRef = useRef<number>(0);
  const lastUpdateTimeRef = useRef<number>(0);
  const debugLogCountRef = useRef<number>(0);
  const rmsScaleFactorRef = useRef<number>(10000); // 動的に調整される感度

  useEffect(() => {
    // WAVファイルハンドラーを初期化
    wavFileHandlerRef.current = new LAppWavFileHandler();

    // クリーンアップ
    return () => {
      if (wavFileHandlerRef.current) {
        wavFileHandlerRef.current.releasePcmData();
        wavFileHandlerRef.current = null;
      }
      if (updateIntervalRef.current) {
        clearInterval(updateIntervalRef.current);
        updateIntervalRef.current = null;
      }
    };
  }, []);

  /**
   * リップシンクを停止
   */
  const stopLipSync = useCallback(() => {
    isLipSyncingRef.current = false;
    previousRmsRef.current = 0;
    lastUpdateTimeRef.current = 0;
    debugLogCountRef.current = 0;

    // 更新タイマーを停止
    if (updateIntervalRef.current) {
      clearInterval(updateIntervalRef.current);
      updateIntervalRef.current = null;
    }

    // Live2Dモデルのリップシンク値をリセット
    try {
      const appDelegate = LAppDelegate.getInstance();
      // subdelegateを取得（通常最初の1つを使用）
      const subdelegates = (appDelegate as unknown as DelegateWithSubdelegates)._subdelegates;
      if (subdelegates && subdelegates.getSize() > 0) {
        const subdelegate = subdelegates.at(0);
        const manager = subdelegate.getLive2DManager();
        if (manager) {
          const model = manager.getModel(0);
          if (model) {
            model.setLipSyncValue(0);
          }
        }
      }
    } catch (error) {
      console.error('リップシンク値のリセットエラー:', error);
    }
  }, []);

  /**
   * リップシンク値を更新
   */
  const updateLipSync = useCallback(() => {
    const updateInterval = 33; // 約30FPS (33ms間隔) - より滑らかな動作のため頻度を上げる

    const update = () => {
      if (!isLipSyncingRef.current) {
        return;
      }

      try {
        // Live2Dマネージャーを取得
        const appDelegate = LAppDelegate.getInstance();
        const subdelegates = (appDelegate as unknown as DelegateWithSubdelegates)._subdelegates;
        if (!subdelegates || subdelegates.getSize() === 0) {
          console.error('Subdelegateが見つかりません');
          return;
        }

        const subdelegate = subdelegates.at(0);
        const manager = subdelegate.getLive2DManager();
        if (!manager) {
          console.error('Live2Dマネージャーが見つかりません');
          return;
        }

        const model = manager.getModel(0);
        if (!model) {
          console.error('Live2Dモデルが見つかりません');
          return;
        }

        // WAVファイルハンドラーから RMS値を取得
        if (wavFileHandlerRef.current) {
          // 現在時刻を取得
          const currentTime = Date.now();

          // 前回の更新からの差分時間を計算（秒単位）
          const deltaTime = lastUpdateTimeRef.current === 0
            ? updateInterval / 1000  // 初回は更新間隔を使用
            : (currentTime - lastUpdateTimeRef.current) / 1000;

          // 現在の更新時刻を記録
          lastUpdateTimeRef.current = currentTime;

          // 音声再生開始からの経過時間（デバッグ用）
          const totalElapsed = (currentTime - audioStartTimeRef.current) / 1000;

          // デバッグログを一定間隔でのみ出力（約100ms間隔 = 10FPS）
          debugLogCountRef.current++;
          const shouldLog = debugLogCountRef.current % 3 === 0;

          if (shouldLog) {
            console.log('リップシンク更新詳細:', {
              totalElapsed,
              deltaTime,
              userTimeSeconds: wavFileHandlerRef.current._userTimeSeconds,
              sampleOffset: wavFileHandlerRef.current._sampleOffset,
              samplesPerChannel: wavFileHandlerRef.current._wavFileInfo?._samplesPerChannel,
              hasPcmData: !!wavFileHandlerRef.current._pcmData
            });
          }

          // WAVファイルハンドラーを更新（前回からの差分時間を渡す）
          const updated = wavFileHandlerRef.current.update(deltaTime);

          if (shouldLog) {
            console.log('update結果:', {
              updated,
              deltaTime,
              newUserTimeSeconds: wavFileHandlerRef.current._userTimeSeconds,
              newSampleOffset: wavFileHandlerRef.current._sampleOffset
            });
          }

          if (!updated) {
            console.log('音声データ終了');
            stopLipSync();
            return;
          }

          // RMS値を取得
          const rms = wavFileHandlerRef.current.getRms();
          if (shouldLog) {
            console.log('RMS値:', {
              rawRms: rms,
              lastRms: wavFileHandlerRef.current._lastRms
            });
          }

          // スケーリングとスムージング処理
          // 1. 基本的なスケーリング（感度調整）
          // 自動調整されたスケールファクターを使用
          let targetRms = Math.min(rms * rmsScaleFactorRef.current, 1);

          // 2. 最小値の閾値設定（微小な値を除外）
          if (targetRms < 0.01) {  // 閾値も下げる（0.05→0.01）
            targetRms = 0;
          }

          // 3. スムージング処理（前の値との線形補間）
          const smoothingFactor = 0.3; // 0-1の値、大きいほど変化が急激
          const smoothedRms = previousRmsRef.current + (targetRms - previousRmsRef.current) * smoothingFactor;
          previousRmsRef.current = smoothedRms;

          if (shouldLog) {
            console.log('リップシンク値計算:', {
              targetRms,
              smoothedRms,
              previousRms: previousRmsRef.current
            });
          }

          // モデルにリップシンク値を設定
          model.setLipSyncValue(smoothedRms);
          if (shouldLog) {
            console.log('モデルにリップシンク値を設定:', smoothedRms);
          }
        }
      } catch (error) {
        console.error('リップシンク更新エラー:', error);
      }
    };

    // 定期的に更新
    updateIntervalRef.current = setInterval(update, updateInterval);
  }, [stopLipSync]);

  /**
   * リップシンクを開始
   * @param audioUrl 音声ファイルのURL（WAV形式）
   */
  const startLipSync = useCallback(async (audioUrl: string): Promise<void> => {
    console.log('useLipSyncHandler: リップシンク開始', {
      urlType: audioUrl.startsWith('data:') ? 'Base64 Data URL' : audioUrl.startsWith('blob:') ? 'Blob URL' : 'External URL',
      urlPreview: audioUrl.substring(0, 100),
      hasWavFileHandler: !!wavFileHandlerRef.current
    });

    // 既存のリップシンクを停止
    stopLipSync();

    if (!wavFileHandlerRef.current) {
      console.error('リップシンク用のオブジェクトが初期化されていません');
      return;
    }

    try {
      isLipSyncingRef.current = true;

      // WAVファイルハンドラーを開始（start内部でloadWavFileが呼ばれる）
      // ただし、startメソッドはPromiseを返さないため、loadWavFileを直接呼ぶ必要がある
      const success = await wavFileHandlerRef.current.loadWavFile(audioUrl);
      if (!success) {
        console.error('WAVファイルのロードに失敗しました');
        isLipSyncingRef.current = false;
        return;
      }

      console.log('WAVファイルのロードに成功');

      // ロード後のWAVファイル情報を確認
      console.log('WAVファイル情報:', {
        numberOfChannels: wavFileHandlerRef.current._wavFileInfo?._numberOfChannels,
        samplingRate: wavFileHandlerRef.current._wavFileInfo?._samplingRate,
        samplesPerChannel: wavFileHandlerRef.current._wavFileInfo?._samplesPerChannel,
        bitsPerSample: wavFileHandlerRef.current._wavFileInfo?._bitsPerSample,
        hasPcmData: !!wavFileHandlerRef.current._pcmData,
        pcmDataLength: wavFileHandlerRef.current._pcmData?.length,
        pcmDataChannelLength: wavFileHandlerRef.current._pcmData?.[0]?.length
      });

      // 最初のPCMサンプルデータを確認（デバッグ用）
      if (wavFileHandlerRef.current._pcmData && wavFileHandlerRef.current._pcmData[0]) {
        const firstSamples = wavFileHandlerRef.current._pcmData[0].slice(0, 10);
        console.log('最初の10サンプル:', firstSamples);

        // PCMデータの範囲を確認
        const pcmChannel = wavFileHandlerRef.current._pcmData[0];
        let minValue = Infinity;
        let maxValue = -Infinity;
        let avgValue = 0;

        for (let i = 0; i < Math.min(10000, pcmChannel.length); i++) {
          const sample = pcmChannel[i];
          minValue = Math.min(minValue, sample);
          maxValue = Math.max(maxValue, sample);
          avgValue += Math.abs(sample);
        }
        avgValue /= Math.min(10000, pcmChannel.length);

        console.log('PCMデータ範囲（最初の10000サンプル）:', {
          min: minValue,
          max: maxValue,
          average: avgValue,
          range: maxValue - minValue
        });

        // RMSのテスト計算
        let testRms = 0;
        for (let i = 0; i < Math.min(1000, pcmChannel.length); i++) {
          const sample = pcmChannel[i];
          testRms += sample * sample;
        }
        testRms = Math.sqrt(testRms / Math.min(1000, pcmChannel.length));
        console.log('最初の1000サンプルのテストRMS:', testRms);

        // より大きなセクションでのRMS計算（音声が本格的に始まる部分）
        let midRms = 0;
        const midStart = Math.floor(pcmChannel.length * 0.3); // 30%地点から
        const midEnd = Math.min(midStart + 5000, pcmChannel.length);
        for (let i = midStart; i < midEnd; i++) {
          const sample = pcmChannel[i];
          midRms += sample * sample;
        }
        midRms = Math.sqrt(midRms / (midEnd - midStart));
        console.log('中間部分のRMS（30%地点から5000サンプル）:', midRms);

        // 感度の自動調整
        // 音声データの平均的なRMS値に基づいて適切なスケールファクターを計算
        const referenceRms = Math.max(testRms, midRms);
        if (referenceRms > 0) {
          // 目標とするリップシンク値（0.3-0.5程度）に対してスケールファクターを計算
          const targetLipSyncValue = 0.4;
          rmsScaleFactorRef.current = targetLipSyncValue / referenceRms;
          console.log('感度自動調整:', {
            referenceRms,
            calculatedScaleFactor: rmsScaleFactorRef.current,
            expectedOutput: referenceRms * rmsScaleFactorRef.current
          });
        } else {
          // RMSが0の場合はデフォルト値を使用
          rmsScaleFactorRef.current = 10000;
          console.log('感度自動調整: デフォルト値を使用（RMS=0）');
        }
      }

      // サンプル位置とRMS値をリセット（startメソッドの処理を直接実行）
      wavFileHandlerRef.current._sampleOffset = 0;
      wavFileHandlerRef.current._userTimeSeconds = 0.0;
      wavFileHandlerRef.current._lastRms = 0.0;

      // 音声再生開始時刻を記録（タイミング同期のため）
      audioStartTimeRef.current = Date.now();
      lastUpdateTimeRef.current = audioStartTimeRef.current; // 最初の更新時刻も記録
      console.log('リップシンク開始時刻記録:', audioStartTimeRef.current);

      // リップシンク更新を開始
      updateLipSync();

      // 注意: 音声の再生はVoiceServiceが既に行っているため、
      // ここでは再生しない（二重再生を防ぐ）

    } catch (error) {
      console.error('リップシンク開始エラー:', error);
      stopLipSync();
    }
  }, [stopLipSync, updateLipSync]);

  return {
    startLipSync,
    stopLipSync,
  };
}