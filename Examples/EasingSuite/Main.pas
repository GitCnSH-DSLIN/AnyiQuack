unit Main;

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
	Dialogs, ExtCtrls, StdCtrls, Math,
	GR32, GR32_Image, GR32_Layers,
	AccessQuery, ComCtrls;

type
	TTrackerLayer = class;

	TMainForm = class(TForm)
		Panel1:TPanel;
		Label1:TLabel;
		EaseGraphImage:TImage32;
    EaseModifierRadioGroup: TRadioGroup;
		EaseTypeListBox:TListBox;
		AnimateOnChangeCheckBox:TCheckBox;
		AnimateButton:TButton;
		Panel2:TPanel;
		Label2:TLabel;
    PageControl1: TPageControl;
    GraphTabSheet: TTabSheet;
		procedure FormCreate(Sender:TObject);
		procedure GraphRecreate(Sender:TObject);
		procedure AnimateButtonClick(Sender:TObject);
		procedure EaseGraphImageMouseMove(Sender:TObject; Shift:TShiftState; X, Y:Integer;
			Layer:TCustomLayer);
	private
		FBackgroundLayer:TBitmapLayer;
		FGraphLayer:TBitmapLayer;
		FTrackerLayer:TTrackerLayer;

		function GetEaseFunction:TEaseFunction;

		procedure BuildBackground;
		procedure BuildGraph;
		procedure UpdateWholeGraph;
	end;

	TTrackerLayer = class(TPositionedLayer)
	protected
		FEaseFunction:TEaseFunction;
		FLength:Integer;
		FProgress:Real;

		procedure Paint(Buffer: TBitmap32); override;
		procedure SetProgress(NewValue:Real);
	public
		constructor Create(ALayerCollection:TLayerCollection); override;

		property Progress:Real read FProgress write SetProgress;
	end;
var
	MainForm:TMainForm;

implementation

{$R *.dfm}

const
	HorizGuideSpace = 30;
	VertGuideSpace = 17;
	HorizGridOffset = 50;
	VertGridOffset = 100;

{** TMainForm **}

procedure TMainForm.AnimateButtonClick(Sender: TObject);
begin
	AnimateButton.Enabled:=FALSE;
	Take(FTrackerLayer)
		.CancelAnimations
		.EachAnimation(3333,
			function(AQ:TAQ; O:TObject):Boolean
			begin
				with TTrackerLayer(O) do
					Progress:=AQ.CurrentInterval.Progress;
				if AQ.CurrentInterval.Progress = 1 then
					AnimateButton.Enabled:=TRUE;
				Result:=TRUE;
			end);
end;

procedure TMainForm.EaseGraphImageMouseMove(Sender:TObject; Shift:TShiftState; X, Y:Integer;
	Layer:TCustomLayer);
begin
	if (Layer = FTrackerLayer) and AnimateButton.Enabled then
		with FTrackerLayer do
			Progress:=((X - HorizGridOffset) + 1) / (Location.Right - Location.Left);
end;

procedure TMainForm.BuildBackground;
var
	cc, X, Y:Integer;
begin
	with FBackgroundLayer do
	begin
		Bitmap.Clear(clGray32);

		Y:=VertGridOffset;
		for cc:=1 to (Bitmap.Width - (HorizGridOffset * 2)) div HorizGuideSpace do
		begin
			X:=HorizGridOffset + (HorizGuideSpace * cc);
			Bitmap.LineTS(X, Y, X, Bitmap.Height - VertGridOffset, $11FFFFFF);
		end;

		X:=HorizGridOffset;
		for cc:=1 to (Bitmap.Height - (VertGridOffset * 2)) div VertGuideSpace do
		begin
			Y:=VertGridOffset + (VertGuideSpace * cc);
			Bitmap.LineTS(X, Y, Bitmap.Width - HorizGridOffset, Y, $22FFFFFF);
		end;

		Bitmap.FrameRectS(HorizGridOffset, VertGridOffset, Bitmap.Width - HorizGridOffset,
			Bitmap.Height - VertGridOffset, clWhite32);
	end;
end;

procedure TMainForm.BuildGraph;
var
	EaseF:TEaseFunction;
	cc, ProgressSteps:Integer;
	Value:Real;
begin
	EaseF:=(GetEaseFunction);

	with FGraphLayer do
	begin
		Bitmap.Clear(0);
		ProgressSteps:=Max(1, Bitmap.Width);

		Bitmap.MoveToF(0, Bitmap.Height);
		Bitmap.PenColor:=clBlack32;

		for cc:=0 to ProgressSteps do
		begin
			Value:=TAQ.EaseReal(0, Bitmap.Height, cc / ProgressSteps, EaseF);
			Bitmap.LineToFS(cc, Bitmap.Height - Value);
		end;
	end;
end;

procedure TMainForm.FormCreate(Sender:TObject);
begin
	EaseTypeListBox.Selected[1]:=TRUE;

	FBackgroundLayer:=TBitmapLayer.Create(EaseGraphImage.Layers);
	FBackgroundLayer.Bitmap.DrawMode:=dmBlend;

	FGraphLayer:=TBitmapLayer.Create(EaseGraphImage.Layers);
	FGraphLayer.Bitmap.DrawMode:=dmBlend;

	FTrackerLayer:=TTrackerLayer.Create(EaseGraphImage.Layers);

	UpdateWholeGraph;
end;

function TMainForm.GetEaseFunction:TEaseFunction;
begin
	Result:=TAQ.Ease(TEaseType(Ord(EaseTypeListBox.ItemIndex)),
		TEaseModifier(Ord(EaseModifierRadioGroup.ItemIndex)))
end;

procedure TMainForm.GraphRecreate(Sender:TObject);
begin
	UpdateWholeGraph;
end;

procedure TMainForm.UpdateWholeGraph;
begin
	EaseGraphImage.BeginUpdate;

	with FBackgroundLayer do
	begin
		Bitmap.SetSize(EaseGraphImage.Width, EaseGraphImage.Height);
		Location:=FloatRect(0, 0, Bitmap.Width, Bitmap.Height);
	end;
	BuildBackground;

	with FGraphLayer do
	begin
		Location:=FloatRect(HorizGridOffset, VertGridOffset,
			EaseGraphImage.Width - HorizGridOffset, EaseGraphImage.Height - VertGridOffset);
		Bitmap.SetSize(Trunc(Location.Right - Location.Left), Trunc(Location.Bottom - Location.Top));
	end;
	BuildGraph;

	with FTrackerLayer do
	begin
		FEaseFunction:=(GetEaseFunction);
		Location:=FloatRect(HorizGridOffset, VertGridOffset,
			EaseGraphImage.Width - HorizGridOffset, EaseGraphImage.Height - VertGridOffset);
	end;

	EaseGraphImage.EndUpdate;
	EaseGraphImage.Invalidate;

	if AnimateOnChangeCheckBox.Checked then
		AnimateButton.Click;
end;

{** TTrackerLayer **}

constructor TTrackerLayer.Create(ALayerCollection: TLayerCollection);
begin
	inherited Create(ALayerCollection);
	FLength:=5000;
end;

procedure TTrackerLayer.Paint(Buffer:TBitmap32);
const
	CrossSize = 5;
var
	StartProgress, ProgressStep, X, Y, AvailWidth:Real;
	EasedProgress:Real;
	DispWidth, DispHeight:Integer;
	ValueColor:TColor32;
	Caption:String;
begin
	with TCustomImage32(LayerCollection.Owner) do
	begin
		DispWidth:=Width;
		DispHeight:=Height;
	end;

	AvailWidth:=Location.Right - Location.Left;
	ProgressStep:=1 / AvailWidth;
	StartProgress:=Max(0, Progress - (ProgressStep * FLength));
	X:=Location.Left + (AvailWidth * Progress);
	Y:=TAQ.EaseReal(Location.Bottom, Location.Top, Progress, FEaseFunction);
	EasedProgress:=0;
	ValueColor:=clBlack32;
	{**
	 * Graph-Linie
	 *}
	Buffer.MoveToF(Location.Left + (AvailWidth * StartProgress),
		TAQ.EaseReal(Location.Bottom, Location.Top, StartProgress, FEaseFunction));
	while StartProgress < Progress do
	begin
		StartProgress:=StartProgress + ProgressStep;
		if StartProgress > 1 then
			StartProgress:=1
		else if StartProgress < 0 then
			StartProgress:=0;
		EasedProgress:=FEaseFunction(StartProgress);
		if (EasedProgress = 1) or (EasedProgress = 0) then
			ValueColor:=clTrBlue32
		else if (EasedProgress > 0) and (EasedProgress < 1) then
			ValueColor:=clTrGreen32
		else
			ValueColor:=clTrRed32;
		Buffer.PenColor:=ValueColor;
		Buffer.LineToFS(Location.Left + (AvailWidth * StartProgress),
			TAQ.EaseReal(Location.Bottom, Location.Top, EasedProgress, nil));
	end;
	{**
	 * Horizontale und vertikale Trackerlinien
	 *}
	Buffer.LineFS(0, Y, DispWidth, Y, ValueColor);
	Buffer.LineFS(X, 0, X, DispHeight, ValueColor);
	Caption:=Format('%.4f', [Progress]);
	Buffer.Textout(Trunc(X + 5), DispHeight - (Buffer.TextHeight(Caption) + 2), Caption);
	Caption:=Format('%.4f', [EasedProgress]);
	Buffer.Textout(2, Trunc(Y + 5), Caption);
	{**
	 * Kreuz
	 *}
	Buffer.LineFS(X - CrossSize, Y - CrossSize, X + CrossSize, Y + CrossSize, ValueColor);
	Buffer.LineFS(X + CrossSize, Y - CrossSize, X - CrossSize, Y + CrossSize, ValueColor);
	{**
	 * Begrenzungen des Wertebalkens
	 *}
	Buffer.LineTS(DispWidth - HorizGridOffset, VertGridOffset, DispWidth, VertGridOffset, clWhite32);
	Buffer.LineTS(DispWidth - HorizGridOffset, DispHeight - 1 - VertGridOffset, DispWidth, DispHeight - 1 - VertGridOffset, clWhite32);
	{**
	 * Wertebalken
	 *}
	if Y < (DispHeight - VertGridOffset) then
		Buffer.FillRectTS(DispWidth - HorizGridOffset, Trunc(Y), DispWidth, DispHeight - VertGridOffset, ValueColor)
	else
		Buffer.FillRectTS(DispWidth - HorizGridOffset, DispHeight - VertGridOffset, DispWidth, Trunc(Y), ValueColor);
end;

procedure TTrackerLayer.SetProgress(NewValue:Real);
begin
	FProgress:=NewValue;
	Changed;
end;

end.
