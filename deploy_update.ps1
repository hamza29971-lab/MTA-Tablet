# deploy_update.ps1
# Kullanim: .\deploy_update.ps1
# Bu betik version.txt i gunceller, APK derler ve GitHub a yukler.

param(
    [string]$RepoPath = "C:\DS-Tablet-G-ncelleme-"
)

$ProjectPath = "C:\new class\flutter_vtm_tablet\vtm_tablet"
$ApkSource   = "$ProjectPath\build\app\outputs\flutter-apk\app-release.apk"
$VersionFile = "$RepoPath\version.json"
$VersionTxt  = "$ProjectPath\assets\version.txt"
$ApkDest     = "$RepoPath\latest.apk"

Write-Host "=== VTM Tablet Guncelleme Yukleme Araci ===" -ForegroundColor Cyan

# Mevcut version.json u oku
$versionData = Get-Content $VersionFile | ConvertFrom-Json
$oldBuild    = $versionData.build_number
$newBuild    = $oldBuild + 1
$newVersion  = $versionData.version

Write-Host "Mevcut surum: v$newVersion (build $oldBuild)"
Write-Host "Yeni surum  : v$newVersion (build $newBuild)"

# 1. assets/version.txt i guncelle (APK a gomulmesi icin)
Set-Content -Path $VersionTxt -Value "$newBuild" -NoNewline
Write-Host "assets/version.txt -> $newBuild" -ForegroundColor Green

# 2. APK yi derle (version.txt icinde yeni sayi gomulu olacak)
Write-Host "APK derleniyor..." -ForegroundColor Yellow
Push-Location $ProjectPath
flutter build apk --release
Pop-Location

if (-not (Test-Path $ApkSource)) {
    Write-Host "HATA: APK bulunamadi: $ApkSource" -ForegroundColor Red
    exit 1
}

# 3. version.json u guncelle
$versionData.build_number = $newBuild
$versionData | ConvertTo-Json | Set-Content $VersionFile -Encoding UTF8
Write-Host "version.json guncellendi." -ForegroundColor Green

# 4. APK yi kopyala
Copy-Item -Path $ApkSource -Destination $ApkDest -Force
$apkMB = [math]::Round((Get-Item $ApkDest).Length / 1MB, 1)
Write-Host "latest.apk kopyalandi. ($apkMB MB)" -ForegroundColor Green

# 5. Git push
Push-Location $RepoPath
git add version.json latest.apk
git commit -m "Guncelleme: v$newVersion build $newBuild"
git push origin main
Pop-Location

Write-Host ""
Write-Host "BASARILI! Build $newBuild GitHub a yuklendi." -ForegroundColor Green
Write-Host "Tabletler WiFi ye baglaninca guncelleme alacak." -ForegroundColor Cyan
