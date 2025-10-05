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

# ✅ Breeze インストール（PHPファイルのみ、npm installはスキップ）
echo "🎨 Breezeをインストール中（PHP部分のみ）..."
set +e  # 一時的にエラーで停止しないようにする
./vendor/bin/sail artisan breeze:install vue --composer=global --no-interaction
BREEZE_EXIT_CODE=$?
set -e  # エラーで停止する設定を戻す

if [ $BREEZE_EXIT_CODE -ne 0 ]; then
    echo "⚠️ Breezeインストールでエラーが発生しましたが、続行します..."
fi

echo ""
echo "⏳ Breezeインストール完了を確認中..."
sleep 3

# ✅ package.jsonとnode_modulesを一旦削除して、依存関係を手動で再構築
echo "🧹 Node関連ファイルをクリーンアップ中..."
rm -f package-lock.json
rm -rf node_modules

# ✅ package.jsonを直接書き換えて互換性のあるバージョンを指定
echo "📝 package.jsonを最適化中..."
cat > package.json <<'PACKAGE_JSON'
{
    "private": true,
    "type": "module",
    "scripts": {
        "dev": "vite",
        "build": "vite build"
    },
    "devDependencies": {
        "@inertiajs/vue3": "^2.0.0",
        "@tailwindcss/forms": "^0.5.3",
        "@vitejs/plugin-vue": "^5.2.0",
        "autoprefixer": "^10.4.12",
        "axios": "^1.7.4",
        "laravel-vite-plugin": "^1.0.0",
        "postcss": "^8.4.31",
        "tailwindcss": "^3.2.1",
        "vite": "^5.0.0",
        "vue": "^3.4.0"
    },
    "dependencies": {
        "@inertiajs/progress": "^0.2.7",
        "ziggy-js": "^2.4.0"
    }
}
PACKAGE_JSON

echo "✅ package.json作成完了"
cat package.json

# ✅ Node 依存パッケージをクリーンインストール
echo ""
echo "📦 Node.jsパッケージをインストール中..."
./vendor/bin/sail npm install

if [ ! -d "node_modules" ]; then
    echo "❌ node_modulesの作成に失敗しました"
    exit 1
fi

echo "✅ Node.jsパッケージインストール完了"

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
echo "🚀 開発サーバーを起動するには:"
echo "   cd $PROJECT_DIR"
echo "   ./vendor/bin/sail npm run dev"
echo ""
echo "💡 ブラウザで http://localhost:${APP_PORT} にアクセスしてください"
echo ""