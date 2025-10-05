# --- UTF-8文字化け対策 ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
# -------------------------

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " 🚀 Laravel Sail + Docker + WSL2 自動構築スクリプト" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ===== 事前チェック =====
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Desktop が見つかりません。インストールしてください。" -ForegroundColor Red
    exit 1
}

# ===== Ubuntu チェック =====
$ubuntuDistro = "Ubuntu"
$existingUbuntu = wsl -l -q | Where-Object { $_ -match $ubuntuDistro }

if (-not $existingUbuntu) {
    Write-Host "⬇️ Ubuntu を自動インストールします..." -ForegroundColor Yellow
    $ubuntuDir = "C:\WSL\$ubuntuDistro"
    if (-not (Test-Path $ubuntuDir)) {
        New-Item -ItemType Directory -Path $ubuntuDir | Out-Null
    }

    # Ubuntu 22.04 LTS (WSL用 rootfs)
    $ubuntuUrl = "https://cloud-images.ubuntu.com/wsl/jammy/current/ubuntu-jammy-wsl-amd64-ubuntu22.04lts.rootfs.tar.gz"
    $ubuntuTar = "$env:TEMP\ubuntu.tar.gz"

    Write-Host "🌐 Ubuntu rootfs をダウンロード中..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $ubuntuUrl -OutFile $ubuntuTar -UseBasicParsing

    Write-Host "📦 Ubuntu を登録中..." -ForegroundColor Yellow
    wsl --import $ubuntuDistro $ubuntuDir $ubuntuTar --version 2

    Write-Host "✅ Ubuntu インストール完了！" -ForegroundColor Green
    Remove-Item $ubuntuTar -Force
} else {
    Write-Host "🟢 Ubuntu はすでにインストールされています。" -ForegroundColor Green
}

# ===== プロジェクト名入力 =====
$projectName = Read-Host "プロジェクト名を入力してください（例: my-project）"
if ([string]::IsNullOrWhiteSpace($projectName)) {
    $projectName = "my-project"
}

# ===== setup.sh ダウンロード =====
$repoUser = "yuuki0508"
$repoName = "laravel-inertia-template"
$setupUrl = "https://raw.githubusercontent.com/$repoUser/$repoName/main/setup.sh"
$setupPath = "$env:USERPROFILE\setup.sh"

Write-Host ""
Write-Host "📥 setup.sh を GitHub から取得しています..." -ForegroundColor Yellow

# 古いファイル削除
if (Test-Path $setupPath) {
    Remove-Item $setupPath -Force
}

Invoke-WebRequest -Uri $setupUrl -OutFile $setupPath -UseBasicParsing
if (-not (Test-Path $setupPath)) {
    Write-Host "❌ setup.sh のダウンロードに失敗しました。" -ForegroundColor Red
    exit 1
}

Write-Host "✅ setup.sh をダウンロードしました: $setupPath" -ForegroundColor Green

# ===== Ubuntu 内で実行 =====
Write-Host ""
Write-Host "⚙️ Ubuntu 上で Laravel セットアップを実行中..." -ForegroundColor Yellow

$escapedUser = $env:UserName
$escapedProjectName = $projectName.Replace("'", "''")

# Bash コマンド（PowerShell変数展開無効）
$wslCommands = @'
cd ~
projectName="{projectName}"
if [ -d "$projectName" ]; then
    echo "⚠️ 既にプロジェクト '$projectName' が存在します。再構築はスキップします。"
    exit 0
fi

mv "/mnt/c/Users/{escapedUser}/setup.sh" ~/setup.sh
chmod +x ~/setup.sh
bash ~/setup.sh "$projectName"
'@

# PowerShell 変数を埋め込み
$wslCommands = $wslCommands.Replace("{escapedUser}", $escapedUser)
$wslCommands = $wslCommands.Replace("{projectName}", $escapedProjectName)

# 実行
wsl -d $ubuntuDistro -e bash -c "$wslCommands"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "✅ すべて完了しました！" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "次のステップ:" -ForegroundColor Cyan
Write-Host "1. WSLを起動:  wsl -d $ubuntuDistro" -ForegroundColor White
Write-Host "2. プロジェクトへ移動: cd ~/$projectName" -ForegroundColor White
Write-Host "3. 開発サーバー起動:  npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "または一発起動コマンド:" -ForegroundColor Cyan
Write-Host "wsl -d $ubuntuDistro -e bash -c 'cd ~/$projectName && ./start.sh'" -ForegroundColor White
Write-Host ""
