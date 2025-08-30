#!/bin/bash

# スワップメモリ設定スクリプト for Amazon Linux 2023
# t3.micro (1GB RAM) 用に2GBのスワップを作成

echo "===== スワップメモリ設定開始 ====="

# 既存のスワップを確認
echo "現在のスワップ状況:"
free -h

# スワップファイルが既に存在する場合は終了
if [ -f /swapfile ]; then
    echo "スワップファイルは既に存在します"
    exit 0
fi

# 2GBのスワップファイルを作成
echo "2GBのスワップファイルを作成中..."
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048

# パーミッションを設定
sudo chmod 600 /swapfile

# スワップ領域として設定
sudo mkswap /swapfile

# スワップを有効化
sudo swapon /swapfile

# 起動時に自動的にスワップを有効にする
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# スワップの設定を調整（メモリ不足時により積極的にスワップを使用）
echo "vm.swappiness=60" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf

# 設定を反映
sudo sysctl -p

echo "===== スワップメモリ設定完了 ====="
echo "新しいスワップ状況:"
free -h