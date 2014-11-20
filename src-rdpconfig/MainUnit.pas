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

unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, ExtCtrls, Registry;

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
    bLicense: TButton;
    procedure FormCreate(Sender: TObject);
    procedure cbAllowTSConnectionsClick(Sender: TObject);
    procedure seRDPPortChange(Sender: TObject);
    procedure bApplyClick(Sender: TObject);
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure bLicenseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ReadSettings;
    procedure WriteSettings;
  end;

var
  MainForm: TMainForm;
  Ready: Boolean = False;

implementation

{$R *.dfm}
{$R resource.res}

uses
  LicenseUnit;

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
  Reg.Free;
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
begin
  ReadSettings;
  Ready := True;
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
