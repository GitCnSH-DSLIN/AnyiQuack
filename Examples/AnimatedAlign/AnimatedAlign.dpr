program AnimatedAlign;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  AQPControlAnimations in '..\..\AQPControlAnimations.pas',
  AnyiQuack in '..\..\AnyiQuack.pas',
  VCLFlickerReduce in '..\..\ThirdPartyLibs\VCLFlickerReduce.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
