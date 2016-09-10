{
  Copyright 2016 Stas'M Corp.

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

program RDPWInst;

{$APPTYPE CONSOLE}

{$R resource.res}

uses
  SysUtils,
  Windows,
  Classes,
  WinSvc,
  Registry,
  WinInet;

function EnumServicesStatusEx(
  hSCManager: SC_HANDLE;
  InfoLevel,
  dwServiceType,
  dwServiceState: DWORD;
  lpServices: PByte;
  cbBufSize: DWORD;
  var pcbBytesNeeded,
  lpServicesReturned,
  lpResumeHandle: DWORD;
  pszGroupName: PWideChar): BOOL; stdcall;
  external advapi32 name 'EnumServicesStatusExW';

type
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
  SERVICE_STATUS_PROCESS = packed record
    dwServiceType,
    dwCurrentState,
    dwControlsAccepted,
    dwWin32ExitCode,
    dwServiceSpecificExitCode,
    dwCheckPoint,
    dwWaitHint,
    dwProcessId,
    dwServiceFlags: DWORD;
  end;
  PSERVICE_STATUS_PROCESS = ^SERVICE_STATUS_PROCESS;
  ENUM_SERVICE_STATUS_PROCESS = packed record
    lpServiceName,
    lpDisplayName: PWideChar;
    ServiceStatusProcess: SERVICE_STATUS_PROCESS;
  end;
  PENUM_SERVICE_STATUS_PROCESS = ^ENUM_SERVICE_STATUS_PROCESS;

const
  SC_ENUM_PROCESS_INFO = 0;
  TermService = 'TermService';
var
  Installed: Boolean;
  Online: Boolean;
  WrapPath: String;
  Arch: Byte;
  OldWow64RedirectionValue: LongBool;

  TermServicePath: String;
  FV: FILE_VERSION;
  TermServicePID: DWORD;
  ShareSvc: Array of String;
  sShareSvc: String;

function SupportedArchitecture: Boolean;
var
  SI: TSystemInfo;
begin
  GetNativeSystemInfo(SI);
  case SI.wProcessorArchitecture of
    0:
    begin
      Arch := 32;
      Result := True; // Intel x86
    end;
    6: Result := False; // Itanium-based x64
    9: begin
      Arch := 64;
      Result := True; // Intel/AMD x64
    end;
    else Result := False;
  end;
end;

function DisableWowRedirection: Boolean;
type
  TFunc = function(var Wow64FsEnableRedirection: LongBool): LongBool; stdcall;
var
  hModule: THandle;
  Wow64DisableWow64FsRedirection: TFunc;
begin
  Result := False;
  hModule := GetModuleHandle(kernel32);
  if hModule <> 0 then
    Wow64DisableWow64FsRedirection := GetProcAddress(hModule, 'Wow64DisableWow64FsRedirection')
  else
    Exit;
  if @Wow64DisableWow64FsRedirection <> nil then
    Result := Wow64DisableWow64FsRedirection(OldWow64RedirectionValue);
end;

function RevertWowRedirection: Boolean;
type
  TFunc = function(var Wow64RevertWow64FsRedirection: LongBool): LongBool; stdcall;
var
  hModule: THandle;
  Wow64RevertWow64FsRedirection: TFunc;
begin
  Result := False;
  hModule := GetModuleHandle(kernel32);
  if hModule <> 0 then
    Wow64RevertWow64FsRedirection := GetProcAddress(hModule, 'Wow64RevertWow64FsRedirection')
  else
    Exit;
  if @Wow64RevertWow64FsRedirection <> nil then
    Result := Wow64RevertWow64FsRedirection(OldWow64RedirectionValue);
end;

procedure CheckInstall;
var
  Code: DWORD;
  TermServiceHost: String;
  Reg: TRegistry;
begin
  if Arch = 64 then
    Reg := TRegistry.Create(KEY_WOW64_64KEY)
  else
    Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  if not Reg.OpenKeyReadOnly('\SYSTEM\CurrentControlSet\Services\TermService') then
  begin
    Reg.Free;
    Code := GetLastError;
    Writeln('[-] OpenKeyReadOnly error (code ', Code, ').');
    Halt(Code);
  end;
  TermServiceHost := Reg.ReadString('ImagePath');
  Reg.CloseKey;
  if (Pos('svchost.exe', LowerCase(TermServiceHost)) = 0)
  and (Pos('svchost -k', LowerCase(TermServiceHost)) = 0) then
  begin
    Reg.Free;
    Writeln('[-] TermService is hosted in a custom application (BeTwin, etc.) - unsupported.');
    Writeln('[*] ImagePath: "', TermServiceHost, '".');
    Halt(ERROR_NOT_SUPPORTED);
  end;
  if not Reg.OpenKeyReadOnly('\SYSTEM\CurrentControlSet\Services\TermService\Parameters') then
  begin
    Reg.Free;
    Code := GetLastError;
    Writeln('[-] OpenKeyReadOnly error (code ', Code, ').');
    Halt(Code);
  end;
  TermServicePath := Reg.ReadString('ServiceDll');
  Reg.CloseKey;
  if (Pos('termsrv.dll', LowerCase(TermServicePath)) = 0)
  and (Pos('rdpwrap.dll', LowerCase(TermServicePath)) = 0) then
  begin
    Reg.Free;
    Writeln('[-] Another third-party TermService library is installed.');
    Writeln('[*] ServiceDll: "', TermServicePath, '".');
    Halt(ERROR_NOT_SUPPORTED);
  end;
  Reg.Free;

  Installed := Pos('rdpwrap.dll', LowerCase(TermServicePath)) > 0;
end;

function SvcGetStart(SvcName: String): Integer;
var
  hSC: SC_HANDLE;
  hSvc: THandle;
  Code: DWORD;
  lpServiceConfig: PQueryServiceConfig;
  Buf: Pointer;
  cbBufSize, pcbBytesNeeded: Cardinal;
begin
  Result := -1;
  Writeln('[*] Checking ', SvcName, '...');
  hSC := OpenSCManager(nil, SERVICES_ACTIVE_DATABASE, SC_MANAGER_CONNECT);
  if hSC = 0 then
  begin
    Code := GetLastError;
    Writeln('[-] OpenSCManager error (code ', Code, ').');
    Exit;
  end;

  hSvc := OpenService(hSC, PWideChar(SvcName), SERVICE_QUERY_CONFIG);
  if hSvc = 0 then
  begin
    CloseServiceHandle(hSC);
    Code := GetLastError;
    Writeln('[-] OpenService error (code ', Code, ').');
    Exit;
  end;

  if QueryServiceConfig(hSvc, nil, 0, pcbBytesNeeded) then begin
    Writeln('[-] QueryServiceConfig failed.');
    Exit;
  end;

  cbBufSize := pcbBytesNeeded;
  GetMem(Buf, cbBufSize);

  if not QueryServiceConfig(hSvc, Buf, cbBufSize, pcbBytesNeeded) then begin
    FreeMem(Buf, cbBufSize);
    CloseServiceHandle(hSvc);
    CloseServiceHandle(hSC);
    Code := GetLastError;
    Writeln('[-] QueryServiceConfig error (code ', Code, ').');
    Exit;
  end else begin
    lpServiceConfig := Buf;
    Result := Integer(lpServiceConfig^.dwStartType);
  end;
  FreeMem(Buf, cbBufSize);
  CloseServiceHandle(hSvc);
  CloseServiceHandle(hSC);
end;

procedure SvcConfigStart(SvcName: String; dwStartType: Cardinal);
var
  hSC: SC_HANDLE;
  hSvc: THandle;
  Code: DWORD;
begin
  Writeln('[*] Configuring ', SvcName, '...');
  hSC := OpenSCManager(nil, SERVICES_ACTIVE_DATABASE, SC_MANAGER_CONNECT);
  if hSC = 0 then
  begin
    Code := GetLastError;
    Writeln('[-] OpenSCManager error (code ', Code, ').');
    Exit;
  end;

  hSvc := OpenService(hSC, PWideChar(SvcName), SERVICE_CHANGE_CONFIG);
  if hSvc = 0 then
  begin
    CloseServiceHandle(hSC);
    Code := GetLastError;
    Writeln('[-] OpenService error (code ', Code, ').');
    Exit;
  end;

  if not ChangeServiceConfig(hSvc, SERVICE_NO_CHANGE, dwStartType,
  SERVICE_NO_CHANGE, nil, nil, nil, nil, nil, nil, nil) then begin
    CloseServiceHandle(hSvc);
    CloseServiceHandle(hSC);
    Code := GetLastError;
    Writeln('[-] ChangeServiceConfig error (code ', Code, ').');
    Exit;
  end;
  CloseServiceHandle(hSvc);
  CloseServiceHandle(hSC);
end;

procedure SvcStart(SvcName: String);
var
  hSC: SC_HANDLE;
  hSvc: THandle;
  Code: DWORD;
  pch: PWideChar;
  procedure ExitError(Func: String; ErrorCode: DWORD);
  begin
    if hSC > 0 then
      CloseServiceHandle(hSC);
    if hSvc > 0 then
      CloseServiceHandle(hSvc);
    Writeln('[-] ', Func, ' error (code ', ErrorCode, ').');
  end;
begin
  hSC := 0;
  hSvc := 0;
  Writeln('[*] Starting ', SvcName, '...');
  hSC := OpenSCManager(nil, SERVICES_ACTIVE_DATABASE, SC_MANAGER_CONNECT);
  if hSC = 0 then
  begin
    ExitError('OpenSCManager', GetLastError);
    Exit;
  end;

  hSvc := OpenService(hSC, PWideChar(SvcName), SERVICE_START);
  if hSvc = 0 then
  begin
    ExitError('OpenService', GetLastError);
    Exit;
  end;

  pch := nil;
  if not StartService(hSvc, 0, pch) then begin
    Code := GetLastError;
    if Code = 1056 then begin // Service already started
      Sleep(2000);            // or SCM hasn't registered killed process
      if not StartService(hSvc, 0, pch) then begin
        ExitError('StartService', Code);
        Exit;
      end;
    end else begin
      ExitError('StartService', Code);
      Exit;
    end;
  end;
  CloseServiceHandle(hSvc);
  CloseServiceHandle(hSC);
end;

procedure CheckTermsrvProcess;
label
  back;
var
  hSC: SC_HANDLE;
  dwNeedBytes, dwReturnBytes, dwResumeHandle, Code: DWORD;
  Svc: Array of ENUM_SERVICE_STATUS_PROCESS;
  I: Integer;
  Found, Started: Boolean;
  TermServiceName: String;
begin
  Started := False;
  back:
  hSC := OpenSCManager(nil, SERVICES_ACTIVE_DATABASE, SC_MANAGER_CONNECT or SC_MANAGER_ENUMERATE_SERVICE);
  if hSC = 0 then
  begin
    Code := GetLastError;
    Writeln('[-] OpenSCManager error (code ', Code, ').');
    Halt(Code);
  end;

  dwResumeHandle := 0;

  SetLength(Svc, 1489);
  FillChar(Svc[0], sizeof(Svc[0])*Length(Svc), 0);
  if not EnumServicesStatusEx(hSC, SC_ENUM_PROCESS_INFO, SERVICE_WIN32, SERVICE_STATE_ALL,
  @Svc[0], sizeof(Svc[0])*Length(Svc), dwNeedBytes, dwReturnBytes, dwResumeHandle, nil) then begin
    Code := GetLastError;
    if Code <> ERROR_MORE_DATA then
    begin
      CloseServiceHandle(hSC);
      Writeln('[-] EnumServicesStatusEx error (code ', Code, ').');
      Halt(Code);
    end
    else
    begin
      SetLength(Svc, 5957);
      FillChar(Svc[0], sizeof(Svc[0])*Length(Svc), 0);
      if not EnumServicesStatusEx(hSC, SC_ENUM_PROCESS_INFO, SERVICE_WIN32, SERVICE_STATE_ALL,
      @Svc[0], sizeof(Svc[0])*Length(Svc), dwNeedBytes, dwReturnBytes, dwResumeHandle, nil) then begin
        CloseServiceHandle(hSC);
        Code := GetLastError;
        Writeln('[-] EnumServicesStatusEx error (code ', Code, ').');
        Halt(Code);
      end;
    end;
  end;
  CloseServiceHandle(hSC);

  Found := False;
  for I := 0 to Length(Svc) - 1 do
  begin
    if Svc[I].lpServiceName = nil then
      Break;
    if LowerCase(Svc[I].lpServiceName) = LowerCase(TermService) then
    begin
      Found := True;
      TermServiceName := Svc[I].lpServiceName;
      TermServicePID := Svc[I].ServiceStatusProcess.dwProcessId;
      Break;
    end;
  end;
  if not Found then
  begin
    Writeln('[-] TermService not found.');
    Halt(ERROR_SERVICE_DOES_NOT_EXIST);
  end;
  if TermServicePID = 0 then
  begin
    if Started then begin
      Writeln('[-] Failed to set up TermService. Unknown error.');
      Halt(ERROR_SERVICE_NOT_ACTIVE);
    end;
    SvcConfigStart(TermService, SERVICE_AUTO_START);
    SvcStart(TermService);
    Started := True;
    goto back;
  end
  else
    Writeln('[+] TermService found (pid ', TermServicePID, ').');

  SetLength(ShareSvc, 0);
  for I := 0 to Length(Svc) - 1 do
  begin
    if Svc[I].lpServiceName = nil then
      Break;
    if Svc[I].ServiceStatusProcess.dwProcessId = TermServicePID then
      if Svc[I].lpServiceName <> TermServiceName then
      begin
        SetLength(ShareSvc, Length(ShareSvc)+1);
        ShareSvc[Length(ShareSvc)-1] := Svc[I].lpServiceName;
      end;
  end;
  sShareSvc := '';
  for I := 0 to Length(ShareSvc) - 1 do
    if sShareSvc = '' then
      sShareSvc := ShareSvc[I]
    else
      sShareSvc := sShareSvc + ', ' + ShareSvc[I];
  if sShareSvc <> '' then
    Writeln('[*] Shared services found: ', sShareSvc)
  else
    Writeln('[*] No shared services found.');
end;

function AddPrivilege(SePriv: String): Boolean;
var
  hToken: THandle;
  SeNameValue: Int64;
  tkp: TOKEN_PRIVILEGES;
  ReturnLength: Cardinal;
  ErrorCode: Cardinal;
begin
  Result := False;
  if not OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES
  or TOKEN_QUERY, hToken) then begin
    ErrorCode := GetLastError;
    Writeln('[-] OpenProcessToken error (code ' + IntToStr(ErrorCode) + ').');
    Exit;
  end;
  if not LookupPrivilegeValue(nil, PWideChar(SePriv), SeNameValue) then begin
    ErrorCode := GetLastError;
    Writeln('[-] LookupPrivilegeValue error (code ' + IntToStr(ErrorCode) + ').');
    Exit;
  end;
  tkp.PrivilegeCount := 1;
  tkp.Privileges[0].Luid := SeNameValue;
  tkp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
  if not AdjustTokenPrivileges(hToken, False, tkp, SizeOf(tkp), tkp, ReturnLength) then begin
    ErrorCode := GetLastError;
    Writeln('[-] AdjustTokenPrivileges error (code ' + IntToStr(ErrorCode) + ').');
    Exit;
  end;
  Result := True;
end;

procedure KillProcess(PID: DWORD);
var
  hProc: THandle;
  Code: DWORD;
begin
  hProc := OpenProcess(PROCESS_TERMINATE, False, PID);
  if hProc = 0 then
  begin
    Code := GetLastError;
    Writeln('[-] OpenProcess error (code ', Code, ').');
    Halt(Code);
  end;
  if not TerminateProcess(hProc, 0) then
  begin
    CloseHandle(hProc);
    Code := GetLastError;
    Writeln('[-] TerminateProcess error (code ', Code, ').');
    Halt(Code);
  end;
  CloseHandle(hProc);
end;

function ExecWait(Cmdline: String): Boolean;
var
  si: STARTUPINFO;
  pi: PROCESS_INFORMATION;
begin
  Result := False;
  ZeroMemory(@si, sizeof(si));
  si.cb := sizeof(si);
  UniqueString(Cmdline);
  if not CreateProcess(nil, PWideChar(Cmdline), nil, nil, True, 0, nil, nil, si, pi) then begin
    Writeln('[-] CreateProcess error (code: ', GetLastError, ').');
    Exit;
  end;
  CloseHandle(pi.hThread);
  WaitForSingleObject(pi.hProcess, INFINITE);
  CloseHandle(pi.hProcess);
  Result := True;
end;

function ExpandPath(Path: String): String;
var
  Str: Array[0..511] of Char;
begin
  Result := '';
  FillChar(Str, 512, 0);
  if Arch = 64 then
    Path := StringReplace(Path, '%ProgramFiles%', '%ProgramW6432%', [rfReplaceAll, rfIgnoreCase]);
  if ExpandEnvironmentStrings(PWideChar(Path), Str, 512) > 0 then
    Result := Str;
end;

procedure SetWrapperDll;
var
  Reg: TRegistry;
  Code: DWORD;
begin
  if Arch = 64 then
    Reg := TRegistry.Create(KEY_WRITE or KEY_WOW64_64KEY)
  else
    Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  if not Reg.OpenKey('\SYSTEM\CurrentControlSet\Services\TermService\Parameters', True) then
  begin
    Code := GetLastError;
    Writeln('[-] OpenKey error (code ', Code, ').');
    Halt(Code);
  end;
  try
    Reg.WriteExpandString('ServiceDll', WrapPath);
    if (Arch = 64) and (FV.Version.w.Major = 6) and (FV.Version.w.Minor = 0) then
      ExecWait('"'+ExpandPath('%SystemRoot%')+'\system32\reg.exe" add HKLM\SYSTEM\CurrentControlSet\Services\TermService\Parameters /v ServiceDll /t REG_EXPAND_SZ /d "'+WrapPath+'" /f');
  except
    Writeln('[-] WriteExpandString error.');
    Halt(ERROR_ACCESS_DENIED);
  end;

  Reg.CloseKey;
  Reg.Free;
end;

procedure ResetServiceDll;
var
  Reg: TRegistry;
  Code: DWORD;
begin
  if Arch = 64 then
    Reg := TRegistry.Create(KEY_WRITE or KEY_WOW64_64KEY)
  else
    Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  if not Reg.OpenKey('\SYSTEM\CurrentControlSet\Services\TermService\Parameters', True) then
  begin
    Code := GetLastError;
    Writeln('[-] OpenKey error (code ', Code, ').');
    Halt(Code);
  end;
  try
    Reg.WriteExpandString('ServiceDll', '%SystemRoot%\System32\termsrv.dll');
  except
    Writeln('[-] WriteExpandString error.');
    Halt(ERROR_ACCESS_DENIED);
  end;
  Reg.CloseKey;
  Reg.Free;
end;

procedure ExtractRes(ResName, Path: String);
var
  ResStream: TResourceStream;
begin
  ResStream := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
  try
    ResStream.SaveToFile(Path);
  except
    Writeln('[-] Failed to extract file.');
    Writeln('[*] Resource name: ' + ResName);
    Writeln('[*] Destination path: ' + Path);
    ResStream.Free;
    Exit;
  end;
  Writeln('[+] Extracted ', ResName, ' -> ', Path);
  ResStream.Free;
end;

function ExtractResText(ResName: String): String;
var
  ResStream: TResourceStream;
  Str: TStringList;
begin
  ResStream := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
  Str := TStringList.Create;
  try
    Str.LoadFromStream(ResStream);
  except

  end;
  ResStream.Free;
  Result := Str.Text;
  Str.Free;
end;

function GitINIFile(var Content: String): Boolean;
const
  URL = 'https://raw.githubusercontent.com/stascorp/rdpwrap/master/res/rdpwrap.ini';
var
  NetHandle: HINTERNET;
  UrlHandle: HINTERNET;
  Str: String;
  Buf: Array[0..1023] of Byte;
  BytesRead: DWORD;
begin
  Result := False;
  Content := '';
  NetHandle := InternetOpen('RDP Wrapper Update', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if not Assigned(NetHandle) then
    Exit;
  UrlHandle := InternetOpenUrl(NetHandle, PChar(URL), nil, 0, INTERNET_FLAG_RELOAD, 0);
  if not Assigned(UrlHandle) then
  begin
    InternetCloseHandle(NetHandle);
    Exit;
  end;
  repeat
    InternetReadFile(UrlHandle, @Buf[0], SizeOf(Buf), BytesRead);
    SetString(Str, PAnsiChar(@Buf[0]), BytesRead);
    Content := Content + Str;
  until BytesRead = 0;
  InternetCloseHandle(UrlHandle);
  InternetCloseHandle(NetHandle);
  Result := True;
end;

procedure ExtractFiles;
var
  RDPClipRes, S: String;
  OnlineINI: TStringList;
begin
  if not DirectoryExists(ExtractFilePath(ExpandPath(WrapPath))) then
    if ForceDirectories(ExtractFilePath(ExpandPath(WrapPath))) then
      Writeln('[+] Folder created: ', ExtractFilePath(ExpandPath(WrapPath)))
    else begin
      Writeln('[-] ForceDirectories error.');
      Writeln('[*] Path: ', ExtractFilePath(ExpandPath(WrapPath)));
      Halt(0);
    end;
  if Online then
  begin
    Writeln('[*] Downloading latest INI file...');
    OnlineINI := TStringList.Create;
    if GitINIFile(S) then begin
      OnlineINI.Text := S;
      S := ExtractFilePath(ExpandPath(WrapPath)) + 'rdpwrap.ini';
      OnlineINI.SaveToFile(S);
      Writeln('[+] Latest INI file -> ', S);
    end
    else
    begin
      Writeln('[-] Failed to get online INI file, using built-in.');
      Online := False;
    end;
    OnlineINI.Free;
  end;
  if not Online then
    ExtractRes('config', ExtractFilePath(ExpandPath(WrapPath)) + 'rdpwrap.ini');

  RDPClipRes := '';
  case Arch of
    32: begin
      ExtractRes('rdpw32', ExpandPath(WrapPath));
      if (FV.Version.w.Major = 6) and (FV.Version.w.Minor = 0) then
        RDPClipRes := 'rdpclip6032';
      if (FV.Version.w.Major = 6) and (FV.Version.w.Minor = 1) then
        RDPClipRes := 'rdpclip6132';
    end;
    64: begin
      ExtractRes('rdpw64', ExpandPath(WrapPath));
      if (FV.Version.w.Major = 6) and (FV.Version.w.Minor = 0) then
        RDPClipRes := 'rdpclip6064';
      if (FV.Version.w.Major = 6) and (FV.Version.w.Minor = 1) then
        RDPClipRes := 'rdpclip6164';
    end;
  end;
  if RDPClipRes <> '' then
    if not FileExists(ExpandPath('%SystemRoot%\System32\rdpclip.exe')) then
      ExtractRes(RDPClipRes, ExpandPath('%SystemRoot%\System32\rdpclip.exe'));
end;

procedure DeleteFiles;
var
  Code: DWORD;
  FullPath, Path: String;
begin
  FullPath := ExpandPath(TermServicePath);
  Path := ExtractFilePath(FullPath);

  if not DeleteFile(PWideChar(Path + 'rdpwrap.ini')) then
  begin
    Code := GetLastError;
    Writeln('[-] DeleteFile error (code ', Code, ').');
    Exit;
  end;
  Writeln('[+] Removed file: ', Path + 'rdpwrap.ini');

  if not DeleteFile(PWideChar(FullPath)) then
  begin
    Code := GetLastError;
    Writeln('[-] DeleteFile error (code ', Code, ').');
    Exit;
  end;
  Writeln('[+] Removed file: ', FullPath);

  if not RemoveDirectory(PWideChar(ExtractFilePath(ExpandPath(TermServicePath)))) then
  begin
    Code := GetLastError;
    Writeln('[-] RemoveDirectory error (code ', Code, ').');
    Exit;
  end;
  Writeln('[+] Removed folder: ', ExtractFilePath(ExpandPath(TermServicePath)));
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

  FreeLibrary(hFile);
  Result := True;
end;

procedure CheckTermsrvVersion;
var
  SuppLvl: Byte;
  VerTxt: String;

  procedure UpdateMsg;
  begin
    Writeln('Try running "update.bat" or "RDPWInst -w" to download latest INI file.');
    Writeln('If it doesn''t help, send your termsrv.dll to project developer for support.');
  end;
begin
  GetFileVersion(ExpandPath(TermServicePath), FV);
  VerTxt := Format('%d.%d.%d.%d',
  [FV.Version.w.Major, FV.Version.w.Minor, FV.Release, FV.Build]);
  Writeln('[*] Terminal Services version: ', VerTxt);

  if (FV.Version.w.Major = 5) and (FV.Version.w.Minor = 1) then
  begin
    if Arch = 32 then
    begin
      Writeln('[!] Windows XP is not supported.');
      Writeln('You may take a look at RDP Realtime Patch by Stas''M for Windows XP');
      Writeln('Link: http://stascorp.com/load/1-1-0-62');
    end;
    if Arch = 64 then
      Writeln('[!] Windows XP 64-bit Edition is not supported.');
    Exit;
  end;
  if (FV.Version.w.Major = 5) and (FV.Version.w.Minor = 2) then
  begin
    if Arch = 32 then
      Writeln('[!] Windows Server 2003 is not supported.');
    if Arch = 64 then
      Writeln('[!] Windows Server 2003 or XP 64-bit Edition is not supported.');
    Exit;
  end;
  SuppLvl := 0;
  if (FV.Version.w.Major = 6) and (FV.Version.w.Minor = 0) then begin
    SuppLvl := 1;
    if (Arch = 32) and (FV.Release = 6000) and (FV.Build = 16386) then begin
      Writeln('[!] This version of Terminal Services may crash on logon attempt.');
      Writeln('It''s recommended to upgrade to Service Pack 1 or higher.');
    end;
  end;
  if (FV.Version.w.Major = 6) and (FV.Version.w.Minor = 1) then
    SuppLvl := 1;
  if Pos('[' + VerTxt + ']', ExtractResText('config')) > 0 then
    SuppLvl := 2;
  case SuppLvl of
    0: begin
      Writeln('[-] This version of Terminal Services is not supported.');
      UpdateMsg;
    end;
    1: begin
      Writeln('[!] This version of Terminal Services is supported partially.');
      Writeln('It means you may have some limitations such as only 2 concurrent sessions.');
      UpdateMsg;
    end;
    2: begin
      Writeln('[+] This version of Terminal Services is fully supported.');
    end;
  end;
end;

procedure CheckTermsrvDependencies;
const
  CertPropSvc = 'CertPropSvc';
  SessionEnv = 'SessionEnv';
begin
  if SvcGetStart(CertPropSvc) = SERVICE_DISABLED then
    SvcConfigStart(CertPropSvc, SERVICE_DEMAND_START);
  if SvcGetStart(SessionEnv) = SERVICE_DISABLED then
    SvcConfigStart(SessionEnv, SERVICE_DEMAND_START);
end;

procedure TSConfigRegistry(Enable: Boolean);
var
  Reg: TRegistry;
  Code: DWORD;
begin
  if Arch = 64 then
    Reg := TRegistry.Create(KEY_WRITE or KEY_WOW64_64KEY)
  else
    Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  if not Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Terminal Server', True) then
  begin
    Code := GetLastError;
    Writeln('[-] OpenKey error (code ', Code, ').');
    Halt(Code);
  end;
  try
    Reg.WriteBool('fDenyTSConnections', not Enable);
  except
    Writeln('[-] WriteBool error.');
    Halt(ERROR_ACCESS_DENIED);
  end;
  Reg.CloseKey;
  if Enable then
  begin
    if not Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Terminal Server\Licensing Core', True) then
    begin
      Code := GetLastError;
      Writeln('[-] OpenKey error (code ', Code, ').');
      Halt(Code);
    end;
    try
      Reg.WriteBool('EnableConcurrentSessions', True);
    except
      Writeln('[-] WriteBool error.');
      Halt(ERROR_ACCESS_DENIED);
    end;
    Reg.CloseKey;

    if not Reg.OpenKey('\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon', True) then
    begin
      Code := GetLastError;
      Writeln('[-] OpenKey error (code ', Code, ').');
      Halt(Code);
    end;
    try
      Reg.WriteBool('AllowMultipleTSSessions', True);
    except
      Writeln('[-] WriteBool error.');
      Halt(ERROR_ACCESS_DENIED);
    end;
    Reg.CloseKey;

    if not Reg.KeyExists('\SYSTEM\CurrentControlSet\Control\Terminal Server\AddIns') then begin
      if not Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Terminal Server\AddIns', True) then
      begin
        Code := GetLastError;
        Writeln('[-] OpenKey error (code ', Code, ').');
        Halt(Code);
      end;
      Reg.CloseKey;
      if not Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Terminal Server\AddIns\Clip Redirector', True) then
      begin
        Code := GetLastError;
        Writeln('[-] OpenKey error (code ', Code, ').');
        Halt(Code);
      end;
      try
        Reg.WriteString('Name', 'RDPClip');
        Reg.WriteInteger('Type', 3);
      except
        Writeln('[-] WriteInteger error.');
        Halt(ERROR_ACCESS_DENIED);
      end;
      Reg.CloseKey;
      if not Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Terminal Server\AddIns\DND Redirector', True) then
      begin
        Code := GetLastError;
        Writeln('[-] OpenKey error (code ', Code, ').');
        Halt(Code);
      end;
      try
        Reg.WriteString('Name', 'RDPDND');
        Reg.WriteInteger('Type', 3);
      except
        Writeln('[-] WriteInteger error.');
        Halt(ERROR_ACCESS_DENIED);
      end;
      Reg.CloseKey;
      if not Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Terminal Server\AddIns\Dynamic VC', True) then
      begin
        Code := GetLastError;
        Writeln('[-] OpenKey error (code ', Code, ').');
        Halt(Code);
      end;
      try
        Reg.WriteInteger('Type', -1);
      except
        Writeln('[-] WriteInteger error.');
        Halt(ERROR_ACCESS_DENIED);
      end;
      Reg.CloseKey;
    end;
  end;
  Reg.Free;
end;

procedure TSConfigFirewall(Enable: Boolean);
begin
  if Enable then
    ExecWait('netsh advfirewall firewall add rule name="Remote Desktop" dir=in protocol=tcp localport=3389 profile=any action=allow')
  else
    ExecWait('netsh advfirewall firewall delete rule name="Remote Desktop"');
end;

function CheckINIDate(Filename, Content: String; var Date: Integer): Boolean;
var
  Str: TStringList;
  I: Integer;
begin
  Result := False;
  Str := TStringList.Create;
  if Filename <> '' then begin
    try
      Str.LoadFromFile(Filename);
    except
      Writeln('[-] Failed to read INI file.');
      Exit;
    end;
  end else
    Str.Text := Content;
  for I := 0 to Str.Count - 1 do
    if Pos('Updated=', Str[I]) = 1 then
      Break;
  if I >= Str.Count then begin
    Writeln('[-] Failed to check INI date.');
    Exit;
  end;
  Content := StringReplace(Str[I], 'Updated=', '', []);
  Content := StringReplace(Content, '-', '', [rfReplaceAll]);
  Str.Free;
  try
    Date := StrToInt(Content);
  except
    Writeln('[-] Wrong INI date format.');
    Exit;
  end;
  Result := True;
end;

procedure CheckUpdate;
var
  INIPath, S: String;
  Str: TStringList;
  I, OldDate, NewDate: Integer;
begin
  INIPath := ExtractFilePath(ExpandPath(TermServicePath)) + 'rdpwrap.ini';
  if not CheckINIDate(INIPath, '', OldDate) then
    Halt(ERROR_ACCESS_DENIED);
  Writeln('[*] Current update date: ',
    Format('%d.%.2d.%.2d', [OldDate div 10000, OldDate div 100 mod 100, OldDate mod 100]));

  if not GitINIFile(S) then begin
    Writeln('[-] Failed to download latest INI from GitHub.');
    Halt(ERROR_ACCESS_DENIED);
  end;
  if not CheckINIDate('', S, NewDate) then
    Halt(ERROR_ACCESS_DENIED);
  Writeln('[*] Latest update date:  ',
    Format('%d.%.2d.%.2d', [NewDate div 10000, NewDate div 100 mod 100, NewDate mod 100]));

  if NewDate = OldDate then
    Writeln('[*] Everything is up to date.')
  else
    if NewDate > OldDate then begin
      Writeln('[+] New update is available, updating...');

      CheckTermsrvProcess;

      Writeln('[*] Terminating service...');
      AddPrivilege('SeDebugPrivilege');
      KillProcess(TermServicePID);
      Sleep(1000);

      if Length(ShareSvc) > 0 then
        for I := 0 to Length(ShareSvc) - 1 do
          SvcStart(ShareSvc[I]);
      Sleep(500);

      Str := TStringList.Create;
      Str.Text := S;
      try
        Str.SaveToFile(INIPath);
      except
        Writeln('[-] Failed to write INI file.');
        Halt(ERROR_ACCESS_DENIED);
      end;
      Str.Free;

      SvcStart(TermService);

      Writeln('[+] Update completed.');
    end else
      Writeln('[*] Your INI file is newer than public file. Are you a developer? :)');
end;

var
  I: Integer;
begin
  Writeln('RDP Wrapper Library v1.6');
  Writeln('Installer v2.3');
  Writeln('Copyright (C) Stas''M Corp. 2016');
  Writeln('');

  if (ParamCount < 1)
  or (
    (ParamStr(1) <> '-l')
    and (ParamStr(1) <> '-i')
    and (ParamStr(1) <> '-w')
    and (ParamStr(1) <> '-u')
    and (ParamStr(1) <> '-r')
  ) then
  begin
    Writeln('USAGE:');
    Writeln('RDPWInst.exe [-l|-i[-s][-o]|-w|-u[-k]|-r]');
    Writeln('');
    Writeln('-l          display the license agreement');
    Writeln('-i          install wrapper to Program Files folder (default)');
    Writeln('-i -s       install wrapper to System32 folder');
    Writeln('-i -o       online install mode (loads latest INI file)');
    Writeln('-w          get latest update for INI file');
    Writeln('-u          uninstall wrapper');
    Writeln('-u -k       uninstall wrapper and keep settings');
    Writeln('-r          force restart Terminal Services');
    Exit;
  end;

  if ParamStr(1) = '-l' then
  begin
    Writeln(ExtractResText('license'));
    Exit;
  end;

  if not CheckWin32Version(6,0) then
  begin
    Writeln('[-] Unsupported Windows version:');
    Writeln('  only >= 6.0 (Vista, Server 2008 and newer) are supported.');
    Exit;
  end;

  if not SupportedArchitecture then
  begin
    Writeln('[-] Unsupported processor architecture.');
    Exit;
  end;

  CheckInstall;

  if ParamStr(1) = '-i' then
  begin
    if Installed then
    begin
      Writeln('[*] RDP Wrapper Library is already installed.');
      Halt(ERROR_INVALID_FUNCTION);
    end;
    Writeln('[*] Notice to user:');
    Writeln('  - By using all or any portion of this software, you are agreeing');
    Writeln('  to be bound by all the terms and conditions of the license agreement.');
    Writeln('  - To read the license agreement, run the installer with -l parameter.');
    Writeln('  - If you do not agree to any terms of the license agreement,');
    Writeln('  do not use the software.');

    Writeln('[*] Installing...');
    if ParamStr(2) = '-s' then
      WrapPath := '%SystemRoot%\system32\rdpwrap.dll'
    else
      WrapPath := '%ProgramFiles%\RDP Wrapper\rdpwrap.dll';

    if Arch = 64 then
      DisableWowRedirection;

    CheckTermsrvVersion;
    CheckTermsrvProcess;

    Writeln('[*] Extracting files...');
    Online := (ParamStr(2) = '-o') or (ParamStr(3) = '-o');
    ExtractFiles;

    Writeln('[*] Configuring service library...');
    SetWrapperDll;

    Writeln('[*] Checking dependencies...');
    CheckTermsrvDependencies;

    Writeln('[*] Terminating service...');
    AddPrivilege('SeDebugPrivilege');
    KillProcess(TermServicePID);
    Sleep(1000);

    if Length(ShareSvc) > 0 then
      for I := 0 to Length(ShareSvc) - 1 do
        SvcStart(ShareSvc[I]);
    Sleep(500);
    SvcStart(TermService);
    Sleep(500);

    Writeln('[*] Configuring registry...');
    TSConfigRegistry(True);
    Writeln('[*] Configuring firewall...');
    TSConfigFirewall(True);

    Writeln('[+] Successfully installed.');

    if Arch = 64 then
      RevertWowRedirection;
  end;
  if ParamStr(1) = '-u' then
  begin
    if not Installed then
    begin
      Writeln('[*] RDP Wrapper Library is not installed.');
      Halt(ERROR_INVALID_FUNCTION);
    end;
    Writeln('[*] Uninstalling...');

    if Arch = 64 then
      DisableWowRedirection;

    CheckTermsrvProcess;

    Writeln('[*] Resetting service library...');
    ResetServiceDll;

    Writeln('[*] Terminating service...');
    AddPrivilege('SeDebugPrivilege');
    KillProcess(TermServicePID);
    Sleep(1000);

    Writeln('[*] Removing files...');
    DeleteFiles;

    if Length(ShareSvc) > 0 then
      for I := 0 to Length(ShareSvc) - 1 do
        SvcStart(ShareSvc[I]);
    Sleep(500);
    SvcStart(TermService);
    Sleep(500);

    if ParamStr(2) <> '-k' then
    begin
      Writeln('[*] Configuring registry...');
      TSConfigRegistry(False);
      Writeln('[*] Configuring firewall...');
      TSConfigFirewall(False);
    end;

    if Arch = 64 then
      RevertWowRedirection;

    Writeln('[+] Successfully uninstalled.');
  end;

  if ParamStr(1) = '-w' then
  begin
    if not Installed then
    begin
      Writeln('[*] RDP Wrapper Library is not installed.');
      Halt(ERROR_INVALID_FUNCTION);
    end;
    Writeln('[*] Checking for updates...');
    CheckUpdate;
  end;

  if ParamStr(1) = '-r' then
  begin
    Writeln('[*] Restarting...');

    CheckTermsrvProcess;

    Writeln('[*] Terminating service...');
    AddPrivilege('SeDebugPrivilege');
    KillProcess(TermServicePID);
    Sleep(1000);

    if Length(ShareSvc) > 0 then
      for I := 0 to Length(ShareSvc) - 1 do
        SvcStart(ShareSvc[I]);
    Sleep(500);
    SvcStart(TermService);

    Writeln('[+] Done.');
  end;
end.
