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
    Write-Host "✅ Ubuntu のインポートが完了しました。" -Foregrou
