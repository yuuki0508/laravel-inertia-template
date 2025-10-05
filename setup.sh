#!/bin/bash

set -e

echo "================================"
echo "🚀 Laravel Sail + Inertia + Vue + Tailwind 自動構築スクリプト"
echo "================================"
echo ""

# ==== 色定義 ====
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ==== ユーザー入力 ====
read -p "📦 プロジェクト名を入力してください (例: laravel-app): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-laravel-app}

read -p "🌐 アプリのポート番号を指定してください (例: 80): " APP_PORT
APP_PORT=${APP_PORT:-80}

read -p "🗄️ phpMyAdmin のポート番号を指定してください (例: 8080): " PMA_PORT
PMA_PORT=${PMA_PORT:-8080}

DB_PASSWORD="password"
DB_NAME="laravel"

echo ""
echo -e "${BLUE}----------------------------------------${NC}"
echo -e "📁 プロジェクト名: ${YELLOW}${PROJECT_NAME}${NC}"
echo -e "🌐 アプリポート:   ${YELLOW}${APP_PORT}${NC}"
echo -e "🗄️ phpMyAdmin:     ${YELLOW}${PMA_PORT}${NC}"
echo -e "${BLUE}----------------------------------------${NC}"
echo ""

# ==== ステップ1: Laravel 新規作成 ====
echo -e "${BLUE}[1/9] Laravel プロジェクト作成中...${NC}"
docker run --rm \
  -v $(pwd):/app \
  -w /app \
  laravelsail/php84-composer:latest bash -c "composer create-project laravel/laravel $PROJECT_NAME"

cd $PROJECT_NAME

# ==== ステップ2: Sail インストール ====
echo -e "${BLUE}[2/9] Laravel Sail 設定中...${NC}"
docker run --rm \
  -v $(pwd):/app \
  -w /app \
  laravelsail/php84-composer:latest bash -c "composer require laravel/sail --dev && php artisan sail:install --with=mysql,redis,mailhog"

# ==== ステップ3: phpMyAdmin を追加 ====
echo -e "${BLUE}[3/9] phpMyAdmin 設定中...${NC}"
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

# ==== ステップ4: .env 設定 ====
echo -e "${BLUE}[4/9] .env 設定を反映中...${NC}"
cp .env.example .env
sed -i "s/DB_HOST=.*/DB_HOST=mysql/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=sail/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env
sed -i "s/APP_PORT=.*/APP_PORT=${APP_PORT}/" .env
sed -i "s/APP_NAME=.*/APP_NAME=\"${PROJECT_NAME}\"/" .env

# ==== ステップ5: コンテナ起動 ====
echo -e "${BLUE}[5/9] Docker コンテナ起動中...${NC}"
./vendor/bin/sail up -d

# ==== ステップ6: Breeze + Vue + Inertia + Tailwind + Ziggy ====
echo -e "${BLUE}[6/9] Breeze + Vue + Inertia + Tailwind + Ziggy を設定中...${NC}"
./vendor/bin/sail composer require laravel/breeze --dev
./vendor/bin/sail artisan breeze:install vue --inertia --no-interaction
./vendor/bin/sail composer require tightenco/ziggy
./vendor/bin/sail npm install
./vendor/bin/sail npm install @inertiajs/progress ziggy-js --save
./vendor/bin/sail npx tailwindcss init -p

# ==== ステップ7: Tailwind 設定 ====
echo -e "${BLUE}[7/9] Tailwind CSS 設定中...${NC}"
cat > tailwind.config.js <<'EOF'
import defaultTheme from 'tailwindcss/defaultTheme';
import forms from '@tailwindcss/forms';

export default {
    content: [
        './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
        './storage/framework/views/*.php',
        './resources/views/**/*.blade.php',
        './resources/js/**/*.vue',
    ],
    theme: {
        extend: {
            fontFamily: {
                sans: ['Figtree', ...defaultTheme.fontFamily.sans],
            },
        },
    },
    plugins: [forms],
};
EOF

# ==== ステップ8: サンプルページ作成 ====
echo -e "${BLUE}[8/9] サンプルページを作成中...${NC}"
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

# ==== ステップ9: DB初期化 ====
echo -e "${BLUE}[9/9] データベース初期化中...${NC}"
./vendor/bin/sail artisan key:generate
./vendor/bin/sail artisan migrate --seed

# ==== 完了メッセージ ====
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ セットアップ完了！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "📁 プロジェクト: $(pwd)"
echo ""
echo "🌐 アクセス情報:"
echo "  - アプリケーション: http://localhost:${APP_PORT}/sample"
echo "  - phpMyAdmin:        http://localhost:${PMA_PORT} (root / ${DB_PASSWORD})"
echo ""
echo "🚀 開発サーバーの起動:"
echo "  cd $(pwd)"
echo "  ./vendor/bin/sail npm run dev"
echo ""
echo "🧭 よく使うコマンド:"
echo "  sail up -d      # コンテナ起動"
echo "  sail down       # コンテナ停止"
echo "  sail artisan    # Artisanコマンド"
echo "  sail composer   # Composerコマンド"
echo "  sail npm        # NPMコマンド"
echo ""
echo "💡 再起動時は 'sail up -d' だけでOKです"
echo ""
