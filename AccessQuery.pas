﻿unit AccessQuery;

interface

uses
	SysUtils, Classes, Controls, ExtCtrls, Contnrs, Windows, Math;

type
	EAQ = class(Exception);
	TAQ = class;
	TInterval = class;

	TObjectArray = array of TObject;
	{**
	 * Typ für anonyme Each-Funktionen
	 *
	 * @param AQ Die TAQ-Instanz, die die Each-Funktion aufruft
	 * @param O Das Objekt, welches durch die Each-Funktion bearbeitet werden soll
	 * @return Boolean Sobald die Funktion FALSE liefert, wird die Ausführung der Each-Methode
	 *         angehalten
	 *}
	TEachFunction = reference to function(AQ:TAQ; O:TObject):Boolean;
	{**
	 * Typ für anonyme Benachrichtigungs-Events, der aber auch mit TNotifyEvent kompatibel ist
	 *}
	TAnonymNotifyEvent = reference to procedure(Sender:TObject);
	{**
	 * Typ für Beschleunigungsfunktionen
	 *
	 * @param StartValue Der Wert, ab dem gestartet wird
	 * @param EndValue Der Endwert, der erreicht werden sollte, wenn Progress = 1 ist
	 * @param Progress Fortschritt der Beschleunigung. Wert zwischen 0..1
	 * @return Real
	 *}
	TEaseFunction = function(StartValue, EndValue, Progress:Real):Real;
	{**
	 * Vordefinierte Arten von Beschleunigungsfunktionen
	 *}
	TEaseType = (etLinear, etQuadratic, etMassiveQuadratic);

	TAQ = class(TObjectList)
	private
	class var
		{**
		 * Nimmt alle gemanagete TAQ-Instanzen auf
		 *
		 * Hierrüber wird, unter anderem, die Freigabe von nicht mehr verwendeten TAQ-Objekten
		 * abgewickelt.
		 *
		 * Wird von der Klassenmethode GarbageCollector instanziert
		 *
		 * @see TAQ.GarbageCollector
		 * @see TAQ.Managed
		 *}
		FGarbageCollector:TAQ;
		{**
		 * Der globale Timer
		 *
		 * Wird von der Klassenmethode GarbageCollector instanziert
		 *
		 * @see TAQ.GarbageCollector
		 *}
		FIntervalTimer:TTimer;
		{**
		 * Nimmt alle gemanagete TAQ-Instanzen auf, die mind. ein Interval verwenden
		 *
		 * Wird von der Klassenmethode GarbageCollector instanziert.
		 *
		 * @see TAQ.GarbageCollector
		 * @see TAQ.UpdateActiveIntervalAQs
		 *}
		FActiveIntervalAQs:TAQ;
	protected
		{**
		 * Der letzte Tick, der als Lebenszeichen ausgewertet wird
		 *
		 * @see MaxLifeTime
		 * @see TAQ.HeartBeat
		 *}
		FLifeTick:Cardinal;
		{**
		 * Nimmt mehrere TInterval-Objekte auf
		 *
		 * Wird von GetIntervals instanziert.
		 *
		 * @see TInterval
		 * @see TAQ.GetIntervals
		 *}
		FIntervals:TObjectList;
		{**
		 * @see TAQ.CurrentInterval
		 *}
		FCurrentInterval:TInterval;
		{**
		 * @see TAQ.Animating
		 *}
		FAnimating:Boolean;
		{**
		 * @see TAQ.Recurse
		 *}
		FRecurse:Boolean;

		class function GarbageCollector:TAQ;
		class procedure GlobalIntervalTimerEvent(Sender:TObject);
		class procedure UpdateActiveIntervalAQs;

		function GetIntervals:TObjectList;
		function HasTimer:Boolean;
		function HasInterval:Boolean;

		procedure LocalIntervalTimerEvent(Sender:TObject);
		procedure AnimateObject(O:TObject; Duration:Integer; Each:TEachFunction;
			LastEach:TEachFunction = nil);

		function CustomFiller(Filler:TEachFunction; Append, Recurse:Boolean):TAQ;

		procedure HeartBeat;

		{**
		 * Bestimmt, ob TAQ.Each ggf. andere enthaltene TAQ-Instanzen rekursiv mit der übergebenen
		 * Each-Funktion durchlaufen soll.
		 *
		 * Standard ist TRUE. Beim FGarbageCollector und FActiveIntervalAQs aber FALSE.
		 *}
		property Recurse:Boolean read FRecurse;
	public
		constructor Create; reintroduce;
		destructor Destroy; override;

		class function Managed:TAQ;
		class function Unmanaged:TAQ;

		class function Take(Objects:TObjectArray):TAQ; overload;
		class function Take(Objects:TObjectList):TAQ; overload;
		class function Take(AObject:TObject):TAQ; overload;

		class function Ease(EaseType:TEaseType):TEaseFunction; overload;
		class function Ease(EaseFunction:TEaseFunction = nil):TEaseFunction; overload;

		function Append(Objects:TObjectArray):TAQ; overload;
		function Append(Objects:TObjectList):TAQ; overload;
		function Append(AObject:TObject):TAQ; overload;

		function AppendAQ(AQ:TAQ):TAQ;

		function Children(Append:Boolean = FALSE; Recurse:Boolean = FALSE;
			ChildrenFiller:TEachFunction = nil):TAQ;
		function Parents(Append:Boolean = FALSE; Recurse:Boolean = FALSE;
			ParentsFiller:TEachFunction = nil):TAQ;

		function AnimationActors(IncludeOrphans:Boolean = TRUE):TAQ;
		function IntervalActors(IncludeOrphans:Boolean = TRUE):TAQ;
		function TimerActors(IncludeOrphans:Boolean = TRUE):TAQ;


		function Each(EachFunction:TEachFunction):TAQ;
		function EachInterval(Interval:Integer; Each:TEachFunction):TAQ;
		function EachTimer(Duration:Integer; Each:TEachFunction; LastEach:TEachFunction = nil):TAQ;

		function FinishTimers:TAQ;
		function CancelTimers:TAQ;
		function CancelIntervals:TAQ;

		function Filter(ByClass:TClass):TAQ; overload;
		function Filter(FilterEach:TEachFunction):TAQ; overload;

		function BoundsAnimation(NewLeft, NewTop, NewWidth, NewHeight:Integer; Duration:Integer;
			EaseFunction:TEaseFunction = nil; OnComplete:TAnonymNotifyEvent = nil):TAQ;
		function ShakeAnimation(XTimes, XDiff, YTimes, YDiff, Duration:Integer;
			OnComplete:TAnonymNotifyEvent = nil):TAQ;

		{**
		 * Diese Eigenschaft ist für jene TEachFunction-Funktionen gedacht, die aus dem Kontext der
		 * EachInterval- und EachTimer-Methoden aufgerufen werden.
		 *}
		property CurrentInterval:TInterval read FCurrentInterval;
		{**
		 * Sagt aus, ob die aktuelle Instanz eine Animation durchführt. Sie wird nur von
		 * internen XAnimation-Methoden gesetzt. Manuelle Animationen mittels EachTimer können
		 * das hier nicht setzen.
		 *}
		property Animating:Boolean read FAnimating;
	end;

	TInterval = class
	private
		{**
		 * Der Tick, als der Interval begann
		 *}
		FFirstTick,
		{**
		 * Der Tick für die nächste Ausführung
		 *}
		FNextTick,
		{**
		 * Der Tick für die letzte Ausführung
		 *
		 * Ist 0, bei unendlichem Interval
		 *}
		FLastTick:Cardinal;
		{**
		 * Die Länge eines Intervals in msec
		 *}
		FInterval:Integer;
		{**
		 * Die Each-Funktion, die nicht unbedingt ausgeführt wird
		 *}
		FNextEach,
		{**
		 * Die letzte Each-Funktion
		 *
		 * Ist nil, bei unendlichem Interval
		 *}
		FLastEach:TEachFunction;
	protected
		procedure UpdateNextTick;
	public
		constructor Infinite(Interval:Integer; Each:TEachFunction);
		constructor Finite(Duration:Integer; Each, LastEach:TEachFunction);

		function Each:TEachFunction;
		function IsFinished:Boolean;
		function IsFinite:Boolean;
		function Progress:Real;

		procedure Finish;
	end;

implementation

const
	{**
	 * Die maximale Lebensdauer einer TAQ-Instanz bei Nichtbeschäftigung (msec)
	 *}
	MaxLifeTime = 10000;
	{**
	 * Der Interval basiert auf 40 msec (25fps = 1 sec)
	 *}
	IntervalResolution = 40;
	{**
	 * Interval für GarbageCollector in msec
	 *}
	GarbageCleanInterval = 1000;

function LinearEase(StartValue, EndValue, Progress:Real):Real;
var
	Delta:Real;
begin
	Delta:=EndValue - StartValue;
	Result:=StartValue + (Delta * Progress);
end;

function QuadraticEase(StartValue, EndValue, Progress:Real):Real;
var
	Delta:Real;
begin
	Delta:=EndValue - StartValue;
	Result:=StartValue + (Delta * Sqr(Progress));
end;

function MassiveQuadraticEase(StartValue, EndValue, Progress:Real):Real;
var
	Delta:Real;
begin
	Delta:=EndValue - StartValue;
	Result:=StartValue + (Delta * Progress * Sqr(Progress));
end;

{** TAQ **}

{**
 * Fügt mehrere Objekte mittels eines Objekt-Arrays hinzu
 *
 * Fungiert als Shortcut, für die Hinzufügung mehrerer Objekte ohne ein TObjectList-Objekt.
 *
 * Beispiel:
 *
 * TAQ.Take(Form1).Append(TObjectArray.Create(Button1, Button2));
 *}
function TAQ.Append(Objects:TObjectArray):TAQ;
var
	cc:Integer;
begin
	Result:=Self;
	for cc:=0 to Length(Objects) - 1 do
		Add(Objects[cc]);
end;

{**
 * Fügt mehrere Objekte aus einer TObjectList-Instanz hinzu
 *}
function TAQ.Append(Objects:TObjectList):TAQ;
var
	cc:Integer;
begin
	Result:=Self;
	{**
	 * Overflows vermeiden
	 *}
	if Objects = Self then
		Exit;
	for cc:=0 to Objects.Count - 1 do
		Add(Objects[cc]);
end;

{**
 * Fügt ein einzelnes Objekt hinzu
 *}
function TAQ.Append(AObject:TObject):TAQ;
begin
	Result:=Self;
	Add(AObject);
end;

{**
 * Fügt eine TAQ-Instanz als solche hinzu
 *
 * Während Append(TObjectList) mit einem TAQ-Objekt als Parameter dessen Objekte hinzufügen würde,
 * fügt diese Methode das TAQ-Objekt selbst hinzu
 *}
function TAQ.AppendAQ(AQ:TAQ):TAQ;
begin
	Result:=Self;
	Add(AQ);
end;

{**
 * Startet die Animation für ein einzelnes Objekt
 *
 * Es ist lediglich eine Switch-Methode, die entscheidet ob das übergebene Objekt in der aktuellen
 * TAQ-Instanz oder in einer neuen Instanz ausgeführt werden soll.
 *
 * Hintergrund: Alle Animationsmethoden von TAQ sollen eine beliebige Anzahl von Objekten für die
 * Animierung unterstützen. Da die Animationen über anonyme Funktionen abgewickelt werden und diese
 * in Delphi nicht explizit neuerstellt werden können, hat es sich als unmöglich herausgestellt
 * mehrere Aufrufe von Each-Funktionen mit verschachtelten Kontexten durchzuführen (der nächste
 * Aufruf überschreibt den Status des Vorhergehenden). Diese Einschränkung gilt jedoch nicht, wenn
 * für jede Animation eine separate TAQ-Instanz genommen wird und genau das soll diese Methode für
 * uns machen. Durch die gemanagte Instanzierung brauche ich mir keine Gedanken über zuviele
 * Instanzen machen...
 *}
procedure TAQ.AnimateObject(O:TObject; Duration:Integer; Each, LastEach:TEachFunction);
var
	CustomLastEach:TEachFunction;
begin
	CustomLastEach:=function(AQ:TAQ; O:TObject):Boolean
	begin
		Result:=TRUE;
		AQ.FAnimating:=FALSE;
		if Assigned(LastEach) then
			LastEach(AQ, O)
		else
			Each(AQ, O);
	end;
	{**
	 * Wenn es nur ein Objekt ist, welches sich in der aktuellen TAQ-Instanz befindet, dann kann
	 * man die aktuelle TAQ auch nehmen...
	 *}
	if (Count = 1) and (Items[0] = O) then
	begin
		EachTimer(Duration, Each, CustomLastEach).FAnimating:=TRUE;
	end
	{**
	 * ...andernfalls muss ein neues her.
	 *}
	else
	begin
		TAQ.Take(O).EachTimer(Duration, Each, CustomLastEach).FAnimating:=TRUE;
	end;
end;


{**
 * Liefert ein neues TAQ-Objekt mit TAQ-Instanzen, die gerade eine Animation, für die in dieser
 * Instanz enthaltene Objekte, durchführen.
 *
 * Da die Each-Methode rekursiv mit den enthaltenen TAQ-Objekten arbeitet, laufen weitere Aktionen
 * transparent ab.
 *}
function TAQ.AnimationActors(IncludeOrphans:Boolean):TAQ;
var
	Actors:TAQ;
begin
	Actors:=Managed;

	Each(
		{**
		 * @param SAQ Synonym für SourceAccessQuery und ist Self von TimerActors
		 * @param SO Synonym für SourceObject und beinhaltet das Objekt für das die passenden
		 *        TAQ-Instanzen gesucht werden
		 *}
		function(SAQ:TAQ; SO:TObject):Boolean
		var
			SOFound:Boolean;
		begin
			Result:=TRUE; // Each soll stets komplett durchlaufen
			SOFound:=FALSE;
			GarbageCollector.Each(
				{**
				 * @param AQ Enthält den GarbageCollector
				 * @param O Enthält eine TAQ-Instanz, die darauf untersucht wird, ob sie SO enthält
				 *        einen aktiven Timer hat und gerade animiert wird
				 *}
				function(AQ:TAQ; O:TObject):Boolean
				begin
					Result:=TRUE; // Each soll stets komplett durchlaufen
					with TAQ(O) do
						if (IndexOf(SO) >= 0) and HasTimer and Animating then
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

{**
 * Führt eine Positionierungsanimation mit den enthaltenen TControl-Objekten durch
 *
 * @param NewLeft Neue absolute Links-Position.
 * @param NewTop Neue absolute Oben-Position.
 * @param NewWidth Neue absolute Breite. Soll die Breite nicht verändert werden, ist -1 anzugeben.
 * @param NewHeight Neue absolute Höhe. Soll die Höhe nicht verändert werden, ist -1 anzugeben.
 * @param Duration Die Dauer der Animation in Millisekunden.
 * @param EaseFunction Optional. Eine Beschleunigungsfunktion. Siehe TAQ.Ease, um vordefinierte
 *        Beschleunigungsfunktion zu verwenden. Wird keine (nil) angegeben, so kommt eine lineare
 *        Beschleunigungsfunktion zum Einsatz.
 * @param OnComplete Stanadrd ist nil. Event-Handler, der ausgelöst wird, wenn die Animation
 *        beendet ist. Das Ereignis wird übrigens für jedes Objekt, das animiert wird, ausgelöst.
 *}
function TAQ.BoundsAnimation(NewLeft, NewTop, NewWidth, NewHeight:Integer; Duration:Integer;
	EaseFunction:TEaseFunction; OnComplete:TAnonymNotifyEvent):TAQ;
var
	WholeEach:TEachFunction;
begin
	Result:=Self.Filter(TControl);

	WholeEach:=function(AQ:TAQ; O:TObject):Boolean
	var
		EachF:TEachFunction;
		PrevLeft, PrevTop, PrevWidth, PrevHeight:Integer;
	begin
		Result:=TRUE;

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

			AniLeft:=Ceil(Ease(EaseFunction)(PrevLeft, NewLeft, Progress));
			AniTop:=Ceil(Ease(EaseFunction)(PrevTop, NewTop, Progress));
			if NewWidth >= 0 then
				AniWidth:=Ceil(Ease(EaseFunction)(PrevWidth, NewWidth, Progress))
			else
				AniWidth:=TControl(O).Width;
			if NewHeight >= 0 then
				AniHeight:=Ceil(Ease(EaseFunction)(PrevHeight, NewHeight, Progress))
			else
				AniHeight:=TControl(O).Height;

			if Progress = 1 then
			begin

				{$IFDEF DEBUG}
				OutputDebugString(PWideChar('BoundsAnimation beendet für $' +
					IntToHex(Integer(O), SizeOf(Integer) * 2)));
				{$ENDIF}

				if Assigned(OnComplete) then
					OnComplete(O);
			end;

			TControl(O).SetBounds(AniLeft, AniTop, AniWidth, AniHeight);
		end;

		AQ.AnimateObject(O, Duration, EachF);
	end;

	Result.Each(WholeEach);
end;

{**
 * Bricht alle, mittels EachInterval erstellte, Intervale ab
 *}
function TAQ.CancelIntervals:TAQ;
var
	CancelInterval:TEachFunction;
begin
	Result:=Self;

	CancelInterval:=function(AQ:TAQ; O:TObject):Boolean
	var
		cc:Integer;
	begin
		Result:=TRUE; // Each soll komplett durchlaufen
		if not (O is TAQ) then
			Exit;
		with TAQ(O) do
		begin
			if not Assigned(FIntervals) then
				Exit;
			FCurrentInterval:=nil;
			for cc:=FIntervals.Count - 1 downto 0 do
				with TInterval(FIntervals[cc]) do
					if not IsFinite then
						FIntervals.Delete(cc);
		end;
	end;

	Each(CancelInterval);
	CancelInterval(Self, Self);

	UpdateActiveIntervalAQs;
end;

{**
 * Bricht alle, mittels EachTimer erstellte, Intervale ab
 *
 * Die Timer können dadurch !nicht! die letzte Each-Funktion ausführen. Siehe FinishTimers.
 *
 * @see TAQ.FinishTimers
 *}
function TAQ.CancelTimers:TAQ;
var
	CancelTimer:TEachFunction;
begin
	Result:=Self;

	CancelTimer:=function(AQ:TAQ; O:TObject):Boolean
	var
		cc:Integer;
		TempAQ:TAQ;
	begin
		Result:=TRUE; // Each soll komplett durchlaufen
		if not (O is TAQ) then
			Exit;
		TempAQ:=TAQ(O);
		if not Assigned(TempAQ.FIntervals) then
			Exit;
		TempAQ.FCurrentInterval:=nil;
		for cc:=TempAQ.FIntervals.Count - 1 downto 0 do
			with TInterval(TempAQ.FIntervals[cc]) do
				if IsFinite then
					TempAQ.FIntervals.Delete(cc);
	end;

	Each(CancelTimer);
	CancelTimer(Self, Self);
	UpdateActiveIntervalAQs;
end;

{**
 * Ermittelt die Kindsobjekte für die enthaltenen Objekte
 *
 * @param ChildrenFiller Optional. Standard ist nil. Wie der Name schon vermuten lässt, hat die
 *        Funktion die Aufgabe, dem übergebenen TAQ-Objekt die Kindsobjekte hinzuzufügen. Wird der
 *        Parameter nicht angegeben (nil), so wird eine interne Funktion verwendet, die nur
 *        von TComponent abgeleitete Objekte akzeptiert und deren Components-Eigenschaft
 *        berücksichtigt.
 * @param Append Optional. Standard ist FALSE. Bestimmt, ob die Kindsobjekte der aktuellen
 *        TAQ-Instanz hinzugefügt werden sollen (TRUE) oder ob eine neue Instanz erstellt
 *        werden soll (FALSE), die zurückgeliefert wird.
 * @param Recurse Optional. Standard ist FALSE. Bestimmt, ob die ermittelten Kindsobjekte wiederrum
 *        auf Kindsobjekte untersucht werden sollen.
 *}
function TAQ.Children(Append, Recurse:Boolean; ChildrenFiller:TEachFunction):TAQ;
begin
	if not Assigned(ChildrenFiller) then
		ChildrenFiller:=function(AQ:TAQ; O:TObject):Boolean
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

	Result:=CustomFiller(ChildrenFiller, Append, Recurse);
end;

{**
 * Überprüft, ob FIntervalTimer erstellt werden muss, oder ob er freigegeben werden kann
 *}

constructor TAQ.Create;
begin
	inherited Create(FALSE);
	FRecurse:=TRUE;
	HeartBeat;
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
		TargetAQ:=Managed;
	Each(Self);
	Result:=TargetAQ;
end;

{**
 * Wichtig:
 * TAQ-Instanzen sollten nie außerhalb freigegeben werden, das ist Aufgabe des GarbageCollectors!
 *}
destructor TAQ.Destroy;
begin
	if Assigned(FIntervals) then
		FIntervals.Free;
	inherited;
end;

{**
 * Führt die übergebene Funktion für jedes Objekt aus
 *
 * Das ist die Kernfunktion der gesamten Klasse, auch wenn sie nicht danach aussieht.
 *}
function TAQ.Each(EachFunction:TEachFunction):TAQ;
var
	cc:Integer;
	O:TObject;
begin
	Result:=Self;
	for cc:=Count - 1 downto 0 do
	begin
		O:=Items[cc];
		if not EachFunction(Self, O) then
			Break
		else if cc >= Count then
			Break;
		if Recurse and (O is TAQ) then
			TAQ(O).Each(EachFunction);
	end;
	HeartBeat;
end;

{**
 * Startet einen unbegrenzten (unendlichen) Timer/Interval
 *
 * Das Interval kann nur manuell mit der Methode TAQ.CancelIntervals beendet werden.
 *
 * @see TAQ.CancelIntervals
 *
 * @param Interval Anzahl der Millisekunden, nach denen die Each-Funktion gestartet wird
 * @param Each Die Each-Funktion, die solange ausgeführt wird, bis das Interval manuell beendet wird
 *
 * @throws EAQ Wenn Interval >= MaxLifeTime ist
 *}
function TAQ.EachInterval(Interval:Integer; Each:TEachFunction):TAQ;
begin
	if Interval >= MaxLifeTime then
		raise EAQ.CreateFmt('Interval (%d) muss kleiner als MaxLifeTime (%d) sein.',
			[Interval, MaxLifeTime]);
	Result:=Self;
	GetIntervals.Add(TInterval.Infinite(Interval, Each));
	UpdateActiveIntervalAQs;
	HeartBeat;
end;

{**
 * Startet einen begrenzten Timer, der nach einer definierten Zeit abläuft
 *
 * Ist in den Each-Funktionen (Parameter Each und LastEach) ein Fortschritt vonnöten,
 * wie es z.B. bei Animationen der Fall ist, so kann dieser in TAQ.CurrentInterval.Progress
 * abgerufen werden.
 *
 * @see TAQ.CurrentInterval
 * @see TInterval.Progress
 *
 * Soll der Timer außerhalb beendet werden, so ist die Methode FinishTimers auf die entsprechende
 * TAQ-Instanz anzuwenden. Der Timer kann aber auch abgebrochen werden, in diesem Fall wird aber
 * die entsprechende LastEach nicht aufgerufen, mittels der Methode CancelTimers.
 *
 * @see TAQ.FinishTimers
 * @see TAQ.CancelTimers
 *
 * Eine weitere Möglichkeit der vorzeitigen Beendigung des Timers besteht innerhalb der
 * Each-Funktionen und zwar über TAQ.CurrentInterval.Finish
 *
 * @see TAQ.CurrentInterval
 * @see TInterval.Finish
 *
 * @param Duration Dauer in Millisekunden
 * @param Each Each-Funktion, die in unbestimmten Abständen aufgerufen wird.
 *        Wird LastEach angegeben, so ist es durchaus möglich, dass diese Funktion niemals
 *        aufgerufen wird, wenn der Timer z.B. zu kurz gesetzt ist oder das System ausgelastet ist.
 *        Wird LastEach jedoch nicht definiert (nil), so ist garantiert, dass sie mindestens einmal
 *        (nämlich zum Abschluss) aufgerufen wird.
 * @param LastEach Optional. Standard ist nil. Wird hier eine Each-Funktion angegeben, so ist
 *        sichergestellt (außer der Timer wird mittels TAQ.CancelTimers abgebrochen), dass sie nach
 *        Ablauf des Timers aufgerufen wird. Ist keine Funktion (nil) angegeben, wird der
 *        Each-Parameter stellvertretend verwendet.
 *
 * @throws EAQ Wenn Duration >= MaxLifeTime ist
 *}
function TAQ.EachTimer(Duration:Integer; Each, LastEach:TEachFunction):TAQ;
begin
	if Duration >= MaxLifeTime then
		raise EAQ.CreateFmt('Dauer des Timers (%d) muss kleiner als MaxLifeTime (%d) sein.',
			[Duration, MaxLifeTime]);
	Result:=Self;
	GetIntervals.Add(TInterval.Finite(Duration, Each, LastEach));
	UpdateActiveIntervalAQs;
	HeartBeat;
end;

{**
 * Stellt sicher, dass eine Beschleunigungsfunktion geliefert wird
 *}
class function TAQ.Ease(EaseFunction:TEaseFunction):TEaseFunction;
begin
	if Assigned(EaseFunction) then
		Result:=EaseFunction
	else
		Result:=LinearEase;
end;

{**
 * Liefert eine Beschleunigungsfunktion anhand eines TEaseType
 *}
class function TAQ.Ease(EaseType:TEaseType):TEaseFunction;
begin
	case EaseType of
		etQuadratic:
			Result:=QuadraticEase;
		etMassiveQuadratic:
			Result:=MassiveQuadraticEase;
	else
		Result:=LinearEase;
	end;
end;

{**
 * Erstellt eine neue TAQ-Instanz, die alle hier verfügbare Objekte enthält, wenn sie von der
 * übergebenen Klasse abgeleitet sind
 *}
function TAQ.Filter(ByClass:TClass):TAQ;
var
	NewAQ:TAQ;
begin
	NewAQ:=Managed;

	Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=TRUE;
			if O is ByClass then
				NewAQ.Add(O);
		end);

	Result:=NewAQ;
end;

{**
 * Übernimmt alle Objekte aus der aktuellen in eine neue TAQ-Instanz, die von der übergebenen
 * Each-Funktion mit TRUE bestätigt werden.
 *}
function TAQ.Filter(FilterEach:TEachFunction):TAQ;
var
	NewAQ:TAQ;
begin
	NewAQ:=Managed;
	Each(
		function(OAQ:TAQ; OO:TObject):Boolean
		begin
			Result:=TRUE;
			if FilterEach(OAQ, OO) then
				NewAQ.Add(OO);
		end);
	Result:=NewAQ;
end;

{**
 * Beendet alle, mittels EachTimer erstellte, Intervale
 *
 * Auf diese Weise haben die Intervale die Möglichkeit, ihre letzte Each-Funktion auszuführen.
 *
 * Alle mittels XAnimation-Methoden gestartete Animationen sollten mit dieser Methode beendet
 * werden, da auf diese Weise das Animating-Flag korrekt zurückgesetzt wird.
 *
 * @see TAQ.CancelTimers
 *}
function TAQ.FinishTimers:TAQ;
var
	FinishTimer:TEachFunction;
begin
	Result:=Self;

	FinishTimer:=function(AQ:TAQ; O:TObject):Boolean
	var
		cc:Integer;
	begin
		Result:=TRUE;
		if not (O is TAQ) then
			Exit;
		with TAQ(O) do
		begin
			if not Assigned(FIntervals) then
				Exit;
			for cc:=0 to FIntervals.Count - 1 do
				{**
				 * TInterval.Finish beendet nur die endlichen Intervale
				 *}
				TInterval(FIntervals[cc]).Finish;
		end;
	end;

	Each(FinishTimer);
	FinishTimer(Self, Self);
end;

{**
 * Liefert eine Instanz des GarbageCollector, der unter anderem die Aufgabe hat, nicht verwendete
 * TAQ-Instanzen freizugeben.
 *
 * Es wird nach dem Singleton-Pattern instanziert.
 *
 * Der GarbageCollector gibt die von ihm verwaltete TAQ-Instanzen frei, wenn das letzte
 * Lebenszeichen (TAQ.FLifeTick) länger als MaxLifeTime her ist.
 *}
class function TAQ.GarbageCollector:TAQ;
begin
	if Assigned(FGarbageCollector) then
		Exit(FGarbageCollector);

	{**
	 * Ab hier fängt die Instanzierung der gesamten Klasse an
	 *}

	FIntervalTimer:=TTimer.Create(nil);
	with FIntervalTimer do
	begin
		Enabled:=TRUE;
		Interval:=IntervalResolution;
		OnTimer:=GlobalIntervalTimerEvent;
	end;

	FActiveIntervalAQs:=TAQ.Create;
	FActiveIntervalAQs.FRecurse:=FALSE;

	FGarbageCollector:=TAQ.Create;
	FGarbageCollector.OwnsObjects:=TRUE;
	FGarbageCollector.FRecurse:=FALSE;
	FGarbageCollector.EachInterval(GarbageCleanInterval,
		{**
		 * In GarbageCollector befindet sich der FGarbageCollector selbst und
		 * in O eine TAQ-Instanz die auf ihre Lebenszeichen untersucht werden muss.
		 *}
		function(GarbageCollector:TAQ; O:TObject):Boolean
		var
			CheckAQ:TAQ;
		begin
			CheckAQ:=TAQ(O);
			if GetTickCount > (CheckAQ.FLifeTick + MaxLifeTime) then
			begin
				GarbageCollector.Remove(CheckAQ);

				{$IFDEF DEBUG}
				OutputDebugString(PWideChar(Format('Verbleibende TAQ-Instanzen im GarbageCollector: %d',
					[GarbageCollector.Count])));
				{$ENDIF}
			end;
			Result:=TRUE;
		end);

	Result:=FGarbageCollector;
end;

{**
 * On-Demand-Instanzierung von FIntervals
 *}
function TAQ.GetIntervals:TObjectList;
begin
	if not Assigned(FIntervals) then
		FIntervals:=TObjectList.Create(TRUE);
	Result:=FIntervals;
end;

{**
 * Der globale OnTimer-Event-Handler von FIntervalTimer
 *
 * Um Speicher zu sparen, wird nur ein TTimer verwendet, der mit einer festen Auflösung läuft.
 * Um nun das Event an die richtigen TAQ-Instanzen zu leiten, wird FActiveIntervalAQs verwendet.
 *}
class procedure TAQ.GlobalIntervalTimerEvent(Sender:TObject);
begin
	FActiveIntervalAQs.Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			TAQ(O).LocalIntervalTimerEvent(Sender);
			Result:=TRUE; // Die Each soll komplett durchlaufen
		end);
end;

{**
 * Ermittelt, ob mind. ein Interval definiert ist
 *
 * Intervalle werden stets mittels TAQ.EachInterval gestartet.
 *
 * @see TAQ.EachInterval
 *}
function TAQ.HasInterval:Boolean;
var
	AnyIntervals:Boolean;
begin
	Result:=FALSE;
	if not (Assigned(FIntervals) and (FIntervals.Count > 0)) then
		Exit;
	AnyIntervals:=FALSE;
	TAQ.Take(FIntervals).Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			AnyIntervals:=not TInterval(O).IsFinite;
			{**
			 * Die Each soll nur laufen, bis das erste Interval gefunden wird
			 *}
			Result:=not AnyIntervals;
		end);
	Result:=AnyIntervals;
end;

{**
 * Ermittelt, ob mind. ein Timer definiert ist
 *
 * Timer werden stets mittels TAQ.EachTimer gestartet.
 *
 * @see TAQ.EachTimer
 *}
function TAQ.HasTimer:Boolean;
var
	AnyTimers:Boolean;
begin
	Result:=FALSE;
	if not (Assigned(FIntervals) and (FIntervals.Count > 0)) then
		Exit;
	AnyTimers:=FALSE;
	TAQ.Take(FIntervals).Each(
		function(AQ:TAQ; O:TObject):Boolean
		begin
			with TInterval(O) do
				AnyTimers:=IsFinite and not IsFinished;
			{**
			 * Die Each soll nur laufen, bis der erste Timer gefunden wird
			 *}
			Result:=not AnyTimers;
		end);
	Result:=AnyTimers;
end;

{**
 * Macht einen "Herzschlag"
 *
 * Dies bedeutet: FLifeTick wird aktualisiert. Diese Instanz wird dann erst nach Ablauf von
 * GetTickCount > (FLifeTick + MaxLifeTime) freigegeben.
 *}
procedure TAQ.HeartBeat;
begin
	FLifeTick:=GetTickCount;
end;

{**
 * Liefert ein neues TAQ-Objekt mit TAQ-Instanzen, die gerade ein Interval, für die in dieser
 * Instanz enthaltene Objekte, haben.
 *
 * Da die Each-Methode rekursiv mit den enthaltenen TAQ-Objekten arbeitet, laufen weitere Aktionen
 * transparent ab.
 *}
function TAQ.IntervalActors(IncludeOrphans:Boolean):TAQ;
var
	Actors:TAQ;
begin
	Actors:=Managed;

	Each(
		{**
		 * @param SAQ Synonym für SourceAccessQuery und ist Self von TimerActors
		 * @param SO Synonym für SourceObject und beinhaltet das Objekt für das die passenden
		 *        TAQ-Instanzen gesucht werden
		 *}
		function(SAQ:TAQ; SO:TObject):Boolean
		var
			SOFound:Boolean;
		begin
			Result:=TRUE; // Each soll stets komplett durchlaufen
			SOFound:=FALSE;
			GarbageCollector.Each(
				{**
				 * @param AQ Enthält den GarbageCollector
				 * @param O Enthält eine TAQ-Instanz, die darauf untersucht wird, ob sie SO enthält
				 *        und einen aktiven Timer hat
				 *}
				function(AQ:TAQ; O:TObject):Boolean
				begin
					Result:=TRUE; // Each soll stets komplett durchlaufen
					with TAQ(O) do
						if (IndexOf(SO) >= 0) and HasInterval then
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

{**
 * Lokaler OnTimer-Event-Handler
 *
 * Das ursprüngliche Ereignis kommt von der Klassenmethode GlobalIntervalTimerEvent
 *
 * @see TAQ.GlobalIntervalTimerEvent
 *}
procedure TAQ.LocalIntervalTimerEvent(Sender:TObject);
var
	EachFunction:TEachFunction;
	AnyRemoved:Boolean;
	cc:Integer;
begin
	if not (Assigned(FIntervals) and (FIntervals.Count > 0)) then
		Exit;

	AnyRemoved:=FALSE;

	for cc:=FIntervals.Count - 1 downto 0 do
	begin
		FCurrentInterval:=TInterval(FIntervals[cc]);
		EachFunction:=(CurrentInterval.Each);
		if Assigned(EachFunction) then
		begin
			Each(EachFunction);
			if CurrentInterval.IsFinished then
			begin
				FIntervals.Delete(cc);
				FCurrentInterval:=nil;
				AnyRemoved:=TRUE;
			end;
		end;
	end;
	if AnyRemoved then
		UpdateActiveIntervalAQs;
end;

{**
 * Liefert eine neue gemanagete TAQ-Instanz, die automatisch freigegeben wird, wenn sie nicht
 * mehr verwendet wird.
 *
 * Auch kann nur eine gemanagete TAQ-Instanz von Intervallen profitieren.
 *}
class function TAQ.Managed:TAQ;
begin
	Result:=Unmanaged;
	{**
	 * Das ist das ganze Geheimnis des TAQ-Objekt-Managing ;)
	 *}
	GarbageCollector.Add(Result);
end;

function TAQ.Parents(Append, Recurse:Boolean; ParentsFiller:TEachFunction):TAQ;
begin
	if not Assigned(ParentsFiller) then
		ParentsFiller:=function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=TRUE;
			if not ((O is TComponent) and (TComponent(O).HasParent)) then
				Exit;
			AQ.Add(TComponent(O).GetParentComponent);
		end;
	Result:=CustomFiller(ParentsFiller, Append, Recurse);
end;

{**
 * Führt eine Schüttel-Animation mit allen enthaltenen TControl-Objekten durch
 *
 * @param XTimes Bestimmt, wie oft das Objekt rechts und links geschüttelt werden soll
 *        Wird 0 angegeben, so wird es nicht in der X-Achse geschüttelt.
 * @param XDiff Bestimmt, wie weit nach rechts bzw. nach links geschüttelt werden soll
 * @param YTimes Bestimmt, wie oft das Objekt runter und hoch geschüttelt werden soll
 *        Wird 0 angegeben, so wird es nicht in der Y-Achse geschüttelt.
 * @param YDiff Bestimmt, wie weit nach unten bzw. nach oben geschüttelt werden soll
 * @param Duration Die Dauer der Animation in Millisekunden
 * @param OnComplete Event-Handler, der aufgerufen wird, wenn die Animation beendet ist.
 *        Das Ereignis wird für jedes animierte Objekt, welches im Sender übergeben wird,
 *        ausgelöst.
 *}
function TAQ.ShakeAnimation(XTimes, XDiff, YTimes, YDiff, Duration:Integer;
	OnComplete:TAnonymNotifyEvent):TAQ;
var
	WholeEach:TEachFunction;
begin
	Result:=Self.Filter(TControl);

	WholeEach:=function(AQ:TAQ; O:TObject):Boolean
	var
		EachF:TEachFunction;
		PrevLeft, PrevTop:Integer;
	begin
		Result:=TRUE;

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
				Result:=Ceil(Diff * Sin(Progress * Times * 6.284));
			end;
		begin
			Result:=TRUE;
			Progress:=AQ.CurrentInterval.Progress;
			AniLeft:=PrevLeft;
			AniTop:=PrevTop;

			if Progress <> 0 then
			begin
				if XDiff > 0 then
					AniLeft:=AniLeft + Swing(XTimes, XDiff, Progress);
				if YDiff > 0 then
					AniTop:=PrevTop + Swing(YTimes, YDiff, Progress);
			end
			else if Progress = 1 then
			begin

				{$IFDEF DEBUG}

				OutputDebugString(PWideChar('ShakeAnimation beendet für $' + IntToHex(Integer(O),
							SizeOf(Integer) * 2)));

				{$ENDIF}

				if Assigned(OnComplete) then
					OnComplete(O);
			end;

			with TControl(O) do
				SetBounds(AniLeft, AniTop, Width, Height);
		end;

		AQ.AnimateObject(O, Duration, EachF);
	end;

	Result.Each(WholeEach);
end;

{**
 * Erstellt eine neue gemanagete TAQ-Instanz, mit Objekten aus dem Array
 *}
class function TAQ.Take(Objects:TObjectArray):TAQ;
begin
	Result:=Managed.Append(Objects);
end;

{**
 * Erstellt eine neue gemanagete TAQ-Instanz, mit einem einzelnen übergebenen Objekt
 *}
class function TAQ.Take(AObject:TObject):TAQ;
begin
	Result:=Managed.Append(AObject);
end;

{**
 * Liefert ein neues TAQ-Objekt mit TAQ-Instanzen, die gerade einen Timer, für die in dieser
 * Instanz enthaltene Objekte, haben.
 *
 * Da die Each-Methode rekursiv mit den enthaltenen TAQ-Objekten arbeitet, laufen weitere Aktionen
 * transparent ab.
 *}
function TAQ.TimerActors(IncludeOrphans:Boolean):TAQ;
var
	Actors:TAQ;
begin
	Actors:=Managed;

	Each(
		{**
		 * @param SAQ Synonym für SourceAccessQuery und ist Self von TimerActors
		 * @param SO Synonym für SourceObject und beinhaltet das Objekt für das die passenden
		 *        TAQ-Instanzen gesucht werden
		 *}
		function(SAQ:TAQ; SO:TObject):Boolean
		var
			SOFound:Boolean;
		begin
			Result:=TRUE; // Each soll stets komplett durchlaufen
			SOFound:=FALSE;
			GarbageCollector.Each(
				{**
				 * @param AQ Enthält den GarbageCollector
				 * @param O Enthält eine TAQ-Instanz, die darauf untersucht wird, ob sie SO enthält
				 *        und einen aktiven Timer hat
				 *}
				function(AQ:TAQ; O:TObject):Boolean
				begin
					Result:=TRUE; // Each soll stets komplett durchlaufen
					with TAQ(O) do
						if (IndexOf(SO) >= 0) and HasTimer then
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

{**
 * Liefert eine neue !nicht! gemanagete TAQ-Instanz
 *
 * Sie muss manuell freigegeben werden.
 *
 * Ein sinnvolles Einsatzszenario wäre:
 *
 * TAQ.Unmanaged.Append(ObjectList).Each(function...).Free;
 *
 * Einschränkung: Die EachTimer- und EachInterval-Methoden können mit ungemanageten TAQ-Instanzen
 * nicht verwendet werden, da die OnTimer-Event-Verteilung über den GarbageCollector in der Methode
 * TAQ.GlobalIntervalTimerEvent abgewickelt wird.
 *
 * @see TAQ.GlobalIntervalTimerEvent
 *}
class function TAQ.Unmanaged:TAQ;
begin
	Result:=TAQ.Create;
end;

{**
 * Aktualisiert FActiveIntervalAQs, die TAQ-Objekte enthält, die wiederrum mindestens ein aktives
 * Interval/Timer besitzen.
 *}
class procedure TAQ.UpdateActiveIntervalAQs;
begin
	FActiveIntervalAQs.Clear;
	GarbageCollector.Each(
		{**
		 * @param AQ Ist der GarbageCollector
		 * @param O Ist ein vom GarbageCollector verwaltetes TAQ-Objekt
		 *}
		function(AQ:TAQ; O:TObject):Boolean
		begin
			Result:=TRUE; // Die Each soll komplett durchlaufen
			with TAQ(O) do
				if Assigned(FIntervals) and (FIntervals.Count > 0) then
					FActiveIntervalAQs.Add(O);
		end);
	{**
	 * Der GarbageCollector ist immer mit dabei
	 *}
	FActiveIntervalAQs.Add(GarbageCollector);

	{$IFDEF DEBUG}
		OutputDebugString(PWideChar('TAQ-Instanzen mit Intervallen: ' +
			IntToStr(FActiveIntervalAQs.Count)));
	{$ENDIF}
end;

{**
 * Erstellt eine neue gemanagete TAQ-Instanz, mit Objekten aus einer TObjectList
 *
 * Anmerkung: TAQ ist von TObjectList abgeleitet und kann somit auch hier übergeben werden
 *}
class function TAQ.Take(Objects:TObjectList):TAQ;
begin
	Result:=Managed.Append(Objects);
end;

{** TInterval **}

{**
 * Liefert die entsprechenden Each-Funktion, wenn der Zeitpunkt erreicht ist oder nil
 *}
function TInterval.Each:TEachFunction;
var
	CurrentTick:Cardinal;
begin
	CurrentTick:=GetTickCount;
	Result:=nil;
	{**
	 * Unendlicher Interval
	 *}
	if (FLastTick = 0) and (CurrentTick >= FNextTick) then
	begin
		Result:=FNextEach;
		UpdateNextTick;
	end
	{**
	 * Endlicher Interval
	 *}
	else if (FLastTick > 0) then
	begin
		if CurrentTick >= FLastTick then
			if Assigned(FLastEach) then
				Result:=FLastEach
			else
				Result:=FNextEach
		else if CurrentTick >= FNextTick then
		begin
			Result:=FNextEach;
			UpdateNextTick;
		end;
	end;
end;

{**
 * Manuelle Beendigung eines endlichen Intervals
 *}
procedure TInterval.Finish;
begin
	if IsFinite and not IsFinished then
		FLastTick:=GetTickCount;
end;

{**
 * Erstellt einen endlichen Interval
 *
 * @param Duration Die Dauer des gesamten Intervals in Millisekunden
 * @param Each Each-Funktion, die in Teilintervalen ausgeführt wird. Es ist durchaus möglich, dass
 *        diese nie ausgeführt wird, es sei denn der LastEach-Parameter wird nicht angegeben.
 * @param LastEach Each-Funktion, die in jedem Fall beim Ablauf des Gesamtintervals ausgeführt wird.
 *        Wird hier nil angegeben, wird stellvertretend die im Each-Parameter angegebene Funktion
 *        verwendet.
 *}
constructor TInterval.Finite(Duration:Integer; Each, LastEach:TEachFunction);
begin
	FNextEach:=Each;
	FLastEach:=LastEach;

	FFirstTick:=GetTickCount;
	FInterval:=Max(1, Ceil(Duration / IntervalResolution));

	FLastTick:=FFirstTick + Cardinal(Duration);
	UpdateNextTick;
end;

{**
 * Erstellt einen unbegrenzten Interval
 *
 * @param Interval Angabe in Millisekunden
 * @param Each Each-Funktion, die immer nach dem gesetzten Interval ausgeführt wird
 *}
constructor TInterval.Infinite(Interval:Integer; Each:TEachFunction);
begin
	FFirstTick:=GetTickCount;
	FNextEach:=Each;
	FLastEach:=nil;
	FInterval:=Interval;
	FLastTick:=0;
	UpdateNextTick;
end;

{**
 * Sagt aus, ob das Interval beendet ist
 *
 * Folglich kann diese Methode TRUE nur bei endlichen Intervalen (TInterval.Finite) liefern.
 *}
function TInterval.IsFinished:Boolean;
begin
	Result:=(FLastTick > 0) and (GetTickCount >= FLastTick);
end;

{**
 * Sagt aus, ob das Interval endlich ist
 *
 * In TAQ wird TRUE als Timer behandlet und FALSE als Interval, doch in diesem Kontext ist beides
 * ein Interval ;)
 *}
function TInterval.IsFinite:Boolean;
begin
	Result:=FLastTick > 0;
end;

{**
 * Liefert den Fortschritt des Intervals als Fließkommazahl im Bereich von 0..1
 *}
function TInterval.Progress:Real;
begin
	Result:=Min(1, (GetTickCount - FFirstTick) / (FLastTick - FFirstTick));
end;

{**
 * Aktualisiert den nächsten gültigen Tick
 *}
procedure TInterval.UpdateNextTick;
begin
	FNextTick:=GetTickCount + Cardinal(FInterval);
end;

initialization

finalization

if Assigned(TAQ.FGarbageCollector) then
begin
	{**
	 * Alle offenen TAQ-Instanzen freigeben
	 *}
	TAQ.FGarbageCollector.Free;
	{**
	 * Dieser Timer wird zusammen mit FGarbageCollector erstellt, muss auch dementsprechend zusammen
	 * freigegeben werden.
	 *}
	TAQ.FIntervalTimer.Free;
	{**
	 * Diese unverwaltete TAQ-Instanz wird ebenfalls mit dem FGarbageCollector erstellt und muss
	 * hier manuell freigegeben werden.
	 *}
	TAQ.FActiveIntervalAQs.Free;
end;

end.
