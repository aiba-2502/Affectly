'use client';

import { useEffect, useRef, useState } from 'react';
import type { Application, DisplayObject } from 'pixi.js';

const Live2DComponent = () => {
  const canvasContainerRef = useRef<HTMLCanvasElement>(null);
  const [app, setApp] = useState<Application | null>(null);
  const [model, setModel] = useState<any>(null);
  const modelRef = useRef<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Dynamic imports for client-side only
    const setupLive2D = async () => {
      try {
        // Load Cubism Core first (try CDN)
        if (!(window as any).Live2DCubismCore) {
          const script = document.createElement('script');
          // Try to load from CDN first, fallback to local
          script.src = 'https://cubism.live2d.com/sdk-web/cubismcore/live2dcubismcore.min.js';
          script.async = true;
          
          try {
            await new Promise((resolve, reject) => {
              script.onload = resolve;
              script.onerror = () => {
                // Fallback to local file
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
    if (!canvasContainerRef.current) return;

    try {
      const { Application } = await import('pixi.js');
      
      const newApp = new Application({
        width: window.innerWidth,
        height: window.innerHeight,
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
      
      // デフォルトのポジション設定
      const scale = 0.3;
      newModel.scale.set(scale);
      newModel.x = currentApp.renderer.width / 2;
      newModel.y = currentApp.renderer.height / 2;

      modelRef.current = newModel;
      setModel(newModel);
      setIsLoading(false);
      
      console.log('Live2D model loaded successfully');
    } catch (error) {
      console.error('Failed to load Live2D model:', error);
      setError(`Failed to load Live2D model: ${error instanceof Error ? error.message : String(error)}`);
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (!app || !model) return;

    const onResize = () => {
      if (!canvasContainerRef.current) return;

      app.renderer.resize(
        canvasContainerRef.current.clientWidth,
        canvasContainerRef.current.clientHeight
      );

      // リサイズ時にモデル位置を調整
      const scale = 0.3;
      model.scale.set(scale);
      model.x = app.renderer.width / 2;
      model.y = app.renderer.height / 2;
    };

    window.addEventListener('resize', onResize);

    return () => {
      window.removeEventListener('resize', onResize);
    };
  }, [app, model]);

  return (
    <div className="w-screen h-screen fixed top-0 left-0 pointer-events-none">
      {error && (
        <div className="absolute top-4 left-4 bg-red-100 text-red-700 p-2 rounded">
          {error}
        </div>
      )}
      {isLoading && (
        <div className="absolute top-4 right-4 bg-blue-100 text-blue-700 p-2 rounded">
          Loading Live2D...
        </div>
      )}
      <canvas
        ref={canvasContainerRef}
        className="w-full h-full"
        style={{ pointerEvents: 'auto' }}
        onContextMenu={(e) => e.preventDefault()}
      />
    </div>
  );
};

export default Live2DComponent;