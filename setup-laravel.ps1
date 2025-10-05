# --- UTF-8文字化け対策 ---
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
# -------------------------

<#
.SYNOPSIS
  Laravel Sail + Vue + Inertia 環境 自動構築スクリプト
.DESCRIPTION
  Windows + Docker Desktop + WSL2 がセットアップされていれば、
  このスクリプト1本でLaravel Sail環境を自動構築します。
  Ubuntuが未導入の場合は自動で導入します。
.PARAMETER ProjectName
  Laravelプロジェクト名（デフォルト: laravel-app）
.PARAMETER Port
  Webアプリケーションのポート番号（デフォルト: 80）
.EXAMPLE
  iwr -useb https://raw.githubusercontent.com/yuuki0508/laravel-inertia-template/main/setup-laravel1.ps1 | iex
#>

$ProjectName = "laravel-app"
$Port = 80

$ErrorActionPreference = "Stop"

function Write-Section($text) {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host " $text" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
}

Write-Section "🚀 Laravel Sail + Docker + WSL2 自動構築スクリプト 開始"

# ===== パラメータ入力 =====
if (-not $ProjectName) {
    $ProjectName = Read-Host "プロジェクト名を入力してください（例: my-project）"
    if ([string]::IsNullOrWhiteSpace($ProjectName)) { $ProjectName = "laravel-app" }
}

if (-not $Port) {
    $Port = Read-Host "アプリのポート番号を入力してください（デフォルト: 80）"
    if ([string]::IsNullOrWhiteSpace($Port)) { $Port = 80 }
}

# ===== Docker チェック =====
Write-Host "`n🔍 Docker Desktop を確認中..." -ForegroundColor Yellow
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Desktop が見つかりません。インストールしてください。" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Docker Desktop が見つかりました。" -ForegroundColor Green
}

# ===== WSL チェック =====
Write-Host "`n🔍 WSL2 の状態を確認中..." -ForegroundColor Yellow
$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ WSL2 が有効化されていません。有効化してください。" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ WSL2 が有効です。" -ForegroundColor Green
}

# ===== Ubuntu チェック =====
Write-Host "`n🔍 Ubuntu の存在を確認中..." -ForegroundColor Yellow
$ubuntuName = "Ubuntu"
$existingUbuntu = wsl -l -q | Where-Object { $_ -match $ubuntuName }

if (-not $existingUbuntu) {
    Write-Host "⬇️ Ubuntuをインストール中..." -ForegroundColor Yellow
    wsl --install -d Ubuntu
    Write-Host "✅ Ubuntu のインストールが完了しました。再起動が必要な場合は再起動してください。" -ForegroundColor Green
    exit 0
} else {
    $distroName = ($existingUbuntu | Select-Object -First 1).Trim()
    Write-Host "🟢 Ubuntu がすでにインストールされています: $distroName" -ForegroundColor Green
}

# ===== テンプレートの取得 =====
Write-Host "`n📦 Laravel テンプレートを確認中..." -ForegroundColor Yellow
$repoUrl = "https://github.com/yuuki0508/laravel-inertia-template.git"
$projectRoot = "$HOME\laravel-docker-template"

if (-not (Test-Path $projectRoot)) {
    Write-Host "テンプレートを取得中..." -ForegroundColor Yellow
    git clone $repoUrl $projectRoot
} else {
    Write-Host "既存のテンプレートを使用します（更新中...）" -ForegroundColor Yellow
    try {
        Set-Location $projectRoot
        git pull origin main
    } catch {
        Write-Host "⚠️ git pull に失敗しましたが既存フォルダを使用します。" -ForegroundColor DarkYellow
    }
}

# ===== Ubuntu 上でセットアップ実行 =====
Write-Host "`n⚙️ Ubuntu 上で Laravel 環境を構築中..." -ForegroundColor Cyan

$escapedPath = "/mnt/c/Users/$env:UserName/laravel-docker-template"
$cmd = @"
cd $escapedPath
if [ -f setup.sh ]; then
  bash setup.sh '$ProjectName' '$Port'
else
  echo '❌ setup.sh が見つかりません。GitHub テンプレートを確認してください。'
  exit 1
fi
"@

try {
    wsl -d $distroName bash -c "$cmd"
} catch {
    Write-Host "❌ Ubuntu 内でのセットアップ中にエラーが発生しました。" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# ===== 起動確認と案内 =====
$appPort = $Port
$pmaPort = 8080

Write-Host ""
Write-Host "🌐 ブラウザを自動で開きます..." -ForegroundColor Green
Start-Process "http://localhost:$appPort/sample"
Start-Process "http://localhost:$pmaPort"

Write-Host ""
Write-Host "✅ Laravel 環境構築が完了しました！" -ForegroundColor Cyan
Write-Host "--------------------------------------------"
Write-Host " プロジェクト名 : $ProjectName"
Write-Host " アプリURL       : http://localhost:$appPort/sample"
Write-Host " phpMyAdmin       : http://localhost:$pmaPort (root / password)"
Write-Host "--------------------------------------------"
Write-Host ""
Write-Host "次のコマンドで Laravel コンテナに接続できます:" -ForegroundColor Yellow
Write-Host "  wsl -d $distroName -e bash -c 'cd $escapedPath && ./vendor/bin/sail shell'"
Write-Host ""
