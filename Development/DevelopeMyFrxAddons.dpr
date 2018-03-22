program DevelopeMyFrxAddons;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  MyFrxPDFPage in '..\MyFrxPDFPage.pas',
  MyPDFRender in '..\MyPDFRender.pas',
  MyChromePDFRender in '..\MyChromePDFRender.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
