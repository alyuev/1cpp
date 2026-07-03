# Build 1CPP.dll with VC6 (MSVC 6.0) portable toolchain + MFC42 (matches the 1C libs ABI).
# VC6 chokes on Cyrillic paths -> everything is passed to cl as 8.3 short paths.
# ASCII-only file. $Vc6 = path to the portable MSVC600 root (may be Cyrillic; converted to 8.3).
param(
  [Parameter(Mandatory=$true)][string]$Vc6,
  [string]$BoostDir = 'deps\boost_1_34_1',
  [ValidateSet('pch','compile','all')][string]$Stage = 'pch',
  [switch]$Stlport,
  [string]$StlportDir = 'deps\STLport'
)
$ErrorActionPreference = 'Continue'
$fso = New-Object -ComObject Scripting.FileSystemObject
function Short($p){ if(Test-Path $p){ $fso.GetFolder($p).ShortPath } else { $p } }

$root  = $PSScriptRoot
$out   = Join-Path $root 'build_vc6'
$obj   = Join-Path $out 'obj'
New-Item -ItemType Directory -Force -Path $out,$obj | Out-Null

$root83  = Short $root
$vc6_83  = Short $Vc6
$vc98    = "$vc6_83\VC98"
$msdev   = "$vc6_83\Common\MSDev98"
$boost83 = Short (Join-Path $root $BoostDir)
$src83   = Short (Join-Path $root 'Source')
$out83   = Short $out
$obj83   = Short $obj

# --- VC6 environment ---
$env:PATH    = "$vc98\Bin;$msdev\Bin;$env:PATH"
$inc = @("$vc98\ATL\Include","$vc98\MFC\Include","$vc98\Include")
if ($Stlport) { $inc = @((Short (Join-Path $root $StlportDir) ) + '\stlport') + $inc }
$env:INCLUDE = ($inc -join ';')
$env:LIB     = "$vc98\MFC\Lib;$vc98\Lib"

$defs = @('/D','WIN32','/D','NDEBUG','/D','_WINDOWS','/D','_USRDLL','/D','_AFXDLL','/D','_MBCS',
          '/D','_ATL_STATIC_REGISTRY','/D','_ANSI','/D','_WIN_DLL')
$incs = @('/I',$src83,'/I',"$src83\1CHEADERS",'/I',$boost83)
$cflags = @('/nologo','/c','/MD','/GX','/GR','/O2','/Zm300')
$pch = "$out83\1CPP.pch"

Write-Output ("cl: " + ((cmd /c "cl 2>&1") | Select-String 'Version' | Select-Object -First 1))
Write-Output "INCLUDE=$($env:INCLUDE)"
Write-Output "=== [PCH] StdAfx.cpp (VC6/MFC42) ==="
$a = @($cflags)+$defs+$incs+@("/YcStdAfx.h","/Fp$pch","/Fo$obj83\StdAfx.obj","$src83\StdAfx.cpp")
& cl @a 2>&1 | Tee-Object -FilePath "$out\pch_build.log" | Select-Object -First 45
if (-not (Test-Path $pch)) { Write-Output 'PCH FAILED'; exit 1 }
Write-Output 'PCH OK'
