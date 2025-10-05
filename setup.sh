#!/usr/bin/env bash
set -euo pipefail

# ======================================================
# 🚀 Laravel Sail + Vue + Inertia 環境 自動構築スクリプト
# ======================================================

echo "============================================="
echo " 🚀 Laravel Sail + Docker + Inertia + Vue セットアップ"
echo "============================================="
echo ""

# --- 引数チェック ---
if [ $# -lt 1 ]; then
  read -rp "プロジェクト名を入力してください（例: my-app）: " PROJECT_NAME
else
  PROJECT_NAME=$1
fi

# --- 環境確認 ---
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Dockerがインストールされていません。Docker Desktopを導入してください。"
  exit 1
fi

if ! command -v wsl >/dev/null 2>&1; then
  echo "❌ WSL2環境が検出されません。Windowsの機能でWSL2を有効化してください。"
  exit 1
fi

# --- ディレクトリ設定 ---
WORK_DIR="$HOME/develop/$PROJECT_NAME"

echo "📁 プロジェクトディレクトリを作成します: $WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# --- Laravel プロジェクト作成 ---
if [ ! -d "$WORK_DIR/vendor" ]; then
  echo "🧱 Laravelプロジェクトを作成しています..."
  docker run --rm \
    -v "$(pwd)":/opt \
    -w /opt \
    laravelsail/php83-composer:latest \
    composer create-project laravel/laravel .
else
  echo "✅ Laravelは既にインストール済みのようです。"
fi

# --- Sailインストール ---
echo "⚙️ Sailをインストール中..."
docker run --rm \
  -v "$(pwd)":/opt \
  -w /opt \
  laravelsail/php83-composer:latest \
  composer require laravel/sail --dev

# --- Sailセットアップ ---
echo "🛠 Sailを初期化中..."
php artisan sail:install --with=mysql,redis,meilisearch,mailpit,selenium

# --- .env修正 ---
sed -i 's/DB_HOST=127.0.0.1/DB_HOST=mysql/' .env
sed -i 's/DB_PASSWORD=/DB_PASSWORD=password/' .env

# --- Sailビルド＆起動 ---
echo "🐳 Dockerコンテナを起動します (初回は数分かかります)..."
./vendor/bin/sail up -d --build

# --- Node.js & npmセットアップ ---
echo "🧩 Node.js + Vue + Inertiaを導入中..."
./vendor/bin/sail npm install vue @vitejs/plugin-vue laravel-vite-plugin inertia inertia-vue3
./vendor/bin/sail npm install

# --- 開発ビルド実行 ---
./vendor/bin/sail npm run build

# --- URL確認 ---
APP_PORT=80
echo ""
echo "============================================="
echo "✅ セットアップが完了しました！"
echo "---------------------------------------------"
echo "📂 プロジェクトディレクトリ: $WORK_DIR"
echo "🌐 アプリURL: http://localhost:$APP_PORT"
echo "🐘 PHPMyAdmin: http://localhost:8080 (root / password)"
echo "============================================="
