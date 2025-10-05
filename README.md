# 🚀 Laravel Inertia Template 環境構築ガイド

このリポジトリは **Ubuntu + Docker Desktop** 環境で  
「Laravel + Inertia + Vue + Tailwind + Sail」 を  
**自動構築** するスクリプトを提供します。

---

## ✅ 前提条件

以下がインストールされていることを確認してください：

| ツール | 確認方法 | 備考 |
|--------|-----------|------|
| Docker Desktop | Windowsにインストール済 | WSL2統合を有効にする |
| Ubuntu (WSL2) | `wsl -l` で確認 | 例: `Ubuntu` が存在すること |
| Git | `git --version` | Ubuntuにインストール済 |
| Curl | `curl --version` | Ubuntuにインストール済 |

また、Ubuntu内に以下ディレクトリが存在することを確認してください：
```bash
mkdir -p ~/develop

# === Laravel + Sail + Inertia 環境を自動構築 ===
# Ubuntu（WSL2）ターミナルで以下を実行

curl -LfsS https://raw.githubusercontent.com/yuuki0508/laravel-inertia-template/main/setup.sh | bash -s my-project

もし改行コードエラーが出た場合は

curl -LfsS -H "Cache-Control: no-cache" https://raw.githubusercontent.com/yuuki0508/laravel-inertia-template/main/setup.sh | bash -s my-project

スクリプトを修正しても変わらない場合は

curl -H "Cache-Control: no-cache"

を実行する


インストールログが最後まで出なかった場合は以下を実行する

# クリーンインストール
rm -rf node_modules package-lock.json
./vendor/bin/sail npm install

# 残りの手順
./vendor/bin/sail composer require tightenco/ziggy
./vendor/bin/sail artisan vendor:publish --tag=ziggy-config
./vendor/bin/sail artisan key:generate
./vendor/bin/sail artisan migrate --seed
./vendor/bin/sail npm run build
./vendor/bin/sail npm run dev


## 削除手順

まずは必ずコンテナを停止させる。

cd ~/develop/my-project
./vendor/bin/sail down

次にディレクトリごと削除する

cd ~/develop
sudo rm -rf my-project

