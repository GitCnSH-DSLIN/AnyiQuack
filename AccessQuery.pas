﻿{**
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
 * The Original Code is AccessQuery.pas.
 *
 * The Initial Developer of the Original Code is Waldemar Derr.
 * Portions created by Waldemar Derr are Copyright (C) 2010 Waldemar Derr.
 * All Rights Reserved.
 *
 * @author Waldemar Derr <mail@wladid.de>
 * @see Project-Home (german) http://id.kihiwi.de/WladiD/His/Habe_ich/KiHiWi.187/
 * @version $Id$
 *}

unit AccessQuery;

interface

uses
	SysUtils, Classes, Controls, ExtCtrls, Contnrs, Windows, Math, Graphics;

{$IFDEF DEBUG}
	{$INCLUDE Debug.inc}
{$ENDIF}
{**
 * Sicherstellen, dass die boolesche Kurzauswertung verwendet wird
 *}
{$BOOLEVAL OFF}

type
	EAQ = class(Exception);
	TAQBase = class;
	TAQ = class;
	TAQPlugin = class;
	TInterval = class;

	TEaseType = (etLinear, etQuadratic, etMassiveQuadratic, etSinus, etElastic,
		etLowWave, etMiddleWave, etHighWave);
	TEaseModifier = (emIn, emOut, emInOut, emInInverted, emOutInverted, emOutIn,
		emInOutMirrored, emOutInMirrored, emInFlip, emOutFlip);
	TActorRole = (arTimer, arInterval, arDelay, arAnimation);

	TObjectArray = array of TObject;

	TEachFunction = reference to function(AQ:TAQ; O:TObject):Boolean;
	TEachMiscFunction<T> = reference to function(AQ:TAQ; O:TObject; Misc:T):Boolean;
	TAnonymNotifyEvent = reference to procedure(Sender:TObject);
	TEaseFunction = reference to function(Progress:Real):Real;


	TAQBase = class(TObjectList)
	protected
		function Each(EachFunction:TEachFunction):TAQ; virtual; abstract;
	public
		constructor Create; reintroduce; virtual;
	end;

	TAQPlugin = class(TAQBase)
	protected
		FWorkAQ:TAQ;

		function GarbageCollector:TAQ;
		function Each(EachFunction:TEachFunction):TAQ; override;

		procedure Autorun; virtual;

		procedure SetImmortally(Value:Boolean);
		function GetImmortally:Boolean;

		property Immortally:Boolean read GetImmortally write SetImmortally;
	public
		property WorkAQ:TAQ read FWorkAQ;
	end;

	TAQ = class sealed (TAQBase)
	private
		class var
		FGarbageCollector:TAQ;
		FIntervalTimer:TTimer;
		FActiveIntervalAQs:TAQ;
		FTick:Cardinal;
		FComponentsNotifier:TComponentList;
	protected
		var
		FLifeTick:Cardinal;
		FIntervals:TObjectList;
		FCurrentInterval:TInterval;
		FChainedTo:TAQ;
		FConditionCount:Byte;
		FBools:Byte;

		class procedure Initialize;
		class procedure Finalize;

		class function GarbageCollector:TAQ;
		class procedure GlobalIntervalTimerEvent(Sender:TObject);
		class procedure ComponentsNotification(AComponent:TComponent; Operation:TOperation);

		procedure Notify(Ptr:Pointer; Action:TListNotification); override;

		function HasActors(ActorRole:TActorRole; ID:Integer = 0):Boolean;

		procedure LocalIntervalTimerEvent(Sender:TObject);

		function GetIntervals:TObjectList;
		procedure ClearIntervals;
		procedure AddInterval(Interval:TInterval);
		procedure ProcessInterval(Interval:TInterval);
		procedure RemoveInterval(Interval:TInterval);

		function CustomFiller(Filler:TEachFunction; Append, Recurse:Boolean):TAQ;
		procedure CustomCancel(ActorRole:TActorRole; ID:Integer; Finish:Boolean);
		function CustomActors(ActorRole:TActorRole; ID:Integer; IncludeOrphans:Boolean):TAQ;

		function IfContainsEach(ByClass:TClass):TEachFunction; overload;
		function IfContainsEach(Objects:TObjectArray):TEachFunction; overload;
		function IfContainsEach(Objects:TObjectList):TEachFunction; overload;
		function IfContainsEach(AQ:TAQ):TEachFunction; overload;

		function ChildrenFiller(AQ:TAQ; O:TObject):Boolean;
		function ParentsFiller(AQ:TAQ; O:TObject):Boolean;

		function IsAlive:Boolean;
		procedure HeartBeat;

		function SupervisorLock(out AQ:TAQ; MethodName:String):Boolean;

		procedure SetRecurse(Value:Boolean);
		function GetRecurse:Boolean;
		procedure SetConditionLock(Value:Boolean);
		function GetConditionLock:Boolean;
		procedure SetImmortally(Value:Boolean);
		function GetImmortally:Boolean;

		class property Tick:Cardinal read FTick;
		property Recurse:Boolean read GetRecurse write SetRecurse;
		property ConditionLock:Boolean read GetConditionLock write SetConditionLock;
		property Immortally:Boolean read GetImmortally write SetImmortally;
	public
		constructor Create; override;
		destructor Destroy; override;

		class function Managed:TAQ;
		class function Unmanaged:TAQ;

		class function Take(AObject:TObject):TAQ; overload;
		class function Take(Objects:TObjectArray):TAQ; overload;
		class function Take(Objects:TObjectList):TAQ; overload;

		class function Ease(EaseType:TEaseType;
			EaseModifier:TEaseModifier = emIn):TEaseFunction; overload;
		class function Ease(EaseFunction:TEaseFunction = nil;
			EaseModifier:TEaseModifier = emIn):TEaseFunction; overload;

		class function EaseReal(StartValue, EndValue, Progress:Real; EaseType:TEaseType;
			EaseModifier:TEaseModifier = emIn):Real; overload;
		class function EaseReal(StartValue, EndValue, Progress:Real;
			EaseFunction:TEaseFunction):Real; overload;

		class function EaseInteger(StartValue, EndValue:Integer; Progress:Real; EaseType:TEaseType;
			EaseModifier:TEaseModifier = emIn):Integer; overload;
		class function EaseInteger(StartValue, EndValue:Integer; Progress:Real;
			EaseFunction:TEaseFunction):Integer; overload;

		class function EaseColor(StartColor, EndColor:TColor; Progress:Real; EaseType:TEaseType;
			EaseModifier:TEaseModifier = emIn):TColor; overload;
		class function EaseColor(StartColor, EndColor:TColor; Progress:Real;
			EaseFunction:TEaseFunction):TColor; overload;

		class function EasePoint(StartPoint, EndPoint:TPoint; Progress:Real; EaseType:TEaseType;
			EaseModifier:TEaseModifier = emIn):TPoint; overload;
		class function EasePoint(StartPoint, EndPoint:TPoint; Progress:Real;
			EaseFunction:TEaseFunction):TPoint; overload;

		class function EaseRect(StartRect, EndRect:TRect; Progress:Real; EaseType:TEaseType;
			EaseModifier:TEaseModifier = emIn):TRect; overload;
		class function EaseRect(StartRect, EndRect:TRect; Progress:Real;
			EaseFunction:TEaseFunction):TRect; overload;

		function Each(EachFunction:TEachFunction):TAQ; override;
		function EachInterval(Interval:Integer; Each:TEachFunction; ID:Integer = 0):TAQ;
		function EachTimer(Duration:Integer; Each:TEachFunction; LastEach:TEachFunction = nil;
			ID:Integer = 0):TAQ;
		function EachAnimation(Duration:Integer; Each:TEachFunction; LastEach:TEachFunction = nil;
			ID:Integer = 0):TAQ;
		function EachDelay(Delay:Integer; Each:TEachFunction; ID:Integer = 0):TAQ;
		function EachRepeat(Times:Integer; EachFunction:TEachFunction):TAQ;
		{**
		 * !Ist erstmal nur ein Entwurf!
		 *
		 * Verarbeitet die Objekte in mehreren Threads
		 *
		 * Der Einsatz dieser Methode soll gut überlegt und vorallem gründlich getestet werden. Sie
		 * lohnt sich nur bei rechenintensiven Verarbeitungsschritten.
		 * Die Each-Methoden sollten nicht die an sie übergebene TAQ-Instanz manipulieren
		 * (Add, Remove etc.): Dies würde zu zufälligen Zugriffsverletzungen führen.
		 *
		 * @param MainEach Wird im Kontext des Threads für jedes Objekt ausgeführt
		 * @param ConcurrentThreads Optional. Standard ist 1. Anzahl von gleichzeitigen Threads.
		 *        Die Werte 0 und 1 haben eine spezielle Bedeutung:
		 *        = 0 Für jedes Objekt wird sofort ein Thread erstellt
		 *        = 1 Es werden maximal soviele Threads erstellt, wieviele die CPU ausführen kann,
		 *            jedoch mindestens 2 (bei einem i7-920 wären es z.B. 8)
		 *        > 1 Es werden maximal soviele Threads erstellt
		 * @param Synchronize Sagt aus, ob die Methode die Beendigung aller Threads abwarten soll.
		 *        - Bei TRUE läuft die Verarbeitung der Objekte zwar über mehrere Threads ab,
		 *          jedoch wird der Haupt-Thread (Anwendung) blockiert, bis die Verarbeitung
		 *          abgeschlossen wurde. Dies ermöglicht den Einsatz von nahezu allen Objekten, auch
		 *          wenn Teile davon nicht Thread-Safe sind.
		 *        - Bei FALSE wird die Anwendung nicht blockiert und die Threads werden parallel
		 *          gestartet. Setzt Kenntniss über die Funktionsweise der zu verarbeiteten Objekte
		 *          voraus.
		 * @param TerminateEach Optional. Standard ist nil. Wird im Kontext des Haupt-Threads
		 *        ausgeführt, wenn ein Thread die Verarbeitung beendet hat.
		 * @param FinalizeEach Optional. Standard ist nil. Wird ebenfalls im Kontext des
		 *        Haupt-Threads für jedes gehaltene Objekt ausgeführt, wenn die Verarbeitung aller
		 *        Objekte beendet ist, also wenn alle Threads fertig sind.
		 *}
//		function EachThread(MainEach:TEachFunction; ConcurrentThreads:Byte = 1;
//			Synchronize:Boolean = FALSE;
//			TerminateEach:TEachFunction = nil; FinalizeEach:TEachFunction = nil):TAQ;

		function NewChain:TAQ;
		function EndChain:TAQ;

		function Die:TAQ;

		function Append(AObject:TObject):TAQ; overload;
		function Append(Objects:TObjectArray):TAQ; overload;
		function Append(Objects:TObjectList):TAQ; overload;
		function AppendAQ(AQ:TAQ):TAQ;

		function ChildrenAppend(Recurse:Boolean = FALSE; ChildrenFiller:TEachFunction = nil):TAQ;
		function ChildrenChain(Recurse:Boolean = FALSE; ChildrenFiller:TEachFunction = nil):TAQ;
		function ParentsAppend(Recurse:Boolean = FALSE; ParentsFiller:TEachFunction = nil):TAQ;
		function ParentsChain(Recurse:Boolean = FALSE; ParentsFiller:TEachFunction = nil):TAQ;

		function MultiplexChain:TAQ;
		function DemultiplexChain:TAQ;

		function AnimationActorsChain(ID:Integer = 0; IncludeOrphans:Boolean = FALSE):TAQ;
		function IntervalActorsChain(ID:Integer = 0; IncludeOrphans:Boolean = FALSE):TAQ;
		function TimerActorsChain(ID:Integer = 0; IncludeOrphans:Boolean = FALSE):TAQ;
		function DelayActorsChain(ID:Integer = 0; IncludeOrphans:Boolean = FALSE):TAQ;

		function FinishAnimations(ID:Integer = 0):TAQ;
		function CancelAnimations(ID:Integer = 0):TAQ;
		function FinishTimers(ID:Integer = 0):TAQ;
		function CancelTimers(ID:Integer = 0):TAQ;
		function CancelDelays(ID:Integer = 0):TAQ;
		function CancelIntervals(ID:Integer = 0):TAQ;

		function FilterChain(ByClass:TClass):TAQ; overload;
		function FilterChain(FilterEach:TEachFunction):TAQ; overload;

		function ExcludeChain(ByClass:TClass):TAQ; overload;
		function ExcludeChain(AObject:TObject):TAQ; overload;
		function ExcludeChain(Objects:TObjectArray):TAQ; overload;
		function ExcludeChain(Objects:TObjectList):TAQ; overload;
		function ExcludeChain(AQ:TAQ):TAQ; overload;
		function ExcludeChain(ExcludeEach:TEachFunction):TAQ; overload;

		function IfThen(Condition:Boolean):TAQ;
		function IfElse:TAQ;
		function IfEnd:TAQ;

		function IfAll(EachFunction:TEachFunction):TAQ;
		function IfAny(EachFunction:TEachFunction):TAQ;

		function IfContains(AObject:TObject):TAQ;

		function IfContainsAny(ByClass:TClass):TAQ; overload;
		function IfContainsAny(Objects:TObjectArray):TAQ; overload;
		function IfContainsAny(Objects:TObjectList):TAQ; overload;
		function IfContainsAny(AQ:TAQ):TAQ; overload;

		function IfContainsAll(ByClass:TClass):TAQ; overload;
		function IfContainsAll(Objects:TObjectArray):TAQ; overload;
		function IfContainsAll(Objects:TObjectList):TAQ; overload;
		function IfContainsAll(AQ:TAQ):TAQ; overload;

		function SliceChain(StartIndex:Integer; Count:Integer = 0):TAQ;

		function DebugMessage(HeadMessage:String = ''; Caption:String = ''):TAQ;

		function Plugin<T:TAQPlugin,CONSTRUCTOR>:T;

		function Contains(AObject:TObject):Boolean;
		procedure Clean;

		property CurrentInterval:TInterval read FCurrentInterval;
	end;

	TInterval = class
	private
		FFirstTick,
		FNextTick,
		FLastTick:Cardinal;
		FInterval:Integer;
		FNextEach,
		FLastEach:TEachFunction;
		FActorRole:TActorRole;
		FID:Integer;
	protected
		procedure UpdateNextTick;
	public
		constructor Infinite(Interval:Integer; Each:TEachFunction; ActorRole:TActorRole;
			ID:Integer);
		constructor Finite(Duration:Integer; Each, LastEach:TEachFunction; ActorRole:TActorRole;
			ID:Integer);

		function Each:TEachFunction;
		function IsCanceled:Boolean;
		function IsFinished:Boolean;
		function IsFinite:Boolean;
		function Progress:Real;

		procedure Finish;
		procedure Cancel;

		property ActorRole:TActorRole read FActorRole;
		property ID:Integer read FID;
	end;

	function Take(AObject:TObject):TAQ; overload;
	function Take(Objects:TObjectArray):TAQ; overload;
	function Take(Objects:TObjectList):TAQ; overload;

	function OA(Objects:array of TObject):TObjectArray;

	function MatchID(CompareID, CurrentID:Integer):Boolean;

implementation

const
	MaxLifeTime = 10000;
	IntervalResolution = 25;
	GarbageCleanInterval = 5000;
	GarbageCleanTime = 100;
	SpareAQsCount = 1000;

const
	RecurseBitMask       = $01;
	ConditionLockBitMask = $02;
	ImmortallyBitMask    = $04;

type
	TComponentsNotifier = class(TComponentList)
	protected
		procedure Notify(Ptr:Pointer; Action:TListNotification); override;
	end;

function LinearEase(Progress:Real):Real;
begin
	Result:=Progress;
end;

function QuadraticEase(Progress:Real):Real;
begin
	Result:=Sqr(Progress);
end;

function MassiveQuadraticEase(Progress:Real):Real;
begin
	Result:=Progress * Sqr(Progress);
end;

function SinusEase(Progress:Real):Real;
begin
	Result:=Sin(Progress * (Pi / 2));
end;

function ElasticEase(Progress:Real):Real;
begin
	Result:=(Sin(Progress * Pi * (0.2 + 2.5 * Progress * Progress * Progress)) *
		Power(1 - Progress, 2.2) + Progress) * (1 + (1.2 * (1 - Progress)));
end;

function LowWave(Progress:Real):Real;
begin
	Result:=Progress + (Sin(Progress * 3 * Pi) * 0.1);
end;

function MiddleWave(Progress:Real):Real;
begin
	Result:=Progress + (Sin(Progress * 3 * Pi) * 0.2);
end;

function HighWave(Progress:Real):Real;
begin
	Result:=Progress + (Sin(Progress * 3 * Pi) * 0.4);
end;

function Take(AObject:TObject):TAQ;
begin
	Result:=TAQ.Take(AObject);
end;

function Take(Objects:TObjectArray):TAQ;
begin
	Result:=TAQ.Take(Objects);
end;

function Take(Objects:TObjectList):TAQ;
begin
	Result:=TAQ.Take(Objects);
end;

function OA(Objects:array of TObject):TObjectArray;
var
	cc:Integer;
begin
	SetLength(Result, Length(Objects));
	for cc:=0 to Length(Objects) - 1 do
		Result[cc]:=Objects[cc];
end;

{**
 * Sagt aus, ob CompareID die CurrentID greift
 *
 * Folgende Regeln werden angewendet:
 * - ist CompareID = 0,  so wird CurrentID nicht verglichen
 *                       und es wird TRUE geliefert
 * - ist CompareID > 0,  so muss CurrentID gleich sein
 * - ist CompareID = -1, so muss CurrentID = 0 sein
 * - ist CompareID = -2, so muss CurrentID > 0 sein
 *}
function MatchID(CompareID, CurrentID:Integer):Boolean;
begin
	Result:=(CompareID = 0) or
		((CompareID > 0) and (CompareID = CurrentID)) or
		((CompareID = -1) and (CurrentID = 0)) or
		((CompareID = -2) and (CurrentID > 0));
end;

procedure SetBit(var Container:Byte; BitMask:Byte; Value:Boolean);
begin
	if Value then
		Container:=Container or BitMask
	else
		Container:=Container and not BitMask;
end;

function GetBit(Container:Byte; BitMask:Byte):Boolean;
begin
	Result:=(Container and BitMask) <> 0;
end;

//var
//	HighPerformanceCounterAvailable:Boolean;
//	HighPerformanceStartCount:Int64;
//	HighPerformanceCountPerSecond:Int64;
//
//{**
// * Returns a smoother TickCount
// *
// * If the high perfomance counter not supported, it will use Windows.GetTickCount
// *}
//function GetTickCount:Cardinal;
//var
//	CurrentCount:Int64;
//begin
//	if HighPerformanceCounterAvailable then
//	begin
//		QueryPerformanceCounter(CurrentCount);
//		Result:=
//			Floor(((CurrentCount - HighPerformanceStartCount) / HighPerformanceCountPerSecond) * 1000);
//	end
//	else
//		Result:=Windows.GetTickCount;
//end;

{** TAQBase **}

constructor TAQBase.Create;
begin
	inherited Create(FALSE);
end;

{** TAQ **}

function TAQ.Append(Objects:TObjectArray):TAQ;
var
	cc:Integer;
begin
	if SupervisorLock(Result, 'Append') then
		Exit;
	for cc:=0 to Length(Objects) - 1 do
		Add(Objects[cc]);
end;

function TAQ.Append(Objects:TObjectList):TAQ;
var
	cc:Integer;
begin
	if SupervisorLock(Result, 'Append') then
		Exit;
	{**
	 * Overflows vermeiden
	 *}
	if Objects = Self then
		Exit;
	for cc:=0 to Objects.Count - 1 do
		Add(Objects[cc]);
end;

function TAQ.Append(AObject:TObject):TAQ;
begin
	if SupervisorLock(Result, 'Append') then
		Exit;
	Add(AObject);
end;

function TAQ.AppendAQ(AQ:TAQ):TAQ;
begin
	if SupervisorLock(Result, 'AppendAQ') then
		Exit;
	Add(AQ);
end;

procedure TAQ.AddInterval(Interval:TInterval);
begin
	{**
	 * Das Intervall wird nicht angenommen, wenn keine Objekte vorhanden sind
	 *
	 * Eine Ausnahme besteht für den Garbage-Collector
	 *}
	if (Count = 0) and (Self <> GarbageCollector) then
	begin
		Interval.Free;
		Exit;
	end;

	if (GetIntervals.Count = 0) and (FActiveIntervalAQs.IndexOf(Self) = -1) then
		FActiveIntervalAQs.Add(Self);
	GetIntervals.Add(Interval);
	{$IFDEF OutputDebugActiveIntervals}
		OutputDebugString(PWideChar('TAQ-Instanzen mit Intervallen: ' +
			IntToStr(FActiveIntervalAQs.Count)));
	{$ENDIF}
end;

function TAQ.AnimationActorsChain(ID:Integer; IncludeOrphans:Boolean):TAQ;
begin
	if SupervisorLock(Result, 'AnimationActorsChain') then
		Exit;
	Result:=CustomActors(arAnimation, ID, IncludeOrphans);
end;

function TAQ.CancelAnimations(ID:Integer):TAQ;
begin
	if SupervisorLock(Result, 'CancelAnimations') then
		Exit;
	CustomCancel(arAnimation, ID, FALSE);
end;

function TAQ.CancelDelays(ID:Integer):TAQ;
begin
	if SupervisorLock(Result, 'CancelDelays') then
		Exit;
	CustomCancel(arDelay, ID, FALSE);
end;

function TAQ.CancelIntervals(ID:Integer):TAQ;
begin
	if SupervisorLock(Result, 'CancelIntervals') then
		Exit;
	CustomCancel(arInterval, ID, FALSE);
end;

function TAQ.CancelTimers(ID:Integer):TAQ;
begin
	if SupervisorLock(Result, 'CancelTimers') then
		Exit;
	CustomCancel(arTimer, ID, FALSE);
end;

function TAQ.NewChain:TAQ;
begin
	if SupervisorLock(Result, 'NewChain') then
		Exit;
	Result:=Managed;
	Result.FChainedTo:=Self;
end;

procedure TAQ.Notify(Ptr:Pointer; Action:TListNotification);
begin
	if (Action = lnAdded) and (TObject(Ptr) is TComponent) and
		(FComponentsNotifier.IndexOf(TComponent(Ptr)) < 0) then
		FComponentsNotifier.Add(TComponent(Ptr));

	inherited Notify(Ptr, Action);

	if (Action in [lnExtracted, lnDeleted]) and (Count = 0) then
	begin
		Clean;
		Die;
	end;
end;

function TAQ.ChildrenAppend(Recurse:Boolean; ChildrenFiller:TEachFunction):TAQ;
begin
	if SupervisorLock(Result, 'ChildrenAppend') then
		Exit;
	if not Assigned(ChildrenFiller) then
		ChildrenFiller:=Self.ChildrenFiller;
	Result:=CustomFiller(ChildrenFiller, TRUE, Recurse);
end;

function TAQ.ChildrenChain(Recurse:Boolean; ChildrenFiller:TEachFunction):TAQ;
begin
	if SupervisorLock(Result, 'ChildrenChain') then
		Exit;
	if not Assigned(ChildrenFiller) then
		ChildrenFiller:=Self.ChildrenFiller;
	Result:=CustomFiller(ChildrenFiller, FALSE, Recurse);
end;

function TAQ.ChildrenFiller(AQ:TAQ; O:TObject):Boolean;
var
	cc:Integer;
begin
	Result:=TRUE;
	if not (O is TComponent) then
		Exit;
	with TComponent(O) do
		for cc:=0 to ComponentCount - 1 do
			AQ.Add(Components[cc]);
end;

procedure TAQ.Clean;
begin
	{**
	 * Globale Auswirkungen
	 *}
	GarbageCollector.Each(
		function(GCC:TAQ; O:TObject):Boolean
		begin
			{**
			 * Sollte ein Plugin für diese Instanz existieren, so muss es freigegeben werden
			 *}
			if (O is TAQPlugin) and (TAQPlugin(O).WorkAQ = Self) then
				GCC.Remove(O)
			{**
			 * Sollte diese Instanz mit einer anderen zuvor verkettet worden sein, so muss diese
			 * Verbindung aufgehoben werden
			 *}
			else if (O is TAQ) and (TAQ(O).FChainedTo = Self) then
				TAQ(O).FChainedTo:=nil;
			Result:=TRUE; // Kompletter Scan
		end);

	Clear;
	FConditionCount:=0;
	FBools:=0;
	Recurse:=TRUE;
	FCurrentInterval:=nil;
	FChainedTo:=nil;

	if Assigned(FIntervals) then
	begin
		ClearIntervals;
		FreeAndNil(FIntervals);
	end;
end;

procedure TAQ.ClearIntervals;
var
	cc:Integer;
begin
	for cc:=FIntervals.Count - 1 downto 0 do
		RemoveInterval(TInterval(FIntervals[cc]));
end;

class procedure TAQ.ComponentsNotification(AComponent:TComponent; Operation:TOperation);
begin
	if Operation = opRemove then
		{**
		 * Die Verbindung zu einer Komponente in allen lebenden TAQ-Instanzen aufheben
		 *}
		GarbageCollector.Each(
			function(GCC:TAQ; O:TObject):Boolean
			begin
				if TAQ(O).IsAlive then
					TAQ(O).Remove(AComponent);
				Result:=TRUE;
			end);
end;

function TAQ.Contains(AObject:TObject):Boolean;
var
	Found:Boolean;
begin
	Found:=FALSE;
	Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Found:=Found or (O = AObject);
			Result:=not Found;
		end);
	Result:=Found;
end;

constructor TAQ.Create;
begin
	inherited Create;
	FConditionCount:=0;
	FBools:=0;
	Recurse:=TRUE;
end;


function TAQ.CustomActors(ActorRole:TActorRole; ID:Integer; IncludeOrphans:Boolean):TAQ;
var
	Actors:TAQ;
begin
	Actors:=NewChain;
	if not Assigned(FActiveIntervalAQs) then
		Exit(Actors);
	Each(
		{**
		 * @param SAQ Synonym für SourceAccessQuery und ist Self von CustomActors
		 * @param SO Synonym für SourceObject und beinhaltet das Objekt für das die passenden
		 *        TAQ-Instanzen gesucht werden
		 *}
		function(SAQ:TAQ; SO:TObject):Boolean
		var
			SOFound:Boolean;
		begin
			Result:=TRUE; // Each soll stets komplett durchlaufen
			SOFound:=FALSE;
			FActiveIntervalAQs.Each(
				{**
				 * @param AQ Enthält FActiveIntervalAQs
				 * @param O Enthält eine TAQ-Instanz, die darauf untersucht wird, ob sie SO enthält
				 *        einen aktiven Timer hat und gerade animiert wird
				 *}
				function(AQ:TAQ; O:TObject):Boolean
				var
					TargetAQ:TAQ;
				begin
					Result:=TRUE; // Each soll stets komplett durchlaufen
					{**
					 * Der Garbage-Collector darf hier nicht berücksichtigt werden
					 *}
					if O = FGarbageCollector then
						Exit;
					TargetAQ:=TAQ(O);
					if TargetAQ.HasActors(ActorRole, ID) and TargetAQ.Contains(SO) then
					begin
						Actors.Add(O);
						SOFound:=TRUE;
					end;
				end);
			if IncludeOrphans and not SOFound then
				Actors.Add(SO);
		end);
	Result:=Actors;
end;

procedure TAQ.CustomCancel(ActorRole:TActorRole; ID:Integer; Finish:Boolean);
var
	Perform:TEachFunction;
begin
	Perform:=function(AQ:TAQ; O:TObject):Boolean
	var
		cc:Integer;
		TempAQ:TAQ;
		CI:TInterval; // Abkürzung für CurrentInterval
	begin
		Result:=TRUE; // Each soll komplett durchlaufen
		if not (O is TAQ) then
			Exit;
		TempAQ:=TAQ(O);
		if not Assigned(TempAQ.FIntervals) then
			Exit;

		for cc:=TempAQ.FIntervals.Count - 1 downto 0 do
		begin
			CI:=TInterval(TempAQ.FIntervals[cc]);

			if (CI.ActorRole = ActorRole) and ((ID = 0) or (ID = CI.ID)) then
			begin
				if Finish then
					CI.Finish
				else
					CI.Cancel;
				TempAQ.ProcessInterval(CI);
			end;
		end;
	end;

	if not Assigned(FActiveIntervalAQs) then
		Exit;
	{**
	 * Abbrüche und Beendigungen können sich nur an aktive TAQ-Instanzen richten
	 *}
	FActiveIntervalAQs
		.Each(
			function(GC:TAQ; Target:TObject):Boolean
			var
				TargetAQ:TAQ;
			begin
				Result:=TRUE; // Each soll komplett durchlaufen
				if Target = FGarbageCollector then
					Exit;
				TargetAQ:=TAQ(Target);
				Each(
					{**
					 * @param AQ Enthält Self aus dem selben Kontext, wie die CustomCancel-Methode
					 * @param O Enthält ein Object aus Self
					 *}
					function(AQ:TAQ; O:TObject):Boolean
					begin
						Result:=TRUE;
						if O is TAQ then
							Exit;
						if TargetAQ.IndexOf(O) >= 0 then
						begin
							TargetAQ.Each(Perform);
							Perform(nil, TargetAQ);
							Result:=FALSE; // Es wird nur ein Objekt-Vorkommen benötigt
						end;
					end);
			end);
end;

function TAQ.CustomFiller(Filler:TEachFunction; Append, Recurse:Boolean):TAQ;
var
	TargetAQ:TAQ;

	procedure Each(SourceAQ:TAQ);
	var
		TempAQ:TAQ;
	begin
		TempAQ:=Unmanaged;
		try
			SourceAQ.Each(
				function(AQ:TAQ; O:TObject):Boolean
				begin
					Result:=Filler(TempAQ, O);
				end);

			if TempAQ.Count = 0 then
				Exit;

			TargetAQ.Append(TempAQ);

			if Recurse then
				Each(TempAQ);
		finally
			TempAQ.Free;
		end;
	end;
begin
	if Append then
		TargetAQ:=Self
	else
		TargetAQ:=NewChain;
	Each(Self);
	Result:=TargetAQ;
end;


function TAQ.DebugMessage(HeadMessage:String = ''; Caption:String = ''):TAQ;
{$IFDEF DEBUG}
var
	ChainPath:TStringList;
	cc:Integer;
	IntervalsCount:Integer;
	WholeMessage:String;
{$ENDIF}
begin
	{$IFNDEF DEBUG}
	Exit(Self);
	{$ELSE}
	if SupervisorLock(Result, 'DebugMessage') then
		Exit;
	ChainPath:=TStringList.Create;
	repeat
		IntervalsCount:=0;
		if Assigned(Result.FIntervals) then
			IntervalsCount:=Result.FIntervals.Count;
		ChainPath.Add(Format('(Objects:%d, Intervals:%d, ConditionCount:%d)',
			[Result.Count, IntervalsCount, Result.FConditionCount]));
		Result:=Result.FChainedTo;
	until not Assigned(Result);

	for cc:=0 to ChainPath.Count - 1 do
		ChainPath[cc]:=Format('Chain #%d - %s' , [ChainPath.Count - cc, ChainPath[cc]]);

	if Caption <> '' then
		Caption:=Caption + ' - ';
	Caption:=Caption + 'Chain-Debug';

	WholeMessage:=ChainPath.Text;
	if HeadMessage <> '' then
		WholeMessage:=HeadMessage + #10#13 + '-------------------------------' + #10#13 +
			WholeMessage;
	MessageBox(0, PWideChar(WholeMessage), PWideChar(Caption), MB_OK or MB_ICONINFORMATION);
//	OutputDebugString(PWideChar(WholeMessage)); // Wer keine Boxen mag, kann die Console für die Ausgabe nutzen
	Result:=Self; // Wichtig, da der richtige Result in der oberen Schleife überschrieben wird
	{$ENDIF}
end;


function TAQ.DelayActorsChain(ID:Integer; IncludeOrphans:Boolean):TAQ;
begin
	if SupervisorLock(Result, 'DelayActorsChain') then
		Exit;
	Result:=CustomActors(arDelay, ID, IncludeOrphans);
end;

function TAQ.DemultiplexChain:TAQ;
var
	SimpleAQ:TAQ;
begin
	if SupervisorLock(Result, 'DemultiplexChain') then
		Exit;
	SimpleAQ:=NewChain;
	Result:=SimpleAQ;
	Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=TRUE;
			if O is TAQ then
				Exit;
			SimpleAQ.Add(O);
		end);
end;

destructor TAQ.Destroy;
begin
	Clean;
	inherited Destroy;
end;

function TAQ.Die:TAQ;
begin
	if SupervisorLock(Result, 'Die') then
		Exit;
	if Assigned(FIntervals) and (FIntervals.Count > 0) then
		Exit;
	FLifeTick:=0;
end;

function TAQ.Each(EachFunction:TEachFunction):TAQ;
var
	cc:Integer;
	O:TObject;
	LocalRecurse:Boolean;
begin
	if SupervisorLock(Result, 'Each') then
		Exit;
	cc:=Count;
	LocalRecurse:=Recurse;
	while cc > 0 do
	begin
		O:=Items[Count - cc];
		if LocalRecurse and (O is TAQ) then
			TAQ(O).Each(EachFunction);
		if not EachFunction(Self, O) then
			Break
		else if cc > Count then
			cc:=Count + 1;
		Dec(cc);
	end;
end;

function TAQ.EachAnimation(Duration:Integer; Each, LastEach:TEachFunction; ID:Integer):TAQ;
begin
	if Duration >= MaxLifeTime then
		raise EAQ.CreateFmt('Dauer der Animation (%d) muss kleiner als MaxLifeTime (%d) sein.',
			[Duration, MaxLifeTime])
	else if SupervisorLock(Result, 'EachAnimation') then
		Exit;
	AddInterval(TInterval.Finite(Duration, Each, LastEach, arAnimation, ID));
end;

function TAQ.EachDelay(Delay:Integer; Each:TEachFunction; ID:Integer):TAQ;
begin
	if Delay >= MaxLifeTime then
		raise EAQ.CreateFmt('Delay (%d) muss kleiner als MaxLifeTime (%d) sein.',
			[Delay, MaxLifeTime])
	else if SupervisorLock(Result, 'EachDelay') then
		 Exit;
	AddInterval(TInterval.Finite(Delay, nil, Each, arDelay, ID));
end;

function TAQ.EachInterval(Interval:Integer; Each:TEachFunction; ID:Integer):TAQ;
begin
	if Interval >= MaxLifeTime then
		raise EAQ.CreateFmt('Interval (%d) muss kleiner als MaxLifeTime (%d) sein.',
			[Interval, MaxLifeTime])
	else if SupervisorLock(Result, 'EachInterval') then
		Exit;
	AddInterval(TInterval.Infinite(Interval, Each, arInterval, ID));
end;

function TAQ.EachRepeat(Times:Integer; EachFunction:TEachFunction):TAQ;
var
	cc:Integer;
begin
	if SupervisorLock(Result, 'EachRepeat') then
		Exit;
	for cc:=1 to Times do
		Each(EachFunction);
end;

function TAQ.EachTimer(Duration:Integer; Each, LastEach:TEachFunction; ID:Integer):TAQ;
begin
	if Duration >= MaxLifeTime then
		raise EAQ.CreateFmt('Dauer des Timers (%d) muss kleiner als MaxLifeTime (%d) sein.',
			[Duration, MaxLifeTime])
	else if SupervisorLock(Result, 'EachTimer') then
		Exit;
	AddInterval(TInterval.Finite(Duration, Each, LastEach, arTimer, ID));
end;



function TAQ.IfEnd:TAQ;
begin
	if SupervisorLock(Result, 'IfEnd') then
		Exit;
	if FConditionCount > 0 then
		Dec(FConditionCount);
	if FConditionCount = 0 then
	begin
		ConditionLock:=FALSE;
		Result:=EndChain;
	end;
end;

function TAQ.ExcludeChain(Objects:TObjectArray):TAQ;
begin
	if SupervisorLock(Result, 'ExcludeChain') then
		Exit;
	Result:=ExcludeChain(
		function(AQ:TAQ; O:TObject):Boolean
		var
			cc:Integer;
		begin
			for cc:=0 to Length(Objects) - 1 do
				if Objects[cc] = O then
					Exit(TRUE);
			Result:=FALSE;
		end);
end;

function TAQ.ExcludeChain(AObject:TObject):TAQ;
begin
	if SupervisorLock(Result, 'ExcludeChain') then
		Exit;
	Result:=ExcludeChain(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=O = AObject;
		end);
end;

function TAQ.ExcludeChain(ByClass:TClass):TAQ;
begin
	if SupervisorLock(Result, 'ExcludeChain') then
		Exit;
	Result:=ExcludeChain(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=O is ByClass;
		end);
end;

function TAQ.ExcludeChain(ExcludeEach:TEachFunction):TAQ;
var
	NewAQ:TAQ;
begin
	if SupervisorLock(Result, 'ExcludeChain') then
		Exit;
	NewAQ:=NewChain;
	Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			if not ExcludeEach(AQ, O) then
				NewAQ.Add(O);
			Result:=TRUE;
		end);
	Result:=NewAQ;
end;

function TAQ.ExcludeChain(AQ:TAQ):TAQ;
begin
	if SupervisorLock(Result, 'ExcludeChain') then
		Exit;
	Result:=ExcludeChain(
		function(OAQ:TAQ; O:TObject):Boolean
		begin
			Result:=AQ.Contains(O);
		end);
end;

function TAQ.ExcludeChain(Objects:TObjectList):TAQ;
begin
	if SupervisorLock(Result, 'ExcludeChain') then
		Exit;
	Result:=ExcludeChain(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=Objects.IndexOf(O) >= 0;
		end);
end;

class function TAQ.Ease(EaseType:TEaseType; EaseModifier:TEaseModifier = emIn):TEaseFunction;
begin
	case EaseType of
		etQuadratic:
			Result:=QuadraticEase;
		etMassiveQuadratic:
			Result:=MassiveQuadraticEase;
		etSinus:
			Result:=SinusEase;
		etElastic:
			Result:=ElasticEase;
		etLowWave:
			Result:=LowWave;
		etMiddleWave:
			Result:=MiddleWave;
		etHighWave:
			Result:=HighWave;
	else
		Result:=LinearEase;
	end;
	Result:=Ease(Result, EaseModifier);
end;

class function TAQ.Ease(EaseFunction:TEaseFunction; EaseModifier:TEaseModifier):TEaseFunction;
begin
	if not Assigned(EaseFunction) then
		EaseFunction:=LinearEase;

	case EaseModifier of
		emIn:
			Result:=EaseFunction;
		emOut:
			Result:=function(Progress:Real):Real
			begin
				Result:=EaseFunction(1 - Progress);
			end;
		emInOut:
			Result:=function(Progress:Real):Real
			begin
				if Progress <= 0.5 then
					Progress:=Progress / 0.5
				else
					Progress:=1 - ((Progress - 0.5) / 0.5);
				Result:=EaseFunction(Progress);
			end;
		emInInverted:
			Result:=function(Progress:Real):Real
			begin
				Result:=1 - EaseFunction(1 - Progress);
			end;
		emOutInverted:
			Result:=function(Progress:Real):Real
			begin
				Result:=1 - EaseFunction(Progress);
			end;
		emOutIn:
			Result:=function(Progress:Real):Real
			begin
				if Progress <= 0.5 then
					Progress:=Progress / 0.5
				else
					Progress:=1 - ((Progress - 0.5) / 0.5);
				Result:=EaseFunction(1 - Progress);
			end;
		emInOutMirrored:
			Result:=function(Progress:Real):Real
			begin
				if Progress <= 0.5 then
					Progress:=Progress / 0.5
				else
					Progress:=1 - ((Progress - 0.5) / 0.5);
				Result:=1 - EaseFunction(1 - Progress);
			end;
		emOutInMirrored:
			Result:=function(Progress:Real):Real
			begin
				if Progress <= 0.5 then
					Progress:=Progress / 0.5
				else
					Progress:=1 - ((Progress - 0.5) / 0.5);
				Result:=1 - EaseFunction(Progress);
			end;
	end;
end;

class function TAQ.EaseColor(StartColor, EndColor:TColor; Progress:Real; EaseType:TEaseType;
	EaseModifier:TEaseModifier):TColor;
begin
	Result:=EaseColor(StartColor, EndColor, Progress, Ease(EaseType, EaseModifier));
end;

class function TAQ.EaseColor(StartColor, EndColor:TColor; Progress:Real;
	EaseFunction:TEaseFunction):TColor;
var
	StartR, StartG, StartB,
	EndR, EndG, EndB:Byte;

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
	if StartColor = EndColor then
		Exit(StartColor);

	StartColor:=ColorToRGB(StartColor);
	StartR:=R(StartColor);
	StartG:=G(StartColor);
	StartB:=B(StartColor);

	EndColor:=ColorToRGB(EndColor);
	EndR:=R(EndColor);
	EndG:=G(EndColor);
	EndB:=B(EndColor);

	Progress:=EaseFunction(Progress);

	Result:=RGB(
		EaseInteger(StartR, EndR, Progress, nil),
		EaseInteger(StartG, EndG, Progress, nil),
		EaseInteger(StartB, EndB, Progress, nil));
end;

class function TAQ.EaseInteger(StartValue, EndValue:Integer; Progress:Real;
	EaseFunction:TEaseFunction):Integer;
begin
	if Assigned(EaseFunction) then
		Progress:=EaseFunction(Progress);
	Result:=Round(StartValue + ((EndValue - StartValue) * Progress));
end;

class function TAQ.EasePoint(StartPoint, EndPoint:TPoint; Progress:Real;
	EaseFunction:TEaseFunction):TPoint;
begin
	if Assigned(EaseFunction) then
		Progress:=EaseFunction(Progress);
	Result:=Point(
		EaseInteger(StartPoint.X, EndPoint.X, Progress, nil),
		EaseInteger(StartPoint.Y, EndPoint.Y, Progress, nil));
end;

class function TAQ.EasePoint(StartPoint, EndPoint:TPoint; Progress:Real; EaseType:TEaseType;
	EaseModifier:TEaseModifier):TPoint;
begin
	Result:=EasePoint(StartPoint, EndPoint, Progress, Ease(EaseType, EaseModifier));
end;

class function TAQ.EaseInteger(StartValue, EndValue:Integer; Progress:Real; EaseType:TEaseType;
	EaseModifier:TEaseModifier):Integer;
begin
	Result:=EaseInteger(StartValue, EndValue, Progress, Ease(EaseType, EaseModifier));
end;

class function TAQ.EaseReal(StartValue, EndValue, Progress:Real; EaseFunction:TEaseFunction):Real;
begin
	if Assigned(EaseFunction) then
		Progress:=EaseFunction(Progress);
	Result:=StartValue + ((EndValue - StartValue) * Progress);
end;

class function TAQ.EaseRect(StartRect, EndRect:TRect; Progress:Real;
	EaseFunction:TEaseFunction):TRect;
begin
	if Assigned(EaseFunction) then
		Progress:=EaseFunction(Progress);
	Result:=Rect(
		EasePoint(StartRect.TopLeft, EndRect.TopLeft, Progress, nil),
		EasePoint(StartRect.BottomRight, EndRect.BottomRight, Progress, nil));
end;

class function TAQ.EaseRect(StartRect, EndRect:TRect; Progress:Real; EaseType:TEaseType;
	EaseModifier:TEaseModifier):TRect;
begin
	Result:=EaseRect(StartRect, EndRect, Progress, Ease(EaseType, EaseModifier));
end;

class function TAQ.EaseReal(StartValue, EndValue, Progress:Real; EaseType:TEaseType;
	EaseModifier:TEaseModifier):Real;
begin
	Result:=EaseReal(StartValue, EndValue, Progress, Ease(EaseType, EaseModifier));
end;

function TAQ.FilterChain(ByClass:TClass):TAQ;
begin
	if SupervisorLock(Result, 'FilterChain') then
		Exit;
	Result:=FilterChain(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=O is ByClass;
		end);
end;

function TAQ.FilterChain(FilterEach:TEachFunction):TAQ;
var
	NewAQ:TAQ;
begin
	if SupervisorLock(Result, 'FilterChain') then
		Exit;
	NewAQ:=NewChain;
	Each(
		function(OAQ:TAQ; OO:TObject):Boolean
		begin
			Result:=TRUE;
			if FilterEach(OAQ, OO) then
				NewAQ.Add(OO);
		end);
	Result:=NewAQ;
end;

class procedure TAQ.Finalize;
begin
	if not Assigned(FGarbageCollector) then
		Exit;
	{**
	 * Freigabe von allem, was in der Klassenmethode TAQ.Initialize instanziert wurde
	 *}
	{**
	 * Alle offenen TAQ-Instanzen freigeben
	 *}
	FGarbageCollector.Free;
	{**
	 * Dieser Timer wird zusammen mit FGarbageCollector erstellt, muss auch dementsprechend zusammen
	 * freigegeben werden.
	 *}
	FIntervalTimer.Free;
	{**
	 * Diese unverwaltete TAQ-Instanz wird ebenfalls mit dem FGarbageCollector erstellt und muss
	 * hier manuell freigegeben werden.
	 *}
	FActiveIntervalAQs.Free;
	{**
	 * Komponentenhelfer freigeben
	 *}
	FComponentsNotifier.Free;
end;

function TAQ.FinishAnimations(ID:Integer):TAQ;
begin
	if SupervisorLock(Result, 'FinishAnimations') then
		Exit;
	CustomCancel(arAnimation, ID, TRUE);
end;

function TAQ.FinishTimers(ID:Integer):TAQ;
begin
	if SupervisorLock(Result, 'FinishTimers') then
		Exit;
	CustomCancel(arTimer, ID, TRUE);
end;

class function TAQ.GarbageCollector:TAQ;
begin
	if Assigned(FGarbageCollector) then
		Exit(FGarbageCollector);

	Initialize;

	FGarbageCollector.EachInterval(GarbageCleanInterval,
		{**
		 * In GarbageCollector befindet sich der FGarbageCollector selbst und
		 * in O eine TAQ-Instanz die auf ihre Lebenszeichen untersucht werden muss.
		 *}
		function(GCC:TAQ; O:TObject):Boolean
		var
			CleanEndTick:Cardinal;
			AQsForDestroy:Integer;
		begin
			{**
			 * Soll nur einmal ausgeführt werden, da die eigentliche Bereinigung in den
			 * untergeordeneten Eachs abläuft
			 *}
			Result:=FALSE;

			AQsForDestroy:=0;
			{**
			 * Vorbereitungen für die Bereinigung
			 *}
			GCC.Each(
				function(AQ:TAQ; O:TObject):Boolean
				begin
					if (O is TAQ) and not TAQ(O).IsAlive then
						Inc(AQsForDestroy);
					Result:=TRUE;
				end);
			{**
			 * Bedingter Start für die Bereinigung
			 *}
			if AQsForDestroy < SpareAQsCount then
			begin
				{$IFDEF OutputDebugGCFree}
				OutputDebugString(PWideChar(Format('Bereinigungsvorgang findet nicht statt, da das Sparlimit (%d) nicht erreicht wurde (%d).',
					[SpareAQsCount, AQsForDestroy])));
				{$ENDIF}
				Exit;
			end;

			CleanEndTick:=GetTickCount + GarbageCleanTime;

			GCC.Each(
				function(GCC:TAQ; O:TObject):Boolean
				begin
					if (O is TAQ) and not TAQ(O).IsAlive then
					begin
						GCC.Remove(O);
						Dec(AQsForDestroy);
						{$IFDEF OutputDebugGCFree}
						OutputDebugString(PWideChar(Format('TAQ freigegeben. Verbleibend im GarbageCollector: %d.',
							[GarbageCollector.Count])));
						{$ENDIF}
					end;
					{**
					 * Bedingte Laufzeit der Bereinigung
					 * Läuft, solange Anzahl abgelaufener Instanzen größer SpareAQsCount ist und
					 * solange die verfügbare Bereingungsdauer nicht überschritten wird.
					 *}
					Result:=(AQsForDestroy > SpareAQsCount) or (CleanEndTick >= GetTickCount);
				end);
				{$IFDEF OutputDebugGCFree}
				if CleanEndTick < GetTickCount then
					OutputDebugString('Bereinigungsvorgang vorzeitig abgebrochen, da das Zeitlimit überschritten wurde.');
				{$ENDIF}
		end);

	Result:=FGarbageCollector;
end;

function TAQ.GetConditionLock:Boolean;
begin
	Result:=GetBit(FBools, ConditionLockBitMask);
end;

function TAQ.GetImmortally:Boolean;
begin
	Result:=GetBit(FBools, ImmortallyBitMask);
end;

function TAQ.GetIntervals:TObjectList;
begin
	if not Assigned(FIntervals) then
		FIntervals:=TObjectList.Create(TRUE);
	Result:=FIntervals;
end;

function TAQ.GetRecurse:Boolean;
begin
	Result:=GetBit(FBools, RecurseBitMask);
end;

class procedure TAQ.GlobalIntervalTimerEvent(Sender:TObject);
begin
	FTick:=GetTickCount;
	FActiveIntervalAQs.Each(
		{**
		 * @param AQ Enthält FActiveIntervalAQs
		 * @param O Enthält ein TAQ-Objekt, welches mind. ein Interval besitzt
		 *}
		function(AQ:TAQ; O:TObject):Boolean
		begin
			TAQ(O).LocalIntervalTimerEvent(Sender);
			Result:=TRUE; // Die Each soll komplett durchlaufen
		end);
end;

function TAQ.HasActors(ActorRole:TActorRole; ID:Integer):Boolean;
var
	AnyActors:Boolean;
begin
	Result:=FALSE;
	if not (Assigned(FIntervals) and (FIntervals.Count > 0)) then
		Exit;
	AnyActors:=FALSE;
	TAQ.Take(FIntervals)
		.Each(
			function(AQ:TAQ; O:TObject):Boolean
			begin
				AnyActors:=(TInterval(O).ActorRole = ActorRole) and
					((ID = 0) or (TInterval(O).ID = ID)) and not TInterval(O).IsFinished;
				{**
				 * Die Each soll nur laufen, bis der erste Actor gefunden wird
				 *}
				Result:=not AnyActors;
			end)
		.Die;
	Result:=AnyActors;
end;

procedure TAQ.HeartBeat;
	{**
	 * Leitet den Herzschlag an ggf. enthaltene TAQ-Instanzen rekursiv weiter
	 *}
	procedure HeartBeatEcho(AQ:TAQ);
	var
		cc:Integer;
	begin
		for cc:=0 to AQ.Count - 1 do
			if AQ[cc] is TAQ then
			begin
				TAQ(AQ[cc]).HeartBeat;
				HeartBeatEcho(TAQ(AQ[cc]));
			end;
	end;
begin
	FLifeTick:=TAQ.Tick;
	{**
	 * Der Herzschlag muss an enthaltene TAQ-Instanzen weitergereicht werden, wenn diese Instanz
	 * Rekursiv (TAQ.Recurse) ist. Standardmäßig sind alle TAQ-Instanzen rekursiv.
	 * Ausnahmen: TAQ.FGarbageCollector
	 *}
	if Recurse then
		HeartBeatEcho(Self);
end;

function TAQ.IfAll(EachFunction:TEachFunction):TAQ;
var
	Condition:Boolean;
begin
	if SupervisorLock(Result, 'IfAll') then
		Exit;
	Condition:=Count > 0;
	Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Condition:=Condition and EachFunction(AQ, O);
			Result:=Condition;
		end);
	Result:=IfThen(Condition);
end;

function TAQ.IfAny(EachFunction:TEachFunction):TAQ;
var
	Condition:Boolean;
begin
	if SupervisorLock(Result, 'IfAny') then
		Exit;
	Condition:=FALSE;
	Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Condition:=Condition or EachFunction(AQ, O);
			Result:=not Condition;
		end);
	Result:=IfThen(Condition);
end;

function TAQ.IfContainsAll(Objects:TObjectList):TAQ;
begin
	if SupervisorLock(Result, 'IfContainsAll') then
		Exit;
	Result:=IfAll(IfContainsEach(Objects));
end;

function TAQ.IfContainsAll(AQ:TAQ):TAQ;
begin
	if SupervisorLock(Result, 'IfContainsAll') then
		Exit;
	Result:=IfAll(IfContainsEach(AQ));
end;

function TAQ.IfContainsAll(Objects:TObjectArray):TAQ;
begin
	if SupervisorLock(Result, 'IfContainsAll') then
		Exit;
	Result:=IfAll(IfContainsEach(Objects));
end;

function TAQ.IfContainsAll(ByClass:TClass):TAQ;
begin
	if SupervisorLock(Result, 'IfContainsAll') then
		Exit;
	Result:=IfAll(IfContainsEach(ByClass));
end;

function TAQ.IfContainsAny(Objects:TObjectList):TAQ;
begin
	if SupervisorLock(Result, 'IfContainsAny') then
		Exit;
	Result:=IfAny(IfContainsEach(Objects));
end;

function TAQ.IfContainsAny(AQ:TAQ):TAQ;
begin
	if SupervisorLock(Result, 'IfContainsAny') then
		Exit;
	Result:=IfAny(IfContainsEach(AQ));
end;

function TAQ.IfContainsAny(Objects:TObjectArray):TAQ;
begin
	if SupervisorLock(Result, 'IfContainsAny') then
		Exit;
	Result:=IfAny(IfContainsEach(Objects));
end;

function TAQ.IfContainsAny(ByClass:TClass):TAQ;
begin
	if SupervisorLock(Result, 'IfContainsAny') then
		Exit;
	Result:=IfAny(IfContainsEach(ByClass));
end;

function TAQ.IfContains(AObject:TObject):TAQ;
begin
	if SupervisorLock(Result, 'IfContains') then
		Exit;
	Result:=IfThen(Contains(AObject));
end;

function TAQ.IfContainsEach(ByClass:TClass):TEachFunction;
begin
	Result:=function(AQ:TAQ; O:TObject):Boolean
	begin
		Result:=O is ByClass;
	end;
end;

function TAQ.IfContainsEach(Objects:TObjectArray):TEachFunction;
begin
	Result:=function(AQ:TAQ; O:TObject):Boolean
	var
		cc:Integer;
	begin
		Result:=FALSE;
		for cc:=0 to Length(Objects) - 1 do
			if O = Objects[cc] then
				Exit(TRUE);
	end;
end;

function TAQ.IfContainsEach(AQ:TAQ):TEachFunction;
begin
	Result:=function(SourceAQ:TAQ; O:TObject):Boolean
	begin
		Result:=AQ.Contains(O);
	end;
end;

function TAQ.IfElse:TAQ;
var
	PrevChain:TAQ;
begin
	if SupervisorLock(Result, 'IfElse') then
		Exit;
	if FConditionCount <= 1 then
	begin
		PrevChain:=IfEnd;
		Result:=PrevChain.IfThen((PrevChain.Count > 0) and (Count = 0));
	end;
end;

function TAQ.IfContainsEach(Objects:TObjectList):TEachFunction;
begin
	Result:=function(AQ:TAQ; O:TObject):Boolean
	begin
		Result:=Objects.IndexOf(O) >= 0;
	end;
end;

function TAQ.IfThen(Condition:Boolean):TAQ;
begin
	if SupervisorLock(Result, 'IfThen') then
		Exit;

	if not ConditionLock then
	begin
		Result:=NewChain;
		Result.ConditionLock:=not Condition;
	end;

	if not Result.ConditionLock then
		Result.Append(Self);
	Inc(Result.FConditionCount);
end;

class procedure TAQ.Initialize;
begin
	{**
	 * Der Garbage-Collector fungiert auch als Singleton-Sperre
	 *}
	if Assigned(FGarbageCollector) then
		Exit;

	{**
	 * Die Initialisierung der gesamten Klasse
	 **********************************************************************************************}

	FTick:=GetTickCount;

	FIntervalTimer:=TTimer.Create(nil);
	with FIntervalTimer do
	begin
		Enabled:=TRUE;
		Interval:=IntervalResolution;
		OnTimer:=GlobalIntervalTimerEvent;
	end;

	FActiveIntervalAQs:=TAQ.Create;
	FActiveIntervalAQs.Recurse:=FALSE;

	FGarbageCollector:=TAQ.Create;
	FGarbageCollector.OwnsObjects:=TRUE;
	FGarbageCollector.Recurse:=FALSE;

	FComponentsNotifier:=TComponentsNotifier.Create;
	FComponentsNotifier.OwnsObjects:=FALSE;
end;

function TAQ.IntervalActorsChain(ID:Integer; IncludeOrphans:Boolean):TAQ;
begin
	if SupervisorLock(Result, 'IntervalActorsChain') then
		Exit;
	Result:=CustomActors(arInterval, ID, IncludeOrphans);
end;

function TAQ.IsAlive:Boolean;
begin
	Result:=((FLifeTick + MaxLifeTime) >= TAQ.Tick) or Immortally;
end;

procedure TAQ.LocalIntervalTimerEvent(Sender:TObject);
var
	cc:Integer;
begin
	if not (Assigned(FIntervals) and (FIntervals.Count > 0)) then
		Exit;

	for cc:=FIntervals.Count - 1 downto 0 do
		ProcessInterval(TInterval(FIntervals[cc]));

	HeartBeat;
end;

class function TAQ.Managed:TAQ;
var
	ManagedAQ:TAQ;
begin
	ManagedAQ:=nil;

	{**
	 * Im GarbageCollector nach einer abgelaufenen Instanz suchen
	 *}
	GarbageCollector.Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			if (O is TAQ) and not TAQ(O).IsAlive then
			begin
				ManagedAQ:=TAQ(O);
				ManagedAQ.Clean;
				ManagedAQ.HeartBeat;
				{$IFDEF OutputDebugGCRecycle}
				OutputDebugString(PWideChar(Format('TAQ %p am Index #%d wiederverwendet.',
					[@O, AQ.IndexOf(O)])));
				{$ENDIF}
			end;
			{**
			 * Die Each soll solange laufen, bis eine abgelaufene Instanz gefunden wurde
			 *}
			Result:=not Assigned(ManagedAQ);
		end);

	if Assigned(ManagedAQ) then
		Exit(ManagedAQ);

	Result:=TAQ.Create;
	Result.HeartBeat;
	{**
	 * Das ist das ganze Geheimnis des TAQ-Objekt-Managing ;)
	 *}
	GarbageCollector.Add(Result);
	{$IFDEF OutputDebugGCCreate}
	OutputDebugString(PWideChar(Format('Neuer TAQ %p am Index #%d.',
		[@Result, GarbageCollector.IndexOf(Result)])));
	{$ENDIF}
end;

function TAQ.MultiplexChain:TAQ;
var
	MultiAQ:TAQ;
begin
	if SupervisorLock(Result, 'MultiplexChain') then
		Exit;
	MultiAQ:=NewChain;
	Result:=MultiAQ;
	Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=TRUE;
			if O is TAQ then
				Exit;
			MultiAQ.AppendAQ(TAQ.Take(O));
		end);
end;

function TAQ.ParentsAppend(Recurse:Boolean; ParentsFiller:TEachFunction):TAQ;
begin
	if SupervisorLock(Result, 'ParentsAppend') then
		Exit;
	if not Assigned(ParentsFiller) then
		ParentsFiller:=Self.ParentsFiller;
	Result:=CustomFiller(ParentsFiller, TRUE, Recurse);
end;

function TAQ.ParentsChain(Recurse:Boolean; ParentsFiller:TEachFunction):TAQ;
begin
	if SupervisorLock(Result, 'ParentsChain') then
		Exit;
	if not Assigned(ParentsFiller) then
		ParentsFiller:=Self.ParentsFiller;
	Result:=CustomFiller(ParentsFiller, FALSE, Recurse);
end;

function TAQ.ParentsFiller(AQ:TAQ; O:TObject):Boolean;
begin
	Result:=TRUE;
	if not ((O is TComponent) and (TComponent(O).HasParent)) then
		Exit;
	AQ.Add(TComponent(O).GetParentComponent);
end;

function TAQ.Plugin<T>:T;
begin
	Result:=T.Create;
	TAQPlugin(Result).FWorkAQ:=Self;
	GarbageCollector.Add(Result);
	TAQPlugin(Result).Autorun;
end;

function TAQ.EndChain:TAQ;
begin
	if SupervisorLock(Result, 'EndChain') then
		Exit;
	if Assigned(FChainedTo) and GarbageCollector.Contains(FChainedTo) then
		Exit(FChainedTo);
	Result:=Managed;
end;

procedure TAQ.ProcessInterval(Interval:TInterval);
var
	EachFunction:TEachFunction;
begin
	FCurrentInterval:=Interval;

	EachFunction:=(CurrentInterval.Each);
	if Assigned(EachFunction) then
		Each(EachFunction);

	if Assigned(CurrentInterval) and CurrentInterval.IsFinished then
	begin
		RemoveInterval(CurrentInterval);
		FCurrentInterval:=nil;
	end;
end;

procedure TAQ.RemoveInterval(Interval:TInterval);
begin
	FIntervals.Remove(Interval);
	if FIntervals.Count = 0 then
		FActiveIntervalAQs.Remove(Self);
	{$IFDEF OutputDebugActiveIntervals}
		OutputDebugString(PWideChar('TAQ-Instanzen mit Intervallen: ' +
			IntToStr(FActiveIntervalAQs.Count)));
	{$ENDIF}
end;

procedure TAQ.SetConditionLock(Value:Boolean);
begin
	if Value = ConditionLock then
		Exit;
	SetBit(FBools, ConditionLockBitMask, Value);
end;

procedure TAQ.SetImmortally(Value:Boolean);
begin
	if Value = Immortally then
		Exit;
	SetBit(FBools, ImmortallyBitMask, Value);
end;

procedure TAQ.SetRecurse(Value:Boolean);
begin
	SetBit(FBools, RecurseBitMask, Value);
end;

function TAQ.SliceChain(StartIndex, Count:Integer):TAQ;
var
	EndIndex, TotalCount, cc:Integer;
begin
	if SupervisorLock(Result, 'SliceChain') then
		Exit;
	Result:=NewChain;
	TotalCount:=Self.Count;
	if TotalCount = 0 then
		Exit;
	if StartIndex < 0 then
		StartIndex:=TotalCount + StartIndex;
	if Count = 0 then
		EndIndex:=TotalCount
	else
		EndIndex:=StartIndex + Count;

	StartIndex:=Max(0, StartIndex);
	EndIndex:=Min(EndIndex, Self.Count);

	for cc:=StartIndex to EndIndex - 1 do
		Result.Add(Items[cc]);
end;

function TAQ.SupervisorLock(out AQ:TAQ; MethodName:String):Boolean;
var
	RelatedMethod:Boolean;
begin
	Result:=FALSE;
	AQ:=Self;
	if ConditionLock then
	begin
		RelatedMethod:=Copy(MethodName, 1, 2) = 'If';
		Result:=(FConditionCount > 0) and not RelatedMethod;
	end;
end;

class function TAQ.Take(Objects:TObjectArray):TAQ;
begin
	Result:=Managed.Append(Objects);
end;

class function TAQ.Take(AObject:TObject):TAQ;
begin
	Result:=Managed.Append(AObject);
end;

function TAQ.TimerActorsChain(ID:Integer; IncludeOrphans:Boolean):TAQ;
begin
	if SupervisorLock(Result, 'TimerActorsChain') then
		Exit;
	Result:=CustomActors(arTimer, ID, IncludeOrphans);
end;

class function TAQ.Unmanaged:TAQ;
begin
	Result:=TAQ.Create;
end;

class function TAQ.Take(Objects:TObjectList):TAQ;
begin
	Result:=Managed.Append(Objects);
end;

{** TAQPlugin **}

procedure TAQPlugin.Autorun;
begin
	// Can be implemented in custom plugins
end;

function TAQPlugin.Each(EachFunction:TEachFunction):TAQ;
begin
	Result:=WorkAQ.Each(EachFunction);
end;

function TAQPlugin.GarbageCollector:TAQ;
begin
	Result:=TAQ.GarbageCollector;
end;

function TAQPlugin.GetImmortally:Boolean;
begin
	Result:=WorkAQ.Immortally;
end;

procedure TAQPlugin.SetImmortally(Value:Boolean);
begin
	WorkAQ.Immortally:=Value;
end;

{** TInterval **}

procedure TInterval.Cancel;
begin
	FInterval:=0;
end;

function TInterval.Each:TEachFunction;
begin
	Result:=nil;
	if IsCanceled then
		Exit;
	{**
	 * Unendlicher Interval
	 *}
	if (FLastTick = 0) and (TAQ.Tick >= FNextTick) then
	begin
		Result:=FNextEach;
		UpdateNextTick;
	end
	{**
	 * Endlicher Interval
	 *}
	else if (FLastTick > 0) then
	begin
		if TAQ.Tick >= FLastTick then
		begin
			if Assigned(FLastEach) then
				Result:=FLastEach
			else
				Result:=FNextEach;
			FLastEach:=nil;
			FNextEach:=nil;
		end
		else if TAQ.Tick >= FNextTick then
		begin
			Result:=FNextEach;
			UpdateNextTick;
		end;
	end;
end;

procedure TInterval.Finish;
begin
	if IsFinite and not IsFinished then
		FLastTick:=TAQ.Tick;
end;

constructor TInterval.Finite(Duration:Integer; Each, LastEach:TEachFunction; ActorRole:TActorRole;
	ID:Integer);
begin
	FID:=ID;
	FActorRole:=ActorRole;
	FNextEach:=Each;
	FLastEach:=LastEach;

	FFirstTick:=TAQ.Tick;
	FInterval:=IntervalResolution;

	FLastTick:=FFirstTick + Cardinal(Duration);
	UpdateNextTick;
end;

constructor TInterval.Infinite(Interval:Integer; Each:TEachFunction; ActorRole:TActorRole;
	ID:Integer);
begin
	FID:=ID;
	FActorRole:=ActorRole;
	FFirstTick:=TAQ.Tick;
	FNextEach:=Each;
	FLastEach:=nil;
	FInterval:=Max(IntervalResolution, Interval);
	FLastTick:=0;
	UpdateNextTick;
end;

function TInterval.IsCanceled:Boolean;
begin
	Result:=FInterval = 0;
end;

function TInterval.IsFinished:Boolean;
begin
	Result:=((FLastTick > 0) and (TAQ.Tick >= FLastTick) and not Assigned(FLastEach) and
		not Assigned(FNextEach)) or IsCanceled;
end;

function TInterval.IsFinite:Boolean;
begin
	Result:=FLastTick > 0;
end;

function TInterval.Progress:Real;
begin
	if (FLastTick = FFirstTick) or (TAQ.Tick >= FLastTick) then
		Exit(1);
	Result:=(Min(TAQ.Tick, FLastTick) - FFirstTick) / (FLastTick - FFirstTick);
end;

procedure TInterval.UpdateNextTick;
begin
	FNextTick:=TAQ.Tick + Cardinal(FInterval);
end;

{** TComponentsNotifier **}

procedure TComponentsNotifier.Notify(Ptr:Pointer; Action:TListNotification);
begin
	if Action = lnExtracted then
		TAQ.ComponentsNotification(TComponent(Ptr), opRemove);
	inherited Notify(Ptr, Action);
end;

initialization

//HighPerformanceCounterAvailable:=QueryPerformanceFrequency(HighPerformanceCountPerSecond);
//if HighPerformanceCounterAvailable then
//	QueryPerformanceCounter(HighPerformanceStartCount);

finalization

TAQ.Finalize;

end.