# Сборка на Intel C++ 11.1.054 (ICL) — прогресс (ветка build/vc6)

Пользователь установил **ICL 11.1.054** (ровно один из двух билдов, что сработали
на форуме dorex). Это переломный момент: **фундаментальный блокер снят**.

## Что уже работает
- **ICL 11.1.054 запускается, лицензия принимается** (ia32, `icl.exe`).
- **`/Qvc6` разбирает VC6-заголовки MFC42/ATL3** — то, обо что падали и VS2022,
  и VS2005, и голый VC6. `class CString` (правильный ABI для либ 1С) — есть.
- Пройдены и закрыты (скрипт `build_icl.ps1`):
  - `winbase.h` `InterlockedIncrement` "C linkage" — патч-копия `deps/vc6patch/winbase.h`
    (x86-объявления Interlocked спрятаны от ICL, он даёт свои intrinsic).
  - STLport wchar (`mbrtowc` и т.п., нет в CRT VC6) — дефайны
    `_STLP_NO_NATIVE_MBSTATE_T`/`_STLP_NO_NATIVE_WIDE_FUNCTIONS`.
  - `comdef.h` — решилось переходом на когерентный набор заголовков «всё от VC6».
- Флаги по рецепту форума: `/Qms2 /Qvc6 /Zl /MD` + дефайны `_STLP_*`, `_AFXDLL`
  и т.д. INCLUDE: STLport ; VC6 MFC ; VC6 ATL ; vc6patch ; VC6 Include.

## Единственный оставшийся барьер: конфигурация STLport под ICL-на-Windows
STLport 5.2.1 (header-only) подхватывает конфиг `stl/config/_icc.h` — а он для
**Intel под Linux** (native-путь `../include`, GLIBC). Для ICL-на-Windows нужен
`_msvc.h` (native-путь через VC-CRT). Из-за неверного native-пути STLport не
находит нативные `<cfloat>`/`<float.h>` → `FLT_MANT_DIG undefined` в `_limits.h`.

Это не проблема компилятора, а **настройка STLport**: его нужно либо собрать/
проинсталлировать под целевой компилятор (как делал автор с форума — он собирал
STLport 5.1.5), либо пропатчить выбор конфига (заставить использовать `_msvc.h`
и корректный native-путь к заголовкам VC6).

## Вывод
Тулчейн подтверждён рабочим: **ICL 11.1.054 + `/Qvc6` + VC6 MFC42/CRT + STLport +
Boost 1.34.1** — именно то, о чём говорит форум. Осталась одна настроечная задача
(правильно сконфигурировать/собрать STLport), после чего — компиляция всех .cpp и
линковка `xilink` в `1cpp.dll`. Это уже не «стена», а конечный объём работы.

## ПРОРЫВ: стек заголовков компилируется под ICL /Qvc8 + PSDK2003

Добыт **Platform SDK for Windows Server 2003 R2** (archive.org, ISO 410 МБ),
админ-распаковка `msiexec /a PSDK-x86.msi`. Его MFC — **версия 6.0
(`_MFC_VER 0x0600`) = `class CString`** (правильный ABI!), и он парсится
современным фронтендом ICL под `/Qvc8` (в отличие от заголовков MFC42 самого VC6).

Рабочая связка (StdAfx.obj + 1CPP.pchi собраны, 0 ошибок):
- Компилятор: **ICL 11.1.054**, флаги `/c /Qms2 /Qvc8 /Zl /MD` + `/Qwd1738,1744`.
- MFC/ATL/Win32: **PSDK2003** (`Include\mfc` = class CString, `Include\atl`, `Include`).
- CRT/STL: **VS2005** (родная STL, есть `<hash_map>`; STLport не понадобился —
  код собирается и на родной STL, как на VS2022).
- Boost 1.34.1 (header-only).
- ICL пишет PCH как `.pchi` (не `.pch`).

Открытый вопрос — CRT: сейчас CRT от VS2005 (msvcr80), а MFC42-либа тянет CRT VC6
(msvcrt) — мульти-CRT (риск для рантайма). Решится на этапе линковки (возможно,
переход на VC6 CRT + STLport, как в оригинальном рецепте форума).
