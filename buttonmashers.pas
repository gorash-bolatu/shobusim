{$RESOURCE fakecode.c}
unit ButtonMashers;

interface

function ProgrammingTime: real;
procedure DoorBreaking;
function JojoSmall(difficulty_relief: byte): boolean;
function JojoBig: boolean;


implementation

uses Aliases, Procs, Draw, Cursor, Resources;
uses _Log;

type
    TimeSpan = System.TimeSpan;

var
    failed_attempts_s, failed_attempts_b: word;

function ProgrammingTime: real;
const
    PROG_WIDTH: byte = 86;
var
    stm: DateTime;
    OH_NO: array of string;
    
    function SpeedrunTime: string;
    begin
        var stm_ppt: TimeSpan := DateTime.Now.Subtract(stm);
        Result := (stm_ppt.Minutes < 1) ? (stm_ppt.ToString('mm\:ss\,fff')) : 'bruh      ';
    end;
    
    procedure srtm;
    var
        curpos: integer;
    begin
        while not KeyAvail do
        begin
            curpos := Cursor.Left;
            Cursor.SetLeft(89);
            TxtClr(Color.Cyan);
            write(SpeedrunTime);
            Cursor.SetLeft(curpos);
            TxtClr(Color.DarkGreen);
            sleep(1);
        end;
        Cursor.Show;
        _Log.mInputs += 1;
        _Log.Val.Add(MillisecondsDelta);
    end;

begin
    (_Log.mInputs, _Log.mTime) := (0, 0);
    writeln('СПИДРАН ПО ПРОГРАММИРОВАНИЮ' + TAB + 'ПОЕХАЛИ');
    var code: string := TextFromResourceFile('fakecode.c');
    try
        OH_NO := code.Split(NewLine.ToCharArray, System.StringSplitOptions.RemoveEmptyEntries);
        code := nil;
        TxtClr(Color.Gray);
        BgClr(Color.Black);
        writeln('┌', '─' * PROG_WIDTH, '┐');
        Cursor.Show;
        stm := DateTime.Now;
        _Log.Val.Clear; MillisecondsDelta;
        for var line := 0 to (Length(OH_NO) - 1) do
        begin
            BgClr(Color.Black);
            Cursor.SetLeft(0);
            TxtClr(Color.Gray);
            write('│', ' ' * PROG_WIDTH, '│');
            Cursor.SetLeft(2);
            TxtClr(Color.DarkGreen);
            ClrKeyBuffer;
            if (line < 5) or (Random(1 + Floor(1.015 * line)) = 0) then srtm;
            foreach ch: char in OH_NO[line] do
            begin
                ClrKeyBuffer;
                if (Random(5 * Floor(1.015 ** line)) = 0) then srtm;
                write(ch);
            end;
            Cursor.SetLeft(89);
            writeln(' ' * SpeedrunTime.Length);
        end;
        _Log.mTime := DateTime.Now.Subtract(stm).TotalMilliseconds.Round;
        Result := DateTime.Now.Subtract(stm).TotalSeconds;
        Cursor.Hide;
        TxtClr(Color.Gray);
        BgClr(Color.Black); // ?
        writeln('├', '─' * PROG_WIDTH, '┤');
        writeln('│', ' ' * PROG_WIDTH, '│');
        writeln('└', '─' * PROG_WIDTH, '┘');
        ClrKeyBuffer;
        ReadKey;
        sleep(300);
        Cursor.GoXY(+2, -2);
        TxtClr(Color.Red);
        write('Compilation error: Segmentation fault (core dumped) at address 0x');
        loop 3 do write(Random(MaxSmallInt).ToString('X')); // ToString('X') - из десятичной в hex
        writeln;
        sleep(800);
        ClrKeyBuffer;
        ReadKey;
        Cursor.GoTop(-(OH_NO.Length + 4));
        ClearLines((OH_NO.Length + 6), True);
    finally
        if (OH_NO <> nil) then
        begin
            for var i: integer := 0 to (OH_NO.Length - 1) do OH_NO[i] := nil;
            OH_NO := nil;
        end;
    end; // try end
    TxtClr(Color.White);
    ClrKeyBuffer;
    writeln('Очередная попытка написать код для "Ultimate Alliance" оборачивается провалом!');
    writeln('Все эти месяцы изучения программирования по индийским туториалам оказались бесполезны.');
    writeln('Оказывается, создавать видеоигры не так-то просто...');
    Console.WindowTop -= Console.WindowHeight div 3;
    
    _Log.Log('======= Presses: ' + _Log.mInputs.ToString);
    _Log.Log('======= AvgCharsPerPress: ' + (5212 / _Log.mInputs).ToString);
    _Log.Log('======= Time: ' + _Log.mTime.ToString);
    _Log.Val.Sort;
    _Log.Log('======= AvgPressTime: ' + (_Log.Val.Average).ToString);
    _Log.Log('======= Median: ~' + (_Log.Val.Item[_Log.Val.LongCount div 2]).ToString);
    _Log.Log('======= Min: ' + (_Log.Val.First).ToString);
    _Log.Log('======= Max: ' + (_Log.Val.Last).ToString);
    _Log.Val.Clear;
    CollectGarbage;
    
end;

procedure DoorBreaking;
const
    GOAL: byte = 30;
    /// (goal * 2) + 2
    GX2P2: byte = 62;
var
    progress: byte;
    starttime: DateTime;
    period: DateTime;
    last_key_pressed_at: DateTime;
    k1, k2: Key;
    cycle: byte;
    switch_color: boolean;
begin
    TxtClr(Color.Gray);
    Draw.Box(GX2P2, 1);
    Cursor.GoXY(+2, -2);
    write('█' * (GX2P2 - 1));
    starttime := DateTime.Now;
    ClrKeyBuffer;
    repeat
        Cursor.SetLeft(64);
        TxtClr(switch_color ? Color.Magenta : Color.Yellow);
        write('ДОЛБИ ПО КНОПКАМ!');
        sleep(2);
        Cursor.SetLeft(1);
        while KeyAvail do
        begin
            k1 := ReadKey;
            if (k1 <> k2) or (DateTime.Now.Subtract(last_key_pressed_at).TotalMilliseconds > 200) then
            begin
                last_key_pressed_at := DateTime.Now;
                k2 := k1;
                progress += ((progress > 2) ? 1 : 2);
            end;
            _Log.PushKey(k1);
        end;
        if (progress > 0) and (DateTime.Now > period) then
        begin
            period := DateTime.Now;
            period := period.AddMilliseconds(65 - (progress * 2));
            period := period.AddMilliseconds(
                DateTime.Now.Subtract(starttime).TotalMilliseconds / 320); // система помощи если долго тупить
            progress -= 1;
        end;
        if (progress > GOAL) then
        begin
            TxtClr(Color.Yellow);
            write('█' * GX2P2);
        end
        else begin
            TxtClr(Color.Gray);
            write('█' * (GOAL - progress + 1));
            TxtClr(Color.Yellow);
            write('█' * (progress * 2));
            TxtClr(Color.Gray);
            write('█' * (GOAL - progress));
        end;
        cycle += 1; // overflow is ok
        if (cycle mod 3 = 0) then switch_color := not switch_color;
    until progress > GOAL;
    _Log.Log('door breaking time: ' + DateTime.Now.Subtract(starttime).ToString);
    Cursor.SetLeft(64);
    TxtClr(Color.Yellow);
    writeln('Двери открыты!    ');
    sleep(400);
    ClrKeyBuffer;
    ReadKey;
    Cursor.GoTop(-2);
    ClearLines(3, True);
    ClrKeyBuffer;
end;

function JojoSmall(difficulty_relief: byte): boolean;
const
    GOAL: byte = 61;
    OFFSET: byte = 19;
    PANICZONE: byte = 14;
    INITIAL_PERIOD_MS = 1500;
    ORA: string = 'О Р А !';
    MUDAK: string = 'М У Д А К !';
var
    progress: shortint := GOAL div 2;
    starttime: DateTime;
    period: DateTime;
    last_key_pressed_at: DateTime;
    k1, k2: Key;
    cycle: word;
    S_last_cur_pos, S_before_cur_pos, K_last_cur_pos, K_before_cur_pos: (integer, integer);
    rnd_a, rnd_b: shortint;
begin
    BeepAsync(800, 1000);
    writeln;
    TxtClr(Color.Gray);
    writeln(' ' * (OFFSET - 1), '┌', '─' * GOAL, '┐');
    writeln(' ' * (OFFSET - 1), '│', ' ' * GOAL, '│');
    writeln(' ' * (OFFSET - 1), '└', '─' * GOAL, '┘');
    Cursor.GoXY(+OFFSET, -2);
    starttime := DateTime.Now;
    ClrKeyBuffer;
    repeat
        if (cycle mod 3 = 0) then
        begin
            if (cycle > 0) and (cycle mod 2 = 0) then
            begin
                Cursor.SetLeft(K_last_cur_pos.Item1);
                Cursor.SetTop(K_last_cur_pos.Item2);
                write(' ' * MUDAK.Length);
                if (cycle > 3) then
                begin
                    Cursor.SetLeft(K_before_cur_pos.Item1);
                    Cursor.SetTop(K_before_cur_pos.Item2);
                    write(' ' * MUDAK.Length);
                    Cursor.SetTop(K_last_cur_pos.Item2);
                end;
                Cursor.GoTop(-rnd_a);
                Cursor.SetLeft(S_last_cur_pos.Item1);
                Cursor.SetTop(S_last_cur_pos.Item2);
                write(' ' * ORA.Length);
                if (cycle > 3) then
                begin
                    Cursor.SetLeft(S_before_cur_pos.Item1);
                    Cursor.SetTop(S_before_cur_pos.Item2);
                    write(' ' * ORA.Length);
                    Cursor.SetTop(S_last_cur_pos.Item2);
                end;
                Cursor.GoTop(-rnd_b);
            end;
            TxtClr(Color.Yellow);
            if (cycle > 0) and (K_last_cur_pos.Item2 = Cursor.Top) then
                rnd_a := FiftyFifty(-2, +2)
            else rnd_a := Random(-1, +1) * 2;
            Cursor.GoTop(+rnd_a);
            Cursor.SetLeft(GOAL + OFFSET + 1);
            if (rnd_a = 0) then Cursor.GoLeft(Random(+4))
            else Cursor.GoLeft(Random(-OFFSET * 2, +3) + 3);
            K_before_cur_pos := K_last_cur_pos;
            K_last_cur_pos := (Cursor.Left, Cursor.Top);
            write(MUDAK);
            Cursor.GoTop(-rnd_a);
            TxtClr(Color.Magenta);
            if (cycle > 0) and (S_last_cur_pos.Item2 = Cursor.Top) then
                rnd_b := FiftyFifty(-2, +2)
            else rnd_b := Random(-1, +1) * 2;
            Cursor.GoTop(+rnd_b);
            Cursor.SetLeft(3);
            Cursor.GoLeft(Random(-3, +3 + OFFSET * Abs(rnd_b)));
            if (rnd_b = 0) then Cursor.GoLeft(+Random(6))
            else if (Cursor.Left > OFFSET) then Cursor.GoLeft(-3);
            S_before_cur_pos := S_last_cur_pos;
            S_last_cur_pos := (Cursor.Left, Cursor.Top);
            write(ORA);
            Cursor.GoTop(-rnd_b);
        end;
        sleep(2);
        Cursor.SetLeft(OFFSET);
        while KeyAvail do
        begin
            k1 := ReadKey;
            if (k1 <> k2) or (DateTime.Now.Subtract(last_key_pressed_at).TotalMilliseconds > 150) then
            begin
                last_key_pressed_at := DateTime.Now;
                k2 := k1;
                progress += 1;
            end;
            _Log.PushKey(k1);
        end;
        if (progress > 0) and (DateTime.Now > period) then
        begin
            var diff: TimeSpan := DateTime.Now.Subtract(starttime);
            period := DateTime.Now;
            var parabolic_speedup: real := Abs((GOAL div 2) - progress) ** Sqrt(2);
            if (failed_attempts_s < 9) then
                parabolic_speedup /= (9 - failed_attempts_s)
            else period := period.AddMilliseconds(failed_attempts_s * 9);
            if (diff.TotalMilliseconds < INITIAL_PERIOD_MS) then parabolic_speedup *= 2;
            period := period.AddMilliseconds(parabolic_speedup);
            period := period.AddMilliseconds(diff.TotalMilliseconds / 250); // система помощи если долго тупить
            period := period.AddMilliseconds(difficulty_relief * 10);
            if (diff.TotalMilliseconds < INITIAL_PERIOD_MS) then progress += (cycle mod 2)
            else progress -= (progress div (GOAL div 3)); // усилить каждую треть
            progress -= 1;
            if (progress > GOAL div 2) then progress -= (diff.TotalMilliseconds.Round mod 2);
        end;
        if (progress < 0) then progress := 0;
        BgClr(((progress < PANICZONE) and (cycle mod 3 > 0)) ? Color.Yellow : Color.Green);
        if (progress > GOAL) then write(' ' * GOAL) else write(' ' * progress);
        BgClr(Color.Red);
        write(' ' * (GOAL - progress));
        if (DateTime.Now.Subtract(starttime).TotalMilliseconds < INITIAL_PERIOD_MS) or (Ord(k1) = 0) then
            if not (progress <= 0) then begin
                TxtClr(cycle mod 2 = 0 ? Color.Blue : Color.Yellow);
                Cursor.SetLeft(30);
                for var c := 1 to 39 do
                begin
                    BgClr((c + 11 > progress) ? Color.Red : Color.Green);
                    write('Д О Л Б И    П О    К Н О П К А М ! ! !'[c]);
                end;
            end;
        BgClr(Color.Black);
        cycle += 1; // no overflow!!!
        if (cycle > MaxSmallInt) then cycle := 6;
    until (progress >= GOAL) or (progress <= 0);
    _Log.Log('ora time: ' + DateTime.Now.Subtract(starttime).ToString);
    Cursor.SetLeft(OFFSET + 12);
    BgClr((progress <= 0) ? Color.Red : Color.Green);
    if (progress <= 0) then
    begin
        TxtClr(Color.Yellow);
        write('МММУУУУУУУУДАААААААААААААААААААААААК!!!');
    end
    else begin
        TxtClr(Color.Magenta);
        write('ОООООРРРРРРРРРРРРААААААААААААААААААА!!!');
    end;
    BgClr(Color.Black);
    sleep(300);
    ClrKeyBuffer;
    ReadKey;
    Cursor.GoTop(-2);
    ClearLines(5, True);
    writeln;
    ClrKeyBuffer;
    TxtClr(Color.White);
    Result := (progress > 0);
    if not Result then failed_attempts_s += 1
    else if (failed_attempts_s > 0) then failed_attempts_s -= 1;
end;

function JojoBig: boolean;
const
    GOAL: byte = 97;
    PANIC_ZONE: byte = 14;
    INITIAL_PERIOD_MS: word = 1800;
var
    progress: shortint := GOAL div 2;
    starttime: DateTime;
    period: DateTime;
    last_key_pressed_at: DateTime;
    k1, k2: Key;
    cycle: word;
    first_pass: boolean := True;
    rnd_a, rnd_b: shortint;
    time_for_strong_attack: TimeSpan := TimeSpan.FromMilliseconds(1300);
    additional_time: TimeSpan := time_for_strong_attack;
    time_to_turn_on_rage: TimeSpan := TimeSpan.FromMilliseconds(6000);
    time_to_turn_off_rage: TimeSpan := TimeSpan.FromMilliseconds(7500);
    rage_mode: boolean;
begin
    BeepAsync(800, 1000);
    writeln;
    WriteEqualsLine;
    Cursor.GoTop(+3);
    TxtClr(Color.Gray);
    Draw.Box(GOAL, 3);
    Cursor.GoTop(+3);
    WriteEqualsLine;
    Cursor.GoXY(+1, -6);
    starttime := DateTime.Now;
    ClrKeyBuffer;
    repeat
        if (cycle mod 3 = 0) then
        begin
            if (cycle > 0) and (cycle mod 2 = 0) then
            begin
                Cursor.SetLeft(0);
                Cursor.GoTop(-6);
                ClearLines(3, False);
                Cursor.GoTop(+5);
                ClearLines(3, False);
                Cursor.GoTop(-5);
            end;
            TxtClr(Color.Magenta);
            rnd_a := FiftyFifty(-6, +2);
            Cursor.GoTop(+rnd_a);
            Cursor.SetLeft(Random(30));
            Draw.Ascii(
                               '╔══╗ ╔══╗ ╔══╣  █',
                               '║  ║ ╠══╝ ║  ║  █',
                               '╚══╝ ╨    ╚══╩╡ ▄');
            Cursor.GoTop(-rnd_a);
            TxtClr(rage_mode ? Color.Red : Color.Yellow);
            rnd_b := FiftyFifty(-6, +2);
            Cursor.GoTop(+rnd_b);
            Cursor.SetLeft(Random(50, 73));
            Draw.Ascii(
                               '╔╗╔╗ ╗ ╔  ╔╗  ╔══╣  ║┌┘ █',
                               '║╚╝║ ╚═╣ ╔╩╩╗ ║  ║  ╠╡  █',
                               '╨  ╨ ══╝ ╨  ╨ ╚══╩╡ ║└┐ ▄');
            Cursor.GoTop(-rnd_b);
        end;
        Cursor.GoTop(-2);
        sleep(2);
        while KeyAvail do
        begin
            k1 := ReadKey;
            if (k1 <> k2) or (DateTime.Now.Subtract(last_key_pressed_at).TotalMilliseconds > 150) then
            begin
                last_key_pressed_at := DateTime.Now;
                k2 := k1;
                progress += 1;
            end;
            _Log.PushKey(k1);
        end;
        if (progress > 0) and (DateTime.Now > period) then
        begin
            var diff: TimeSpan := DateTime.Now.Subtract(starttime);
            period := DateTime.Now;
            var parabolic_speedup: integer := 110 - Round(Abs(progress - (GOAL div 2)) ** Sqrt(2) * 1.1);
            period := period.AddMilliseconds(parabolic_speedup);
            period := period.AddMilliseconds(diff.TotalMilliseconds / 50); // система помощи если долго тупить
            period := period.AddMilliseconds(failed_attempts_b * 100);
            if (progress <= PANIC_ZONE) then
                period := period.AddMilliseconds(80 + (progress * 2)); // система помощи если мало здоровья
            if (diff.TotalMilliseconds > INITIAL_PERIOD_MS) then
                case progress of
                    0..GOAL div 3: progress -= 1;
                    (1 + GOAL div 3)..(GOAL - GOAL div 2): progress -= progress div 14;
                    (GOAL - GOAL div 3)..GOAL: progress -= 1;
                else progress -= progress div 10;
                end //case end
            else if (progress > GOAL div 2) then progress -= 2 else progress -= 1;
            if (progress > GOAL div 2) then
            begin
                progress -= 1;
                if (diff.TotalMilliseconds.Round in INITIAL_PERIOD_MS..(INITIAL_PERIOD_MS * 10)) then progress -= 1;
                if (progress > (GOAL - GOAL div 3)) then progress -= progress div 14;
                if (progress > (GOAL - GOAL div 4)) then progress -= progress div 18;
            end;
            if (diff > time_for_strong_attack) then
            begin
                progress -= progress div 11;
                if (progress > PANIC_ZONE) then progress -= 1;
                if (time_for_strong_attack.Seconds > 10) then
                    additional_time := TimeSpan.FromMilliseconds(1400 - progress * 13)
                else
                    additional_time := TimeSpan.FromMilliseconds(additional_time.TotalMilliseconds ** 1.01);
                time_for_strong_attack.Add(additional_time);
            end;
            if rage_mode then
            begin
                time_for_strong_attack := diff;
                progress -= progress div 7;
                if (progress > 3) then progress -= (progress div 7 + 3);
                if (diff > time_to_turn_off_rage) then rage_mode := False;
            end
            else if (diff > time_to_turn_on_rage) then begin
                time_to_turn_off_rage := time_to_turn_on_rage.Add(
                    TimeSpan.FromMilliseconds(2000 + (time_to_turn_on_rage.TotalMilliseconds / 12)));
                if (time_to_turn_on_rage.TotalMilliseconds <= 6000) then
                    time_to_turn_on_rage := TimeSpan.FromMilliseconds(12300)
                else
                    time_to_turn_on_rage := TimeSpan.FromMilliseconds(time_to_turn_on_rage.TotalMilliseconds * 1.6);
                rage_mode := True;
            end;
            if (cycle mod 2 = 0) and (not KeyAvail) then progress -= 1; // штраф за ненажимание клавиш каждые 2 цикла
        end;
        if (progress < 0) then progress := 0;
        loop 3 do
        begin
            Cursor.SetLeft(1);
            if (progress < PANIC_ZONE) and (cycle mod 3 > 0) then BgClr(Color.Yellow) else BgClr(Color.Green);
            var amount: byte := progress;
            case progress of
                1..4: amount += Random(2);
                5..(GOAL - 4): amount += Random(-3, +3);
                (GOAL - 3)..(GOAL - 1): amount -= Random(2);
            else if (progress >= GOAL) then amount := GOAL
                else amount := 0;
            end;
            write(' ' * amount);
            BgClr(Color.Red);
            writeln(' ' * (GOAL - amount));
        end;
        Cursor.GoTop(-2);
        if rage_mode then
        begin
            TxtClr(cycle mod 2 = 0 ? Color.Blue : Color.Yellow);
            Cursor.SetLeft(30);
            for var c := 1 to 42 do
            begin
                BgClr((c + 27 > progress) ? Color.Red : Color.Green);
                write('С Е Р Г Е Е В С К А Я    Я Р О С Т Ь ! ! !'[c]);
            end;
        end
        else if ((DateTime.Now.Subtract(starttime) < 
            TimeSpan.FromMilliseconds(INITIAL_PERIOD_MS + INITIAL_PERIOD_MS div 3))
            or (Ord(k1) = 0)) then
        begin
            TxtClr(cycle mod 2 = 0 ? Color.Blue : Color.Yellow);
            Cursor.SetLeft(31);
            for var c := 1 to 39 do
            begin
                BgClr((c + 30 > progress) ? Color.Red : Color.Green);
                write('Д О Л Б И    П О    К Н О П К А М ! ! !'[c]);
            end;
        end;
        writeln;
        BgClr(Color.Black);
        cycle += 1; // no overflow!!!
        if (cycle > MaxSmallInt) then cycle := 6;
    until (progress >= GOAL) or (progress <= 0);
    _Log.Log('ora ora time: ' + DateTime.Now.Subtract(starttime).ToString);
    Cursor.GoTop(-6);
    ClearLines(3, False);
    Cursor.GoTop(+5);
    ClearLines(3, False);
    Cursor.GoTop(-7);
    BgClr((progress <= 0) ? Color.Red : Color.Green);
    if (progress > 0) then
    begin
        Cursor.SetLeft(25);
        TxtClr(Color.Magenta);
        Draw.Ascii(
                    '╔══╗ ╔══╗ ' + '╔══╣  ' * 6 + '█',
                    '║  ║ ╠══╝ ' + '║  ║  ' * 6 + '█',
                    '╚══╝ ╨    ' + '╚══╩═ ' * 6 + '▄');
    end
    else begin
        Cursor.SetLeft(22);
        TxtClr(Color.Yellow);
        Draw.Ascii(
                    '╔╗╔╗ ╗ ╔  ╔╗  ' + '╔══╣  ' * 6 + '║┌─ █',
                    '║╚╝║ ╚═╣ ╔╩╩╗ ' + '║  ║  ' * 6 + '╠╡  █',
                    '╨  ╨ ══╝ ╨  ╨ ' + '╚══╩═ ' * 6 + '║└─ ▄');
    end;
    BgClr(Color.Black);
    sleep(300);
    ClrKeyBuffer;
    ReadKey;
    Cursor.GoTop(-4);
    ClearLines(12, True);
    writeln;
    ClrKeyBuffer;
    TxtClr(Color.White);
    Result := (progress > 0);
    if not Result then failed_attempts_b += 1
    else if (failed_attempts_b > 0) then failed_attempts_b -= 1;
end;

end.