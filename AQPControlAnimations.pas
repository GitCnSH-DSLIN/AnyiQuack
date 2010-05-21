{**
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 * The Original Code is AQP.Control.Animations.pas.
 *
 * The Initial Developer of the Original Code is Waldemar Derr.
 * Portions created by Waldemar Derr are Copyright (C) 2010 Waldemar Derr.
 * All Rights Reserved.
 *
 * @author Waldemar Derr <mail@wladid.de>
 * @see Project-Home (german) http://id.kihiwi.de/WladiD/His/Habe_ich/KiHiWi.187/
 * @version $Id$
 *}

unit AQPControlAnimations;

interface

uses
	Controls, Windows, Math, Graphics, AccessQuery;

type
	TAQPControlAnimations = class(TAQPlugin)
	protected
		procedure CustomColorAnimation(FromColor, ToColor:TColor; Duration:Integer; ID:Integer;
			ColorAssignFunction:TEachMiscFunction<TColor>; EaseFunction:TEaseFunction = nil;
			OnComplete:TAnonymNotifyEvent = nil);
	public
		function BoundsAnimation(NewLeft, NewTop, NewWidth, NewHeight:Integer; Duration:Integer;
			ID:Integer = 0; EaseFunction:TEaseFunction = nil;
			OnComplete:TAnonymNotifyEvent = nil):TAQ;
		function ShakeAnimation(XTimes, XDiff, YTimes, YDiff, Duration:Integer; ID:Integer = 0;
			OnComplete:TAnonymNotifyEvent = nil):TAQ;
		function BackgroundColorAnimation(ToColor:TColor; Duration:Integer; ID:Integer = 0;
			EaseFunction:TEaseFunction = nil; OnComplete:TAnonymNotifyEvent = nil):TAQ;
		function FontColorAnimation(ToColor:TColor; Duration:Integer; ID:Integer = 0;
			EaseFunction:TEaseFunction = nil; OnComplete:TAnonymNotifyEvent = nil):TAQ;
	end;

implementation

type
	TControlRobin = class helper for TControl
	protected
		function GetBackgroundColor:TColor;
		procedure SetBackgroundColor(NewColor:TColor);
		function GetFontColor:TColor;
		procedure SetFontColor(NewColor:TColor);
	public
		property BackgroundColor:TColor read GetBackgroundColor write SetBackgroundColor;
		property FontColor:TColor read GetFontColor write SetFontColor;
	end;

{** TAQPControlAnimations **}

function TAQPControlAnimations.BackgroundColorAnimation(ToColor:TColor; Duration, ID:Integer;
	EaseFunction:TEaseFunction; OnComplete:TAnonymNotifyEvent):TAQ;
begin
	Result:=Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=TRUE; // Komplett durchlaufen
			if O is TControl then
				Take(O)
					.Plugin<TAQPControlAnimations>
					.CustomColorAnimation(TControl(O).BackgroundColor, ToColor, Duration, ID,
						function(AQ:TAQ; O:TObject; Color:TColor):Boolean
						begin
							TControl(O).BackgroundColor:=Color;
							Result:=TRUE;
						end,
						EaseFunction, OnComplete);
		end);
end;

function TAQPControlAnimations.BoundsAnimation(NewLeft, NewTop, NewWidth, NewHeight, Duration, ID:Integer;
	EaseFunction:TEaseFunction; OnComplete:TAnonymNotifyEvent):TAQ;
var
	WholeEach:TEachFunction;
begin
	WholeEach:=function(AQ:TAQ; O:TObject):Boolean
	var
		EachF:TEachFunction;
		PrevLeft, PrevTop, PrevWidth, PrevHeight:Integer;
	begin
		Result:=TRUE;
		if not (O is TControl) then
			Exit;

		with TControl(O) do
		begin
			PrevLeft:=Left;
			PrevTop:=Top;
			PrevWidth:=Width;
			PrevHeight:=Height;
		end;

		EachF:=function(AQ:TAQ; O:TObject):Boolean
		var
			Progress:Real;
			AniLeft, AniTop, AniWidth, AniHeight:Integer;
		begin
			Result:=TRUE;
			Progress:=AQ.CurrentInterval.Progress;

			AniLeft:=Ceil(TAQ.Ease(EaseFunction)(PrevLeft, NewLeft, Progress));
			AniTop:=Ceil(TAQ.Ease(EaseFunction)(PrevTop, NewTop, Progress));
			if NewWidth >= 0 then
				AniWidth:=Ceil(TAQ.Ease(EaseFunction)(PrevWidth, NewWidth, Progress))
			else
				AniWidth:=TControl(O).Width;
			if NewHeight >= 0 then
				AniHeight:=Ceil(TAQ.Ease(EaseFunction)(PrevHeight, NewHeight, Progress))
			else
				AniHeight:=TControl(O).Height;

			TControl(O).SetBounds(AniLeft, AniTop, AniWidth, AniHeight);

			if Progress = 1 then
			begin
				{$IFDEF OutputDebugAnimation}
				OutputDebugString(PWideChar('BoundsAnimation beendet f�r $' +
					IntToHex(Integer(O), SizeOf(Integer) * 2)));
				{$ENDIF}

				if Assigned(OnComplete) then
					OnComplete(O);
			end;
		end;

		Take(O).EachAnimation(Duration, EachF, nil, ID);
	end;

	Result:=Each(WholeEach);
end;

procedure TAQPControlAnimations.CustomColorAnimation(FromColor, ToColor:TColor; Duration, ID:Integer;
	ColorAssignFunction:TEachMiscFunction<TColor>; EaseFunction:TEaseFunction;
	OnComplete:TAnonymNotifyEvent);
var
	FromR, FromG, FromB,
	ToR, ToG, ToB:Byte;

	function R(Color:TColor):Byte;
	begin
		Result:=Color and $FF;
	end;

	function G(Color:TColor):Byte;
	begin
		Result:=(Color and $FF00) shr 8;
	end;

	function B(Color:TColor):Byte;
	begin
		Result:=(Color and $FF0000) shr 16;
	end;
begin
	if FromColor = ToColor then
		Exit;
	FromColor:=ColorToRGB(FromColor);
	FromR:=R(FromColor);
	FromG:=G(FromColor);
	FromB:=B(FromColor);
	ToColor:=ColorToRGB(ToColor);
	ToR:=R(ToColor);
	ToG:=G(ToColor);
	ToB:=B(ToColor);

	EaseFunction:=(TAQ.Ease(EaseFunction));
	WorkAQ.EachAnimation(Duration,
		function(AQ:TAQ; O:TObject):Boolean
		var
			NewR:Byte;
			NewG:Byte;
			NewB:Byte;
			NewColor:TColor;
			Progress:Real;
		begin
			Progress:=AQ.CurrentInterval.Progress;

			NewR:=Round(EaseFunction(FromR, ToR, Progress));
			NewG:=Round(EaseFunction(FromG, ToG, Progress));
			NewB:=Round(EaseFunction(FromB, ToB, Progress));
			NewColor:=RGB(NewR, NewG, NewB);
			Result:=ColorAssignFunction(AQ, O, NewColor);

			if (Progress = 1) and Assigned(OnComplete) then
				OnComplete(O);
		end,
		nil, ID);
end;

function TAQPControlAnimations.FontColorAnimation(ToColor:TColor; Duration, ID:Integer;
	EaseFunction:TEaseFunction; OnComplete:TAnonymNotifyEvent):TAQ;
begin
	Result:=Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=TRUE; // Komplett durchlaufen
			if O is TControl then
				Take(O)
					.Plugin<TAQPControlAnimations>
					.CustomColorAnimation(TControl(O).FontColor, ToColor, Duration, ID,
						function(AQ:TAQ; O:TObject; Color:TColor):Boolean
						begin
							TControl(O).FontColor:=Color;
							Result:=TRUE;
						end,
						EaseFunction, OnComplete);
		end);
end;

function TAQPControlAnimations.ShakeAnimation(XTimes, XDiff, YTimes, YDiff, Duration, ID:Integer;
	OnComplete:TAnonymNotifyEvent):TAQ;
var
	WholeEach:TEachFunction;
begin
	WholeEach:=function(AQ:TAQ; O:TObject):Boolean
	var
		EachF:TEachFunction;
		PrevLeft, PrevTop:Integer;
	begin
		Result:=TRUE;
		if not (O is TControl) then
			Exit;

		with TControl(O) do
		begin
			PrevLeft:=Left;
			PrevTop:=Top;
		end;

		EachF:=function(AQ:TAQ; O:TObject):Boolean
		var
			Progress:Real;
			AniLeft, AniTop:Integer;

			function Swing(Times, Diff:Integer; Progress:Real):Integer;
			begin
				Result:=Ceil(Diff * Sin(Progress * Times * Pi * 2));
			end;
		begin
			Result:=TRUE;
			Progress:=AQ.CurrentInterval.Progress;
			AniLeft:=PrevLeft;
			AniTop:=PrevTop;

			if Progress < 1 then
			begin
				if XDiff > 0 then
					AniLeft:=AniLeft + Swing(XTimes, XDiff, Progress);
				if YDiff > 0 then
					AniTop:=PrevTop + Swing(YTimes, YDiff, Progress);
			end;

			with TControl(O) do
				SetBounds(AniLeft, AniTop, Width, Height);

			if Progress = 1 then
			begin
				{$IFDEF OutputDebugAnimation}
				OutputDebugString(PWideChar('ShakeAnimation beendet f�r $' + IntToHex(Integer(O),
					SizeOf(Integer) * 2)));
				{$ENDIF}

				if Assigned(OnComplete) then
					OnComplete(O);
			end;
		end;

		Take(O).EachAnimation(Duration, EachF, nil, ID);
	end;

	Result:=Each(WholeEach);
end;

{** TControlRobin **}

function TControlRobin.GetBackgroundColor:TColor;
begin
	Result:=Color;
end;

function TControlRobin.GetFontColor: TColor;
begin
	Result:=Font.Color;
end;

procedure TControlRobin.SetBackgroundColor(NewColor:TColor);
begin
	Color:=NewColor;
end;

procedure TControlRobin.SetFontColor(NewColor:TColor);
begin
	Font.Color:=NewColor;
end;

end.
