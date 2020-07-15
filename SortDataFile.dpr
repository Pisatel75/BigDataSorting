program SortDataFile;

uses
  Vcl.Forms,
  SortUnit in 'SortUnit.pas' {Form1},
  GlobalVar in 'GlobalVar.pas',
  TThreadUnit in 'TThreadUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
