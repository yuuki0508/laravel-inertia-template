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

## 実行方法

bash <(curl -fsSL https://raw.githubusercontent.com/yuuki0508/laravel-inertia-template/main/setup.sh) my-project
