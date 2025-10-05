# =============================================
# 🚀 Laravel Sail + Docker + WSL2 完全自動構築スクリプト（冪等対応版）
# ---------------------------------------------
# ✅ 前提条件:
#   - Windows + Docker Desktop + WSL2 が導入済み
#   - このファイルは PowerShell (管理者権限) で実行
#   - GitHub リポジトリ: yuuki0508/laravel-inertia-template
# =============================================

# --- UTF-8出力対策 ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# --- 基本設定 ---
$repoUser = "yuuki0508"
$repoName = "laravel-inertia-template"
$ubuntuDistro = "Ubuntu"
$ubuntuRoot = "C:\WSL\$ubuntuDistro"
$ubuntuUrl = "https://cloud-images.ubuntu.com/wsl/jammy/current/ubuntu-jammy-wsl-amd64-ubuntu22.04lts.rootfs.tar.gz"
$setupUrl = "https://raw.githubusercontent.com/$repoUser/$repoName/main/setup.sh"
$setupFile = "$env:USERPROFILE\setup.sh"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " 🚀 Laravel Sail + Docker + WSL2 自動構築 開始 " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# --- Dockerチェック ---
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Desktop が見つかりません。インストールしてください。" -ForegroundColor Red
    exit 1
}

# --- WSL有効化チェック ---
$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ WSL2 が有効化されていません。再起動後に有効化してください。" -ForegroundColor Red
    exit 1
}

# --- Ubuntu の存在確認 ---
$existing = wsl -l -q | Select-String $ubuntuDistro
if (-not $existing) {
    Write-Host "⬇️ Ubuntuが見つかりません。手動でrootfsからインストールします..." -ForegroundColor Yellow

    # ディレクトリ作成
    if (-not (Test-Path $ubuntuRoot)) {
        New-Item -ItemType Directory -Path $ubuntuRoot | Out-Null
    }

    $ubuntuTar = "$env:TEMP\ubuntu.tar.gz"

    # rootfs ダウンロード
    Write-Host "🌐 Ubuntu rootfs をダウンロード中..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $ubuntuUrl -OutFile $ubuntuTar -UseBasicParsing

    # WSL インポート
    Write-Host "📦 Ubuntu rootfs をインポート中..." -ForegroundColor Cyan
    wsl --import $ubuntuDistro $ubuntuRoot $ubuntuTar --version 2

    Remove-Item $ubuntuTar -Force
    Write-Host "✅ Ubuntu のインポートが完了しました。" -ForegroundColor Green
} else {
    Write-Host "🟢 Ubuntu は既にインストールされています。スキップします。" -ForegroundColor Green
}

# --- setup.sh のダウンロード（安全・再実行対応） ---
Write-Host ""
Write-Host "📥 setup.sh をダウンロード中..." -ForegroundColor Cyan

# 古いファイル削除
Get-ChildItem -Path $env:USERPROFILE -Filter "setup.sh*" | Remove-Item -Force -ErrorAction SilentlyContinue

# 新規ダウンロード
Invoke-WebRequest -Uri $setupUrl -OutFile $setupFile -UseBasicParsing

# 不可視文字を除去
$newName = "$env:USERPROFILE\setup.sh"
Get-ChildItem $env:USERPROFILE | Where-Object { $_.Name -match "setup.sh" -and $_.Name -ne "setup.sh" } | ForEach-Object {
    Rename-Item $_.FullName $newName -Force
}

if (Test-Path $setupFile) {
    Write-Host "✅ setup.sh ダウンロード完了: $setupFile" -ForegroundColor Green
} else {
    Write-Host "❌ setup.sh のダウンロードに失敗しました。" -ForegroundColor Red
    exit 1
}

# --- プロジェクト名入力 ---
$projectName = Read-Host "作成するLaravelプロジェクト名を入力してください（例: my-project）"
if ([string]::IsNullOrWhiteSpace($projectName)) {
    $projectName = "my-project"
}

# --- WSL 内でのセットアップ ---
Write-Host ""
Write-Host "⚙️ Ubuntu 上で Laravel 環境を構築中..." -ForegroundColor Yellow

$escapedUser = $env:UserName.Replace("'", "''")
$escapedProjectName = $projectName.Replace("'", "''")

$wslCommands = @"
cd ~
if [ -d "$escapedProjectName" ]; then
    echo "⚠️ 既にプロジェクト '$escapedProjectName' が存在します。再構築はスキップします。"
    exit 0
fi

# setup.sh を配置して実行
mv /mnt/c/Users/$escapedUser/setup.sh ~/setup.sh
chmod +x ~/setup.sh
bash ~/setup.sh '$escapedProjectName'
"@

wsl -d $ubuntuDistro -e bash -c "$wslCommands"

# --- 完了メッセージ ---
Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "✅ すべてのセットアップが完了しました！" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "📍 次の手順:"
Write-Host "1️⃣  WSLを起動: wsl -d $ubuntuDistro"
Write-Host "2️⃣  プロジェクトへ移動: cd ~/$projectName"
Write-Host "3️⃣  開発サーバー起動: ./start.sh または npm run dev"
Write-Host ""
Write-Host "💡 もう一度このスクリプトを実行しても、既存環境を壊さず安全に再実行できます。" -ForegroundColor Cyan
