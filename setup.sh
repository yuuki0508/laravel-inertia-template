#!/usr/bin/env bash
set -e

# ================================
#  Laravel + Inertia + Vue 環境構築スクリプト (Docker完全依存)
#  動作環境: Ubuntu (WSL2) + Docker Desktop
# ================================

# --- UTF-8設定 ---
export LANG=C.UTF-8

# --- プロジェクト名の取得 ---
PROJECT_NAME=$1
if [ -z "$PROJECT_NAME" ]; then
  echo "🧩 プロジェクト名を指定してください。例："
  echo "  bash <(curl -fsSL https://raw.githubusercontent.com/yuuki0508/laravel-inertia-template/main/setup.sh) my-project"
  exit 1
fi

DEV_DIR="$HOME/develop"
PROJECT_DIR="$DEV_DIR/$PROJECT_NAME"

echo "=============================================="
echo "🚀 Laravel + Inertia + Vue 環境を構築します"
echo "=============================================="
echo ""
echo "📂 プロジェクト名: $PROJECT_NAME"
echo "📁 作成先: $PROJECT_DIR"
echo ""

# --- developディレクトリ確認 ---
if [ ! -d "$DEV_DIR" ]; then
  echo "📁 developディレクトリが存在しません。作成します..."
  mkdir -p "$DEV_DIR"
fi

# --- プロジェクトフォルダ確認 ---
if [ -d "$PROJECT_DIR" ]; then
  echo "⚠️ 既に同名のプロジェクトが存在します。削除して再作成しますか？ (y/n)"
  read -r CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    rm -rf "$PROJECT_DIR"
  else
    echo "🚫 中止しました。"
    exit 0
  fi
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# --- Laravelプロジェクト作成（Docker Composer使用） ---
echo ""
echo "🧱 Laravel プロジェクトを作成中..."
docker run --rm -v "$(pwd):/app" composer create-project laravel/laravel .

# --- Sail準備 ---
echo ""
echo "⚙️ Laravel Sail をインストール中..."
docker run --rm -v "$(pwd):/app" -w /app laravelsail/php84-composer:latest composer require laravel/sail --dev

# --- Sailセットアップ ---
echo ""
echo "⚙️ Sail 初期化中..."
./vendor/bin/sail install --with=mysql,redis,meilisearch,mailpit,selenium

# --- npm / Node環境構築 ---
echo ""
echo "📦 フロントエンド依存関係をインストール中..."
./vendor/bin/sail npm install
./vendor/bin/sail npm install vue @vitejs/plugin-vue laravel-vite-plugin
./vendor/bin/sail npm run build

# --- Inertia導入 ---
echo ""
echo "🔗 Inertia.js を導入中..."
./vendor/bin/sail composer require inertiajs/inertia-laravel
./vendor/bin/sail npm install @inertiajs/vue3
./vendor/bin/sail artisan inertia:middleware
./vendor/bin/sail artisan migrate

# --- アプリ起動 ---
echo ""
echo "🚀 Dockerコンテナを起動します..."
./vendor/bin/sail up -d

# --- 完了メッセージ ---
echo ""
echo "✅ セットアップが完了しました！"
echo "---------------------------------------------"
echo " プロジェクト: $PROJECT_NAME"
echo " URL: http://localhost"
echo " コンテナ起動: ./vendor/bin/sail up -d"
echo " 停止: ./vendor/bin/sail down"
echo " 再構築: ./vendor/bin/sail build --no-cache"
echo "---------------------------------------------"
