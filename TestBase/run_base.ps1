$ErrorActionPreference='SilentlyContinue'
$base=$PSScriptRoot   # каталог тест-базы (скрипт лежит в нём)
$exe='C:\Program Files (x86)\1Cv77\BIN\1cv7.exe'
$log=Join-Path $base 'test_log.txt'
$mlg=Join-Path $base 'SYSLOG\1cv7.mlg'
Get-Process 1cv7 | Stop-Process -Force
Start-Sleep -Seconds 1
Get-ChildItem $base -Filter '*.LCK' | ForEach-Object { [IO.File]::Delete($_.FullName) }
$usr=Join-Path $base '1SUSERS.DBF'; if(Test-Path $usr){ [IO.File]::Delete($usr) }
if(Test-Path $log){ [IO.File]::Delete($log) }
$mlgBefore=0; if(Test-Path $mlg){ $mlgBefore=(Get-Content $mlg -Encoding Default).Count }
# каталог базы в PATH: чтобы LoadLibrary(1cpp.dll) нашёл рядом libmmd.dll (Intel runtime)
$env:PATH = $base + ';' + $env:PATH
$a='ENTERPRISE /M /D"'+$base+'"'
$p=Start-Process -FilePath $exe -ArgumentList $a -PassThru
Write-Output ('1C PID '+$p.Id+' | '+$a)
$done=$false
for($i=0;$i -lt 75;$i++){
  Start-Sleep -Seconds 2
  if(Test-Path $log){ if((Get-Content $log -Encoding Default -Raw) -match '__DONE__'){ $done=$true; break } }
  if($p.HasExited){ Write-Output ('1C exited '+$p.ExitCode); break }
}
Start-Sleep -Seconds 1
Get-Process 1cv7 | Stop-Process -Force
Start-Sleep -Seconds 1
Get-ChildItem $base -Filter '*.LCK' | ForEach-Object { [IO.File]::Delete($_.FullName) }
Write-Output ('done='+$done)
Write-Output '===== LOG ====='
if(Test-Path $log){ Get-Content $log -Encoding Default } else { Write-Output '(no log)' }
Write-Output '===== 1C MLG (new errors) ====='
if(Test-Path $mlg){ $all=Get-Content $mlg -Encoding Default; if($all.Count -gt $mlgBefore){ $all[$mlgBefore..($all.Count-1)] | Where-Object { $_ -match ';E;Grbg|Err:' } | ForEach-Object { $_ } } }
