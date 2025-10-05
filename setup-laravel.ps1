# =============================================
#  Laravel Sail + Docker + WSL2 自動構築スクリプト
#  (PowerShell 5.1 / 7 両対応・UTF-8完全対応)
# =============================================

# --- UTF-8 文字化け対策（強化版） ---
# 入出力エンコーディング設定
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# PowerShell 7用の追加設定
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8

# Windows環境での追加設定
if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
}
# ---------------------------------------

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " 🚀 Laravel Sail + Docker + WSL2 自動構築スクリプト" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# --- 事前チェック ---
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Desktop が見つかりません。インストールしてください。" -ForegroundColor Red
    exit 1
}

# --- WSL 状態確認 ---
$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ WSL2 が有効化されていません。有効化してください。" -ForegroundColor Red
    exit 1
}

# --- Ubuntu 確認 ---
$existingUbuntu = wsl -l -q | Where-Object { $_ -match "Ubuntu" }
if (-not $existingUbuntu) {
    Write-Host "⬇️ Ubuntu 22.04 LTS を自動インストールします..." -ForegroundColor Yellow
    $installDir = "C:\WSL\Ubuntu"
    if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir | Out-Null }

    # ✅ 正しいUbuntu 22.04 LTS rootfs
    $ubuntuUrl = "https://cloud-images.ubuntu.com/wsl/jammy/current/ubuntu-jammy-wsl-amd64-ubuntu22.04lts.rootfs.tar.gz"
    $ubuntuTar = "$env:TEMP\ubuntu-jammy-wsl-amd64-ubuntu22.04lts.rootfs.tar.gz"

    Write-Host "📦 Ubuntu rootfs をダウンロード中..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $ubuntuUrl -OutFile $ubuntuTar -UseBasicParsing

    Write-Host "📂 WSL にインポート中..." -ForegroundColor Yellow
    wsl --import Ubuntu $installDir $ubuntuTar --version 2

    Write-Host "✅ Ubuntu 22.04 LTS のインストールが完了しました。" -ForegroundColor Green
} else {
    Write-Host "🟢 Ubuntu はすでにインストールされています。" -ForegroundColor Green
}

# --- プロジェクト名入力 ---
$projectName = Read-Host "プロジェクト名を入力してください（例: my-project）"
if ([string]::IsNullOrWhiteSpace($projectName)) {
    $projectName = "my-project"
}

# --- setup.sh ダウンロード ---
$setupUrl = "https://raw.githubusercontent.com/yuuki0508/laravel-inertia-template/main/setup.sh"
$setupFile = "$env:USERPROFILE\setup.sh"

# 旧ファイル削除（制御文字付き含む）
Get-ChildItem -Path $env:USERPROFILE -Filter "setup.sh*" -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Host "🌐 setup.sh をダウンロードしています..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $setupUrl -OutFile $setupFile -UseBasicParsing

# ファイル名が壊れていないか修正
$fixCandidates = Get-ChildItem -Path $env:USERPROFILE -Filter "setup.sh*" | Where-Object { $_.Name -ne "setup.sh" }
foreach ($f in $fixCandidates) {
    Rename-Item $f.FullName $setupFile -Force
}

Write-Host "✅ setup.sh ダウンロード完了: $setupFile" -ForegroundColor Green

# --- Ubuntu上で実行 ---
Write-Host ""
Write-Host "⚙️ Ubuntu 上で Laravel セットアップを実行中..." -ForegroundColor Cyan
$escapedProjectName = $projectName.Replace("'", "''")

$wslCommand = @"
cd ~
if [ -d "$escapedProjectName" ]; then
  echo "⚠️ 既にプロジェクト '$escapedProjectName' が存在します。再構築はスキップします。"
  exit 0
fi
mv /mnt/c/Users/$env:UserName/setup.sh ~/setup.sh
chmod +x ~/setup.sh
bash ~/setup.sh '$escapedProjectName'
"@

wsl -d Ubuntu bash -c "$wslCommand"

# --- 完了メッセージ ---
Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "✅ すべて完了しました！" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "次のステップ:" -ForegroundColor Cyan
Write-Host "1️⃣  WSLを起動: wsl -d Ubuntu" -ForegroundColor White
Write-Host "2️⃣  プロジェクトに移動: cd ~/$projectName" -ForegroundColor White
Write-Host "3️⃣  開発サーバー起動: npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "または一発起動:" -ForegroundColor Cyan
Write-Host "wsl -d Ubuntu -e bash -c 'cd ~/$projectName && ./start.sh'" -ForegroundColor White
Write-Host ""
