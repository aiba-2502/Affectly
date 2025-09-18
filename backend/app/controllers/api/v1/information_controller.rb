module Api
  module V1
    class InformationController < ApplicationController
      def index
        information = {
          app_name: "心のログ (Kokoro Log)",
          version: "1.0.0",
          description: "AIキャラクターとの対話を通じて、あなたの感情を記録・整理するアプリケーション",
          features: [
            {
              title: "感情の言語化",
              description: "AIキャラクターとの自然な対話を通じて、言葉にしにくい感情を表現できます",
              icon: "chat"
            },
            {
              title: "感情の記録",
              description: "日々の感情の変化を自動的に記録し、いつでも振り返ることができます",
              icon: "calendar"
            },
            {
              title: "感情の分析",
              description: "AIが対話内容を分析し、感情の傾向やパターンを可視化します",
              icon: "chart"
            },
            {
              title: "プライバシー保護",
              description: "すべての対話内容は安全に保護され、あなただけがアクセスできます",
              icon: "lock"
            }
          ],
          how_to_use: [
            {
              step: 1,
              title: "アカウント作成",
              description: "メールアドレスとパスワードで簡単に登録できます",
              details: [
                "トップページから「新規登録」をクリック",
                "必要情報を入力して登録",
                "確認メールが届いたら認証完了"
              ]
            },
            {
              step: 2,
              title: "対話を開始",
              description: "AIキャラクターとの対話を始めましょう",
              details: [
                "ホーム画面から「新しい対話を始める」をクリック",
                "今の気持ちや出来事を自由に話してください",
                "AIキャラクターが優しく応答します"
              ]
            },
            {
              step: 3,
              title: "感情を記録",
              description: "対話の内容は自動的に記録されます",
              details: [
                "対話中に感じた感情は自動的にタグ付けされます",
                "重要な対話にはメモを追加できます",
                "カレンダーから過去の対話を確認できます"
              ]
            },
            {
              step: 4,
              title: "振り返りと分析",
              description: "定期的に感情の変化を振り返りましょう",
              details: [
                "週次・月次のサマリーレポートを確認",
                "感情の傾向グラフで変化を可視化",
                "AIからのアドバイスを参考に自己理解を深める"
              ]
            }
          ],
          tips: [
            {
              title: "正直に話すことが大切",
              description: "AIキャラクターは判断しません。安心して本音を話してください。"
            },
            {
              title: "継続が力になる",
              description: "毎日少しずつでも対話を続けることで、自己理解が深まります。"
            },
            {
              title: "プライバシー設定を確認",
              description: "マイページから公開範囲やデータの扱いを設定できます。"
            }
          ],
          support: {
            email: "support@kokorolog.com",
            faq_url: "/faq",
            privacy_policy_url: "/privacy",
            terms_url: "/terms"
          }
        }

        render json: {
          status: "success",
          data: information
        }
      end
    end
  end
end
