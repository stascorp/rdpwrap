{
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
}

library rdpwrap;

uses
  SysUtils,
  Windows,
  TlHelp32,
  LiteINI;

{$R rdpwrap.res}

// Hook core definitions

type
  OldCode = packed record
    One: DWORD;
    two: Word;
  end;

  far_jmp = packed record
    PushOp: Byte;
    PushArg: Pointer;
    RetOp: Byte;
  end;

  mov_far_jmp = packed record
    MovOp: Byte;
    MovArg: Byte;
    PushOp: Byte;
    PushArg: Pointer;
    RetOp: Byte;
  end;

  TTHREADENTRY32 = packed record
    dwSize: DWORD;
    cntUsage: DWORD;
    th32ThreadID: DWORD;
    th32OwnerProcessID: DWORD;
    tpBasePri: LongInt;
    tpDeltaPri: LongInt;
    dwFlags: DWORD;
  end;
  //IntArray = Array of Integer;
  FILE_VERSION = record
    Version: record case Boolean of
      True: (dw: DWORD);
      False: (w: record
        Minor, Major: Word;
      end;)
    end;
    Release, Build: Word;
    bDebug, bPrerelease, bPrivate, bSpecial: Boolean;
  end;

const
  THREAD_SUSPEND_RESUME = 2;
  TH32CS_SNAPTHREAD = 4;
var
  INI: INIFile;
  LogFile: String = '\rdpwrap.txt';
  bw: {$if CompilerVersion>=16} NativeUInt {$else} DWORD {$endif};
  IsHooked: Boolean = False;

// Unhooked import

function OpenThread(dwDesiredAccess: DWORD; bInheritHandle: BOOL;
  dwThreadId: DWORD): DWORD; stdcall; external kernel32;

function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): DWORD;
  stdcall; external kernel32;

function Thread32First(hSnapshot: THandle; var lpte: TTHREADENTRY32): bool;
  stdcall; external kernel32;

function Thread32Next(hSnapshot: THandle; var lpte: TTHREADENTRY32): bool;
  stdcall; external kernel32;

// Wrapped import

var
  TSMain: function(dwArgc: DWORD; lpszArgv: PWideChar): DWORD; stdcall;
  TSGlobals: function(lpGlobalData: Pointer): DWORD; stdcall;

// Hooked import and vars

var
  SLGetWindowsInformationDWORD: function(pwszValueName: PWideChar;
    pdwValue: PDWORD): HRESULT; stdcall;
  TermSrvBase: Pointer;
  FV: FILE_VERSION;

var
  Stub_SLGetWindowsInformationDWORD: far_jmp;
  Old_SLGetWindowsInformationDWORD: OldCode;

// Main code

procedure WriteLog(S: AnsiString);
var
  F: TextFile;
begin
  if not FileExists(LogFile) then
    Exit;
  AssignFile(F, LogFile);
  Append(F);
  Write(F, S+#13#10);
  CloseFile(F);
end;

function GetModuleHandleEx(dwFlags: DWORD; lpModuleName: PWideChar;
  var phModule: HMODULE): BOOL; stdcall; external kernel32 name 'GetModuleHandleExW';

function GetCurrentModule: HMODULE;
const
  GET_MODULE_HANDLE_EX_FLAG_PIN = 1;
  GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT = 2;
  GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS = 4;
begin
  Result := 0;
  GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, @GetCurrentModule, Result);
end;

function GetBinaryPath: String;
var
  Buf: Array[0..511] of Byte;
begin
  ZeroMemory(@Buf[0], Length(Buf));
  GetModuleFileName(GetCurrentModule, PWideChar(@Buf[0]), Length(Buf));
  Result := PWideChar(@Buf[0]);
end;

procedure StopThreads;
var
  h, CurrTh, ThrHandle, CurrPr: DWORD;
  Thread: TTHREADENTRY32;
begin
  CurrTh := GetCurrentThreadId;
  CurrPr := GetCurrentProcessId;
  h := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if h <> INVALID_HANDLE_VALUE then
  begin
    Thread.dwSize := SizeOf(TTHREADENTRY32);
    if Thread32First(h, Thread) then
      repeat
        if (Thread.th32ThreadID <> CurrTh) and
          (Thread.th32OwnerProcessID = CurrPr) then
        begin
          ThrHandle := OpenThread(THREAD_SUSPEND_RESUME, false,
            Thread.th32ThreadID);
          if ThrHandle > 0 then
          begin
            SuspendThread(ThrHandle);
            CloseHandle(ThrHandle);
          end;
        end;
      until not Thread32Next(h, Thread);
      CloseHandle(h);
  end;
end;

procedure RunThreads;
var
  h, CurrTh, ThrHandle, CurrPr: DWORD;
  Thread: TTHREADENTRY32;
begin
  CurrTh := GetCurrentThreadId;
  CurrPr := GetCurrentProcessId;
  h := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if h <> INVALID_HANDLE_VALUE then
  begin
    Thread.dwSize := SizeOf(TTHREADENTRY32);
    if Thread32First(h, Thread) then
      repeat
        if (Thread.th32ThreadID <> CurrTh) and
          (Thread.th32OwnerProcessID = CurrPr) then
        begin
          ThrHandle := OpenThread(THREAD_SUSPEND_RESUME, false,
            Thread.th32ThreadID);
          if ThrHandle > 0 then
          begin
            ResumeThread(ThrHandle);
            CloseHandle(ThrHandle);
          end;
        end;
      until not Thread32Next(h, Thread);
      CloseHandle(h);
  end;
end;

function GetModuleAddress(ModuleName: String; ProcessId: DWORD; var BaseAddr: Pointer; var BaseSize: DWORD): Boolean;
var
  hSnap: THandle;
  md: MODULEENTRY32;
begin
  Result := False;
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, ProcessId);
  if hSnap = INVALID_HANDLE_VALUE Then
    Exit;
  md.dwSize := SizeOf(MODULEENTRY32);
  if Module32First(hSnap, md) then
  begin
    if LowerCase(ExtractFileName(md.szExePath)) = LowerCase(ModuleName) then
    begin
      Result := True;
      BaseAddr := Pointer(md.modBaseAddr);
      BaseSize := md.modBaseSize;
      CloseHandle(hSnap);
      Exit;
    end;
    while Module32Next(hSnap, md) Do
    begin
      if LowerCase(ExtractFileName(md.szExePath)) = LowerCase(ModuleName) then
      begin
        Result := True;
        BaseAddr := Pointer(md.modBaseAddr);
        BaseSize := md.modBaseSize;
        Break;
      end;
    end;
  end;
  CloseHandle(hSnap);
end;

{procedure FindMem(Mem: Pointer; MemSz: DWORD; Buf: Pointer; BufSz: DWORD;
  From: DWORD; var A: IntArray);
var
  I: Integer;
begin
  SetLength(A, 0);
  I:=From;
  if From>0 then
    Inc(PByte(Mem), From);
  while I < MemSz - BufSz + 1 do
  begin
    if (not IsBadReadPtr(Mem, BufSz)) and (CompareMem(Mem, Buf, BufSz)) then
    begin
      SetLength(A, Length(A)+1);
      A[Length(A)-1] := I;
    end;
    Inc(I);
    Inc(PByte(Mem));
  end;
end;}

function GetModuleVersion(const ModuleName: String; var FileVersion: FILE_VERSION): Boolean;
type
  VS_VERSIONINFO = record
    wLength, wValueLength, wType: Word;
    szKey: Array[1..16] of WideChar;
    Padding1: Word;
    Value: VS_FIXEDFILEINFO;
    Padding2, Children: Word;
  end;
  PVS_VERSIONINFO = ^VS_VERSIONINFO;
const
  VFF_DEBUG = 1;
  VFF_PRERELEASE = 2;
  VFF_PRIVATE = 8;
  VFF_SPECIAL = 32;
var
  hMod: HMODULE;
  hResourceInfo: HRSRC;
  VersionInfo: PVS_VERSIONINFO;
begin
  Result := False;

  if ModuleName = '' then
    hMod := GetModuleHandle(nil)
  else
    hMod := GetModuleHandle(PWideChar(ModuleName));
  if hMod = 0 then
    Exit;

  hResourceInfo := FindResource(hMod, PWideChar(1), PWideChar($10));
  if hResourceInfo = 0 then
    Exit;

  VersionInfo := Pointer(LoadResource(hMod, hResourceInfo));
  if VersionInfo = nil then
    Exit;

  FileVersion.Version.dw := VersionInfo.Value.dwFileVersionMS;
  FileVersion.Release := Word(VersionInfo.Value.dwFileVersionLS shr 16);
  FileVersion.Build := Word(VersionInfo.Value.dwFileVersionLS);
  FileVersion.bDebug := (VersionInfo.Value.dwFileFlags and VFF_DEBUG) = VFF_DEBUG;
  FileVersion.bPrerelease := (VersionInfo.Value.dwFileFlags and VFF_PRERELEASE) = VFF_PRERELEASE;
  FileVersion.bPrivate := (VersionInfo.Value.dwFileFlags and VFF_PRIVATE) = VFF_PRIVATE;
  FileVersion.bSpecial := (VersionInfo.Value.dwFileFlags and VFF_SPECIAL) = VFF_SPECIAL;

  Result := True;
end;

function GetFileVersion(const FileName: String; var FileVersion: FILE_VERSION): Boolean;
type
  VS_VERSIONINFO = record
    wLength, wValueLength, wType: Word;
    szKey: Array[1..16] of WideChar;
    Padding1: Word;
    Value: VS_FIXEDFILEINFO;
    Padding2, Children: Word;
  end;
  PVS_VERSIONINFO = ^VS_VERSIONINFO;
const
  VFF_DEBUG = 1;
  VFF_PRERELEASE = 2;
  VFF_PRIVATE = 8;
  VFF_SPECIAL = 32;
var
  hFile: HMODULE;
  hResourceInfo: HRSRC;
  VersionInfo: PVS_VERSIONINFO;
begin
  Result := False;

  hFile := LoadLibraryEx(PWideChar(FileName), 0, LOAD_LIBRARY_AS_DATAFILE);
  if hFile = 0 then
    Exit;

  hResourceInfo := FindResource(hFile, PWideChar(1), PWideChar($10));
  if hResourceInfo = 0 then
    Exit;

  VersionInfo := Pointer(LoadResource(hFile, hResourceInfo));
  if VersionInfo = nil then
    Exit;

  FileVersion.Version.dw := VersionInfo.Value.dwFileVersionMS;
  FileVersion.Release := Word(VersionInfo.Value.dwFileVersionLS shr 16);
  FileVersion.Build := Word(VersionInfo.Value.dwFileVersionLS);
  FileVersion.bDebug := (VersionInfo.Value.dwFileFlags and VFF_DEBUG) = VFF_DEBUG;
  FileVersion.bPrerelease := (VersionInfo.Value.dwFileFlags and VFF_PRERELEASE) = VFF_PRERELEASE;
  FileVersion.bPrivate := (VersionInfo.Value.dwFileFlags and VFF_PRIVATE) = VFF_PRIVATE;
  FileVersion.bSpecial := (VersionInfo.Value.dwFileFlags and VFF_SPECIAL) = VFF_SPECIAL;

  Result := True;
end;

function OverrideSL(ValueName: String; var Value: DWORD): Boolean;
begin
  Result := True;
  if INIValueExists(INI, 'SLPolicy', ValueName) then begin
    Value := INIReadDWord(INI, 'SLPolicy', ValueName, 0);
    Exit;
  end;
  Result := False;
end;

function New_SLGetWindowsInformationDWORD(pwszValueName: PWideChar;
  pdwValue: PDWORD): HRESULT; stdcall;
var
  dw: DWORD;
begin
  // wrapped SLGetWindowsInformationDWORD function
  // termsrv.dll will call this function instead of original SLC.dll

  // Override SL Policy

  WriteLog('Policy query: ' + pwszValueName);
  if OverrideSL(pwszValueName, dw) then begin
    pdwValue^ := dw;
    Result := S_OK;
    WriteLog('Policy rewrite: ' + IntToStr(pdwValue^));
    Exit;
  end;

  // If the requested value name is not defined above

  // revert to original SL Policy function
  WriteProcessMemory(GetCurrentProcess, @SLGetWindowsInformationDWORD,
    @Old_SLGetWindowsInformationDWORD, SizeOf(OldCode), bw);

  // get result
  Result := SLGetWindowsInformationDWORD(pwszValueName, pdwValue);
  if Result = S_OK then
    WriteLog('Policy result: ' + IntToStr(pdwValue^))
  else
    WriteLog('Policy request failed');
  // wrap it back
  WriteProcessMemory(GetCurrentProcess, @SLGetWindowsInformationDWORD,
    @Stub_SLGetWindowsInformationDWORD, SizeOf(far_jmp), bw);
end;

function New_Win8SL(pwszValueName: PWideChar; pdwValue: PDWORD): HRESULT; register;
var
  dw: DWORD;
begin
  // wrapped unexported function SLGetWindowsInformationDWORDWrapper in termsrv.dll
  // for Windows 8 support

  // Override SL Policy

  WriteLog('Policy query: ' + pwszValueName);
  if OverrideSL(pwszValueName, dw) then begin
    pdwValue^ := dw;
    Result := S_OK;
    WriteLog('Policy rewrite: ' + IntToStr(pdwValue^));
    Exit;
  end;

  // If the requested value name is not defined above
  // use function from SLC.dll

  Result := SLGetWindowsInformationDWORD(pwszValueName, pdwValue);
  if Result = S_OK then
    WriteLog('Policy result: ' + IntToStr(pdwValue^))
  else
    WriteLog('Policy request failed');
end;

function New_Win8SL_CP(eax: DWORD; pdwValue: PDWORD; ecx: DWORD; pwszValueName: PWideChar): HRESULT; register;
begin
  // wrapped unexported function SLGetWindowsInformationDWORDWrapper in termsrv.dll
  // for Windows 8 Consumer Preview support

  Result := New_Win8SL(pwszValueName, pdwValue);
end;

function New_CSLQuery_Initialize: HRESULT; stdcall;
var
  Sect: String;
  bServerSku,
  bRemoteConnAllowed,
  bFUSEnabled,
  bAppServerAllowed,
  bMultimonAllowed,
  lMaxUserSessions,
  ulMaxDebugSessions,
  bInitialized: PDWORD;
begin
  bServerSku := nil;
  bRemoteConnAllowed := nil;
  bFUSEnabled := nil;
  bAppServerAllowed := nil;
  bMultimonAllowed := nil;
  lMaxUserSessions := nil;
  ulMaxDebugSessions := nil;
  bInitialized := nil;
  WriteLog('>>> CSLQuery::Initialize');
  Sect := IntToStr(FV.Version.w.Major)+'.'+IntToStr(FV.Version.w.Minor)+'.'+
          IntToStr(FV.Release)+'.'+IntToStr(FV.Build)+'-SLInit';
  if INISectionExists(INI, Sect) then begin
    bServerSku := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'bServerSku.x86', 0));
    bRemoteConnAllowed := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'bRemoteConnAllowed.x86', 0));
    bFUSEnabled := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'bFUSEnabled.x86', 0));
    bAppServerAllowed := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'bAppServerAllowed.x86', 0));
    bMultimonAllowed := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'bMultimonAllowed.x86', 0));
    lMaxUserSessions := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'lMaxUserSessions.x86', 0));
    ulMaxDebugSessions := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'ulMaxDebugSessions.x86', 0));
    bInitialized := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'bInitialized.x86', 0));
  end;

  if bServerSku <> nil then begin
    bServerSku^ := INIReadDWord(INI, 'SLInit', 'bServerSku', 1);
    WriteLog('SLInit [0x'+IntToHex(DWORD(bServerSku), 1)+'] bServerSku = ' + IntToStr(bServerSku^));
  end;
  if bRemoteConnAllowed <> nil then begin
    bRemoteConnAllowed^ := INIReadDWord(INI, 'SLInit', 'bRemoteConnAllowed', 1);
    WriteLog('SLInit [0x'+IntToHex(DWORD(bRemoteConnAllowed), 1)+'] bRemoteConnAllowed = ' + IntToStr(bRemoteConnAllowed^));
  end;
  if bFUSEnabled <> nil then begin
    bFUSEnabled^ := INIReadDWord(INI, 'SLInit', 'bFUSEnabled', 1);
    WriteLog('SLInit [0x'+IntToHex(DWORD(bFUSEnabled), 1)+'] bFUSEnabled = ' + IntToStr(bFUSEnabled^));
  end;
  if bAppServerAllowed <> nil then begin
    bAppServerAllowed^ := INIReadDWord(INI, 'SLInit', 'bAppServerAllowed', 1);
    WriteLog('SLInit [0x'+IntToHex(DWORD(bAppServerAllowed), 1)+'] bAppServerAllowed = ' + IntToStr(bAppServerAllowed^));
  end;
  if bMultimonAllowed <> nil then begin
    bMultimonAllowed^ := INIReadDWord(INI, 'SLInit', 'bMultimonAllowed', 1);
    WriteLog('SLInit [0x'+IntToHex(DWORD(bMultimonAllowed), 1)+'] bMultimonAllowed = ' + IntToStr(bMultimonAllowed^));
  end;
  if lMaxUserSessions <> nil then begin
    lMaxUserSessions^ := INIReadDWord(INI, 'SLInit', 'lMaxUserSessions', 0);
    WriteLog('SLInit [0x'+IntToHex(DWORD(lMaxUserSessions), 1)+'] lMaxUserSessions = ' + IntToStr(lMaxUserSessions^));
  end;
  if ulMaxDebugSessions <> nil then begin
    ulMaxDebugSessions^ := INIReadDWord(INI, 'SLInit', 'ulMaxDebugSessions', 0);
    WriteLog('SLInit [0x'+IntToHex(DWORD(ulMaxDebugSessions), 1)+'] ulMaxDebugSessions = ' + IntToStr(ulMaxDebugSessions^));
  end;
  if bInitialized <> nil then begin
    bInitialized^ := INIReadDWord(INI, 'SLInit', 'bInitialized', 1);
    WriteLog('SLInit [0x'+IntToHex(DWORD(bInitialized), 1)+'] bInitialized = ' + IntToStr(bInitialized^));
  end;
  Result := S_OK;
  WriteLog('<<< CSLQuery::Initialize');
end;

procedure HookFunctions;
var
  ConfigFile, Sect, FuncName: String;
  V: DWORD;
  TS_Handle, SLC_Handle: THandle;
  TermSrvSize: DWORD;
  SignPtr: Pointer;
  I: Integer;
  PatchList: SList;
  Patch: Array of TBytes;
  Jump: far_jmp;
  MovJump: mov_far_jmp;
begin
  { hook function ^^
     (called once)   }
  IsHooked := True;
  TSMain := nil;
  TSGlobals := nil;
  SLGetWindowsInformationDWORD := nil;

  WriteLog('Loading configuration...');
  ConfigFile := ExtractFilePath(GetBinaryPath) + 'rdpwrap.ini';
  WriteLog('Configuration file: ' + ConfigFile);
  INILoad(INI, ConfigFile);
  if Length(INI) = 0 then begin
    WriteLog('Error: Failed to load configuration');
    Exit;
  end;

  LogFile := INIReadString(INI, 'Main', 'LogFile', ExtractFilePath(GetBinaryPath) + 'rdpwrap.txt');
  WriteLog('Initializing RDP Wrapper...');

  // load termsrv.dll and get functions
  TS_Handle := LoadLibrary('termsrv.dll');
  if TS_Handle = 0 then begin
    WriteLog('Error: Failed to load Terminal Services library');
    Exit;
  end;
  TSMain := GetProcAddress(TS_Handle, 'ServiceMain');
  TSGlobals := GetProcAddress(TS_Handle, 'SvchostPushServiceGlobals');
  WriteLog(
    'Base addr:  0x' + IntToHex(TS_Handle, 8) + #13#10 +
    'SvcMain:    termsrv.dll+0x' + IntToHex(Cardinal(@TSMain) - TS_Handle, 1) + #13#10 +
    'SvcGlobals: termsrv.dll+0x' + IntToHex(Cardinal(@TSGlobals) - TS_Handle, 1)
  );

  V := 0;
  // check termsrv version
  if GetModuleVersion('termsrv.dll', FV) then
    V := Byte(FV.Version.w.Minor) or (Byte(FV.Version.w.Major) shl 8)
  else begin
    // check NT version
    // V := GetVersion; // deprecated
    // V := ((V and $FF) shl 8) or ((V and $FF00) shr 8);
  end;
  if V = 0 then begin
    WriteLog('Error: Failed to detect Terminal Services version');
    Exit;
  end;

  WriteLog('Version:    '+
  IntToStr(FV.Version.w.Major)+'.'+
  IntToStr(FV.Version.w.Minor)+'.'+
  IntToStr(FV.Release)+'.'+
  IntToStr(FV.Build));

  // temporarily freeze threads
  WriteLog('Freezing threads...');
  StopThreads();

  WriteLog('Caching patch codes...');
  PatchList := INIReadSection(INI, 'PatchCodes');
  SetLength(Patch, Length(PatchList));
  for I := 0 to Length(Patch) - 1 do begin
    Patch[I] := INIReadBytes(INI, 'PatchCodes', PatchList[I]);
    if Length(Patch[I]) > 16 then  // for security reasons
      SetLength(Patch[I], 16);     // not more than 16 bytes
  end;

  if (V = $0600) and (INIReadBool(INI, 'Main', 'SLPolicyHookNT60', True)) then begin
    // Windows Vista
    // uses SL Policy API (slc.dll)

    // load slc.dll and hook function
    SLC_Handle := LoadLibrary('slc.dll');
    SLGetWindowsInformationDWORD := GetProcAddress(SLC_Handle, 'SLGetWindowsInformationDWORD');

    if @SLGetWindowsInformationDWORD <> nil then
    begin
      // rewrite original function to call our function (make hook)

      WriteLog('Hook SLGetWindowsInformationDWORD');
      Stub_SLGetWindowsInformationDWORD.PushOp := $68;
      Stub_SLGetWindowsInformationDWORD.PushArg := @New_SLGetWindowsInformationDWORD;
      Stub_SLGetWindowsInformationDWORD.RetOp := $C3;
      ReadProcessMemory(GetCurrentProcess, @SLGetWindowsInformationDWORD,
        @Old_SLGetWindowsInformationDWORD, SizeOf(OldCode), bw);
      WriteProcessMemory(GetCurrentProcess, @SLGetWindowsInformationDWORD,
        @Stub_SLGetWindowsInformationDWORD, SizeOf(far_jmp), bw);
    end;
  end;
  if (V = $0601) and (INIReadBool(INI, 'Main', 'SLPolicyHookNT61', True)) then begin
    // Windows 7
    // uses SL Policy API (slc.dll)

    // load slc.dll and hook function
    SLC_Handle := LoadLibrary('slc.dll');
    SLGetWindowsInformationDWORD := GetProcAddress(SLC_Handle, 'SLGetWindowsInformationDWORD');

    if @SLGetWindowsInformationDWORD <> nil then
    begin
      // rewrite original function to call our function (make hook)

      WriteLog('Hook SLGetWindowsInformationDWORD');
      Stub_SLGetWindowsInformationDWORD.PushOp := $68;
      Stub_SLGetWindowsInformationDWORD.PushArg := @New_SLGetWindowsInformationDWORD;
      Stub_SLGetWindowsInformationDWORD.RetOp := $C3;
      ReadProcessMemory(GetCurrentProcess, @SLGetWindowsInformationDWORD,
        @Old_SLGetWindowsInformationDWORD, SizeOf(OldCode), bw);
      WriteProcessMemory(GetCurrentProcess, @SLGetWindowsInformationDWORD,
        @Stub_SLGetWindowsInformationDWORD, SizeOf(far_jmp), bw);
    end;
  end;
  if V = $0602 then begin
    // Windows 8
    // uses SL Policy internal unexported function

    // load slc.dll and get function
    // (will be used on intercepting undefined values)
    SLC_Handle := LoadLibrary('slc.dll');
    SLGetWindowsInformationDWORD := GetProcAddress(SLC_Handle, 'SLGetWindowsInformationDWORD');
  end;
  if V = $0603 then begin
    // Windows 8.1
    // uses SL Policy internal inline code
  end;
  if V = $0604 then begin
    // Windows 10
    // uses SL Policy internal inline code
  end;

  Sect := IntToStr(FV.Version.w.Major)+'.'+IntToStr(FV.Version.w.Minor)+'.'+
          IntToStr(FV.Release)+'.'+IntToStr(FV.Build);

  if INISectionExists(INI, Sect) then
    if GetModuleAddress('termsrv.dll', GetCurrentProcessId, TermSrvBase, TermSrvSize) then begin
      if INIReadBool(INI, Sect, 'LocalOnlyPatch.x86', False) then begin
        WriteLog('Patch CEnforcementCore::GetInstanceOfTSLicense');
        SignPtr := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'LocalOnlyOffset.x86', 0));
        I := SListFind(PatchList, INIReadString(INI, Sect, 'LocalOnlyCode.x86', ''));
        if I >= 0 then
          WriteProcessMemory(GetCurrentProcess, SignPtr, @Patch[I][0], Length(Patch[I]), bw);
      end;
      if INIReadBool(INI, Sect, 'SingleUserPatch.x86', False) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        SignPtr := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'SingleUserOffset.x86', 0));
        I := SListFind(PatchList, INIReadString(INI, Sect, 'SingleUserCode.x86', ''));
        if I >= 0 then
          WriteProcessMemory(GetCurrentProcess, SignPtr, @Patch[I][0], Length(Patch[I]), bw);
      end;
      if INIReadBool(INI, Sect, 'DefPolicyPatch.x86', False) then begin
        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'DefPolicyOffset.x86', 0));
        I := SListFind(PatchList, INIReadString(INI, Sect, 'DefPolicyCode.x86', ''));
        if I >= 0 then
          WriteProcessMemory(GetCurrentProcess, SignPtr, @Patch[I][0], Length(Patch[I]), bw);
      end;
      if INIReadBool(INI, Sect, 'SLPolicyInternal.x86', False) then begin
        WriteLog('Hook SLGetWindowsInformationDWORDWrapper');
        SignPtr := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'SLPolicyOffset.x86', 0));
        MovJump.MovOp := $89;  // mov eax, ecx
        MovJump.MovArg := $C8; // __msfastcall compatibility
        MovJump.PushOp := $68;
        MovJump.PushArg := @New_Win8SL;
        MovJump.RetOp := $C3;
        FuncName := INIReadString(INI, Sect, 'SLPolicyFunc.x86', 'New_Win8SL');
        if FuncName = 'New_Win8SL' then
          MovJump.PushArg := @New_Win8SL;
        if FuncName = 'New_Win8SL_CP' then
          MovJump.PushArg := @New_Win8SL_CP;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @MovJump, SizeOf(mov_far_jmp), bw);
      end;
      if INIReadBool(INI, Sect, 'SLInitHook.x86', False) then begin
        WriteLog('Hook CSLQuery::Initialize');
        SignPtr := Pointer(Cardinal(TermSrvBase) + INIReadDWordHex(INI, Sect, 'SLInitOffset.x86', 0));
        Jump.PushOp := $68;
        Jump.PushArg := @New_CSLQuery_Initialize;
        Jump.RetOp := $C3;
        FuncName := INIReadString(INI, Sect, 'SLInitFunc.x86', 'New_CSLQuery_Initialize');
        if FuncName = 'New_CSLQuery_Initialize' then
          Jump.PushArg := @New_CSLQuery_Initialize;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @Jump, SizeOf(far_jmp), bw);
      end;
    end;

  // unfreeze threads
  WriteLog('Resumimg threads...');
  RunThreads();
end;

function TermServiceMain(dwArgc: DWORD; lpszArgv: PWideChar): DWORD; stdcall;
begin
  // wrap ServiceMain function
  WriteLog('>>> ServiceMain');
  if not IsHooked then
    HookFunctions;
  Result := 0;
  if @TSMain <> nil then
    Result := TSMain(dwArgc, lpszArgv);
  WriteLog('<<< ServiceMain');
end;

function TermServiceGlobals(lpGlobalData: Pointer): DWORD; stdcall;
begin
  // wrap SvchostPushServiceGlobals function
  WriteLog('>>> SvchostPushServiceGlobals');
  if not IsHooked then
    HookFunctions;
  Result := 0;
  if @TSGlobals <> nil then
    Result := TSGlobals(lpGlobalData);
  WriteLog('<<< SvchostPushServiceGlobals');
end;

// export section

exports
  TermServiceMain index 1 name 'ServiceMain',
  TermServiceGlobals index 2 name 'SvchostPushServiceGlobals';

begin
  // DllMain procedure is not used
end.