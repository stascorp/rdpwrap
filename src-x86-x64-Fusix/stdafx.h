// stdafx.h: включаемый файл дл€ стандартных системных включаемых файлов
// или включаемых файлов дл€ конкретного проекта, которые часто используютс€, но
// не часто измен€ютс€
//

#pragma once

#include "targetver.h"

#define WIN32_LEAN_AND_MEAN             // »сключите редко используемые компоненты из заголовков Windows
#define _CRT_SECURE_NO_WARNINGS


// ‘айлы заголовков Windows:
#include <windows.h>
#include <TlHelp32.h>


// TODO: ”становите здесь ссылки на дополнительные заголовки, требующиес€ дл€ программы

typedef VOID	(WINAPI* SERVICEMAIN)(DWORD, LPTSTR*);
typedef VOID	(WINAPI* SVCHOSTPUSHSERVICEGLOBALS)(VOID*);
typedef HRESULT (WINAPI* SLGETWINDOWSINFORMATIONDWORD)(PCWSTR, DWORD*);