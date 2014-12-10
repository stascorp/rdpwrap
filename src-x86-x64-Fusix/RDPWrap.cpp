/*
  Copyright 2014 Stas'M Corp.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

#include "stdafx.h"
#include "IniFile.h"
#include <stdlib.h>

typedef struct
{
	union
	{
		struct
		{
			WORD Minor;
			WORD Major;
		} wVersion;
		DWORD dwVersion;
	};
	WORD Release;
	WORD Build;
} FILE_VERSION;

#ifdef _WIN64
typedef unsigned long long PLATFORM_DWORD;
struct FARJMP
{	// x64 far jump | opcode | assembly
	BYTE MovOp;		// 48	mov rax, ptr
	BYTE MovRegArg;	// B8
	DWORD64 MovArg;	// PTR
	BYTE PushRaxOp; // 50	push rax
	BYTE RetOp;		// C3	retn
};
#else
typedef unsigned long PLATFORM_DWORD;
struct FARJMP
{	// x86 far jump | opcode | assembly
	BYTE PushOp;	// 68	push ptr
	DWORD PushArg;	// PTR
	BYTE RetOp;		// C3	retn
};
#endif

FARJMP Old_SLGetWindowsInformationDWORD, Stub_SLGetWindowsInformationDWORD;
SLGETWINDOWSINFORMATIONDWORD _SLGetWindowsInformationDWORD;

INI_FILE *IniFile;
wchar_t LogFile[256] = L"\\rdpwrap.txt\0";
HMODULE hTermSrv;
HMODULE hSLC;
PLATFORM_DWORD TermSrvBase;
FILE_VERSION FV;
SERVICEMAIN _ServiceMain;
SVCHOSTPUSHSERVICEGLOBALS _SvchostPushServiceGlobals;
bool AlreadyHooked = false;

DWORD INIReadDWordHex(INI_FILE *IniFile, char *Sect, char *VariableName, PLATFORM_DWORD Default)
{
	INI_VAR_DWORD Variable;

	if(IniFile->GetVariableInSection(Sect, VariableName, &Variable))
	{
		return Variable.ValueHex;
	}
	return Default;
}

void INIReadString(INI_FILE *IniFile, char *Sect, char *VariableName, char *Default, char *Ret, DWORD RetSize)
{
	INI_VAR_STRING Variable;

	memset(Ret, 0x00, RetSize);
	if(!IniFile->GetVariableInSection(Sect, VariableName, &Variable))
	{
		strcpy_s(Ret, RetSize, Default);
		return;
	}
	strcpy_s(Ret, RetSize, Variable.Value);
}

void WriteToLog(LPSTR Text)
{
	DWORD dwBytesOfWritten;

	HANDLE hFile = CreateFile(LogFile, GENERIC_WRITE, FILE_SHARE_WRITE | FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	if (hFile == INVALID_HANDLE_VALUE) return;

	SetFilePointer(hFile, 0, 0, FILE_END);
	WriteFile(hFile, Text, strlen(Text), &dwBytesOfWritten, NULL);
	CloseHandle(hFile);
}

HMODULE GetCurrentModule()
{
	HMODULE hModule = NULL;
	GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, (LPCWSTR)GetCurrentModule, &hModule);
	return hModule;
}

/*PLATFORM_DWORD SearchAddressBySignature(char *StartPosition, PLATFORM_DWORD Size, char *Signature, int SignatureSize)
{
	PLATFORM_DWORD AddressReturn = -1;

	for (PLATFORM_DWORD i = 0; i < Size; i++)
	{
		for (int j = 0; StartPosition[i+j] == Signature[j] && j < SignatureSize; j++)
		{
			if (j == SignatureSize-1) AddressReturn = (PLATFORM_DWORD)&StartPosition[i];
		}
	}

	return AddressReturn;
}*/

bool GetModuleCodeSectionInfo(HMODULE hModule, PLATFORM_DWORD *BaseAddr, PLATFORM_DWORD *BaseSize)
{
	PIMAGE_DOS_HEADER		pDosHeader;
	PIMAGE_FILE_HEADER      pFileHeader;
	PIMAGE_OPTIONAL_HEADER  pOptionalHeader;

	if (hModule == NULL) return false;

	pDosHeader = (PIMAGE_DOS_HEADER)hModule;
	pFileHeader = (PIMAGE_FILE_HEADER)(((PBYTE)hModule)+pDosHeader->e_lfanew+4);
	pOptionalHeader = (PIMAGE_OPTIONAL_HEADER)(pFileHeader+1);

	*BaseAddr = (PLATFORM_DWORD)hModule;
	*BaseSize = (PLATFORM_DWORD)pOptionalHeader->SizeOfCode;

	if (*BaseAddr <= 0 || *BaseSize <= 0) return false;
	return true;
}

void SetThreadsState(bool Resume)
{
	HANDLE h, hThread;
	DWORD CurrTh, CurrPr;
	THREADENTRY32 Thread;

	CurrTh = GetCurrentThreadId();
	CurrPr = GetCurrentProcessId();

	h = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
	if (h != INVALID_HANDLE_VALUE)
	{
		Thread.dwSize = sizeof(THREADENTRY32);
		Thread32First(h, &Thread);
		do
		{
			if (Thread.th32ThreadID != CurrTh && Thread.th32OwnerProcessID == CurrPr)
			{
				hThread = OpenThread(THREAD_SUSPEND_RESUME, false, Thread.th32ThreadID);
				if (hThread != INVALID_HANDLE_VALUE)
				{
					if (Resume)		ResumeThread(hThread);
					else			SuspendThread(hThread);
					CloseHandle(hThread);
				}
			}
		} while (Thread32Next(h, &Thread));
		CloseHandle(h);
	}
}

BOOL __stdcall GetModuleVersion(LPCWSTR lptstrModuleName, FILE_VERSION *FileVersion)
{
	typedef struct
	{
		WORD             wLength;
		WORD             wValueLength;
		WORD             wType;
		WCHAR            szKey[16];
		WORD             Padding1;
		VS_FIXEDFILEINFO Value;
		WORD             Padding2;
		WORD             Children;
	} VS_VERSIONINFO;

	HMODULE hMod = GetModuleHandle(lptstrModuleName);
	if(!hMod)
	{
		return false;
	}

	HRSRC hResourceInfo = FindResourceW(hMod, (LPCWSTR)1, (LPCWSTR)0x10);
	if(!hResourceInfo)
	{
		return false;
	}

	VS_VERSIONINFO *VersionInfo = (VS_VERSIONINFO*)LoadResource(hMod, hResourceInfo);
	if(!VersionInfo)
	{
		return false;
	}

	FileVersion->dwVersion = VersionInfo->Value.dwFileVersionMS;
	FileVersion->Release = (WORD)(VersionInfo->Value.dwFileVersionLS >> 16);
	FileVersion->Build = (WORD)VersionInfo->Value.dwFileVersionLS;

	return true;
}

BOOL __stdcall GetFileVersion(LPCWSTR lptstrFilename, FILE_VERSION *FileVersion)
{
	typedef struct
	{
		WORD             wLength;
		WORD             wValueLength;
		WORD             wType;
		WCHAR            szKey[16];
		WORD             Padding1;
		VS_FIXEDFILEINFO Value;
		WORD             Padding2;
		WORD             Children;
	} VS_VERSIONINFO;

	HMODULE hFile = LoadLibraryExW(lptstrFilename, NULL, LOAD_LIBRARY_AS_DATAFILE);
	if(!hFile)
	{
		return false;
	}

	HRSRC hResourceInfo = FindResourceW(hFile, (LPCWSTR)1, (LPCWSTR)0x10);
	if(!hResourceInfo)
	{
		return false;
	}

	VS_VERSIONINFO *VersionInfo = (VS_VERSIONINFO*)LoadResource(hFile, hResourceInfo);
	if(!VersionInfo)
	{
		return false;
	}

	FileVersion->dwVersion = VersionInfo->Value.dwFileVersionMS;
	FileVersion->Release = (WORD)(VersionInfo->Value.dwFileVersionLS >> 16);
	FileVersion->Build = (WORD)VersionInfo->Value.dwFileVersionLS;

	return true;
}

bool OverrideSL(LPWSTR ValueName, DWORD *Value)
{
	INI_VAR_DWORD Variable = {0};

	if (IniFile->VariableExists(L"SLPolicy", ValueName))
	{
		if (!(IniFile->GetVariableInSection(L"SLPolicy", ValueName, &Variable))) *Value = 0;
		else *Value = Variable.ValueDec;
		return true;
	}
	return false;
}

HRESULT WINAPI New_SLGetWindowsInformationDWORD(PWSTR pwszValueName, DWORD *pdwValue)
{
	// wrapped SLGetWindowsInformationDWORD function
	// termsrv.dll will call this function instead of original SLC.dll

	// Override SL Policy

	extern FARJMP Old_SLGetWindowsInformationDWORD, Stub_SLGetWindowsInformationDWORD;
	extern SLGETWINDOWSINFORMATIONDWORD _SLGetWindowsInformationDWORD;

	char *Log;
	DWORD dw;
	SIZE_T bw;
	HRESULT Result;

	Log = new char[1024];
	wsprintfA(Log, "Policy query: %S\r\n", pwszValueName);
	WriteToLog(Log);
	delete[] Log;

	if (OverrideSL(pwszValueName, &dw))
	{
		*pdwValue = dw;

		Log = new char[1024];
		wsprintfA(Log, "Policy rewrite: %i\r\n", dw);
		WriteToLog(Log);
		delete[] Log;

		return S_OK;
	}

	WriteProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Old_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);
	Result = _SLGetWindowsInformationDWORD(pwszValueName, pdwValue);
	if (Result == S_OK)
	{
		Log = new char[1024];
		wsprintfA(Log, "Policy result: %i\r\n", dw);
		WriteToLog(Log);
		delete[] Log;
	} else {
		WriteToLog("Policy request failed\r\n");
	}
	WriteProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Stub_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);

	return Result;
}

HRESULT __fastcall New_Win8SL(PWSTR pwszValueName, DWORD *pdwValue)
{
	// wrapped unexported function SLGetWindowsInformationDWORDWrapper in termsrv.dll
	// for Windows 8 support

	// Override SL Policy

	extern SLGETWINDOWSINFORMATIONDWORD _SLGetWindowsInformationDWORD;

	char *Log;
	DWORD dw;
	HRESULT Result;

	Log = new char[1024];
	wsprintfA(Log, "Policy query: %S\r\n", pwszValueName);
	WriteToLog(Log);
	delete[] Log;

	if (OverrideSL(pwszValueName, &dw))
	{
		*pdwValue = dw;

		Log = new char[1024];
		wsprintfA(Log, "Policy rewrite: %i\r\n", dw);
		WriteToLog(Log);
		delete[] Log;

		return S_OK;
	}

	Result = _SLGetWindowsInformationDWORD(pwszValueName, pdwValue);
	if (Result == S_OK)
	{
		Log = new char[1024];
		wsprintfA(Log, "Policy result: %i\r\n", dw);
		WriteToLog(Log);
		delete[] Log;
	} else {
		WriteToLog("Policy request failed\r\n");
	}

	return Result;
}

#ifndef _WIN64
HRESULT __fastcall New_Win8SL_CP(DWORD arg1, DWORD *pdwValue, PWSTR pwszValueName, DWORD arg4)
{
	// wrapped unexported function SLGetWindowsInformationDWORDWrapper in termsrv.dll
	// for Windows 8 Consumer Preview support

	return New_Win8SL(pwszValueName, pdwValue);
}
#endif

HRESULT WINAPI New_CSLQuery_Initialize()
{
	extern PLATFORM_DWORD TermSrvBase;
	extern FILE_VERSION FV;

	char *Log;
	DWORD *bServerSku = NULL;
	DWORD *bRemoteConnAllowed = NULL;
	DWORD *bFUSEnabled = NULL;
	DWORD *bAppServerAllowed = NULL;
	DWORD *bMultimonAllowed = NULL;
	DWORD *lMaxUserSessions = NULL;
	DWORD *ulMaxDebugSessions = NULL;
	DWORD *bInitialized = NULL;

	WriteToLog(">>> CSLQuery::Initialize\r\n");

	char *Sect;
	Sect = new char[256];
	memset(Sect, 0x00, 256);
	wsprintfA(Sect, "%d.%d.%d.%d-SLInit", FV.wVersion.Major, FV.wVersion.Minor, FV.Release, FV.Build);

	if (IniFile->SectionExists(Sect))
	{
		#ifdef _WIN64
		bServerSku = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bServerSku.x64", 0));
		bRemoteConnAllowed = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bRemoteConnAllowed.x64", 0));
		bFUSEnabled = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bFUSEnabled.x64", 0));
		bAppServerAllowed = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bAppServerAllowed.x64", 0));
		bMultimonAllowed = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bMultimonAllowed.x64", 0));
		lMaxUserSessions = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "lMaxUserSessions.x64", 0));
		ulMaxDebugSessions = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "ulMaxDebugSessions.x64", 0));
		bInitialized = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bInitialized.x64", 0));
		#else
		bServerSku = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bServerSku.x86", 0));
		bRemoteConnAllowed = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bRemoteConnAllowed.x86", 0));
		bFUSEnabled = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bFUSEnabled.x86", 0));
		bAppServerAllowed = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bAppServerAllowed.x86", 0));
		bMultimonAllowed = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bMultimonAllowed.x86", 0));
		lMaxUserSessions = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "lMaxUserSessions.x86", 0));
		ulMaxDebugSessions = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "ulMaxDebugSessions.x86", 0));
		bInitialized = (DWORD*)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "bInitialized.x86", 0));
		#endif
	}
	delete[] Sect;

	if (bServerSku)
	{
		*bServerSku = INIReadDWordHex(IniFile, "SLInit", "bServerSku", 1);

		Log = new char[1024];
		wsprintfA(Log, "SLInit [0x%p] bServerSku = %d\r\n", bServerSku, *bServerSku);
		WriteToLog(Log);
		delete[] Log;
	}
	if (bRemoteConnAllowed)
	{
		*bRemoteConnAllowed = INIReadDWordHex(IniFile, "SLInit", "bRemoteConnAllowed", 1);

		Log = new char[1024];
		wsprintfA(Log, "SLInit [0x%p] bRemoteConnAllowed = %d\r\n", bRemoteConnAllowed, *bRemoteConnAllowed);
		WriteToLog(Log);
		delete[] Log;
	}
	if (bFUSEnabled)
	{
		*bFUSEnabled = INIReadDWordHex(IniFile, "SLInit", "bFUSEnabled", 1);

		Log = new char[1024];
		wsprintfA(Log, "SLInit [0x%p] bFUSEnabled = %d\r\n", bFUSEnabled, *bFUSEnabled);
		WriteToLog(Log);
		delete[] Log;
	}
	if (bAppServerAllowed)
	{
		*bAppServerAllowed = INIReadDWordHex(IniFile, "SLInit", "bAppServerAllowed", 1);

		Log = new char[1024];
		wsprintfA(Log, "SLInit [0x%p] bAppServerAllowed = %d\r\n", bAppServerAllowed, *bAppServerAllowed);
		WriteToLog(Log);
		delete[] Log;
	}
	if (bMultimonAllowed)
	{
		*bMultimonAllowed = INIReadDWordHex(IniFile, "SLInit", "bMultimonAllowed", 1);

		Log = new char[1024];
		wsprintfA(Log, "SLInit [0x%p] bMultimonAllowed = %d\r\n", bMultimonAllowed, *bMultimonAllowed);
		WriteToLog(Log);
		delete[] Log;
	}
	if (lMaxUserSessions)
	{
		*lMaxUserSessions = INIReadDWordHex(IniFile, "SLInit", "lMaxUserSessions", 0);

		Log = new char[1024];
		wsprintfA(Log, "SLInit [0x%p] lMaxUserSessions = %d\r\n", lMaxUserSessions, *lMaxUserSessions);
		WriteToLog(Log);
		delete[] Log;
	}
	if (ulMaxDebugSessions)
	{
		*ulMaxDebugSessions = INIReadDWordHex(IniFile, "SLInit", "ulMaxDebugSessions", 0);

		Log = new char[1024];
		wsprintfA(Log, "SLInit [0x%p] ulMaxDebugSessions = %d\r\n", ulMaxDebugSessions, *ulMaxDebugSessions);
		WriteToLog(Log);
		delete[] Log;
	}
	if (bInitialized)
	{
		*bInitialized = INIReadDWordHex(IniFile, "SLInit", "bInitialized", 1);

		Log = new char[1024];
		wsprintfA(Log, "SLInit [0x%p] bInitialized = %d\r\n", bInitialized, *bInitialized);
		WriteToLog(Log);
		delete[] Log;
	}
	WriteToLog("<<< CSLQuery::Initialize\r\n");
	return S_OK;
}

void Hook()
{
	extern FARJMP Old_SLGetWindowsInformationDWORD, Stub_SLGetWindowsInformationDWORD;
	extern SLGETWINDOWSINFORMATIONDWORD _SLGetWindowsInformationDWORD;
	extern HMODULE hTermSrv;
	extern HMODULE hSLC;
	extern PLATFORM_DWORD TermSrvBase;
	extern FILE_VERSION FV;
	extern wchar_t LogFile[256];

	AlreadyHooked = true;
	char *Log;

	wchar_t ConfigFile[256] = { 0x00 };
	WriteToLog("Loading configuration...\r\n");

	GetModuleFileName(GetCurrentModule(), ConfigFile, 255);
	for (DWORD i = wcslen(ConfigFile); i > 0; i--)
	{
		if (ConfigFile[i] == '\\')
		{
			memset(&ConfigFile[i + 1], 0x00, ((256 - (i + 1))) * 2);
			memcpy(&ConfigFile[i + 1], L"rdpwrap.ini", strlen("rdpwrap.ini") * 2);
			break;
		}
	}

	Log = new char[1024];
	wsprintfA(Log, "Configuration file: %S\r\n", ConfigFile);
	WriteToLog(Log);
	delete[] Log;

	IniFile = new INI_FILE(ConfigFile);
	// TODO: implement this
	if (IniFile == NULL)
	{
		WriteToLog("Error: Failed to load configuration\r\n");
		return;
	}

	INI_VAR_STRING LogFileVar;

	if(!(IniFile->GetVariableInSection("Main", "LogFile", &LogFileVar)))
	{
		GetModuleFileName(GetCurrentModule(), LogFile, 255);
		for(DWORD i = wcslen(LogFile); i > 0; i--)
		{
			if(LogFile[i] == '\\')
			{
				memset(&LogFile[i+1], 0x00, ((256-(i+1)))*2);
				memcpy(&LogFile[i+1], L"rdpwrap.txt", strlen("rdpwrap.txt")*2);
				break;
			}
		}
	}
	else
	{
		// TODO: Change it before add UNICODE in IniFile
		wchar_t wcLogFile[256];
		memset(wcLogFile, 0x00, 256);
		mbstowcs(wcLogFile, LogFileVar.Value, 255);
		wcscpy(LogFile, wcLogFile);
	}

	SIZE_T bw;
	WORD Ver = 0;
	PLATFORM_DWORD TermSrvSize, SignPtr;
	FARJMP Jump;

	WriteToLog("Initializing RDP Wrapper...\r\n");

	hTermSrv = LoadLibrary(L"termsrv.dll");
	if (hTermSrv == 0)
	{
		WriteToLog("Error: Failed to load Terminal Services library\r\n");
		return;
	}
	_ServiceMain = (SERVICEMAIN)GetProcAddress(hTermSrv, "ServiceMain");
	_SvchostPushServiceGlobals = (SVCHOSTPUSHSERVICEGLOBALS)GetProcAddress(hTermSrv, "SvchostPushServiceGlobals");

	Log = new char[4096];
	wsprintfA(Log,
		"Base addr:  0x%p\r\n"
		"SvcMain:    termsrv.dll+0x%p\r\n"
		"SvcGlobals: termsrv.dll+0x%p\r\n",
		hTermSrv,
		(PLATFORM_DWORD)_ServiceMain - (PLATFORM_DWORD)hTermSrv,
		(PLATFORM_DWORD)_SvchostPushServiceGlobals - (PLATFORM_DWORD)hTermSrv);
	WriteToLog(Log);
	delete[] Log;

	// check termsrv version
	if (GetModuleVersion(L"termsrv.dll", &FV))
	{
		Ver = (BYTE)FV.wVersion.Minor | ((BYTE)FV.wVersion.Major << 8);
	} else {
		// check NT version
		// Ver = GetVersion(); // deprecated
		// Ver = ((Ver & 0xFF) << 8) | ((Ver & 0xFF00) >> 8);
	}
	if (Ver == 0)
	{
		WriteToLog("Error: Failed to detect Terminal Services version\r\n");
		return;
	}

	Log = new char[1024];
	wsprintfA(Log, "Version:    %d.%d.%d.%d\r\n", FV.wVersion.Major, FV.wVersion.Minor, FV.Release, FV.Build);
	WriteToLog(Log);
	delete[] Log;

	// temporarily freeze threads
	WriteToLog("Freezing threads...\r\n");
	SetThreadsState(false);

	bool Bool;
	if (!(IniFile->GetVariableInSection("Main", "SLPolicyHookNT60", &Bool))) Bool = true;

	if ((Ver == 0x0600) && Bool)
	{
		// Windows Vista
		// uses SL Policy API (slc.dll)

		// load slc.dll and hook function
		hSLC = LoadLibrary(L"slc.dll");
		_SLGetWindowsInformationDWORD = (SLGETWINDOWSINFORMATIONDWORD)GetProcAddress(hSLC, "SLGetWindowsInformationDWORD");
		if (_SLGetWindowsInformationDWORD != INVALID_HANDLE_VALUE)
		{
			// rewrite original function to call our function (make hook)

			WriteToLog("Hook SLGetWindowsInformationDWORD\r\n");
			#ifdef _WIN64
			Stub_SLGetWindowsInformationDWORD.MovOp = 0x48;
			Stub_SLGetWindowsInformationDWORD.MovRegArg = 0xB8;
			Stub_SLGetWindowsInformationDWORD.MovArg = (PLATFORM_DWORD)New_SLGetWindowsInformationDWORD;
			Stub_SLGetWindowsInformationDWORD.PushRaxOp = 0x50;
			Stub_SLGetWindowsInformationDWORD.RetOp = 0xC3;
			#else
			Stub_SLGetWindowsInformationDWORD.PushOp = 0x68;
			Stub_SLGetWindowsInformationDWORD.PushArg = (PLATFORM_DWORD)New_SLGetWindowsInformationDWORD;
			Stub_SLGetWindowsInformationDWORD.RetOp = 0xC3;
			#endif

			ReadProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Old_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);
			WriteProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Stub_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);
		}
	}

	if (!(IniFile->GetVariableInSection("Main", "SLPolicyHookNT61", &Bool))) Bool = true;

	if ((Ver == 0x0601) && Bool)
	{
		// Windows 7
		// uses SL Policy API (slc.dll)

		// load slc.dll and hook function
		hSLC = LoadLibrary(L"slc.dll");
		_SLGetWindowsInformationDWORD = (SLGETWINDOWSINFORMATIONDWORD)GetProcAddress(hSLC, "SLGetWindowsInformationDWORD");
		if (_SLGetWindowsInformationDWORD != INVALID_HANDLE_VALUE)
		{
			// rewrite original function to call our function (make hook)

			WriteToLog("Hook SLGetWindowsInformationDWORD\r\n");
			#ifdef _WIN64
			Stub_SLGetWindowsInformationDWORD.MovOp = 0x48;
			Stub_SLGetWindowsInformationDWORD.MovRegArg = 0xB8;
			Stub_SLGetWindowsInformationDWORD.MovArg = (PLATFORM_DWORD)New_SLGetWindowsInformationDWORD;
			Stub_SLGetWindowsInformationDWORD.PushRaxOp = 0x50;
			Stub_SLGetWindowsInformationDWORD.RetOp = 0xC3;
			#else
			Stub_SLGetWindowsInformationDWORD.PushOp = 0x68;
			Stub_SLGetWindowsInformationDWORD.PushArg = (PLATFORM_DWORD)New_SLGetWindowsInformationDWORD;
			Stub_SLGetWindowsInformationDWORD.RetOp = 0xC3;
			#endif

			ReadProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Old_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);
			WriteProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Stub_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);
		}
	}
	if (Ver == 0x0602)
	{
		// Windows 8
		// uses SL Policy internal unexported function

		// load slc.dll and get function
		// (will be used on intercepting undefined values)
		hSLC = LoadLibrary(L"slc.dll");
		_SLGetWindowsInformationDWORD = (SLGETWINDOWSINFORMATIONDWORD)GetProcAddress(hSLC, "SLGetWindowsInformationDWORD");
	}
	if (Ver == 0x0603)
	{
		// Windows 8.1
		// uses SL Policy internal inline code
	}
	if (Ver == 0x0604)
	{
		// Windows 10
		// uses SL Policy internal inline code
	}

	char *Sect;
	INI_VAR_STRING PatchName;
	INI_VAR_BYTEARRAY Patch;
	Sect = new char[256];
	memset(Sect, 0x00, 256);
	wsprintfA(Sect, "%d.%d.%d.%d", FV.wVersion.Major, FV.wVersion.Minor, FV.Release, FV.Build);

	if (IniFile->SectionExists(Sect))
	{
		if (GetModuleCodeSectionInfo(hTermSrv, &TermSrvBase, &TermSrvSize))
		{
			#ifdef _WIN64
			if (!(IniFile->GetVariableInSection(Sect, "LocalOnlyPatch.x64", &Bool))) Bool = false;
			#else
			if (!(IniFile->GetVariableInSection(Sect, "LocalOnlyPatch.x86", &Bool))) Bool = false;
			#endif
			if (Bool)
			{
				WriteToLog("Patch CEnforcementCore::GetInstanceOfTSLicense\r\n");
				Bool = false;
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "LocalOnlyOffset.x64", 0));
				Bool = IniFile->GetVariableInSection(Sect, "LocalOnlyCode.x64", &PatchName);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "LocalOnlyOffset.x86", 0));
				Bool = IniFile->GetVariableInSection(Sect, "LocalOnlyCode.x86", &PatchName);
				#endif
				if (Bool) Bool = IniFile->GetVariableInSection("PatchCodes", PatchName.Value, &Patch);
				if (Bool && (SignPtr > TermSrvBase)) WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, Patch.Value, Patch.ArraySize, &bw);
			}
			#ifdef _WIN64
			if (!(IniFile->GetVariableInSection(Sect, "SingleUserPatch.x64", &Bool))) Bool = false;
			#else
			if (!(IniFile->GetVariableInSection(Sect, "SingleUserPatch.x86", &Bool))) Bool = false;
			#endif
			if (Bool)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				Bool = false;
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "SingleUserOffset.x64", 0));
				Bool = IniFile->GetVariableInSection(Sect, "SingleUserCode.x64", &PatchName);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "SingleUserOffset.x86", 0));
				Bool = IniFile->GetVariableInSection(Sect, "SingleUserCode.x86", &PatchName);
				#endif
				if (Bool) Bool = IniFile->GetVariableInSection("PatchCodes", PatchName.Value, &Patch);
				if (Bool && (SignPtr > TermSrvBase)) WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, Patch.Value, Patch.ArraySize, &bw);
			}
			#ifdef _WIN64
			if (!(IniFile->GetVariableInSection(Sect, "DefPolicyPatch.x64", &Bool))) Bool = false;
			#else
			if (!(IniFile->GetVariableInSection(Sect, "DefPolicyPatch.x86", &Bool))) Bool = false;
			#endif
			if (Bool)
			{
				WriteToLog("Patch CDefPolicy::Query\r\n");
				Bool = false;
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "DefPolicyOffset.x64", 0));
				Bool = IniFile->GetVariableInSection(Sect, "DefPolicyCode.x64", &PatchName);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "DefPolicyOffset.x86", 0));
				Bool = IniFile->GetVariableInSection(Sect, "DefPolicyCode.x86", &PatchName);
				#endif
				if (Bool) Bool = IniFile->GetVariableInSection("PatchCodes", PatchName.Value, &Patch);
				if (Bool && (SignPtr > TermSrvBase)) WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, Patch.Value, Patch.ArraySize, &bw);
			}
			#ifdef _WIN64
			if (!(IniFile->GetVariableInSection(Sect, "SLPolicyInternal.x64", &Bool))) Bool = false;
			#else
			if (!(IniFile->GetVariableInSection(Sect, "SLPolicyInternal.x86", &Bool))) Bool = false;
			#endif
			if (Bool)
			{
				WriteToLog("Hook SLGetWindowsInformationDWORDWrapper\r\n");
				char *FuncName;
				FuncName = new char[1024];
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "SLPolicyOffset.x64", 0));
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;

				INIReadString(IniFile, Sect, "SLPolicyFunc.x64", "New_Win8SL", FuncName, 1024);

				if (strcmp(FuncName, "New_Win8SL"))
				{
					Jump.MovArg = (PLATFORM_DWORD)New_Win8SL;
				}
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "SLPolicyOffset.x86", 0));
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.RetOp = 0xC3;

				INIReadString(IniFile, Sect, "SLPolicyFunc.x86", "New_Win8SL", FuncName, 1024);

				if (strcmp(FuncName, "New_Win8SL"))
				{
					Jump.PushArg = (PLATFORM_DWORD)New_Win8SL;
				}
				if (strcmp(FuncName, "New_Win8SL_CP"))
				{
					Jump.PushArg = (PLATFORM_DWORD)New_Win8SL_CP;
				}
				#endif
				delete[] FuncName;
				if (SignPtr > TermSrvBase) WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
			#ifdef _WIN64
			if (!(IniFile->GetVariableInSection(Sect, "SLInitHook.x64", &Bool))) Bool = false;
			#else
			if (!(IniFile->GetVariableInSection(Sect, "SLInitHook.x86", &Bool))) Bool = false;
			#endif
			if (Bool)
			{
				WriteToLog("Hook CSLQuery::Initialize\r\n");
				char *FuncName;
				FuncName = new char[1024];
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "SLInitOffset.x64", 0));
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;

				INIReadString(IniFile, Sect, "SLInitFunc.x64", "New_CSLQuery_Initialize", FuncName, 1024);

				if (strcmp(FuncName, "New_CSLQuery_Initialize"))
				{
					Jump.MovArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				}
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + INIReadDWordHex(IniFile, Sect, "SLInitOffset.x86", 0));
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.RetOp = 0xC3;

				INIReadString(IniFile, Sect, "SLInitFunc.x86", "New_CSLQuery_Initialize", FuncName, 1024);

				if (strcmp(FuncName, "New_CSLQuery_Initialize"))
				{
					Jump.PushArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				}
				#endif
				delete[] FuncName;
				if (SignPtr > TermSrvBase) WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
		}
	}
	delete[] Sect;

	WriteToLog("Resumimg threads...\r\n");
	SetThreadsState(true);
	return;
}

void WINAPI ServiceMain(DWORD dwArgc, LPTSTR *lpszArgv)
{
	WriteToLog(">>> ServiceMain\r\n");
	if (!AlreadyHooked) Hook();

	if (_ServiceMain != NULL) _ServiceMain(dwArgc, lpszArgv);
	WriteToLog("<<< ServiceMain\r\n");
}

void WINAPI SvchostPushServiceGlobals(void *lpGlobalData)
{
	WriteToLog(">>> SvchostPushServiceGlobals\r\n");
	if (!AlreadyHooked) Hook();

	if (_SvchostPushServiceGlobals != NULL) _SvchostPushServiceGlobals(lpGlobalData);
	WriteToLog("<<< SvchostPushServiceGlobals\r\n");
}
