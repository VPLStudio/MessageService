program MessageServiceDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainFrm in 'MainFrm.pas' {MainForm},
  VPL.Messaging in 'VPL.Messaging.pas',
  VPL.IPC in 'VPL.IPC.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
