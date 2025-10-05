#!/bin/bash
set -e

# ================================
# Laravel Sail + Inertia + Vue 自動構築スクリプト（Docker専用）
# ================================

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
  -v $(pwd):/app \
  -w /app \
  laravelsail/php84-composer:latest \
  bash -c "composer create-project laravel/laravel ."

# ✅ ここで権限を修正！
sudo chown -R $USER:$USER "$PROJECT_DIR"

# ---------- Laravel Sail導入 ----------
echo "⚙️ Laravel Sailをインストール中..."
docker run --rm \
  -v $(pwd):/app \
  -w /app \
  laravelsail/php84-composer:latest \
  bash -c "composer require laravel/sail --dev && php artisan sail:install --with=mysql,redis,mailpit"

# 再度所有権修正（Dockerで生成されたものも対象）
sudo chown -R $USER:$USER "$PROJECT_DIR"

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
cp .env.example .env || sudo cp .env.example .env
sudo chown $USER:$USER .env

sed -i "s/DB_HOST=.*/DB_HOST=mysql/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=sail/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env
sed -i "s/APP_PORT=.*/APP_PORT=${APP_PORT}/" .env
sed -i "s/APP_NAME=.*/APP_NAME=\"${PROJECT_NAME}\"/" .env

# ---------- コンテナ起動 ----------
echo "🐳 Dockerコンテナを起動中..."
./vendor/bin/sail up -d

# ---------- Breeze + Vue + Inertia ----------
echo "✨ Laravel Breeze + Vue + Inertia を導入中..."
./vendor/bin/sail composer require laravel/breeze --dev
./vendor/bin/sail artisan breeze:install vue --inertia

./vendor/bin/sail npm install
./vendor/bin/sail npm install @inertiajs/progress ziggy-js --save
./vendor/bin/sail composer require tightenco/ziggy
./vendor/bin/sail artisan vendor:publish --tag=ziggy-config

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
