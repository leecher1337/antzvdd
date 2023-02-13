#include <windows.h>

//
// WinMain
//

int PASCAL WinMain(HANDLE hInstance, HANDLE hPrevInstance,
                   LPSTR lpszCmdLine, int nCmdShow)
{
	char szPath[255];

	LoadLibrary("VNTD.DRV");
	wsprintf(szPath, "MISSION1.EXE %s", lpszCmdLine);
	WinExec(szPath, SW_SHOW);
}
