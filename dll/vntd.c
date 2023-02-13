/*************************************************************
 *
 *************************************************************
 * Module:   vntd.c
 * Descr.:   Main module and dispatcher. 
 * License:  GPL 3
 * Date  :   27.12.2022
 * Changelog:
 *************************************************************/
#define WIN32_LEAN_AND_MEAN
#define i386
#include <windows.h>
#include <vddsvc.h>
#include <wownt32.h>

#pragma comment (lib, "ntvdm.lib")
#pragma comment (lib, "wow32.lib")

typedef struct tagRegBuf
{
   unsigned short   Client_BX ;
   unsigned short   Client_CX ;
   unsigned short   Client_AX ;
   unsigned short   Client_DX ;
} REGBUF;

#pragma data_seg(".SHARED")
REGBUF reg_buffer[196];

unsigned short reg_buffer_offset = 0, func3_v86_bx = 0, func4_bx = 0, func6_v86_bx = 0, func7_v86_bx = 0;
HWND hWnd = NULL;
#pragma data_seg()
#pragma comment(linker,"/SECTION:.SHARED,RWS")

#ifdef TRACE
static void DumpRegs(char *pszProc)
{
	char szBuf[128];

	wsprintf(szBuf, "%s: DI=%04X, AX=%04X, BX=%04X, CX=%04X, DX=%04X\n", pszProc, getDI(), getBP(), getBX(), getCX(), getDX());
	OutputDebugString(szBuf);
}


static void DumpHWnd(void)
{
	char szBuf[128];

	wsprintf(szBuf, "hWnd=%08X\n", hWnd);
	OutputDebugString(szBuf);
}
#else
#define DumpRegs(x)
#define DumpHWnd()
#endif

// Windows End (PM = Protected Mode):
__declspec(dllexport) VOID __cdecl PM_0(void)
{
	DumpRegs("PM_0");
    switch ( getDI() & 0xF )
    {
      case 0:
        //Param1 = getAX();
        //pfnFuncOffs = getBX();
        //pfnFuncSelector = getCX();
		  hWnd = FULLHWND_32(getBP()); // AX = function number, therefore we take BP as alternative
		  DumpHWnd();
        break;
      case 1:
        setBX(reg_buffer[reg_buffer_offset].Client_BX);
        setCX(reg_buffer[reg_buffer_offset].Client_CX);
        setAX(reg_buffer[reg_buffer_offset].Client_AX);
        setDX(reg_buffer[reg_buffer_offset].Client_DX);
        reg_buffer_offset++;
        break;
      case 2:
        reg_buffer[reg_buffer_offset].Client_BX = getBX();
        reg_buffer[reg_buffer_offset].Client_CX = getCX();
        reg_buffer[reg_buffer_offset].Client_AX = getAX();
        reg_buffer[reg_buffer_offset].Client_DX = getDX();
        reg_buffer_offset++;
        break;
      case 3:
        func3_v86_bx = 0;
		setCF(0);
        break;
      case 4:
        setBX(func4_bx);
        reg_buffer_offset = 0;
        break;
      case 5:
        func4_bx = getBX();
        reg_buffer_offset = 0;
        break;
      case 6:
        func6_v86_bx = getBX();
        func4_bx = 0;
        reg_buffer_offset = 0;
        func3_v86_bx = 0;
        func7_v86_bx = 0;
        break;
      case 7:
        func7_v86_bx = getBX();
        break;
    }
}

// DOS end (V86)
__declspec(dllexport) VOID __cdecl V86_0(void)
{
	DumpRegs("V86_0");
    switch ( getDI() & 0xF )
    {
      case 0:
        //pfnFunc(Param1, 0x500, a1->Client_BX, a1->Client_DX, a1->Client_AX);
		PostMessage(hWnd, WM_USER + 0x100, getBX(), ((LPARAM)getDX() << 16 |  getBP()));
		DumpHWnd();
        break;
      case 1:
        setBX(reg_buffer[reg_buffer_offset].Client_BX);
        setCX(reg_buffer[reg_buffer_offset].Client_CX);
        setAX(reg_buffer[reg_buffer_offset].Client_AX);
        setDX(reg_buffer[reg_buffer_offset].Client_DX);
        reg_buffer_offset++;
        break;
      case 2:
        reg_buffer[reg_buffer_offset].Client_BX = getBX();
        reg_buffer[reg_buffer_offset].Client_CX = getCX();
        reg_buffer[reg_buffer_offset].Client_AX = getAX();
        reg_buffer[reg_buffer_offset].Client_DX = getDX();
        reg_buffer_offset++;
        break;
      case 3:
        setBX(func3_v86_bx);
        break;
      case 4:
        setBX(func4_bx);
        reg_buffer_offset = 0;
        break;
      case 5:
        func4_bx = getBX();
        reg_buffer_offset = 0;
        func3_v86_bx = 1;
        break;
      case 6:
        setBX(func6_v86_bx);
        break;
      case 7:
        setBX(func7_v86_bx);
        break;
      }
      setCF(0);
}

__declspec(dllexport) BOOL __cdecl
VDDInitialize(
    HANDLE   hVdd,
    DWORD    dwReason,
    LPVOID   lpReserved)
{
    return TRUE;
}

__declspec(dllexport) VOID __cdecl
VDDRegisterInit(
    VOID
    )
{
    setCF(0);
}

