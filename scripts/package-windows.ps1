param(
  [Parameter(Mandatory = $true)]
  [string] $InstallDir,

  [Parameter(Mandatory = $true)]
  [string] $DistDir,

  [Parameter(Mandatory = $true)]
  [ValidateSet("x64")]
  [string] $Arch,

  [Parameter(Mandatory = $true)]
  [string] $Version,

  [Parameter(Mandatory = $true)]
  [string] $UpstreamSha
)

$ErrorActionPreference = "Stop"

if (!(Test-Path -Path $InstallDir -PathType Container)) {
  throw "Install directory does not exist: $InstallDir"
}

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

$assetBase = "Ladybird-nightly-windows-$Arch"
$zipPath = Join-Path $DistDir "$assetBase.zip"
$installerPath = Join-Path $DistDir "$assetBase-setup.exe"

if (Test-Path $zipPath) {
  Remove-Item $zipPath -Force
}
Compress-Archive -Path (Join-Path $InstallDir "*") -DestinationPath $zipPath -Force

$makensis = (Get-Command makensis.exe -ErrorAction SilentlyContinue).Source
if (!$makensis) {
  $candidate = "${env:ProgramFiles(x86)}\NSIS\makensis.exe"
  if (Test-Path $candidate) {
    $makensis = $candidate
  }
}
if (!$makensis) {
  throw "makensis.exe was not found. Install NSIS before running this script."
}

$escapedInstallDir = $InstallDir.Replace("\", "\\")
$escapedInstallerPath = $installerPath.Replace("\", "\\")
$nsiPath = Join-Path ([System.IO.Path]::GetTempPath()) "ladybird-nightly-$Arch.nsi"

@"
Unicode True
Name "Ladybird Nightly"
OutFile "$escapedInstallerPath"
InstallDir "`$LOCALAPPDATA\LadybirdNightly"
RequestExecutionLevel user

Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Section "Install"
  SetOutPath "`$INSTDIR"
  File /r "$escapedInstallDir\*"
  CreateDirectory "`$SMPROGRAMS\Ladybird Nightly"
  IfFileExists "`$INSTDIR\bin\Ladybird.exe" shortcut_upper 0
  IfFileExists "`$INSTDIR\bin\ladybird.exe" shortcut_lower no_shortcut
  shortcut_upper:
  CreateShortcut "`$SMPROGRAMS\Ladybird Nightly\Ladybird.lnk" "`$INSTDIR\bin\Ladybird.exe"
  Goto no_shortcut
  shortcut_lower:
  CreateShortcut "`$SMPROGRAMS\Ladybird Nightly\Ladybird.lnk" "`$INSTDIR\bin\ladybird.exe"
  no_shortcut:
  FileOpen `$0 "`$INSTDIR\BUILD.txt" w
  FileWrite `$0 "Ladybird nightly build`$\r`$\n"
  FileWrite `$0 "Version: $Version`$\r`$\n"
  FileWrite `$0 "Upstream commit: $UpstreamSha`$\r`$\n"
  FileClose `$0
  WriteUninstaller "`$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "`$SMPROGRAMS\Ladybird Nightly\Ladybird.lnk"
  RMDir "`$SMPROGRAMS\Ladybird Nightly"
  RMDir /r "`$INSTDIR"
SectionEnd
"@ | Set-Content -Path $nsiPath -Encoding UTF8

& $makensis /V3 $nsiPath
if ($LASTEXITCODE -ne 0) {
  $lineNumber = 1
  Get-Content -Path $nsiPath | ForEach-Object {
    "{0,4}: {1}" -f $lineNumber, $_
    $lineNumber++
  }
  exit $LASTEXITCODE
}
