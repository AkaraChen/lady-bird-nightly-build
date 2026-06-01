param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("x86_64", "aarch64")]
  [string] $Arch
)

$ErrorActionPreference = "Stop"

$version = "1.243.0"
$name = "wasm-tools-$version-$Arch-windows"
$filename = "$name.zip"
$url = "https://github.com/bytecodealliance/wasm-tools/releases/download/v$version/$filename"

Invoke-WebRequest -Uri $url -OutFile $filename
Expand-Archive -Path $filename -DestinationPath . -Force
Remove-Item $filename

$toolDir = Join-Path (Get-Location) $name
if ($env:GITHUB_PATH) {
  Add-Content -Path $env:GITHUB_PATH -Value $toolDir
} else {
  Write-Output $toolDir
}
