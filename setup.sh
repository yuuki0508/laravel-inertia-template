#!/bin/bash
set -e

# ==============================
# Laravel Sail + Inertia + Vue 自動セットアップ
# ==============================

# --- カラー定義 ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo -e " 🚀 Laravel Sail + Vue + Inertia セットアップ開始"
echo -e "==========================================${NC}"

# --- 前提チェック ---
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠ Docker がインストールされていません。Docker Desktop をインストールしてください。${NC}"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}⚠ Git がインストールされていません。sudo apt install git を実行してください。${NC}"
    exit 1
fi

# --- プロジェクト名を取得 ---
if [ -z "$1" ]; then
    read -p "新しい Laravel プロジェクト名を入力してください: " PROJECT_NAME
else
    PROJECT_NAME=$1
fi

BASE_DIR=~/develop
PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

echo -e "${BLUE}📁 プロジェクトディレクトリを作成: ${PROJECT_DIR}${NC}"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# --- Laravel プロジェクト作成 ---
echo -e "${BLUE}[1/6] Laravel プロジェクトを作成中...${NC}"
docker run --rm \
    -v $(pwd):/app \
    -w /app \
    laravelsail/php84-composer:latest bash -c "composer create-project laravel/laravel ."

# --- Sail を導入 ---
echo -e "${BLUE}[2/6] Laravel Sail をインストール中...${NC}"
docker run --rm \
    -v $(pwd):/app \
    -w /app \
    laravelsail/php84-composer:latest bash -c "composer require laravel/sail --dev && php artisan sail:install --with=mysql,redis,mailpit"

# --- Sailエイリアス登録 ---
if ! grep -q "alias sail=" ~/.bashrc; then
    echo "alias sail='[ -f sail ] && sh sail || sh vendor/bin/sail'" >> ~/.bashrc
    echo -e "${GREEN}✅ Sail エイリアスを追加しました${NC}"
fi
source ~/.bashrc

# --- .envを設定 ---
echo -e "${BLUE}[3/6] 環境設定中 (.env)...${NC}"
cp .env.example .env
sed -i "s/DB_HOST=.*/DB_HOST=mysql/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=sail/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=password/" .env
sed -i "s/APP_NAME=.*/APP_NAME=\"$PROJECT_NAME\"/" .env

# --- Sailユーザー設定（権限対策）---
echo -e "${BLUE}[4/6] 権限対策を適用中...${NC}"
export SAIL_USER=$(id -u):$(id -g)
sudo chown -R $USER:$USER .

# --- コンテナ起動 ---
echo -e "${BLUE}[5/6] Docker コンテナを起動中...${NC}"
./vendor/bin/sail up -d --build

# --- Laravel Breeze + Inertia + Vue インストール ---
echo -e "${BLUE}[6/6] Breeze + Inertia + Vue を導入中...${NC}"
./vendor/bin/sail composer require laravel/breeze --dev
./vendor/bin/sail artisan breeze:install vue --inertia
./vendor/bin/sail npm install
./vendor/bin/sail npm run build
./vendor/bin/sail artisan migrate

# --- 権限の最終調整 ---
sudo chown -R $USER:$USER .

echo -e "${GREEN}"
echo "=========================================="
echo "✅ Laravel Sail + Inertia + Vue セットアップ完了！"
echo "=========================================="
echo ""
echo "📍 プロジェクトパス: $PROJECT_DIR"
echo "🌐 アプリURL: http://localhost"
echo "💾 DB: mysql / sail / password"
echo ""
echo "開発を始めるには:"
echo "  cd $PROJECT_DIR"
echo "  ./vendor/bin/sail npm run dev"
echo ""
echo "コンテナ起動コマンド:"
echo "  ./vendor/bin/sail up -d"
echo -e "${NC}"
