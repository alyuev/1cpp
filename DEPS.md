# Внешние зависимости (не хранятся в git)

Тяжёлые сторонние библиотеки в репозиторий НЕ включены — их нужно скачать
отдельно и положить в `deps/`. Версии подобраны под тулчейн сборки (см.
[СБОРКА_форум.md](СБОРКА_форум.md)).

## Заголовочные зависимости → в `deps/`

| Что | Версия | Куда | Откуда скачать |
|---|---|---|---|
| **Boost** | **1.34.1** | `deps/boost_1_34_1/` | https://sourceforge.net/projects/boost/files/boost/1.34.1/ (`boost_1_34_1.7z`/`.tar.gz`) |
| **STLport** | **5.2.1** | `deps/STLport/` | https://sourceforge.net/projects/stlport/files/STLport/STLport-5.2.1/ (`STLport-5.2.1.tar.bz2`) |

Только заголовки Boost (header-only). STLport требует сборки под целевой
компилятор — процедура и правки описаны в [СБОРКА_форум.md](СБОРКА_форум.md) п.3
(собранная либа кладётся в `C:\stlport_icl`).

## Тулчейн (ставится в систему, не в git)

Полный рецепт — в [СБОРКА_форум.md](СБОРКА_форум.md). Кратко:

- **Intel C++ Compiler 11.1.054** (IA-32) — основной компилятор `icl`.
- **Visual Studio 2005** — host-окружение + линкер `link.exe`.
- **Platform SDK for Windows Server 2003 R2** — заголовки MFC 6.0/ATL
  (`class CString`). ISO: archive.org, `en_platformsdk_windowsr2_march2006.iso`.
- **Visual C++ 6.0** — CRT (`msvcrt`) и `mfc42.lib` (правильный ABI).

## Сборка

```powershell
build_icl.ps1 -Stage all -Vc6 <путь к VC6 MSVC600>
```

Результат — `build_icl/1CPP.dll` (готовая копия — в `dist/1CPP.dll`). Проверка
загрузки в 1С — тест-база `TestBase/` (`run_base.ps1`).
