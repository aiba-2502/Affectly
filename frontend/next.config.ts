import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  // Turbopackの最新設定形式
  turbopack: {
    resolveAlias: {
      'pixi.js': 'pixi.js/dist/pixi.min.js',
    },
  },
  // 実験的機能の有効化
  experimental: {
    optimizeCss: true, // CSS最適化
    optimizePackageImports: ['pixi.js', 'pixi-live2d-display-lipsyncpatch'], // パッケージの最適化
  },
  // 画像の最適化
  images: {
    formats: ['image/avif', 'image/webp'],
  },
  // webpack設定でバンドルサイズを最適化
  webpack: (config, { isServer }) => {
    if (!isServer) {
      // クライアントサイドのバンドル最適化
      config.optimization = {
        ...config.optimization,
        splitChunks: {
          chunks: 'all',
          cacheGroups: {
            pixi: {
              test: /[\\/]node_modules[\\/](pixi\.js|pixi-live2d)[\\/]/,
              name: 'pixi-vendor',
              priority: 10,
            },
          },
        },
      };
    }
    return config;
  },
};

export default nextConfig;
