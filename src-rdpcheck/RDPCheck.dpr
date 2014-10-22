program RDPCheck;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {Frm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Local RDP Checker';
  Application.CreateForm(TFrm, Frm);
  Application.Run;
end.
