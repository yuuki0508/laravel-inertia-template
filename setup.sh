#!/bin/bash
set -e

# ===== 初期設定 =====
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE} Laravel Sail + Inertia + Vue 自動構築 ${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# ===== プロジェクト名の取得 =====
if [ -z "$1" ]; then
    read -p "プロジェクト名を入力してください: " PROJECT_NAME
else
    PROJECT_NAME=$1
fi
if [ -z "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}⚠️ プロジェクト名が指定されていません。中止します。${NC}"
    exit 1
fi

# ===== developディレクトリの確認 =====
DEV_DIR="$HOME/develop"
mkdir -p "$DEV_DIR"
cd "$DEV_DIR"

# ===== プロジェクトディレクトリ作成 =====
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}⚠️ 既に $PROJECT_NAME ディレクトリが存在します。再利用します。${NC}"
else
    mkdir "$PROJECT_NAME"
    echo -e "${GREEN}✅ $PROJECT_NAME ディレクトリを作成しました${NC}"
fi
cd "$PROJECT_NAME"

# ===== 必要ツール確認 =====
echo -e "${BLUE}[1/8] ツール確認中...${NC}"
for cmd in docker docker-compose curl git; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}$cmd が見つかりません。インストールしてください。${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ 必要ツール確認完了${NC}"

# ===== Laravel プロジェクト作成 =====
if [ ! -f "artisan" ]; then
    echo -e "${BLUE}[2/8] Laravel プロジェクト作成中...${NC}"
    docker run --rm \
      -v $(pwd):/app \
      -w /app \
      laravelsail/php84-composer:latest bash -c "composer create-project laravel/laravel ."
else
    echo -e "${YELLOW}⚠️ Laravel は既に作成済みです。${NC}"
fi

# ===== Sail 設定 =====
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${BLUE}[3/8] Laravel Sail セットアップ中...${NC}"
    docker run --rm \
      -v $(pwd):/app \
      -w /app \
      laravelsail/php84-composer:latest bash -c "composer require laravel/sail --dev && php artisan sail:install --with=mysql,redis,mailpit"
fi

# ===== .env設定 =====
echo -e "${BLUE}[4/8] 環境設定中...${NC}"
cp -n .env.example .env || true
sed -i "s/APP_NAME=.*/APP_NAME=\"$PROJECT_NAME\"/" .env
sed -i "s/DB_HOST=.*/DB_HOST=mysql/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=password/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=sail/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=laravel/" .env

# ===== コンテナ起動 =====
echo -e "${BLUE}[5/8] Docker コンテナを起動中...${NC}"
./vendor/bin/sail up -d

# ===== Breeze + Inertia + Vue =====
if [ ! -d "resources/js/Pages" ]; then
    echo -e "${BLUE}[6/8] Laravel Breeze + Inertia + Vue セットアップ中...${NC}"
    ./vendor/bin/sail composer require laravel/breeze --dev
    ./vendor/bin/sail artisan breeze:install vue --no-interaction
    ./vendor/bin/sail npm install
fi

# ===== Ziggy設定 =====
echo -e "${BLUE}[7/8] Ziggy 設定中...${NC}"
./vendor/bin/sail composer require tightenco/ziggy
./vendor/bin/sail artisan vendor:publish --tag=ziggy-config --force || true

# ===== 初期マイグレーション =====
echo -e "${BLUE}[8/8] データベース初期化中...${NC}"
sleep 5
./vendor/bin/sail artisan migrate --force

# ===== 完了 =====
cat > start.sh <<'EOF'
#!/bin/bash
./vendor/bin/sail up -d
./vendor/bin/sail npm run dev
EOF
chmod +x start.sh

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}🎉 セットアップ完了！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "📁 パス: ~/develop/$PROJECT_NAME"
echo "🌐 アプリ: http://localhost"
echo "📬 Mailpit: http://localhost:8025"
echo ""
echo "次回起動コマンド:"
echo "  cd ~/develop/$PROJECT_NAME && ./start.sh"
echo ""
