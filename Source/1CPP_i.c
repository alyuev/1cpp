

/* this ALWAYS GENERATED file contains the IIDs and CLSIDs */

/* link this file in with the server and any clients */


 /* File created by MIDL compiler version 6.00.0366 */
/* at Thu Apr 29 09:33:17 2010
 */
/* Compiler settings for 1CPP.idl:
    Oicf, W1, Zp8, env=Win32 (32b run)
    protocol : dce , ms_ext, c_ext, robust
    error checks: allocation ref bounds_check enum stub_data 
    VC __declspec() decoration level: 
         __declspec(uuid()), __declspec(selectany), __declspec(novtable)
         DECLSPEC_UUID(), MIDL_INTERFACE()
*/
//@@MIDL_FILE_HEADING(  )

#pragma warning( disable: 4049 )  /* more than 64k source lines */


#ifdef __cplusplus
extern "C"{
#endif 


#include <rpc.h>
#include <rpcndr.h>

#ifdef _MIDL_USE_GUIDDEF_

#ifndef INITGUID
#define INITGUID
#include <guiddef.h>
#undef INITGUID
#else
#include <guiddef.h>
#endif

#define MIDL_DEFINE_GUID(type,name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8) \
        DEFINE_GUID(name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8)

#else // !_MIDL_USE_GUIDDEF_

#ifndef __IID_DEFINED__
#define __IID_DEFINED__

typedef struct _IID
{
    unsigned long x;
    unsigned short s1;
    unsigned short s2;
    unsigned char  c[8];
} IID;

#endif // __IID_DEFINED__

#ifndef CLSID_DEFINED
#define CLSID_DEFINED
typedef IID CLSID;
#endif // CLSID_DEFINED

#define MIDL_DEFINE_GUID(type,name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8) \
        const type name = {l,w1,w2,{b1,b2,b3,b4,b5,b6,b7,b8}}

#endif !_MIDL_USE_GUIDDEF_

MIDL_DEFINE_GUID(IID, IID_IInitDone,0xAB634001,0xF13D,0x11d0,0xA4,0x59,0x00,0x40,0x95,0xE1,0xDA,0xEA);


MIDL_DEFINE_GUID(IID, IID_IPropertyProfile,0xAB634002,0xF13D,0x11d0,0xA4,0x59,0x00,0x40,0x95,0xE1,0xDA,0xEA);


MIDL_DEFINE_GUID(IID, IID_IAsyncEvent,0xab634004,0xf13d,0x11d0,0xa4,0x59,0x00,0x40,0x95,0xe1,0xda,0xea);


MIDL_DEFINE_GUID(IID, IID_ILanguageExtender,0xAB634003,0xF13D,0x11d0,0xA4,0x59,0x00,0x40,0x95,0xE1,0xDA,0xEA);


MIDL_DEFINE_GUID(IID, IID_IStatusLine,0xab634005,0xf13d,0x11d0,0xa4,0x59,0x00,0x40,0x95,0xe1,0xda,0xea);


MIDL_DEFINE_GUID(IID, IID_IExtWndsSupport,0xefe19ea0,0x09e4,0x11d2,0xa6,0x01,0x00,0x80,0x48,0xda,0x00,0xde);


MIDL_DEFINE_GUID(IID, IID_IPropertyLink,0x52512A61,0x2A9D,0x11d1,0xA4,0xD6,0x00,0x40,0x95,0xE1,0xDA,0xEA);


MIDL_DEFINE_GUID(IID, LIBID_Addin,0x3A5F0172,0x87E1,0x4ab6,0xBE,0x86,0x39,0x06,0x6F,0x6E,0x0A,0xB9);


MIDL_DEFINE_GUID(CLSID, CLSID_ExtraC,0xFDE5AE76,0x00B3,0x4bdb,0x92,0x1B,0xD5,0x93,0x79,0x97,0xB1,0xB7);


MIDL_DEFINE_GUID(CLSID, CLSID_AddInConnection,0x3DB19F89,0xE57D,0x4698,0xA6,0xDC,0x4C,0xD7,0x02,0xFA,0x9B,0x4D);

#undef MIDL_DEFINE_GUID

#ifdef __cplusplus
}
#endif



