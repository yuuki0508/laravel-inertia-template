#!/bin/bash
set -e

# ================================
# Laravel Sail + Inertia + Vue 自動構築スクリプト（Docker専用）
# ================================

# ---------- 設定 ----------
PROJECT_NAME=${1:-laravel-app}
APP_PORT=${2:-80}
DB_PASSWORD="password"
DB_NAME="laravel"
PMA_PORT=8080
DEVELOP_DIR="$HOME/develop"
PROJECT_DIR="$DEVELOP_DIR/$PROJECT_NAME"

# ---------- 初期表示 ----------
echo "============================================="
echo " 🚀 Laravel Sail + Inertia + Vue 自動構築"
echo "============================================="
echo "📁 プロジェクト名 : $PROJECT_NAME"
echo "🌐 アプリポート   : $APP_PORT"
echo "🗄️  DBパスワード  : $DB_PASSWORD"
echo ""

# ---------- 前提チェック ----------
if ! command -v docker &> /dev/null; then
    echo "❌ Dockerが見つかりません。Docker Desktopをインストールしてください。"
    exit 1
fi

# developフォルダ確認
if [ ! -d "$DEVELOP_DIR" ]; then
    echo "📂 developフォルダが見つかりません。作成します。"
    mkdir -p "$DEVELOP_DIR"
fi

# 既存プロジェクトチェック
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  既に $PROJECT_DIR が存在します。削除して再実行するか、別名を指定してください。"
    exit 1
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ---------- Laravel新規作成（DockerでComposer実行） ----------
echo "📦 Laravel新規プロジェクトを作成中..."
docker run --rm \
  -v $(pwd):/app \
  -w /app \
  laravelsail/php84-composer:latest bash -c "composer create-project laravel/laravel ."

# ---------- Laravel Sail導入 ----------
echo "⚙️ Laravel Sailをインストール中..."
docker run --rm \
  -v $(pwd):/app \
  -w /app \
  laravelsail/php84-composer:latest bash -c "composer require laravel/sail --dev && php artisan sail:install --with=mysql,redis,mailpit"

# ---------- phpMyAdmin追加 ----------
cat > docker-compose.override.yml <<EOF
version: '3'
services:
  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    ports:
      - "${PMA_PORT}:80"
    environment:
      PMA_HOST: mysql
      PMA_USER: root
      PMA_PASSWORD: ${DB_PASSWORD}
    networks:
      - sail
EOF

# ---------- 環境設定 ----------
echo "🔧 .env設定を調整中..."
cp .env.example .env
sed -i "s/DB_HOST=.*/DB_HOST=mysql/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=sail/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env
sed -i "s/APP_PORT=.*/APP_PORT=${APP_PORT}/" .env
sed -i "s/APP_NAME=.*/APP_NAME=\"${PROJECT_NAME}\"/" .env

# ---------- コンテナ起動 ----------
echo "🐳 Dockerコンテナを起動中..."
./vendor/bin/sail up -d

# ---------- Breeze + Vue + Inertia + Ziggy ----------
echo "✨ Laravel Breeze + Vue + Inertia を導入中..."
./vendor/bin/sail composer require laravel/breeze --dev
./vendor/bin/sail artisan breeze:install vue --inertia

echo "📦 依存パッケージをインストール中..."
./vendor/bin/sail npm install
./vendor/bin/sail npm install @inertiajs/progress ziggy-js --save

# ---------- Ziggy設定 ----------
echo "🧭 Ziggy設定を追加中..."
./vendor/bin/sail composer require tightenco/ziggy
./vendor/bin/sail artisan vendor:publish --tag=ziggy-config

# ---------- サンプルページ ----------
mkdir -p resources/js/Pages/Sample resources/js/Components

cat > resources/js/Pages/Sample/Index.vue <<'EOF'
<template>
  <div class="p-8">
    <h1 class="text-2xl font-bold text-indigo-600">🎉 サンプルページ</h1>
    <p class="mt-2">このページは Inertia + Vue.js + Tailwind によって描画されています。</p>
    <SampleComponent />
  </div>
</template>

<script setup>
import SampleComponent from '@/Components/SampleComponent.vue';
</script>
EOF

cat > resources/js/Components/SampleComponent.vue <<'EOF'
<template>
  <div class="mt-4 p-4 bg-gray-100 rounded-xl">
    <p class="text-gray-700">✅ これはサンプルコンポーネントです。</p>
    <button 
      @click="count++"
      class="mt-2 px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 transition">
      カウント: {{ count }}
    </button>
  </div>
</template>

<script setup>
import { ref } from 'vue';
const count = ref(0);
</script>
EOF

cat >> routes/web.php <<'EOF'

use Inertia\Inertia;
use Illuminate\Support\Facades\Route;

Route::get('/sample', function () {
    return Inertia::render('Sample/Index');
})->name('sample');
EOF

# ---------- DB初期化 ----------
echo "🧱 データベースを初期化中..."
./vendor/bin/sail artisan key:generate
./vendor/bin/sail artisan migrate --seed

# ---------- 完了メッセージ ----------
echo ""
echo "✅ セットアップ完了！"
echo ""
echo "📁 プロジェクトディレクトリ: $PROJECT_DIR"
echo "🌐 アプリ:        http://localhost:${APP_PORT}/sample"
echo "🗄️ phpMyAdmin:   http://localhost:${PMA_PORT} (root / ${DB_PASSWORD})"
echo ""
echo "🚀 開発サーバー起動コマンド:"
echo "  cd $PROJECT_DIR"
echo "  ./vendor/bin/sail npm run dev"
