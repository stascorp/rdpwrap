program RDPConf;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Remote Desktop Protocol Configuration';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
