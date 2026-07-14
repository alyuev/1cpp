# Rebuild STLport static lib with DYNAMIC RTL (/MD) so its namespace becomes
# stlpx_std (cross native runtime), matching the app (static STLport + /MD + _AFXDLL).
$ErrorActionPreference='Continue'
$fso=New-Object -ComObject Scripting.FileSystemObject
function Short($p){ if(Test-Path $p){ $fso.GetFolder($p).ShortPath } else { $p } }

$iclvars='C:\Program Files (x86)\Intel\Compiler\11.1\054\bin\iclvars.bat'
cmd /c "`"$iclvars`" ia32 vs2005 > nul 2>&1 && set" | ForEach-Object {
  if($_ -match '^([^=]+)=(.*)$'){ Set-Item "Env:$($matches[1])" $matches[2] }
}

# VC6 root resolved from the C:\stlport_icl\include junction (8.3 short form)
$vc6inc = 'D:\B6E3~1\1236A~1\SQLite\tools\MSVC600\VC98\Include'
$psdk = Short 'D:\psdk2003\Microsoft Platform SDK for Windows Server 2003 R2'
# native stack (no MFC needed for STLport src): PSDK Win32 + VC6 CRT
$env:INCLUDE = "$psdk\Include;$vc6inc"
$env:LIB = "$psdk\Lib;D:\B6E3~1\1236A~1\SQLite\tools\MSVC600\VC98\Lib"

$libdir='C:\stlport_icl\build\lib'
Write-Output "Cleaning static release objs (were /MT)..."
Remove-Item "$libdir\obj\icl\static\*" -Recurse -Force -ErrorAction SilentlyContinue

Push-Location $libdir
Write-Output "=== nmake release-static WITH_DYNAMIC_RTL=1 ==="
& nmake /f Makefile WITH_DYNAMIC_RTL=1 release-static 2>&1 | Tee-Object "$env:TEMP\stlport_md_build.log" | Select-Object -Last 40
Pop-Location

Write-Output "=== resulting lib ==="
Get-ChildItem 'C:\stlport_icl\lib\stlport_static.lib' | Select-Object Name,Length,LastWriteTime | Format-List
