program CustomPlugin;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  AQPCustomPlugin in 'AQPCustomPlugin.pas',
  AnyiQuack in '..\..\AnyiQuack.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
