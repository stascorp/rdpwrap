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

unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, ExtCtrls, Registry, WinSvc;

type
  TMainForm = class(TForm)
    bOK: TButton;
    bCancel: TButton;
    bApply: TButton;
    cbSingleSessionPerUser: TCheckBox;
    rgNLA: TRadioGroup;
    cbAllowTSConnections: TCheckBox;
    rgShadow: TRadioGroup;
    seRDPPort: TSpinEdit;
    lRDPPort: TLabel;
    lService: TLabel;
    lListener: TLabel;
    lWrapper: TLabel;
    lsListener: TLabel;
    lsService: TLabel;
    lsWrapper: TLabel;
    Timer: TTimer;
    lTSVer: TLabel;
    lsTSVer: TLabel;
    lWrapVer: TLabel;
    lsWrapVer: TLabel;
    bLicense: TButton;
    gbDiag: TGroupBox;
    lsSuppVer: TLabel;
    cbHideUsers: TCheckBox;
    gbGeneral: TGroupBox;
    procedure FormCreate(Sender: TObject);
    procedure cbAllowTSConnectionsClick(Sender: TObject);
    procedure seRDPPortChange(Sender: TObject);
    procedure bApplyClick(Sender: TObject);
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure bLicenseClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function ExecWait(Cmdline: String): Boolean;
    procedure ReadSettings;
    procedure WriteSettings;
  end;
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
  WTS_SESSION_INFOW = record
    SessionId: DWORD;
    Name: packed array [0..33] of WideChar;
    State: DWORD;
  end;
  WTS_SESSION = Array[0..0] of WTS_SESSION_INFOW;
  PWTS_SESSION_INFOW = ^WTS_SESSION;

const
  winstadll = 'winsta.dll';
var
  MainForm: TMainForm;
  Ready: Boolean = False;
  Arch: Byte;
  OldWow64RedirectionValue: LongBool;
  OldPort: Word;
  INI: String;

function WinStationEnumerateW(hServer: THandle;
  var ppSessionInfo: PWTS_SESSION_INFOW; var pCount: DWORD): BOOL; stdcall;
  external winstadll name 'WinStationEnumerateW';
function WinStationFreeMemory(P: Pointer): BOOL; stdcall; external winstadll;

implementation

{$R *.dfm}
{$R resource.res}

uses
  LicenseUnit;

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

function IsWrapperInstalled(var WrapperPath: String): ShortInt;
var
  TermServiceHost,
  TermServicePath: String;
  Reg: TRegistry;
begin
  Result := -1;
  WrapperPath := '';
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  if not Reg.OpenKeyReadOnly('\SYSTEM\CurrentControlSet\Services\TermService') then begin
    Reg.Free;
    Exit;
  end;
  TermServiceHost := Reg.ReadString('ImagePath');
  Reg.CloseKey;
  if Pos('svchost.exe', LowerCase(TermServiceHost)) = 0 then
  begin
    Result := 2;
    Reg.Free;
    Exit;
  end;
  if not Reg.OpenKeyReadOnly('\SYSTEM\CurrentControlSet\Services\TermService\Parameters') then
  begin
    Reg.Free;
    Exit;
  end;
  TermServicePath := Reg.ReadString('ServiceDll');
  Reg.CloseKey;
  Reg.Free;
  if (Pos('termsrv.dll', LowerCase(TermServicePath)) = 0)
  and (Pos('rdpwrap.dll', LowerCase(TermServicePath)) = 0) then
  begin
    Result := 2;
    Exit;
  end;

  if Pos('rdpwrap.dll', LowerCase(TermServicePath)) > 0 then begin
    WrapperPath := TermServicePath;
    Result := 1;
  end else
    Result := 0;
end;

function GetTermSrvState: ShortInt;
type
  SERVICE_STATUS_PROCESS = record
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
const
  SvcName = 'TermService';
var
  hSC: SC_HANDLE;
  hSvc: THandle;
  lpServiceStatusProcess: PSERVICE_STATUS_PROCESS;
  Buf: Pointer;
  cbBufSize, pcbBytesNeeded: Cardinal;
begin
  Result := -1;
  hSC := OpenSCManager(nil, SERVICES_ACTIVE_DATABASE, SC_MANAGER_CONNECT);
  if hSC = 0 then
    Exit;

  hSvc := OpenService(hSC, PWideChar(SvcName), SERVICE_QUERY_STATUS);
  if hSvc = 0 then
  begin
    CloseServiceHandle(hSC);
    Exit;
  end;

  if QueryServiceStatusEx(hSvc, SC_STATUS_PROCESS_INFO, nil, 0, pcbBytesNeeded) then
    Exit;

  cbBufSize := pcbBytesNeeded;
  GetMem(Buf, cbBufSize);

  if not QueryServiceStatusEx(hSvc, SC_STATUS_PROCESS_INFO, Buf, cbBufSize, pcbBytesNeeded) then begin
    FreeMem(Buf, cbBufSize);
    CloseServiceHandle(hSvc);
    CloseServiceHandle(hSC);
    Exit;
  end else begin
    lpServiceStatusProcess := Buf;
    Result := ShortInt(lpServiceStatusProcess^.dwCurrentState);
  end;
  FreeMem(Buf, cbBufSize);
  CloseServiceHandle(hSvc);
  CloseServiceHandle(hSC);
end;

function IsListenerWorking: Boolean;
var
  pCount: DWORD;
  SessionInfo: PWTS_SESSION_INFOW;
  I: Integer;
begin
  Result := False;
  if not WinStationEnumerateW(0, SessionInfo, pCount) then
    Exit;
  for I := 0 to pCount - 1 do
    if SessionInfo^[I].Name = 'RDP-Tcp' then begin
      Result := True;
      Break;
    end;
  WinStationFreeMemory(SessionInfo);
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

function TMainForm.ExecWait(Cmdline: String): Boolean;
var
  si: STARTUPINFO;
  pi: PROCESS_INFORMATION;
begin
  Result := False;
  ZeroMemory(@si, sizeof(si));
  si.cb := sizeof(si);
  si.dwFlags := STARTF_USESHOWWINDOW;
  si.wShowWindow := SW_HIDE;
  UniqueString(Cmdline);
  if not CreateProcess(nil, PWideChar(Cmdline), nil, nil, True, 0, nil, nil, si, pi) then begin
    MessageBox(Handle,
      PWideChar('CreateProcess error (code: ' + IntToStr(GetLastError) + ').'),
      'Error', MB_ICONERROR or MB_OK);
    Exit;
  end;
  CloseHandle(pi.hThread);
  WaitForSingleObject(pi.hProcess, INFINITE);
  CloseHandle(pi.hProcess);
  Result := True;
end;

procedure TMainForm.ReadSettings;
var
  Reg: TRegistry;
  SecurityLayer, UserAuthentication: Integer;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  Reg.OpenKeyReadOnly('\SYSTEM\CurrentControlSet\Control\Terminal Server');
  try
    cbAllowTSConnections.Checked := not Reg.ReadBool('fDenyTSConnections');
  except

  end;
  try
    cbSingleSessionPerUser.Checked := Reg.ReadBool('fSingleSessionPerUser');
  except

  end;
  Reg.CloseKey;

  Reg.OpenKeyReadOnly('\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp');
  seRDPPort.Value := 3389;
  try
    seRDPPort.Value := Reg.ReadInteger('PortNumber');
  except

  end;
  OldPort := seRDPPort.Value;
  SecurityLayer := 0;
  UserAuthentication := 0;
  try
    SecurityLayer := Reg.ReadInteger('SecurityLayer');
    UserAuthentication := Reg.ReadInteger('UserAuthentication');
  except

  end;
  if (SecurityLayer = 0) and (UserAuthentication = 0) then
    rgNLA.ItemIndex := 0;
  if (SecurityLayer = 1) and (UserAuthentication = 0) then
    rgNLA.ItemIndex := 1;
  if (SecurityLayer = 2) and (UserAuthentication = 1) then
    rgNLA.ItemIndex := 2;
  try
    rgShadow.ItemIndex := Reg.ReadInteger('Shadow');
  except

  end;
  Reg.CloseKey;
  Reg.OpenKeyReadOnly('\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System');
  try
    cbHideUsers.Checked := Reg.ReadBool('dontdisplaylastusername');
  except

  end;
  Reg.CloseKey;
  Reg.Free;
end;

procedure TMainForm.WriteSettings;
var
  Reg: TRegistry;
  SecurityLayer, UserAuthentication: Integer;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Terminal Server', True);
  try
    Reg.WriteBool('fDenyTSConnections', not cbAllowTSConnections.Checked);
  except

  end;
  try
    Reg.WriteBool('fSingleSessionPerUser', cbSingleSessionPerUser.Checked);
  except

  end;
  Reg.CloseKey;

  Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp', True);
  try
    Reg.WriteInteger('PortNumber', seRDPPort.Value);
  except

  end;
  if OldPort <> seRDPPort.Value then
  begin
    OldPort := seRDPPort.Value;
    ExecWait('netsh advfirewall firewall set rule name="Remote Desktop" new localport=' + IntToStr(OldPort));
  end;
  case rgNLA.ItemIndex of
    0: begin
      SecurityLayer := 0;
      UserAuthentication := 0;
    end;
    1: begin
      SecurityLayer := 1;
      UserAuthentication := 0;
    end;
    2: begin
      SecurityLayer := 2;
      UserAuthentication := 1;
    end;
    else begin
      SecurityLayer := -1;
      UserAuthentication := -1;
    end;
  end;
  if SecurityLayer >= 0 then begin
    try
      Reg.WriteInteger('SecurityLayer', SecurityLayer);
      Reg.WriteInteger('UserAuthentication', UserAuthentication);
    except

    end;
  end;
  if rgShadow.ItemIndex >= 0 then begin
    try
      Reg.WriteInteger('Shadow', rgShadow.ItemIndex);
    except

    end;
  end;
  Reg.CloseKey;
  Reg.OpenKey('\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services', True);
  if rgShadow.ItemIndex >= 0 then begin
    try
      Reg.WriteInteger('Shadow', rgShadow.ItemIndex);
    except

    end;
  end;
  Reg.CloseKey;
  Reg.OpenKey('\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', True);
  try
    Reg.WriteBool('dontdisplaylastusername', cbHideUsers.Checked);
  except

  end;
  Reg.CloseKey;
  Reg.Free;
end;

function CheckSupport(FV: FILE_VERSION): Byte;
var
  VerTxt: String;
begin
  Result := 0;
  if (FV.Version.w.Major = 6) and (FV.Version.w.Minor = 0) then
    Result := 1;
  if (FV.Version.w.Major = 6) and (FV.Version.w.Minor = 1) then
    Result := 1;
  VerTxt := Format('%d.%d.%d.%d',
  [FV.Version.w.Major, FV.Version.w.Minor, FV.Release, FV.Build]);
  if Pos('[' + VerTxt + ']', INI) > 0 then
    Result := 2;
end;

procedure TMainForm.TimerTimer(Sender: TObject);
var
  WrapperPath, INIPath: String;
  FV: FILE_VERSION;
  L: TStringList;
  CheckSupp: Boolean;
begin
  CheckSupp := False;
  case IsWrapperInstalled(WrapperPath) of
    -1: begin
      lsWrapper.Caption := 'Unknown';
      lsWrapper.Font.Color := clGrayText;
    end;
    0: begin
      lsWrapper.Caption := 'Not installed';
      lsWrapper.Font.Color := clGrayText;
    end;
    1: begin
      lsWrapper.Caption := 'Installed';
      lsWrapper.Font.Color := clGreen;
      CheckSupp := True;
      INIPath := ExtractFilePath(ExpandPath(WrapperPath)) + 'rdpwrap.ini';
      if not FileExists(INIPath) then
        CheckSupp := False;
    end;
    2: begin
      lsWrapper.Caption := '3rd-party';
      lsWrapper.Font.Color := clRed;
    end;
  end;
  case GetTermSrvState of
    -1, 0: begin
      lsService.Caption := 'Unknown';
      lsService.Font.Color := clGrayText;
    end;
    SERVICE_STOPPED: begin
      lsService.Caption := 'Stopped';
      lsService.Font.Color := clRed;
    end;
    SERVICE_START_PENDING: begin
      lsService.Caption := 'Starting...';
      lsService.Font.Color := clGrayText;
    end;
    SERVICE_STOP_PENDING: begin
      lsService.Caption := 'Stopping...';
      lsService.Font.Color := clGrayText;
    end;
    SERVICE_RUNNING: begin
      lsService.Caption := 'Running';
      lsService.Font.Color := clGreen;
    end;
    SERVICE_CONTINUE_PENDING: begin
      lsService.Caption := 'Resuming...';
      lsService.Font.Color := clGrayText;
    end;
    SERVICE_PAUSE_PENDING: begin
      lsService.Caption := 'Suspending...';
      lsService.Font.Color := clGrayText;
    end;
    SERVICE_PAUSED: begin
      lsService.Caption := 'Suspended';
      lsService.Font.Color := clWindowText;
    end;
  end;
  if IsListenerWorking then begin
    lsListener.Caption := 'Listening';
    lsListener.Font.Color := clGreen;
  end else begin
    lsListener.Caption := 'Not listening';
    lsListener.Font.Color := clRed;
  end;
  if WrapperPath = '' then begin
    lsWrapVer.Caption := 'N/A';
    lsWrapVer.Font.Color := clGrayText;
  end else
    if not GetFileVersion(ExpandPath(WrapperPath), FV) then begin
      lsWrapVer.Caption := 'N/A';
      lsWrapVer.Font.Color := clGrayText;
    end else begin
      lsWrapVer.Caption :=
      IntToStr(FV.Version.w.Major)+'.'+
      IntToStr(FV.Version.w.Minor)+'.'+
      IntToStr(FV.Release)+'.'+
      IntToStr(FV.Build);
      lsWrapVer.Font.Color := clWindowText;
    end;
  if not GetFileVersion('termsrv.dll', FV) then begin
    lsTSVer.Caption := 'N/A';
    lsTSVer.Font.Color := clGrayText;
  end else begin
    lsTSVer.Caption :=
    IntToStr(FV.Version.w.Major)+'.'+
    IntToStr(FV.Version.w.Minor)+'.'+
    IntToStr(FV.Release)+'.'+
    IntToStr(FV.Build);
    lsTSVer.Font.Color := clWindowText;
    lsSuppVer.Visible := CheckSupp;
    if CheckSupp then begin
      if INI = '' then begin
        L := TStringList.Create;
        try
          L.LoadFromFile(INIPath);
        except

        end;
        INI := L.Text;
        L.Free;
      end;
      case CheckSupport(FV) of
        0: begin
          lsSuppVer.Caption := '[not supported]';
          lsSuppVer.Font.Color := clRed;
        end;
        1: begin
          lsSuppVer.Caption := '[supported partially]';
          lsSuppVer.Font.Color := clOlive;
        end;
        2: begin
          lsSuppVer.Caption := '[fully supported]';
          lsSuppVer.Font.Color := clGreen;
        end;
      end;
    end;
  end;
end;

procedure TMainForm.bLicenseClick(Sender: TObject);
begin
  LicenseForm.mText.Text := ExtractResText('LICENSE');
  if LicenseForm.ShowModal <> mrOk then
    Halt(0);
end;

procedure TMainForm.cbAllowTSConnectionsClick(Sender: TObject);
begin
  if Ready then
    bApply.Enabled := True;
end;

procedure TMainForm.seRDPPortChange(Sender: TObject);
begin
  if Ready then
    bApply.Enabled := True;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  SI: TSystemInfo;
begin
  GetNativeSystemInfo(SI);
  case SI.wProcessorArchitecture of
    0: Arch := 32;
    6: Arch := 64; // Itanium-based x64
    9: Arch := 64; // Intel/AMD x64
    else Arch := 0;
  end;
  if Arch = 64 then
    DisableWowRedirection;
  ReadSettings;
  Ready := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Arch = 64 then
    RevertWowRedirection;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if bApply.Enabled then
    CanClose := MessageBox(Handle, 'Settings are not saved. Do you want to exit?',
    'Warning', mb_IconWarning or mb_YesNo) = mrYes;
end;

procedure TMainForm.bOKClick(Sender: TObject);
begin
  if bApply.Enabled then begin
    WriteSettings;
    bApply.Enabled := False;
  end;
  Close;
end;

procedure TMainForm.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.bApplyClick(Sender: TObject);
begin
  WriteSettings;
  bApply.Enabled := False;
end;

end.
