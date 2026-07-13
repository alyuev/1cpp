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

# INCLUDE (/Qvc6 + coherent VC6 + built STLport): STLport(configured) ; VC6 MFC/ATL ;
# patched winbase ; VC6 CRT/Win32. STLportDir points at the ICL-built STLport (ASCII path).
$stlA = 'C:\stlport_icl\stlport'
$patch = Short (Join-Path $root 'deps\vc6patch')
$env:INCLUDE = "$stlA;$vc98\MFC\Include;$vc98\ATL\Include;$patch;$vc98\Include"

$defs=@('/D_AFXDLL','/DWIN32','/DNDEBUG','/D_ANSI','/D_WINDOWS','/D_USRDLL','/D_AFX_DLL',
        '/D_ATL_STATIC_REGISTRY','/D_WIN_DLL','/D_MBCS',
        '/D_STLP_USE_STATIC_LIB','/D_STLP_NEW_PLATFORM_SDK','/D_STLP_USING_PLATFORM_SDK_COMPILER',
        '/D_STLP_NO_NATIVE_MBSTATE_T','/D_STLP_NO_NATIVE_WIDE_FUNCTIONS',
        '/D_STLP_NO_NATIVE_WIDE_STREAMS')
$flags=@('/nologo','/Ob1','/O2','-W0','/Qwd1738,1744','/Qwe1011','/Qinline-max-size:100',
         '/EHsc','/Qms2','/Qvc6','/Zl','/MD','/Zm800')
$incs=@("/I$stlA","/I$src","/I$src\1CHEADERS","/I$boost")
$pch="$out83\1CPP.pch"

Write-Output ("icl: " + ((cmd /c "icl 2>&1") | Select-String 'Version' | Select-Object -First 1))
Write-Output "INCLUDE=$($env:INCLUDE)"
Write-Output "=== [PCH] $File (ICL + MFC42 headers) ==="
$a=@($flags)+$defs+$incs+@("/YcStdAfx.h","/Fp$pch","/Fo$obj83\StdAfx.obj","$src\$File")
& icl @a 2>&1 | Tee-Object -FilePath "$out\pch_build.log" | Select-Object -First 45
if(-not (Test-Path $pch)){ Write-Output 'PCH FAILED'; exit 1 }
Write-Output 'PCH OK'
