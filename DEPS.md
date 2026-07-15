# Внешние зависимости (не хранятся в git)

Тяжёлые сторонние библиотеки в репозиторий НЕ включены — их нужно скачать
отдельно и положить в `deps/`. Версии подобраны под тулчейн сборки (см.
[СБОРКА_форум.md](СБОРКА_форум.md)).

## Что нужно скачать отдельно → в `deps/`

| Что | Версия | Куда | Откуда скачать |
|---|---|---|---|
| **Boost** | **1.34.1** | `deps/boost_1_34_1/` | https://sourceforge.net/projects/boost/files/boost/1.34.1/ (`boost_1_34_1.7z`/`.tar.gz`) |

Boost — header-only, ванильный: скачал, распаковал в `deps/boost_1_34_1/` — готово.

## STLport — УЖЕ в репозитории (скачивать не нужно)

STLport под этот проект **нельзя просто скачать** — он патченный (namespace в
`features.h`, `_msvc.h`, исключения complex) и **пересобран под `/MD` → `stlpx_std`**.
Поэтому подготовленный STLport лежит прямо в репозитории:

- `deps/stlport_icl/stlport/` — патченные заголовки;
- `deps/stlport_icl/lib/stlport_statix.lib` — собранная статическая либа.

Единственное, что не хранится в git, — **junction'ы `deps/stlport_icl/include` и
`…/crt` на заголовки CRT VC6** (машинно-зависимы). Их **автоматически создаёт
`build_icl.ps1`** из переданного пути `-Vc6`. Ручных действий не требуется.

(Пересобрать STLport с нуля, если вдруг понадобится, — скрипт `build_stlport_md.ps1`;
процедура и правки описаны в [СБОРКА_форум.md](СБОРКА_форум.md).)

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
