# Build 1CPP.dll with Intel C++ Compiler 11.1.054 (ICL) — the original-era toolchain.
# Recipe from the icpp community (forum.dorex.pro topic 104): ICL + MFC/ATL(class CString) +
# VC6 CRT + STLport + Boost 1.34.1.  Flags: /Qms2 /Qvc8 /Zl /MD.
# ASCII-only; VC6/legacy headers -> 8.3 short paths.
param(
  [ValidateSet('pch','compile','all')][string]$Stage='pch',
  [string]$BoostDir='deps\boost_1_34_1',
  [string]$StlportDir='deps\STLport',
  [Parameter(Mandatory=$true)][string]$Vc6,
  [string]$File='StdAfx.cpp'
)
$ErrorActionPreference='Continue'
$fso=New-Object -ComObject Scripting.FileSystemObject
function Short($p){ if(Test-Path $p){ $fso.GetFolder($p).ShortPath } else { $p } }

$root=$PSScriptRoot
$out=Join-Path $root 'build_icl'; $obj=Join-Path $out 'obj'
New-Item -ItemType Directory -Force -Path $out,$obj | Out-Null

$iclvars='C:\Program Files (x86)\Intel\Compiler\11.1\054\bin\iclvars.bat'
# import ICL + VS2005 host env
cmd /c "`"$iclvars`" ia32 vs2005 > nul 2>&1 && set" | ForEach-Object {
  if($_ -match '^([^=]+)=(.*)$'){ Set-Item "Env:$($matches[1])" $matches[2] }
}

$vc98=(Short $Vc6)+'\VC98'
$boost=Short (Join-Path $root $BoostDir)
$stl=(Short (Join-Path $root $StlportDir))+'\stlport'
$src=Short (Join-Path $root 'Source')
$out83=Short $out; $obj83=Short $obj

# INCLUDE (no-STLport variant): VC6 MFC/ATL (class CString) FIRST, then VS2005 STL/CRT/Win32.
# The code also builds with native STL (proven on VS2022); VS2005 STL provides <hash_map>.
$vs = 'C:\Program Files (x86)\Microsoft Visual Studio 8\VC'
$env:INCLUDE = "$vc98\MFC\Include;$vc98\ATL\Include;$vs\include;$vs\PlatformSDK\include"

$defs=@('/D_AFXDLL','/DWIN32','/DNDEBUG','/D_ANSI','/D_WINDOWS','/D_USRDLL','/D_AFX_DLL',
        '/D_ATL_STATIC_REGISTRY','/D_WIN_DLL','/D_MBCS',
        '/D_CRT_SECURE_NO_DEPRECATE','/D_CRT_NONSTDC_NO_DEPRECATE',
        '/D_CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES=0',
        '/D_CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_COUNT=0')
$flags=@('/nologo','/Ob1','/O2','-W0','/Qwd1738,1744','/Qwe1011','/Qinline-max-size:100',
         '/EHsc','/Qms2','/Qvc6','/Zl','/MD','/Zm800')
$incs=@("/I$src","/I$src\1CHEADERS","/I$boost")
$pch="$out83\1CPP.pch"

Write-Output ("icl: " + ((cmd /c "icl 2>&1") | Select-String 'Version' | Select-Object -First 1))
Write-Output "INCLUDE=$($env:INCLUDE)"
Write-Output "=== [PCH] $File (ICL + MFC42 headers) ==="
$a=@($flags)+$defs+$incs+@("/YcStdAfx.h","/Fp$pch","/Fo$obj83\StdAfx.obj","$src\$File")
& icl @a 2>&1 | Tee-Object -FilePath "$out\pch_build.log" | Select-Object -First 45
if(-not (Test-Path $pch)){ Write-Output 'PCH FAILED'; exit 1 }
Write-Output 'PCH OK'
