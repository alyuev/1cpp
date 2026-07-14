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

# INCLUDE (/Qvc8, NO STLport): PSDK2003 MFC(6.0=class CString)/ATL ; PSDK Win32 ;
# VS2005 CRT/STL (native STL has <hash_map>; code builds on native STL, proven on VS2022).
$psdk = Short 'D:\psdk2003\Microsoft Platform SDK for Windows Server 2003 R2'
$vsinc = 'C:\Program Files (x86)\Microsoft Visual Studio 8\VC\include'
$env:INCLUDE = "$psdk\Include\mfc;$psdk\Include\atl;$psdk\Include;$vsinc"

$defs=@('/D_AFXDLL','/DWIN32','/DNDEBUG','/D_ANSI','/D_WINDOWS','/D_USRDLL','/D_AFX_DLL',
        '/D_ATL_STATIC_REGISTRY','/D_WIN_DLL','/D_MBCS')
$flags=@('/nologo','/c','/Ob1','/O2','-W0','/Qwd1738,1744','/Qwe1011','/Qinline-max-size:100',
         '/EHsc','/Qms2','/Qvc8','/Zl','/MD','/Zm800')
$incs=@("/I$src","/I$src\1CHEADERS","/I$boost")
$pch="$out83\1CPP.pch"     # ICL writes the PCH as 1CPP.pchi

Write-Output ("icl: " + ((cmd /c "icl 2>&1") | Select-String 'Version' | Select-Object -First 1))
Write-Output "=== [PCH] StdAfx.cpp (ICL /Qvc8 + PSDK2003 MFC + native STL) ==="
$a=@($flags)+$defs+$incs+@("/YcStdAfx.h","/Fp$pch","/Fo$obj83\StdAfx.obj","$src\StdAfx.cpp")
& icl @a 2>&1 | Tee-Object -FilePath "$out\pch_build.log" | Out-Null
if(-not (Test-Path "$out\obj\StdAfx.obj")){ Write-Output 'PCH FAILED'; Get-Content "$out\pch_build.log" | Select-Object -Last 25; exit 1 }
Write-Output 'PCH OK'
if($Stage -eq 'pch'){ exit 0 }

# --- compile all .cpp from vcproj (with /Yu) ---
$vcproj = Get-Content (Join-Path $src '1CPP.vcproj') -Raw
$cpps = ([regex]::Matches($vcproj,'RelativePath="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }) |
        Where-Object { $_ -match '\.cpp$' } |
        ForEach-Object { ($_ -replace '^\.\\','') -replace '/','\' } | Sort-Object -Unique |
        Where-Object { $_ -notmatch 'StdAfx\.cpp$' -and $_ -notmatch '^Forwarder\\' }
Write-Output "=== [COMPILE] $($cpps.Count) .cpp (ICL /Yu) ==="
$log="$out\compile.log"; "" | Set-Content $log; $failed=@(); $i=0
foreach($rel in $cpps){
  $i++
  if(-not (Test-Path (Join-Path $src $rel))){ Write-Output "  MISS $rel"; continue }
  $o="$obj83\"+(($rel -replace '[\\/]','_') -replace '\.cpp$','.obj')
  $ca=@($flags)+$defs+$incs+@("/YuStdAfx.h","/Fp$pch","/Fo$o","$src\$rel")
  $r = & icl @ca 2>&1; $r | Add-Content $log
  if(-not (Test-Path ($o -replace '/','\'))){ $failed+=$rel
    $ec=($r|Select-String ': error'|Measure-Object).Count
    Write-Output ("  FAIL [{0}/{1}] {2} ({3} err)" -f $i,$cpps.Count,$rel,$ec) }
}
Write-Output "=== COMPILE: $($cpps.Count-$failed.Count)/$($cpps.Count) OK, $($failed.Count) failed ==="
if($failed.Count -gt 0){
  Write-Output "=== top error codes ==="
  Select-String -Path $log -Pattern 'error #(\d+)' | ForEach-Object { $_.Matches[0].Groups[1].Value } |
    Group-Object | Sort-Object Count -Descending | Select-Object -First 12 |
    ForEach-Object { Write-Output ("  #{0} x{1}" -f $_.Name,$_.Count) }
  exit 1
}
if($Stage -eq 'compile'){ exit 0 }

# --- resources ---
$vc6l = (Short $Vc6)+'\VC98'
$res="$out83\1CPP.res"
Write-Output "=== [RC] 1CPP.rc ==="
& rc /l 0x419 /d NDEBUG /d _AFXDLL "/I$psdk\Include\mfc" "/I$src" "/fo$res" "$src\1CPP.rc" 2>&1 |
  Tee-Object "$out\rc.log" | Out-Null
if(-not (Test-Path $res)){ Write-Output "RC FAILED"; Get-Content "$out\rc.log" | Select-Object -Last 15; exit 1 }
Write-Output "RC OK"
# compile GUID file 1CPP_i.c
& icl /nologo /c /MD "/Fo$obj83\1CPP_i.obj" "$src\1CPP_i.c" 2>&1 | Out-Null

# --- link (xilink): VC6 CRT (msvcrt) + mfc42 (class CString) + 1C libs ---
Write-Output "=== [LINK] 1CPP.dll (xilink) ==="
$objs = Get-ChildItem "$out\obj\*.obj" | ForEach-Object { $_.FullName }
$libpaths = @("/LIBPATH:$vc6l\MFC\Lib","/LIBPATH:$vc6l\Lib","/LIBPATH:$psdk\Lib","/LIBPATH:$src\LIBS")
$syslibs = @('mfc42.lib','msvcrt.lib','kernel32.lib','user32.lib','gdi32.lib','winspool.lib',
             'comdlg32.lib','advapi32.lib','shell32.lib','ole32.lib','oleaut32.lib','uuid.lib',
             'odbc32.lib','odbccp32.lib','Rpcrt4.lib','winmm.lib','version.lib','msimg32.lib','shlwapi.lib')
$dll="$out83\1CPP.dll"
$la = @('/dll','/nologo','/MACHINE:IX86','/DEF:'+"$src\1CPP.DEF",'/BASE:0x24000000',
        '/IGNORE:4199','/OUT:'+$dll) + $objs + @($res) + $libpaths + $syslibs
& xilink @la 2>&1 | Tee-Object "$out\link.log" | Out-Null
if(Test-Path $dll){
  Write-Output "LINK OK -> $dll"; Get-Item $dll | Select-Object Name,Length | Format-List
}else{
  $u=(Select-String -Path "$out\link.log" -Pattern 'LNK2001|LNK2019'|Measure-Object).Count
  Write-Output "LINK FAILED. unresolved lines: $u"
  Select-String -Path "$out\link.log" -Pattern 'error LNK\d+' | Select-Object -First 15 | ForEach-Object { $_.Line }
  exit 1
}
