// ICL build compatibility: VC6 CRT (msvcrt.lib) does not provide the array
// operator delete[](void*); provide it here forwarding to the scalar operator.
#include <new>
void operator delete[](void* p) throw() { ::operator delete(p); }
