import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface NotificationStore {
  showAnalysisNotification: boolean;
  lastNotificationTime: string | null;
  notificationDismissed: boolean;
  setShowAnalysisNotification: (show: boolean) => void;
  dismissNotification: () => void;
  checkAndShowNotification: (needsAnalysis: boolean) => void;
  resetNotificationState: () => void;
}

export const useNotificationStore = create<NotificationStore>()(
  persist(
    (set, get) => ({
      showAnalysisNotification: false,
      lastNotificationTime: null,
      notificationDismissed: false,

      setShowAnalysisNotification: (show) => {
        set({
          showAnalysisNotification: show,
          lastNotificationTime: show ? new Date().toISOString() : get().lastNotificationTime
        });
      },

      dismissNotification: () => {
        set({
          showAnalysisNotification: false,
          notificationDismissed: true
        });
      },

      checkAndShowNotification: (needsAnalysis) => {
        const state = get();

        // AI分析が必要で、まだ通知を表示していない場合
        if (needsAnalysis && !state.notificationDismissed) {
          // 最後の通知から5分以上経過している場合のみ表示
          const lastTime = state.lastNotificationTime ? new Date(state.lastNotificationTime) : null;
          const now = new Date();
          const fiveMinutes = 5 * 60 * 1000;

          if (!lastTime || (now.getTime() - lastTime.getTime() > fiveMinutes)) {
            set({
              showAnalysisNotification: true,
              lastNotificationTime: now.toISOString(),
              notificationDismissed: false
            });
          }
        } else if (!needsAnalysis) {
          // AI分析が不要になったらリセット
          set({
            showAnalysisNotification: false,
            notificationDismissed: false
          });
        }
      },

      resetNotificationState: () => {
        set({
          showAnalysisNotification: false,
          lastNotificationTime: null,
          notificationDismissed: false
        });
      }
    }),
    {
      name: 'notification-storage',
      partialize: (state) => ({
        lastNotificationTime: state.lastNotificationTime,
        notificationDismissed: state.notificationDismissed
      })
    }
  )
);