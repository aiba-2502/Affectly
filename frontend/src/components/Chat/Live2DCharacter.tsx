'use client';

import React, { useEffect, useRef, useState } from 'react';

interface Live2DCharacterProps {
  modelPath?: string;
  emotion?: 'Neutral' | 'Happy' | 'Sad' | 'Angry' | 'Relaxed' | 'Surprised';
  isSpeak?: boolean;
}

export const Live2DCharacter: React.FC<Live2DCharacterProps> = ({
  modelPath = '/live2d/nike01/nike01.model3.json',
  emotion = 'Neutral',
  isSpeak = false
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const appRef = useRef<any>(null);
  const modelRef = useRef<any>(null);
  const [isClient, setIsClient] = useState(false);
  const [pixiLoaded, setPixiLoaded] = useState(false);

  // クライアントサイドでのみ実行
  useEffect(() => {
    setIsClient(true);
  }, []);

  // PIXIとLive2Dをクライアントサイドでのみロード
  useEffect(() => {
    if (!isClient) return;

    const loadPixi = async () => {
      try {
        const PIXI = await import('pixi.js');
        const { Live2DModel } = await import('pixi-live2d-display-lipsyncpatch');
        
        if (!canvasRef.current) return;

        // PIXIアプリケーションを作成
        const app = new (PIXI as any).Application({
          view: canvasRef.current,
          width: 300,
          height: 400,
          backgroundColor: 0xffffff,
          backgroundAlpha: 0,
          antialias: true,
          resolution: window.devicePixelRatio || 1
        });

        appRef.current = app;

        // Live2Dモデルをロード
        Live2DModel.from(modelPath, { autoInteract: false }).then((model: any) => {
          modelRef.current = model;
          
          // モデルのスケールと位置を調整
          model.scale.set(0.15, 0.15);
          model.x = app.view.width / 2;
          model.y = app.view.height * 0.8;
          
          // モデルをステージに追加
          app.stage.addChild(model);

          // アイドルモーションを開始
          model.motion('Idle');
          
          setPixiLoaded(true);
        }).catch((error: any) => {
          console.error('Failed to load Live2D model:', error);
        });
      } catch (error) {
        console.error('Failed to load PIXI or Live2D:', error);
      }
    };

    loadPixi();

    return () => {
      if (appRef.current) {
        appRef.current.destroy(true, true);
      }
    };
  }, [isClient, modelPath]);

  // 感情の変更処理
  useEffect(() => {
    if (!pixiLoaded || !modelRef.current) return;

    // 感情に応じたモーションを再生
    const motionGroup = emotion;
    modelRef.current.motion(motionGroup).catch((error: any) => {
      console.error('Failed to play motion:', error);
      // フォールバックとしてNeutralモーションを再生
      modelRef.current?.motion('Neutral');
    });
  }, [emotion, pixiLoaded]);

  // 話している時の口パク処理
  useEffect(() => {
    if (!pixiLoaded || !modelRef.current) return;

    // 話している時の口パク表現
    if (isSpeak) {
      // 簡易的な口パク表現
      const interval = setInterval(() => {
        if (modelRef.current && modelRef.current.internalModel) {
          const mouthValue = Math.random();
          // Live2Dモデルのパラメータを直接操作（モデルに依存）
          try {
            modelRef.current.internalModel.coreModel.setParameterValueById('ParamMouthOpenY', mouthValue);
          } catch (error) {
            console.error('Failed to set mouth parameter:', error);
          }
        }
      }, 100);

      return () => clearInterval(interval);
    } else {
      // 口を閉じる
      try {
        if (modelRef.current && modelRef.current.internalModel) {
          modelRef.current.internalModel.coreModel.setParameterValueById('ParamMouthOpenY', 0);
        }
      } catch (error) {
        console.error('Failed to close mouth:', error);
      }
    }
  }, [isSpeak, pixiLoaded]);

  // サーバーサイドでは何も表示しない
  if (!isClient) {
    return (
      <div className="flex justify-center items-center">
        <div className="w-[300px] h-[400px] bg-gray-100 rounded-lg animate-pulse" />
      </div>
    );
  }

  return (
    <div className="flex justify-center items-center">
      <canvas 
        ref={canvasRef} 
        className="rounded-lg"
        style={{ maxWidth: '100%', height: 'auto' }}
      />
    </div>
  );
};