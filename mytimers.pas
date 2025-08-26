﻿/// оболочка для System.Timers.Timer
unit MyTimers;

interface

type
    /// оболочка для System.Timers.Timer
    Timer = class
    private
        _tmr: System.Timers.Timer;
    public
        /// приостановить таймер
        procedure Disable;
        /// запустить/возобновить таймер
        procedure Enable;
        /// таймер, выполняющий proc() каждые period мс
        constructor Create(period: real; proc: procedure);
        destructor Destroy;
    end;
// type end

implementation

var
    ListOfAll: List<Timer> := new List<Timer>;

procedure Timer.Disable := if (_tmr <> nil) and _tmr.Enabled then _tmr.Stop;

procedure Timer.Enable := if (_tmr <> nil) then _tmr.Start;

constructor Timer.Create(period: real; proc: procedure);
begin
    _tmr := new System.Timers.Timer(period);
    _tmr.Elapsed += (o: object; e: System.Timers.ElapsedEventArgs) -> proc();
    _tmr.AutoReset := True;
    ListOfAll.Add(self);
end;

destructor Timer.Destroy;
begin
    if (_tmr <> nil) then
    begin
        _tmr.Stop;
        _tmr.Dispose;
        _tmr := nil;
    end;
end;

initialization

finalization
    if (ListOfAll = nil) then exit;
    foreach i: Timer in ListOfAll do i.Destroy;
    ListOfAll.Clear;
    ListOfAll := nil;

end.