'use client';

import { useEffect, useRef, useState } from 'react';
import type { Application, DisplayObject } from 'pixi.js';

// 履歴画面専用のLive2D設定
const LIVE2D_CONFIG = {
  scale: 0.22,           // 少し引いて表示
  horizontalOffset: -10, // 中央寄りに調整
  verticalOffset: 0,     // 垂直方向のオフセット
};

const Live2DHistoryComponent = () => {
  const canvasContainerRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [app, setApp] = useState<Application | null>(null);
  const [model, setModel] = useState<any>(null);
  const modelRef = useRef<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const setupLive2D = async () => {
      try {
        // Load Cubism Core first
        if (!(window as any).Live2DCubismCore) {
          const script = document.createElement('script');
          script.src = 'https://cubism.live2d.com/sdk-web/cubismcore/live2dcubismcore.min.js';
          script.async = true;

          try {
            await new Promise((resolve, reject) => {
              script.onload = resolve;
              script.onerror = () => {
                const fallbackScript = document.createElement('script');
                fallbackScript.src = '/live2dcubismcore.min.js';
                fallbackScript.onload = resolve;
                fallbackScript.onerror = reject;
                document.head.appendChild(fallbackScript);
              };
              document.head.appendChild(script);
            });
          } catch (e) {
            console.warn('Failed to load Cubism Core from CDN, using stub');
          }
        }

        // Then load PIXI
        const PIXI = await import('pixi.js');
        (window as any).PIXI = PIXI;

        // Initialize app after PIXI is loaded
        await initApp();
      } catch (err) {
        console.error('Failed to setup Live2D:', err);
        setError('Failed to initialize Live2D');
        setIsLoading(false);
      }
    };

    setupLive2D();

    return () => {
      if (modelRef.current) {
        try {
          modelRef.current.destroy();
        } catch (e) {
          console.error('Error destroying model:', e);
        }
        modelRef.current = null;
      }
      if (app) {
        try {
          app.destroy(true);
        } catch (e) {
          console.error('Error destroying app:', e);
        }
      }
    };
  }, []);

  useEffect(() => {
    if (app) {
      // 既存のモデルがある場合は先に削除
      if (modelRef.current) {
        app.stage.removeChild(modelRef.current as unknown as DisplayObject);
        modelRef.current.destroy();
        modelRef.current = null;
        setModel(null);
      }
      // ステージをクリア
      app.stage.removeChildren();
      // 新しいモデルを読み込む
      loadLive2DModel(app, '/live2d/nike01/nike01.model3.json');
    }
  }, [app]);

  const initApp = async () => {
    if (!canvasContainerRef.current || !containerRef.current) return;

    try {
      const { Application } = await import('pixi.js');

      // コンテナのサイズを取得
      const containerRect = containerRef.current.getBoundingClientRect();

      const newApp = new Application({
        width: containerRect.width,
        height: containerRect.height,
        view: canvasContainerRef.current,
        backgroundAlpha: 0,
        antialias: true,
        resolution: window.devicePixelRatio || 1,
      });

      setApp(newApp);
    } catch (err) {
      console.error('Failed to initialize PIXI Application:', err);
      setError('Failed to initialize graphics engine');
      setIsLoading(false);
    }
  };

  const loadLive2DModel = async (currentApp: any, modelPath: string) => {
    if (!canvasContainerRef.current) return;

    try {
      setIsLoading(true);
      setError(null);

      // Check if Cubism Core is loaded
      if (!(window as any).Live2DCubismCore) {
        throw new Error('Live2D Cubism Core not loaded');
      }

      // Dynamic import of Live2D
      const Live2DModule = await import('pixi-live2d-display-lipsyncpatch/cubism4');
      const { Live2DModel } = Live2DModule;

      // Use from() instead of fromSync() for better compatibility
      const newModel = await Live2DModel.from(modelPath);

      if (!newModel) {
        throw new Error('Model failed to load');
      }

      currentApp.stage.addChild(newModel as any);

      // Set anchor and position
      if (newModel.anchor) {
        newModel.anchor.set(0.5, 0.5);
      }

      // 履歴画面用のポジション設定
      newModel.scale.set(LIVE2D_CONFIG.scale);

      // キャラクターを左側中央に配置
      newModel.x = currentApp.renderer.width / 2 + LIVE2D_CONFIG.horizontalOffset;
      newModel.y = currentApp.renderer.height / 2 + LIVE2D_CONFIG.verticalOffset;

      modelRef.current = newModel;
      setModel(newModel);
      setIsLoading(false);

      console.log('Live2D model loaded successfully for history page');
    } catch (error) {
      console.error('Failed to load Live2D model:', error);
      setError(`Failed to load Live2D model: ${error instanceof Error ? error.message : String(error)}`);
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (!app || !model || !containerRef.current) return;

    const onResize = () => {
      if (!canvasContainerRef.current || !containerRef.current) return;

      const containerRect = containerRef.current.getBoundingClientRect();

      app.renderer.resize(
        containerRect.width,
        containerRect.height
      );

      // リサイズ時にモデル位置を調整
      model.scale.set(LIVE2D_CONFIG.scale);
      model.x = app.renderer.width / 2 + LIVE2D_CONFIG.horizontalOffset;
      model.y = app.renderer.height / 2 + LIVE2D_CONFIG.verticalOffset;
    };

    window.addEventListener('resize', onResize);

    return () => {
      window.removeEventListener('resize', onResize);
    };
  }, [app, model]);

  return (
    <div ref={containerRef} className="w-full h-full relative">
      {error && (
        <div className="absolute top-4 left-4 bg-red-100 text-red-700 p-2 rounded z-10 text-xs">
          {error}
        </div>
      )}
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-gray-400 text-center">
            <div className="animate-pulse">
              <div className="w-24 h-24 bg-gray-200 rounded-full mx-auto mb-2"></div>
              <p className="text-xs">読み込み中...</p>
            </div>
          </div>
        </div>
      )}
      <canvas
        ref={canvasContainerRef}
        className="w-full h-full"
        style={{
          display: isLoading ? 'none' : 'block',
        }}
      />
    </div>
  );
};

export default Live2DHistoryComponent;