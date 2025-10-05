#!/bin/bash
set -e
PROJECT_NAME=${1:-laravel-app}
APP_PORT=${2:-80}
DB_PASSWORD="password"
DB_NAME="laravel"
PMA_PORT=8080
DEVELOP_DIR="$HOME/develop"
PROJECT_DIR="$DEVELOP_DIR/$PROJECT_NAME"

echo "============================================="
echo " 🚀 Laravel Sail + Inertia + Vue 自動構築"
echo "============================================="

# ---------- 前提チェック ----------
if ! command -v docker &> /dev/null; then
    echo "❌ Dockerが見つかりません。Docker Desktopをインストールしてください。"
    exit 1
fi

mkdir -p "$DEVELOP_DIR"
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  既に $PROJECT_DIR が存在します。削除して再実行するか、別名を指定してください。"
    exit 1
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ---------- Laravel新規作成 ----------
echo "📦 Laravel新規プロジェクトを作成中..."
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v $(pwd):/app \
  -w /app \
  laravelsail/php84-composer:latest \
  bash -c "composer create-project laravel/laravel ."

# ---------- Laravel Sail導入 ----------
echo "⚙️ Laravel Sailをインストール中..."
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v $(pwd):/app \
  -w /app \
  laravelsail/php84-composer:latest \
  bash -c "composer require laravel/sail --dev && php artisan sail:install --with=mysql,redis,mailpit"

# ---------- phpMyAdmin ----------
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

# ---------- Breeze + Vue + Inertia ----------
echo "✨ Laravel Breeze + Vue + Inertia を導入中..."

# ✅ Sailコンテナ起動前にBreezeをインストール
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v $(pwd):/app \
  -w /app \
  laravelsail/php84-composer:latest \
  bash -c "composer require laravel/breeze --dev"

# ✅ コンテナを起動
echo "🐳 Sailコンテナを起動中..."
./vendor/bin/sail up -d

# コンテナが完全に起動するまで待機
echo "⏳ データベース起動を待機中..."
sleep 10

# ✅ Viteバージョン互換性を事前に修正するためにpackage.jsonを取得
echo "🔧 Vite依存関係の事前修正..."
if [ -f "package.json" ]; then
    # 既存のpackage.jsonがあればViteバージョンを修正
    sed -i 's/"vite": "\^[0-9.]*"/"vite": "^6.0.0"/' package.json
fi

# ✅ Breeze インストール（Vue + Inertia）- npm installをスキップ
echo "🎨 Breezeをインストール中..."
./vendor/bin/sail artisan breeze:install vue --composer=global --no-interaction || true

# ✅ Breezeインストール後にpackage.jsonを再修正
echo "🔧 Viteバージョンを再調整中..."
sed -i 's/"vite": "\^7[0-9.]*"/"vite": "^6.0.0"/' package.json
sed -i 's/"@vitejs\/plugin-vue": "\^[0-9.]*"/"@vitejs\/plugin-vue": "^5.2.0"/' package.json

# ✅ Node 依存パッケージをクリーンインストール
echo "📦 Node.jsパッケージをインストール中..."
./vendor/bin/sail npm install --legacy-peer-deps

# ✅ 追加パッケージをインストール
echo "📦 追加パッケージをインストール中..."
./vendor/bin/sail npm install @inertiajs/progress ziggy-js --save --legacy-peer-deps

# ✅ Ziggy導入
echo "🗺️ Ziggyをインストール中..."
./vendor/bin/sail composer require tightenco/ziggy
./vendor/bin/sail artisan vendor:publish --tag=ziggy-config

# ---------- DB初期化 ----------
echo "🧱 データベースを初期化中..."
./vendor/bin/sail artisan key:generate
./vendor/bin/sail artisan migrate --seed

# ---------- ビルド ----------
echo "🏗️ フロントエンドをビルド中..."
./vendor/bin/sail npm run build

# ---------- 完了メッセージ ----------
echo ""
echo "============================================="
echo "✅ セットアップ完了！"
echo "============================================="
echo ""
echo "📁 プロジェクトディレクトリ: $PROJECT_DIR"
echo "🌐 アプリ:        http://localhost:${APP_PORT}"
echo "🗄️ phpMyAdmin:   http://localhost:${PMA_PORT} (root / ${DB_PASSWORD})"
echo ""
echo "🚀 次のステップ:"
echo "   cd $PROJECT_DIR"
echo "   ./vendor/bin/sail npm run dev"
echo ""
echo "💡 開発サーバー起動後、ブラウザで http://localhost:${APP_PORT} にアクセス"
echo ""