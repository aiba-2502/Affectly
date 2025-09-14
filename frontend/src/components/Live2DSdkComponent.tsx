'use client';

import { LAppDelegate } from '@/lib/live2d/demo/lappdelegate';
import { LAppGlManager } from '@/lib/live2d/demo/lappglmanager';
import { useEffect, useRef, useCallback } from 'react';

function Live2DSdkComponent() {
  const ref = useRef<HTMLCanvasElement | null>(null);
  const delegateRef = useRef<LAppDelegate | null>(null);

  // resizeView をuseCallbackでメモ化
  const resizeView = useCallback(() => {
    if (delegateRef.current) {
      delegateRef.current.onResize();
    }
  }, []);

  useEffect(() => {
    if (ref.current) {
      // Canvas要素を設定
      LAppGlManager.setCanvas(ref.current);

      // LAppDelegateのインスタンスを取得して初期化
      const appDelegateInstance = LAppDelegate.getInstance();
      if (appDelegateInstance.initialize()) {
        appDelegateInstance.run();
        delegateRef.current = appDelegateInstance;
      }

      // リサイズイベントリスナーを追加
      window.addEventListener('resize', resizeView);
    }

    // クリーンアップ
    return () => {
      LAppDelegate.releaseInstance();
      window.removeEventListener('resize', resizeView);
    };
  }, [resizeView]);

  return (
    <div id="live2d-container" className="w-screen h-screen fixed top-0 left-0 pointer-events-none z-0">
      <canvas
        ref={ref}
        className="w-full h-full"
        style={{ pointerEvents: 'auto' }}
      />
    </div>
  );
}

export default Live2DSdkComponent;