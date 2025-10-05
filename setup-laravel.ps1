# =============================================
# 🚀 Laravel Sail + Docker + WSL2 環境 完全自動構築スクリプト
# =============================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "🐳 Laravel Sail + Docker + WSL2 自動構築を開始します..." -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ===== Docker Desktop チェック =====
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Desktop が見つかりません。インストールしてください。" -ForegroundColor Red
    exit 1
}

# ===== WSL 状態確認 =====
$wslStatus = wsl --status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ WSL2 が有効化されていません。有効化して再試行してください。" -ForegroundColor Red
    exit 1
}

# ===== Ubuntu rootfs インポート方式 =====
$ubuntuName = "Ubuntu"
$ubuntuDir = "C:\WSL\$ubuntuName"
$ubuntuTar = "$env:USERPROFILE\Downloads\ubuntu-jammy-rootfs.tar.gz"
$ubuntuUrl = "https://cloud-images.ubuntu.com/wsl/jammy/current/ubuntu-jammy-wsl-amd64-ubuntu22.04lts.rootfs.tar.gz"



$existing = wsl --list --quiet | Select-String $ubuntuName
if (-not $existing) {
    Write-Host "🐧 Ubuntuが未インストールのため、自動導入を開始します..." -ForegroundColor Yellow

    if (-not (Test-Path $ubuntuDir)) {
        Write-Host "📂 ディレクトリ作成中: $ubuntuDir" -ForegroundColor DarkGray
        New-Item -ItemType Directory -Path $ubuntuDir | Out-Null
    }

    if (-not (Test-Path $ubuntuTar)) {
        Write-Host "⬇️ Ubuntu rootfsをダウンロード中..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $ubuntuUrl -OutFile $ubuntuTar
    } else {
        Write-Host "🟢 既存のrootfsを再利用します。" -ForegroundColor Green
    }

    Write-Host "📦 Ubuntu rootfsをインポート中..." -ForegroundColor Cyan
    wsl --import $ubuntuName $ubuntuDir $ubuntuTar --version 2

    Write-Host "✅ Ubuntu の登録が完了しました！" -ForegroundColor Green
} else {
    Write-Host "🟢 既に Ubuntu が登録されています。" -ForegroundColor Green
}

wsl --set-default $ubuntuName | Out-Null
Write-Host "⚙️ Ubuntu を既定ディストリビューションに設定しました。" -ForegroundColor Gray

# ===== プロジェクト情報入力 =====
Write-Host ""
$projectName = Read-Host "🔧 プロジェクト名を入力してください（例: my-app）"
if ([string]::IsNullOrWhiteSpace($projectName)) { $projectName = "laravel-app" }

$port = Read-Host "🌐 使用するポート番号を入力してください（例: 80）"
if ([string]::IsNullOrWhiteSpace($port)) { $port = 80 }

Write-Host ""
Write-Host "✅ プロジェクト設定: $projectName / Port $port" -ForegroundColor Green
Write-Host ""

# ===== setup.sh を Ubuntu 上で実行 =====
$setupUrl = "https://raw.githubusercontent.com/yuuki0508/laravel-inertia-template/main/setup.sh"

$wslCommands = @"
cd ~
echo '⬇️ セットアップスクリプトをダウンロード中...'
curl -fsSL $setupUrl -o setup.sh
chmod +x setup.sh
bash setup.sh '$projectName' '$port'
"@

Write-Host "⚙️ Ubuntu上でセットアップを実行中..." -ForegroundColor Yellow
wsl -d $ubuntuName -e bash -c $wslCommands

# ===== 完了メッセージ =====
Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "✅ すべて完了しました！" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "次のステップ:" -ForegroundColor Cyan
Write-Host "1️⃣  WSLを起動: wsl -d $ubuntuName" -ForegroundColor White
Write-Host "2️⃣  プロジェクトへ移動: cd ~/$projectName" -ForegroundColor White
Write-Host "3️⃣  サーバー起動: npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "または一発起動:" -ForegroundColor Cyan
Write-Host "wsl -d $ubuntuName -e bash -c 'cd ~/$projectName && ./start.sh'" -ForegroundColor White
Write-Host ""
Write-Host "🌐 LaravelアプリURL: http://localhost:$port" -ForegroundColor Green
Write-Host "---------------------------------------------" -ForegroundColor Gray
