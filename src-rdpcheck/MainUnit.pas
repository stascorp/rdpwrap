{
  Copyright 2015 Stas'M Corp.

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
  Dialogs, OleServer, MSTSCLib_TLB, OleCtrls, Registry;

type
  TFrm = class(TForm)
    RDP: TMsRdpClient2;
    procedure RDPDisconnected(ASender: TObject; discReason: Integer);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Frm: TFrm;
  SecurityLayer, UserAuthentication: DWORD;

implementation

{$R *.dfm}

procedure TFrm.FormCreate(Sender: TObject);
var
  Reg: TRegistry;
begin
  RDP.DisconnectedText := 'Disconnected.';
  RDP.ConnectingText := 'Connecting...';
  RDP.ConnectedStatusText := 'Connected.';
  RDP.UserName := '';
  RDP.Server := '127.0.0.2';
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;

  if Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp', True) then
  begin
    try
      SecurityLayer := Reg.ReadInteger('SecurityLayer');
      UserAuthentication := Reg.ReadInteger('UserAuthentication');
      Reg.WriteInteger('SecurityLayer', 0);
      Reg.WriteInteger('UserAuthentication', 0);
    except

    end;
    Reg.CloseKey;
  end;

  if Reg.OpenKeyReadOnly('\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp') then begin
    try
      RDP.AdvancedSettings2.RDPPort := Reg.ReadInteger('PortNumber');
    except

    end;
    Reg.CloseKey;
  end;
  Reg.Free;
  Sleep(1000);
  RDP.Connect;
end;

procedure TFrm.RDPDisconnected(ASender: TObject; discReason: Integer);
var
  ErrStr: String;
  Reg: TRegistry;
begin
  case discReason of
    1: ErrStr := 'Local disconnection.';
    2: ErrStr := 'Disconnected by user.';
    3: ErrStr := 'Disconnected by server.';
    $904: ErrStr := 'Socket closed.';
    $C08: ErrStr := 'Decompress error.';
    $108: ErrStr := 'Connection timed out.';
    $C06: ErrStr := 'Decryption error.';
    $104: ErrStr := 'DNS name lookup failure.';
    $508: ErrStr := 'DNS lookup failed.';
    $B06: ErrStr := 'Encryption error.';
    $604: ErrStr := 'Windows Sockets gethostbyname() call failed.';
    $208: ErrStr := 'Host not found error.';
    $408: ErrStr := 'Internal error.';
    $906: ErrStr := 'Internal security error.';
    $A06: ErrStr := 'Internal security error.';
    $506: ErrStr := 'The encryption method specified is not valid.';
    $804: ErrStr := 'Bad IP address specified.';
    $606: ErrStr := 'Server security data is not valid.';
    $406: ErrStr := 'Security data is not valid.';
    $308: ErrStr := 'The IP address specified is not valid.';
    $808: ErrStr := 'License negotiation failed.';
    $908: ErrStr := 'Licensing time-out.';
    $106: ErrStr := 'Out of memory.';
    $206: ErrStr := 'Out of memory.';
    $306: ErrStr := 'Out of memory.';
    $706: ErrStr := 'Failed to unpack server certificate.';
    $204: ErrStr := 'Socket connection failed.';
    $404: ErrStr := 'Windows Sockets recv() call failed.';
    $704: ErrStr := 'Time-out occurred.';
    $608: ErrStr := 'Internal timer error.';
    $304: ErrStr := 'Windows Sockets send() call failed.';
    $B07: ErrStr := 'The account is disabled.';
    $E07: ErrStr := 'The account is expired.';
    $D07: ErrStr := 'The account is locked out.';
    $C07: ErrStr := 'The account is restricted.';
    $1B07: ErrStr := 'The received certificate is expired.';
    $1607: ErrStr := 'The policy does not support delegation of credentials to the target server.';
    $2107: ErrStr := 'The server authentication policy does not allow connection requests using saved credentials. The user must enter new credentials.';
    $807: ErrStr := 'Login failed.';
    $1807: ErrStr := 'No authority could be contacted for authentication. The domain name of the authenticating party could be wrong, the domain could be unreachable, or there might have been a trust relationship failure.';
    $A07: ErrStr := 'The specified user has no account.';
    $F07: ErrStr := 'The password is expired.';
    $1207: ErrStr := 'The user password must be changed before logging on for the first time.';
    $1707: ErrStr := 'Delegation of credentials to the target server is not allowed unless mutual authentication has been achieved.';
    $2207: ErrStr := 'The smart card is blocked.';
    $1C07: ErrStr := 'An incorrect PIN was presented to the smart card.';
    $B09: ErrStr := 'Network Level Authentication is required, run RDPCheck as administrator.';
    $708: ErrStr := 'RDP is working, but the client doesn''t allow loopback connections. Try to connect to your PC from another device in the network.';
    else ErrStr := 'Unknown code 0x'+IntToHex(discReason, 1);
  end;
  if (discReason > 2) then
    MessageBox(Handle, PWideChar(ErrStr), 'Disconnected', mb_Ok or mb_IconError);

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;

  if Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp', True) then
  begin
    try
      Reg.WriteInteger('SecurityLayer', SecurityLayer);
      Reg.WriteInteger('UserAuthentication', UserAuthentication);
    except

    end;
    Reg.CloseKey;
  end;

  Reg.Free;

  Halt(0);
end;

end.
