# -*- coding: utf-8 -*-
"""
Чтение / запись текста модуля 1С во внешней обработке .ert (1С 7.7).

Модуль хранится в OLE-потоке "MD Programm text":
  формат = raw deflate (zlib, wbits=-15), текст в кодировке CP1251.

Чтение  -> olefile (read-only).
Запись  -> COM structured storage (pywin32): SetSize+Write умеет менять
           размер потока (olefile.write_stream так не может).

Запуск (через venv с olefile+pywin32):
  python ert_module.py get  "Тест 1SQLite.ert" [вывод.txt]
  python ert_module.py set  "Тест 1SQLite.ert"  исходник.txt
"""
import sys, zlib, olefile

STREAM = "MD Programm text"


def get_module(ert_path):
    ole = olefile.OleFileIO(ert_path)
    try:
        data = ole.openstream(STREAM).read()
    finally:
        ole.close()
    return zlib.decompress(data, -15).decode("cp1251")


def set_module(ert_path, text_cp1251_str):
    raw = text_cp1251_str.encode("cp1251")
    co = zlib.compressobj(9, zlib.DEFLATED, -15)
    comp = co.compress(raw) + co.flush()
    # самопроверка: распакуется ли обратно ровно в то, что пишем
    assert zlib.decompress(comp, -15) == raw, "round-trip сжатия не сошёлся"

    import pythoncom
    from win32com.storagecon import STGM_READWRITE, STGM_SHARE_EXCLUSIVE, STGM_DIRECT

    root_mode = STGM_READWRITE | STGM_SHARE_EXCLUSIVE | STGM_DIRECT
    stg = pythoncom.StgOpenStorage(ert_path, None, root_mode)
    try:
        stm = stg.OpenStream(STREAM, None, STGM_READWRITE | STGM_SHARE_EXCLUSIVE, 0)
        stm.SetSize(len(comp))          # меняем размер потока под новые данные
        stm.Seek(0, 0)                  # STREAM_SEEK_SET
        stm.Write(comp)
        stm.Commit(0)
        stm = None
    finally:
        stg = None                      # освобождаем COM-ссылки -> flush на диск
    return len(comp), len(raw)


def read_source(path):
    """Авто-кодировка исходника: сперва UTF-8, иначе CP1251. Возврат как unicode."""
    b = open(path, "rb").read()
    try:
        s = b.decode("utf-8")
    except UnicodeDecodeError:
        s = b.decode("cp1251")
    # 1С хранит текст с CRLF
    return s.replace("\r\n", "\n").replace("\n", "\r\n")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    cmd, ert = sys.argv[1], sys.argv[2]
    if cmd == "get":
        txt = get_module(ert)
        if len(sys.argv) > 3:
            with open(sys.argv[3], "w", encoding="utf-8", newline="") as f:
                f.write(txt)
            print("извлечено %d симв -> %s" % (len(txt), sys.argv[3]))
        else:
            sys.stdout.buffer.write(txt.encode("utf-8"))
    elif cmd == "set":
        txt = read_source(sys.argv[3])
        comp, raw = set_module(ert, txt)
        print("записано: %d симв (%d байт CP1251) -> поток '%s' (%d байт сжато)"
              % (len(txt), raw, STREAM, comp))
    else:
        print("неизвестная команда:", cmd)
        sys.exit(1)


if __name__ == "__main__":
    main()
