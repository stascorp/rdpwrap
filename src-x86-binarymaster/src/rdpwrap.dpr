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

// RDP Wrapper Library project by Stas'M

// Terminal Services supported versions
// 6.0.X.X        (Windows Vista, any)                    [policy hook only]
// 6.0.6000.16386 (Windows Vista)                         [policy hook + extended patch]
// 6.0.6001.18000 (Windows Vista SP1)                     [policy hook + extended patch]
// 6.0.6001.22565 (Windows Vista SP1 with KB977541)       [todo]
// 6.0.6001.22635 (Windows Vista SP1 with KB970911)       [todo]
// 6.0.6001.22801 (Windows Vista SP1 with KB2381675)      [todo]
// 6.0.6002.18005 (Windows Vista SP2)                     [policy hook + extended patch]
// 6.0.6002.22269 (Windows Vista SP2 with KB977541)       [todo]
// 6.0.6002.22340 (Windows Vista SP2 with KB970911)       [todo]
// 6.0.6002.22515 (Windows Vista SP2 with KB2381675)      [todo]
// 6.0.6002.22641 (Windows Vista SP2 with KB2523307)      [todo]
// 6.0.6002.19214 (Windows Vista SP2 with KB3003743 GDR)  [policy hook + extended patch]
// 6.0.6002.23521 (Windows Vista SP2 with KB3003743 LDR)  [policy hook + extended patch]
// 6.1.X.X        (Windows 7, any)                        [policy hook only]
// 6.1.7600.16385 (Windows 7)                             [policy hook + extended patch]
// 6.1.7600.20890 (Windows 7 with KB2479710)              [todo]
// 6.1.7600.21316 (Windows 7 with KB2750090)              [todo]
// 6.1.7601.17514 (Windows 7 SP1)                         [policy hook + extended patch]
// 6.1.7601.21650 (Windows 7 SP1 with KB2479710)          [todo]
// 6.1.7601.21866 (Windows 7 SP1 with KB2647409)          [todo]
// 6.1.7601.22104 (Windows 7 SP1 with KB2750090)          [todo]
// 6.1.7601.18540 (Windows 7 SP1 with KB2984972 GDR)      [policy hook + extended patch]
// 6.1.7601.22750 (Windows 7 SP1 with KB2984972 LDR)      [policy hook + extended patch]
// 6.1.7601.18637 (Windows 7 SP1 with KB3003743 GDR)      [policy hook + extended patch]
// 6.1.7601.22843 (Windows 7 SP1 with KB3003743 LDR)      [policy hook + extended patch]
// 6.2.8102.0     (Windows 8 Developer Preview)           [policy hook + extended patch]
// 6.2.8250.0     (Windows 8 Consumer Preview)            [policy hook + extended patch]
// 6.2.8400.0     (Windows 8 Release Preview)             [policy hook + extended patch]
// 6.2.9200.16384 (Windows 8)                             [policy hook + extended patch]
// 6.2.9200.17048 (Windows 8 with KB2973501 GDR)          [policy hook + extended patch]
// 6.2.9200.21166 (Windows 8 with KB2973501 LDR)          [policy hook + extended patch]
// 6.3.9431.0     (Windows 8.1 Preview)                   [init hook + extended patch]
// 6.3.9600.16384 (Windows 8.1)                           [init hook + extended patch]
// 6.3.9600.17095 (Windows 8.1 with KB2959626)            [init hook + extended patch]
// 6.3.9600.17415 (Windows 8.1 with KB3000850)            [!todo]
// 6.4.9841.0     (Windows 10 Technical Preview)          [init hook + extended patch]
// 6.4.9860.0     (Windows 10 Technical Preview Update 1) [init hook + extended patch]
// 6.4.9879.0     (Windows 10 Technical Preview Update 2) [!todo]

// Known failures
// 6.0.6000.16386 (Windows Vista RTM x86, crashes on logon attempt)

// Internal changelog:

// 2014.11.13 :
// - researching KB3003743
// - added support for version 6.0.6002.19214
// - added support for version 6.0.6002.23521
// - added support for version 6.1.7601.18637
// - added support for version 6.1.7601.22843

// 2014.11.02 :
// - researching termsrv.dll 6.4.9860.0
// - done

// 2014.10.19 :
// - added support for version 6.0.6000.16386 (x64)
// - added support for version 6.0.6001.18000 (x64)
// - added support for version 6.1.7600.16385

// 2014.10.18 :
// - corrected some typos in source
// - simplified signature constants
// - added support for version 6.0.6000.16386 (x86)
// - added support for version 6.0.6001.18000 (x86)
// - added support for version 6.0.6002.18005
// - added support for version 6.1.7601.17514
// - added support for version 6.1.7601.18540
// - added support for version 6.1.7601.22750
// - added support for version 6.2.9200.17048
// - added support for version 6.2.9200.21166

// 2014.10.17 :
// - collecting information about all versions of Terminal Services beginning from Vista
// - added [todo] to the versions list

// 2014.10.16 :
// - got new updates: KB2984972 for Win 7 (still works with 2 concurrent users) and KB2973501 for Win 8 (doesn't work)

// 2014.10.02 :
// - researching Windows 10 TP Remote Desktop
// - done! even without debugging symbols ^^)

// 2014.07.20 :
// - added support for Windows 8 Release Preview
// - added support for Windows 8 Consumer Preview
// - added support for Windows 8 Developer Preview

// 2014.07.19 :
// - improved patching of Windows 8
// - added policy patches
// - will patch CDefPolicy::Query
// - will patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled

// 2014.07.18 :
// - researched patched files from MDL forum
// - CSLQuery::GetMaxSessions requires no patching
// - it's better to change the default policy, so...
// - will patch CDefPolicy::Query
// - will patch CEnforcementCore::GetInstanceOfTSLicense
// - will patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
// - the function CSLQuery::Initialize is hooked correctly

// 2014.07.17 :
// - will hook only CSLQuery::Initialize function
// - CSLQuery::GetMaxSessions will be patched
// - added x86 signatures for 6.3.9431.0 (Windows 8.1 Preview)

// 2014.07.16 :
// - changing asm opcodes is bad, will hook CSL functions

// 2014.07.15 :
// - added x86 signatures for 6.3.9600.16384 (Windows 8.1)
// 2014.07.15 :
// - added x86 signatures for 6.3.9600.17095 (Windows 8.1 with KB2959626)

uses
  SysUtils,
  Windows,
  TlHelp32;

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
  IntArray = Array of Integer;
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
  bw: DWORD;
  IsHooked: Boolean = False;
  FCount: Cardinal = 0;

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

const
  CDefPolicy_Query_edx_ecx: Array[0..12] of Byte =
  ($BA,$00,$01,$00,$00,$89,$91,$20,$03,$00,$00,$5E,$90);
  CDefPolicy_Query_eax_esi: Array[0..11] of Byte =
  ($B8,$00,$01,$00,$00,$89,$86,$20,$03,$00,$00,$90);
  CDefPolicy_Query_eax_ecx: Array[0..11] of Byte =
  ($B8,$00,$01,$00,$00,$89,$81,$20,$03,$00,$00,$90);

// ------------------- TermService build 6.0.6000.16386

// Original
// .text:6F335CD8          cmp     edx, [ecx+320h]
// .text:6F335CDE          pop     esi
// .text:6F335CDF          jz      loc_6F3426F1
//_______________
//
// Changed
// .text:6F335CD8          mov     edx, 100h
// .text:6F335CDD          mov     [ecx+320h], edx
// .text:6F335CE3          pop     esi
// .text:6F335CE4          nop
// CDefPolicy_Query_edx_ecx

// ------------------- TermService build 6.0.6001.18000

// Original
// .text:6E817FD8          cmp     edx, [ecx+320h]
// .text:6E817FDE          pop     esi
// .text:6E817FDF          jz      loc_6E826F16
//_______________
//
// Changed
// .text:6E817FD8          mov     edx, 100h
// .text:6E817FDD          mov     [ecx+320h], edx
// .text:6E817FE3          pop     esi
// .text:6E817FE4          nop
// CDefPolicy_Query_edx_ecx

// ------------------- TermService build 6.0.6002.18005

// Original
// .text:6F5979C0          cmp     edx, [ecx+320h]
// .text:6F5979C6          pop     esi
// .text:6F5979C7          jz      loc_6F5A6F26
//_______________
//
// Changed
// .text:6F5979C0          mov     edx, 100h
// .text:6F5979C5          mov     [ecx+320h], edx
// .text:6F5979CB          pop     esi
// .text:6F5979CC          nop
// CDefPolicy_Query_edx_ecx

// ------------------- TermService build 6.0.6002.19214

// Original
// .text:6F5979B8          cmp     edx, [ecx+320h]
// .text:6F5979BE          pop     esi
// .text:6F5979BF          jz      loc_6F5A6F3E
//_______________
//
// Changed
// .text:6F5979B8          mov     edx, 100h
// .text:6F5979BD          mov     [ecx+320h], edx
// .text:6F5979C3          pop     esi
// .text:6F5979C4          nop
// CDefPolicy_Query_edx_ecx

// ------------------- TermService build 6.0.6002.23521

// Original
// .text:6F5979CC          cmp     edx, [ecx+320h]
// .text:6F5979D2          pop     esi
// .text:6F5979D3          jz      loc_6F5A6F2E
//_______________
//
// Changed
// .text:6F5979CC          mov     edx, 100h
// .text:6F5979D1          mov     [ecx+320h], edx
// .text:6F5979D7          pop     esi
// .text:6F5979D8          nop
// CDefPolicy_Query_edx_ecx

// ------------------- TermService build 6.1.7600.16385

// Original
// .text:6F2F96F3          cmp     eax, [esi+320h]
// .text:6F2F96F9          jz      loc_6F30E256
//_______________
//
// Changed
// .text:6F2F96F3          mov     eax, 100h
// .text:6F2F96F8          mov     [esi+320h], eax
// .text:6F2F96FE          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.1.7601.17514

// Original
// .text:6F2F9D53          cmp     eax, [esi+320h]
// .text:6F2F9D59          jz      loc_6F30B25E
//_______________
//
// Changed
// .text:6F2F9D53          mov     eax, 100h
// .text:6F2F9D58          mov     [esi+320h], eax
// .text:6F2F9D5E          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.1.7601.18540

// Original
// .text:6F2F9D9F          cmp     eax, [esi+320h]
// .text:6F2F9DA5          jz      loc_6F30B2AE
//_______________
//
// Changed
// .text:6F2F9D9F          mov     eax, 100h
// .text:6F2F9DA4          mov     [esi+320h], eax
// .text:6F2F9DAA          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.1.7601.22750

// Original
// .text:6F2F9E21          cmp     eax, [esi+320h]
// .text:6F2F9E27          jz      loc_6F30B6CE
//_______________
//
// Changed
// .text:6F2F9E21          mov     eax, 100h
// .text:6F2F9E26          mov     [esi+320h], eax
// .text:6F2F9E2C          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.1.7601.18637

// Original
// .text:6F2F9DBB          cmp     eax, [esi+320h]
// .text:6F2F9DC1          jz      loc_6F30B2A6
//_______________
//
// Changed
// .text:6F2F9DBB          mov     eax, 100h
// .text:6F2F9DC0          mov     [esi+320h], eax
// .text:6F2F9DC6          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.1.7601.22843

// Original
// .text:6F2F9E25          cmp     eax, [esi+320h]
// .text:6F2F9E2B          jz      loc_6F30B6D6
//_______________
//
// Changed
// .text:6F2F9E25          mov     eax, 100h
// .text:6F2F9E2A          mov     [esi+320h], eax
// .text:6F2F9E30          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.2.8102.0

// Original
// .text:1000E47C          cmp     eax, [esi+320h]
// .text:1000E482          jz      loc_1002D775
//_______________
//
// Changed
// .text:1000E47C          mov     eax, 100h
// .text:1000E481          mov     [esi+320h], eax
// .text:1000E487          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.2.8250.0

// Original
// .text:10013520          cmp     eax, [esi+320h]
// .text:10013526          jz      loc_1002DB85
//_______________
//
// Changed
// .text:10013520          mov     eax, 100h
// .text:10013525          mov     [esi+320h], eax
// .text:1001352B          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.2.8400.0

// Original
// .text:10013E48          cmp     eax, [esi+320h]
// .text:10013E4E          jz      loc_1002E079
//_______________
//
// Changed
// .text:10013E48          mov     eax, 100h
// .text:10013E4D          mov     [esi+320h], eax
// .text:10013E53          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.2.9200.16384

// Original
// .text:10013F08          cmp     eax, [esi+320h]
// .text:10013F0E          jz      loc_1002E161
//_______________
//
// Changed
// .text:10013F08          mov     eax, 100h
// .text:10013F0D          mov     [esi+320h], eax
// .text:10013F13          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.2.9200.17048

// Original
// .text:1001F408          cmp     eax, [esi+320h]
// .text:1001F40E          jz      loc_1002E201
//_______________
//
// Changed
// .text:1001F408          mov     eax, 100h
// .text:1001F40D          mov     [esi+320h], eax
// .text:1001F413          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.2.9200.21166

// Original
// .text:10013F30          cmp     eax, [esi+320h]
// .text:10013F36          jz      loc_1002E189
//_______________
//
// Changed
// .text:10013F30          mov     eax, 100h
// .text:10013F35          mov     [esi+320h], eax
// .text:10013F3B          nop
// CDefPolicy_Query_eax_esi

// ------------------- TermService build 6.3.9431.0

// Original
// .text:1002EA25          cmp     eax, [ecx+320h]
// .text:1002EA2B          jz      loc_100348C1
//_______________
//
// Changed
// .text:1002EA25          mov     eax, 100h
// .text:1002EA2A          mov     [ecx+320h], eax
// .text:1002EA30          nop
// CDefPolicy_Query_eax_ecx

// ------------------- TermService build 6.3.9600.16384

// Original
// .text:10016115          cmp     eax, [ecx+320h]
// .text:1001611B          jz      loc_10034DE1
//_______________
//
// Changed
// .text:10016115          mov     eax, 100h
// .text:1001611A          mov     [ecx+320h], eax
// .text:10016120          nop
// CDefPolicy_Query_eax_ecx

// ------------------- TermService build 6.3.9600.17095

// Original
// .text:10037529          cmp     eax, [ecx+320h]
// .text:1003752F          jz      loc_10043662
//_______________
//
// Changed
// .text:10037529          mov     eax, 100h
// .text:1003752E          mov     [ecx+320h], eax
// .text:10037534          nop
// CDefPolicy_Query_eax_ecx

// ------------------- TermService build 6.4.9841.0

// Original
// .text:1003B989          cmp     eax, [ecx+320h]
// .text:1003B98F          jz      loc_1005E809
//_______________
//
// Changed
// .text:1003B989          mov     eax, 100h
// .text:1003B98E          mov     [ecx+320h], eax
// .text:1003B994          nop
// CDefPolicy_Query_eax_ecx

// ------------------- TermService build 6.4.9860.0

// Original
// .text:1003BEC9          cmp     eax, [ecx+320h]
// .text:1003BECF          jz      loc_1005EE1A
//_______________
//
// Changed
// .text:1003BEC9          mov     eax, 100h
// .text:1003BECE          mov     [ecx+320h], eax
// .text:1003BED4          nop
// CDefPolicy_Query_eax_ecx

var
  Stub_SLGetWindowsInformationDWORD: far_jmp;
  Old_SLGetWindowsInformationDWORD: OldCode;

// Main code

procedure WriteLog(S: AnsiString);
const
  LogFile = '\rdpwrap.txt';
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

function GetModuleVersion(const ModuleName: TFileName; var FileVersion: FILE_VERSION): Boolean;
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

function GetFileVersion(const FileName: TFileName; var FileVersion: FILE_VERSION): Boolean;
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
  // Allow Remote Connections
  if ValueName = 'TerminalServices-RemoteConnectionManager-AllowRemoteConnections' then begin
    Value := 1;
    Exit;
  end;
  // Allow Multiple Sessions
  if ValueName = 'TerminalServices-RemoteConnectionManager-AllowMultipleSessions' then begin
    Value := 1;
    Exit;
  end;
  // Allow Multiple Sessions (Application Server Mode)
  if ValueName = 'TerminalServices-RemoteConnectionManager-AllowAppServerMode' then begin
    Value := 1;
    Exit;
  end;
  // Allow Multiple Monitors
  if ValueName = 'TerminalServices-RemoteConnectionManager-AllowMultimon' then begin
    Value := 1;
    Exit;
  end;
  // Max User Sessions (0 = unlimited)
  if ValueName = 'TerminalServices-RemoteConnectionManager-MaxUserSessions' then begin
    Value := 0;
    Exit;
  end;
  // Max Debug Sessions (Win 8, 0 = unlimited)
  if ValueName = 'TerminalServices-RemoteConnectionManager-ce0ad219-4670-4988-98fb-89b14c2f072b-MaxSessions' then begin
    Value := 0;
    Exit;
  end;
  // Max Sessions
  // 0 - logon not possible even from console
  // 1 - only one active user (console or remote)
  // 2 - allow concurrent sessions
  if ValueName = 'TerminalServices-RemoteConnectionManager-45344fe7-00e6-4ac6-9f01-d01fd4ffadfb-MaxSessions' then begin
    Value := 2;
    Exit;
  end;
  // Allow Advanced Compression with RDP 7 Protocol
  if ValueName = 'TerminalServices-RDP-7-Advanced-Compression-Allowed' then begin
    Value := 1;
    Exit;
  end;
  // IsTerminalTypeLocalOnly = 0
  if ValueName = 'TerminalServices-RemoteConnectionManager-45344fe7-00e6-4ac6-9f01-d01fd4ffadfb-LocalOnly' then begin
    Value := 0;
    Exit;
  end;
  // Max Sessions (hard limit)
  if ValueName = 'TerminalServices-RemoteConnectionManager-8dc86f1d-9969-4379-91c1-06fe1dc60575-MaxSessions' then begin
    Value := 1000;
    Exit;
  end;
  // Allow Easy Print
  if ValueName = 'TerminalServices-DeviceRedirection-Licenses-TSEasyPrintAllowed' then begin
    Value := 1;
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
    WriteLog('Rewrite: ' + IntToStr(pdwValue^));
    Exit;
  end;

  // If the requested value name is not defined above

  // revert to original SL Policy function
  WriteProcessMemory(GetCurrentProcess, @SLGetWindowsInformationDWORD,
    @Old_SLGetWindowsInformationDWORD, SizeOf(OldCode), bw);

  // get result
  Result := SLGetWindowsInformationDWORD(pwszValueName, pdwValue);
  if Result = S_OK then
    WriteLog('Result: ' + IntToStr(pdwValue^))
  else
    WriteLog('Failed');
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
    WriteLog('Rewrite: ' + IntToStr(pdwValue^));
    Exit;
  end;

  // If the requested value name is not defined above
  // use function from SLC.dll

  Result := SLGetWindowsInformationDWORD(pwszValueName, pdwValue);
  if Result = S_OK then
    WriteLog('Result: ' + IntToStr(pdwValue^))
  else
    WriteLog('Failed');
end;

function New_Win8SL_CP(eax: DWORD; pdwValue: PDWORD; ecx: DWORD; pwszValueName: PWideChar): HRESULT; register;
begin
  // wrapped unexported function SLGetWindowsInformationDWORDWrapper in termsrv.dll
  // for Windows 8 Consumer Preview support

  Result := New_Win8SL(pwszValueName, pdwValue);
end;

function New_CSLQuery_Initialize: HRESULT; stdcall;
var
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
  WriteLog('> CSLQuery::Initialize');
  if (FV.Release = 9431) and (FV.Build = 0) then begin
    bFUSEnabled :=        Pointer(Cardinal(TermSrvBase) + $A22A8);
    lMaxUserSessions :=   Pointer(Cardinal(TermSrvBase) + $A22AC);
    bAppServerAllowed :=  Pointer(Cardinal(TermSrvBase) + $A22B0);
    bInitialized :=       Pointer(Cardinal(TermSrvBase) + $A22B4);
    bMultimonAllowed :=   Pointer(Cardinal(TermSrvBase) + $A22B8);
    bServerSku :=         Pointer(Cardinal(TermSrvBase) + $A22BC);
    ulMaxDebugSessions := Pointer(Cardinal(TermSrvBase) + $A22C0);
    bRemoteConnAllowed := Pointer(Cardinal(TermSrvBase) + $A22C4);
  end;
  if (FV.Release = 9600) and (FV.Build = 16384) then begin
    bFUSEnabled :=        Pointer(Cardinal(TermSrvBase) + $C02A8);
    lMaxUserSessions :=   Pointer(Cardinal(TermSrvBase) + $C02AC);
    bAppServerAllowed :=  Pointer(Cardinal(TermSrvBase) + $C02B0);
    bInitialized :=       Pointer(Cardinal(TermSrvBase) + $C02B4);
    bMultimonAllowed :=   Pointer(Cardinal(TermSrvBase) + $C02B8);
    bServerSku :=         Pointer(Cardinal(TermSrvBase) + $C02BC);
    ulMaxDebugSessions := Pointer(Cardinal(TermSrvBase) + $C02C0);
    bRemoteConnAllowed := Pointer(Cardinal(TermSrvBase) + $C02C4);
  end;
  if (FV.Release = 9600) and (FV.Build = 17095) then begin
    bFUSEnabled :=        Pointer(Cardinal(TermSrvBase) + $C12A8);
    lMaxUserSessions :=   Pointer(Cardinal(TermSrvBase) + $C12AC);
    bAppServerAllowed :=  Pointer(Cardinal(TermSrvBase) + $C12B0);
    bInitialized :=       Pointer(Cardinal(TermSrvBase) + $C12B4);
    bMultimonAllowed :=   Pointer(Cardinal(TermSrvBase) + $C12B8);
    bServerSku :=         Pointer(Cardinal(TermSrvBase) + $C12BC);
    ulMaxDebugSessions := Pointer(Cardinal(TermSrvBase) + $C12C0);
    bRemoteConnAllowed := Pointer(Cardinal(TermSrvBase) + $C12C4);
  end;
  if (FV.Release = 9841) and (FV.Build = 0) then begin
    bFUSEnabled :=        Pointer(Cardinal(TermSrvBase) + $BF9F0);
    lMaxUserSessions :=   Pointer(Cardinal(TermSrvBase) + $BF9F4);
    bAppServerAllowed :=  Pointer(Cardinal(TermSrvBase) + $BF9F8);
    bInitialized :=       Pointer(Cardinal(TermSrvBase) + $BF9FC);
    bMultimonAllowed :=   Pointer(Cardinal(TermSrvBase) + $BFA00);
    bServerSku :=         Pointer(Cardinal(TermSrvBase) + $BFA04);
    ulMaxDebugSessions := Pointer(Cardinal(TermSrvBase) + $BFA08);
    bRemoteConnAllowed := Pointer(Cardinal(TermSrvBase) + $BFA0C);
  end;
  if (FV.Release = 9860) and (FV.Build = 0) then begin
    bFUSEnabled :=        Pointer(Cardinal(TermSrvBase) + $BF7E0);
    lMaxUserSessions :=   Pointer(Cardinal(TermSrvBase) + $BF7E4);
    bAppServerAllowed :=  Pointer(Cardinal(TermSrvBase) + $BF7E8);
    bInitialized :=       Pointer(Cardinal(TermSrvBase) + $BF7EC);
    bMultimonAllowed :=   Pointer(Cardinal(TermSrvBase) + $BF7F0);
    bServerSku :=         Pointer(Cardinal(TermSrvBase) + $BF7F4);
    ulMaxDebugSessions := Pointer(Cardinal(TermSrvBase) + $BF7F8);
    bRemoteConnAllowed := Pointer(Cardinal(TermSrvBase) + $BF7FC);
  end;
  if bServerSku <> nil then begin
    WriteLog('[0x'+IntToHex(DWORD(bServerSku), 1)+'] bServerSku = 1');
    bServerSku^ := 1;
  end;
  if bRemoteConnAllowed <> nil then begin
    WriteLog('[0x'+IntToHex(DWORD(bRemoteConnAllowed), 1)+'] bRemoteConnAllowed = 1');
    bRemoteConnAllowed^ := 1;
  end;
  if bFUSEnabled <> nil then begin
    WriteLog('[0x'+IntToHex(DWORD(bFUSEnabled), 1)+'] bFUSEnabled = 1');
    bFUSEnabled^ := 1;
  end;
  if bAppServerAllowed <> nil then begin
    WriteLog('[0x'+IntToHex(DWORD(bAppServerAllowed), 1)+'] bAppServerAllowed = 1');
    bAppServerAllowed^ := 1;
  end;
  if bMultimonAllowed <> nil then begin
    WriteLog('[0x'+IntToHex(DWORD(bMultimonAllowed), 1)+'] bMultimonAllowed = 1');
    bMultimonAllowed^ := 1;
  end;
  if lMaxUserSessions <> nil then begin
    WriteLog('[0x'+IntToHex(DWORD(lMaxUserSessions), 1)+'] lMaxUserSessions = 0');
    lMaxUserSessions^ := 0;
  end;
  if ulMaxDebugSessions <> nil then begin
    WriteLog('[0x'+IntToHex(DWORD(ulMaxDebugSessions), 1)+'] ulMaxDebugSessions = 0');
    ulMaxDebugSessions^ := 0;
  end;
  if bInitialized <> nil then begin
    WriteLog('[0x'+IntToHex(DWORD(bInitialized), 1)+'] bInitialized = 1');
    bInitialized^ := 1;
  end;
  Result := S_OK;
end;

procedure HookFunctions;
var
  V: DWORD;
  TS_Handle, SLC_Handle: THandle;
  TermSrvSize: DWORD;
  SignPtr: Pointer;
  Results: IntArray;
  Jump: far_jmp;
  MovJump: mov_far_jmp;
  nop: DWORD;
  b: Byte;
begin
  { hook function ^^
     (called once)   }
  IsHooked := True;
  nop := $90909090;
  TSMain := nil;
  TSGlobals := nil;
  SLGetWindowsInformationDWORD := nil;
  WriteLog('init');

  // load termsrv.dll and get functions
  TS_Handle := LoadLibrary('termsrv.dll');
  if TS_Handle = 0 then begin
    WriteLog('Error: Failed to load Terminal Services library');
    Exit;
  end;
  WriteLog('Base addr:  0x'+IntToHex(TS_Handle, 8));
  TSMain := GetProcAddress(TS_Handle, 'ServiceMain');
  WriteLog('SvcMain:    termsrv.dll+0x'+IntToHex(Cardinal(@TSMain) - TS_Handle, 1));
  TSGlobals := GetProcAddress(TS_Handle, 'SvchostPushServiceGlobals');
  WriteLog('SvcGlobals: termsrv.dll+0x'+IntToHex(Cardinal(@TSGlobals) - TS_Handle, 1));

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

  WriteLog('Version: '+IntToStr(FV.Version.w.Major)+'.'+IntToStr(FV.Version.w.Minor));
  WriteLog('Release: '+IntToStr(FV.Release));
  WriteLog('Build:   '+IntToStr(FV.Build));

  // temporarily freeze threads
  WriteLog('freeze');
  StopThreads();

  if (V = $0600) then begin
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

    if GetModuleAddress('termsrv.dll', GetCurrentProcessId, TermSrvBase, TermSrvSize) then begin
      // Patch functions:
      // CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
      // CDefPolicy::Query

      if (FV.Release = 6000) and (FV.Build = 16386) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6F320000
        // .text:6F3360B9          lea     eax, [ebp+VersionInformation]
        // .text:6F3360BF          inc     ebx            <- nop
        // .text:6F3360C0          push    eax             ; lpVersionInformation
        // .text:6F3360C1          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6F3360CB          mov     [esi], ebx
        // .text:6F3360CD          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $160BF);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $15CD8);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_edx_ecx[0],
        SizeOf(CDefPolicy_Query_edx_ecx), bw);
      end;
      if (FV.Release = 6001) and (FV.Build = 18000) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6E800000
        // .text:6E8185DE          lea     eax, [ebp+VersionInformation]
        // .text:6E8185E4          inc     ebx            <- nop
        // .text:6E8185E5          push    eax             ; lpVersionInformation
        // .text:6E8185E6          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6E8185F0          mov     [esi], ebx
        // .text:6E8185F2          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $185E4);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $17FD8);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_edx_ecx[0],
        SizeOf(CDefPolicy_Query_edx_ecx), bw);
      end;
      if (FV.Release = 6002) and (FV.Build = 18005) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6F580000
        // .text:6F597FA2          lea     eax, [ebp+VersionInformation]
        // .text:6F597FA8          inc     ebx            <- nop
        // .text:6F597FA9          push    eax             ; lpVersionInformation
        // .text:6F597FAA          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6F597FB4          mov     [esi], ebx
        // .text:6F597FB6          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $17FA8);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $179C0);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_edx_ecx[0],
        SizeOf(CDefPolicy_Query_edx_ecx), bw);
      end;
      if (FV.Release = 6002) and (FV.Build = 19214) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6F580000
        // .text:6F597FBE          lea     eax, [ebp+VersionInformation]
        // .text:6F597FC4          inc     ebx            <- nop
        // .text:6F597FC5          push    eax             ; lpVersionInformation
        // .text:6F597FC6          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6F597FD0          mov     [esi], ebx
        // .text:6F597FD2          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $17FC4);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $179B8);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_edx_ecx[0],
        SizeOf(CDefPolicy_Query_edx_ecx), bw);
      end;
      if (FV.Release = 6002) and (FV.Build = 23521) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6F580000
        // .text:6F597FAE          lea     eax, [ebp+VersionInformation]
        // .text:6F597FB4          inc     ebx            <- nop
        // .text:6F597FB5          push    eax             ; lpVersionInformation
        // .text:6F597FB6          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6F597FC0          mov     [esi], ebx
        // .text:6F597FC2          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $17FB4);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $179CC);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_edx_ecx[0],
        SizeOf(CDefPolicy_Query_edx_ecx), bw);
      end;
    end;
  end;
  if (V = $0601) then begin
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

    if GetModuleAddress('termsrv.dll', GetCurrentProcessId, TermSrvBase, TermSrvSize) then begin
      // Patch functions:
      // CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
      // CDefPolicy::Query

      if (FV.Release = 7600) and (FV.Build = 16385) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6F2E0000
        // .text:6F2F9E1F          lea     eax, [ebp+VersionInformation]
        // .text:6F2F9E25          inc     ebx            <- nop
        // .text:6F2F9E26          push    eax             ; lpVersionInformation
        // .text:6F2F9E27          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6F2F9E31          mov     [esi], ebx
        // .text:6F2F9E33          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $19E25);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $196F3);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);
      end;
      if (FV.Release = 7601) and (FV.Build = 17514) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6F2E0000
        // .text:6F2FA497          lea     eax, [ebp+VersionInformation]
        // .text:6F2FA49D          inc     ebx            <- nop
        // .text:6F2FA49E          push    eax             ; lpVersionInformation
        // .text:6F2FA49F          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6F2FA4A9          mov     [esi], ebx
        // .text:6F2FA4AB          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $1A49D);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $19D53);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);
      end;
      if (FV.Release = 7601) and (FV.Build = 18540) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6F2E0000
        // .text:6F2FA4DF          lea     eax, [ebp+VersionInformation]
        // .text:6F2FA4E5          inc     ebx            <- nop
        // .text:6F2FA4E6          push    eax             ; lpVersionInformation
        // .text:6F2FA4E7          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6F2FA4F1          mov     [esi], ebx
        // .text:6F2FA4F3          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $1A4E5);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $19D9F);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);
      end;
      if (FV.Release = 7601) and (FV.Build = 22750) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6F2E0000
        // .text:6F2FA64F          lea     eax, [ebp+VersionInformation]
        // .text:6F2FA655          inc     ebx            <- nop
        // .text:6F2FA656          push    eax             ; lpVersionInformation
        // .text:6F2FA657          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6F2FA661          mov     [esi], ebx
        // .text:6F2FA663          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $1A655);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $19E21);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);
      end;
      if (FV.Release = 7601) and (FV.Build = 18637) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6F2E0000
        // .text:6F2FA4D7          lea     eax, [ebp+VersionInformation]
        // .text:6F2FA4DD          inc     ebx            <- nop
        // .text:6F2FA4DE          push    eax             ; lpVersionInformation
        // .text:6F2FA4DF          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6F2FA4E9          mov     [esi], ebx
        // .text:6F2FA4EB          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $1A4DD);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $19DBB);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);
      end;
      if (FV.Release = 7601) and (FV.Build = 22843) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // Imagebase: 6F2E0000
        // .text:6F2FA64F          lea     eax, [ebp+VersionInformation]
        // .text:6F2FA655          inc     ebx            <- nop
        // .text:6F2FA656          push    eax             ; lpVersionInformation
        // .text:6F2FA657          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:6F2FA661          mov     [esi], ebx
        // .text:6F2FA663          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $1A655);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $19E25);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);
      end;
    end;
  end;
  if V = $0602 then begin
    // Windows 8
    // uses SL Policy internal unexported function

    // load slc.dll and get function
    // (will be used on intercepting undefined values)
    SLC_Handle := LoadLibrary('slc.dll');
    SLGetWindowsInformationDWORD := GetProcAddress(SLC_Handle, 'SLGetWindowsInformationDWORD');

    if GetModuleAddress('termsrv.dll', GetCurrentProcessId, TermSrvBase, TermSrvSize) then begin
      // Patch functions:
      // CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
      // CDefPolicy::Query
      // Hook function:
      // SLGetWindowsInformationDWORDWrapper

      if (FV.Release = 8102) and (FV.Build = 0) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:1000F7E5          lea     eax, [esp+150h+VersionInformation]
        // .text:1000F7E9          inc     esi            <- nop
        // .text:1000F7EA          push    eax             ; lpVersionInformation
        // .text:1000F7EB          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:1000F7F3          mov     [edi], esi
        // .text:1000F7F5          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $F7E9);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $E47C);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);

        WriteLog('Hook SLGetWindowsInformationDWORDWrapper');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $1B909);
        MovJump.MovOp := $89;  // mov eax, ecx
        MovJump.MovArg := $C8; // __msfastcall compatibility
        MovJump.PushOp := $68;
        MovJump.PushArg := @New_Win8SL;
        MovJump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @MovJump, SizeOf(mov_far_jmp), bw);
      end;
      if (FV.Release = 8250) and (FV.Build = 0) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:100159C5          lea     eax, [esp+150h+VersionInformation]
        // .text:100159C9          inc     esi            <- nop
        // .text:100159CA          push    eax             ; lpVersionInformation
        // .text:100159CB          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:100159D3          mov     [edi], esi
        // .text:100159D5          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $159C9);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $13520);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);

        WriteLog('Hook SLGetWindowsInformationDWORDWrapper');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $1A0A9);
        MovJump.MovOp := $89;  // mov eax, ecx
        MovJump.MovArg := $C8; // __msfastcall compatibility
        MovJump.PushOp := $68;
        MovJump.PushArg := @New_Win8SL_CP;
        MovJump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @MovJump, SizeOf(mov_far_jmp), bw);
      end;
      if (FV.Release = 8400) and (FV.Build = 0) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:1001547E          lea     eax, [esp+150h+VersionInformation]
        // .text:10015482          inc     esi            <- nop
        // .text:10015483          push    eax             ; lpVersionInformation
        // .text:10015484          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:1001548C          mov     [edi], esi
        // .text:1001548E          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $15482);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $13E48);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);

        WriteLog('Hook SLGetWindowsInformationDWORDWrapper');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $19629);
        MovJump.MovOp := $89;  // mov eax, ecx
        MovJump.MovArg := $C8; // __msfastcall compatibility
        MovJump.PushOp := $68;
        MovJump.PushArg := @New_Win8SL;
        MovJump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @MovJump, SizeOf(mov_far_jmp), bw);
      end;
      if (FV.Release = 9200) and (FV.Build = 16384) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:1001554E          lea     eax, [esp+150h+VersionInformation]
        // .text:10015552          inc     esi            <- nop
        // .text:10015553          push    eax             ; lpVersionInformation
        // .text:10015554          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:1001555C          mov     [edi], esi
        // .text:1001555E          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $15552);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $13F08);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);

        WriteLog('Hook SLGetWindowsInformationDWORDWrapper');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $19559);
        MovJump.MovOp := $89;  // mov eax, ecx
        MovJump.MovArg := $C8; // __msfastcall compatibility
        MovJump.PushOp := $68;
        MovJump.PushArg := @New_Win8SL;
        MovJump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @MovJump, SizeOf(mov_far_jmp), bw);
      end;
      if (FV.Release = 9200) and (FV.Build = 17048) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:1002058E          lea     eax, [esp+150h+VersionInformation]
        // .text:10020592          inc     esi            <- nop
        // .text:10020593          push    eax             ; lpVersionInformation
        // .text:10020594          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:1002059C          mov     [edi], esi
        // .text:1002059E          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $20592);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $1F408);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);

        WriteLog('Hook SLGetWindowsInformationDWORDWrapper');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $17059);
        MovJump.MovOp := $89;  // mov eax, ecx
        MovJump.MovArg := $C8; // __msfastcall compatibility
        MovJump.PushOp := $68;
        MovJump.PushArg := @New_Win8SL;
        MovJump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @MovJump, SizeOf(mov_far_jmp), bw);
      end;
      if (FV.Release = 9200) and (FV.Build = 21166) then begin
        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:10015576          lea     eax, [esp+150h+VersionInformation]
        // .text:1001557A          inc     esi            <- nop
        // .text:1001557B          push    eax             ; lpVersionInformation
        // .text:1001557C          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
        // .text:10015584          mov     [edi], esi
        // .text:10015586          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $1557A);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $13F30);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_esi[0],
        SizeOf(CDefPolicy_Query_eax_esi), bw);

        WriteLog('Hook SLGetWindowsInformationDWORDWrapper');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $19581);
        MovJump.MovOp := $89;  // mov eax, ecx
        MovJump.MovArg := $C8; // __msfastcall compatibility
        MovJump.PushOp := $68;
        MovJump.PushArg := @New_Win8SL;
        MovJump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @MovJump, SizeOf(mov_far_jmp), bw);
      end;
    end;
  end;
  if V = $0603 then begin
    // Windows 8.1
    // uses SL Policy internal inline code

    if GetModuleAddress('termsrv.dll', GetCurrentProcessId, TermSrvBase, TermSrvSize) then begin
      // Patch functions:
      // CEnforcementCore::GetInstanceOfTSLicense
      // CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
      // CDefPolicy::Query
      // Hook function:
      // CSLQuery::Initialize

      if (FV.Release = 9431) and (FV.Build = 0) then begin
        WriteLog('Patch CEnforcementCore::GetInstanceOfTSLicense');
        // .text:1008A604          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SGJAAU_GUID@@PAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
        // .text:1008A609          test    eax, eax
        // .text:1008A60B          js      short loc_1008A628
        // .text:1008A60D          cmp     [ebp+var_8], 0
        // .text:1008A611          jz      short loc_1008A628 <- jmp
        SignPtr := Pointer(Cardinal(TermSrvBase) + $8A611);
        b := $EB;
        WriteProcessMemory(GetCurrentProcess, SignPtr, @b, 1, bw);

        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:100306A4          lea     eax, [esp+150h+VersionInformation]
        // .text:100306A8          inc     ebx            <- nop
        // .text:100306A9          mov     [edi], ebx
        // .text:100306AB          push    eax             ; lpVersionInformation
        // .text:100306AC          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $306A8);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $2EA25);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_ecx[0],
        SizeOf(CDefPolicy_Query_eax_ecx), bw);

        WriteLog('Hook CSLQuery::Initialize');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $196B0);
        Jump.PushOp := $68;
        Jump.PushArg := @New_CSLQuery_Initialize;
        Jump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @Jump, SizeOf(far_jmp), bw);
      end;
      if (FV.Release = 9600) and (FV.Build = 16384) then begin
        WriteLog('Patch CEnforcementCore::GetInstanceOfTSLicense');
        // .text:100A271C          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SGJAAU_GUID@@PAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
        // .text:100A2721          test    eax, eax
        // .text:100A2723          js      short loc_100A2740
        // .text:100A2725          cmp     [ebp+var_8], 0
        // .text:100A2729          jz      short loc_100A2740 <- jmp
        SignPtr := Pointer(Cardinal(TermSrvBase) + $A2729);
        b := $EB;
        WriteProcessMemory(GetCurrentProcess, SignPtr, @b, 1, bw);

        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:10018024          lea     eax, [esp+150h+VersionInformation]
        // .text:10018028          inc     ebx            <- nop
        // .text:10018029          mov     [edi], ebx
        // .text:1001802B          push    eax             ; lpVersionInformation
        // .text:1001802C          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $18028);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $16115);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_ecx[0],
        SizeOf(CDefPolicy_Query_eax_ecx), bw);

        WriteLog('Hook CSLQuery::Initialize');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $1CEB0);
        Jump.PushOp := $68;
        Jump.PushArg := @New_CSLQuery_Initialize;
        Jump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @Jump, SizeOf(far_jmp), bw);
      end;
      if (FV.Release = 9600) and (FV.Build = 17095) then begin
        WriteLog('Patch CEnforcementCore::GetInstanceOfTSLicense');
        // .text:100A36C4          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SGJAAU_GUID@@PAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
        // .text:100A36C9          test    eax, eax
        // .text:100A36CB          js      short loc_100A36E8
        // .text:100A36CD          cmp     [ebp+var_8], 0
        // .text:100A36D1          jz      short loc_100A36E8 <- jmp
        SignPtr := Pointer(Cardinal(TermSrvBase) + $A36D1);
        b := $EB;
        WriteProcessMemory(GetCurrentProcess, SignPtr, @b, 1, bw);

        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:10036BA5          lea     eax, [esp+150h+VersionInformation]
        // .text:10036BA9          inc     ebx            <- nop
        // .text:10036BAA          mov     [edi], ebx
        // .text:10036BAC          push    eax             ; lpVersionInformation
        // .text:10036BAD          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $36BA9);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $37529);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_ecx[0],
        SizeOf(CDefPolicy_Query_eax_ecx), bw);

        WriteLog('Hook CSLQuery::Initialize');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $117F1);
        Jump.PushOp := $68;
        Jump.PushArg := @New_CSLQuery_Initialize;
        Jump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @Jump, SizeOf(far_jmp), bw);
      end;

    end;
  end;
  if V = $0604 then begin
    // Windows 10
    // uses SL Policy internal inline code

    if GetModuleAddress('termsrv.dll', GetCurrentProcessId, TermSrvBase, TermSrvSize) then begin
      // Patch functions:
      // CEnforcementCore::GetInstanceOfTSLicense
      // CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
      // CDefPolicy::Query
      // Hook function:
      // CSLQuery::Initialize

      if (FV.Release = 9841) and (FV.Build = 0) then begin
        WriteLog('Patch CEnforcementCore::GetInstanceOfTSLicense');
        // .text:1009569B          call    sub_100B7EE5
        // .text:100956A0          test    eax, eax
        // .text:100956A2          js      short loc_100956BF
        // .text:100956A4          cmp     [ebp+var_C], 0
        // .text:100956A8          jz      short loc_100956BF <- jmp
        SignPtr := Pointer(Cardinal(TermSrvBase) + $956A8);
        b := $EB;
        WriteProcessMemory(GetCurrentProcess, SignPtr, @b, 1, bw);

        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:10030121          lea     eax, [esp+150h+VersionInformation]
        // .text:10030125          inc     ebx            <- nop
        // .text:10030126          mov     [edi], ebx
        // .text:10030128          push    eax             ; lpVersionInformation
        // .text:10030129          call    ds:GetVersionExW
        SignPtr := Pointer(Cardinal(TermSrvBase) + $30125);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $3B989);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_ecx[0],
        SizeOf(CDefPolicy_Query_eax_ecx), bw);

        WriteLog('Hook CSLQuery::Initialize');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $46A68);
        Jump.PushOp := $68;
        Jump.PushArg := @New_CSLQuery_Initialize;
        Jump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @Jump, SizeOf(far_jmp), bw);
      end;

      if (FV.Release = 9860) and (FV.Build = 0) then begin
        WriteLog('Patch CEnforcementCore::GetInstanceOfTSLicense');
        // .text:100962BB          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SGJAAU_GUID@@PAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
        // .text:100962C0          test    eax, eax
        // .text:100962C2          js      short loc_100962DF
        // .text:100962C4          cmp     [ebp+var_C], 0
        // .text:100962C8          jz      short loc_100962DF <- jmp
        SignPtr := Pointer(Cardinal(TermSrvBase) + $962C8);
        b := $EB;
        WriteProcessMemory(GetCurrentProcess, SignPtr, @b, 1, bw);

        WriteLog('Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled');
        // .text:10030841          lea     eax, [esp+150h+VersionInformation]
        // .text:10030845          inc     ebx            <- nop
        // .text:10030846          mov     [edi], ebx
        // .text:10030848          push    eax             ; lpVersionInformation
        // .text:10030849          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
        SignPtr := Pointer(Cardinal(TermSrvBase) + $30845);
        WriteProcessMemory(GetCurrentProcess, SignPtr, @nop, 1, bw);

        WriteLog('Patch CDefPolicy::Query');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $3BEC9);
        WriteProcessMemory(GetCurrentProcess, SignPtr,
        @CDefPolicy_Query_eax_ecx[0],
        SizeOf(CDefPolicy_Query_eax_ecx), bw);

        WriteLog('Hook CSLQuery::Initialize');
        SignPtr := Pointer(Cardinal(TermSrvBase) + $46F18);
        Jump.PushOp := $68;
        Jump.PushArg := @New_CSLQuery_Initialize;
        Jump.RetOp := $C3;
        WriteProcessMemory(GetCurrentProcess, SignPtr,
          @Jump, SizeOf(far_jmp), bw);
      end;

    end;
  end;

  // unfreeze threads
  WriteLog('resume');
  RunThreads();
end;

function TermServiceMain(dwArgc: DWORD; lpszArgv: PWideChar): DWORD; stdcall;
begin
  // wrap ServiceMain function
  WriteLog('> ServiceMain');
  if not IsHooked then
    HookFunctions;
  Result := 0;
  if @TSMain <> nil then
    Result := TSMain(dwArgc, lpszArgv);
end;

function TermServiceGlobals(lpGlobalData: Pointer): DWORD; stdcall;
begin
  // wrap SvchostPushServiceGlobals function
  WriteLog('> SvchostPushServiceGlobals');
  if not IsHooked then
    HookFunctions;
  Result := 0;
  if @TSGlobals <> nil then
    Result := TSGlobals(lpGlobalData);
end;

// export section

exports
  TermServiceMain index 1 name 'ServiceMain';
exports
  TermServiceGlobals index 2 name 'SvchostPushServiceGlobals';

begin
  // DllMain procedure is not used
end.