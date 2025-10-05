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



## 削除手順

まずは必ずコンテナを停止させる。

cd ~/develop/my-project
./vendor/bin/sail down

次にディレクトリごと削除する

cd ~/develop
sudo rm -rf my-project

