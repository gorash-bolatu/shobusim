unit LegMinigame;

interface

function Survived: boolean;



implementation

uses Aliases, Procs, Draw, Anim, Cursor, _Log;

var
    failed_attempts: byte;

procedure DrawHandGrabbingA;
begin
    TxtClr(Color.Magenta);
    Draw.Text('\ | /');
    Cursor.GoTop(+1);
    TxtClr(Color.Gray);
    write('─');
    TxtClr(Color.Magenta);
    write('\|/');
    TxtClr(Color.Gray);
    write('─');
    Cursor.GoXY(-5, +1);
    TxtClr(Color.Magenta);
    write('  |  ');
end;

procedure DrawHurtHandGrabbingA;
begin
    TxtClr(Color.Red);
    Draw.Text('\ | /');
    Cursor.GoTop(+1);
    TxtClr(Color.Gray);
    write('─');
    TxtClr(Color.Red);
    write('\|/');
    TxtClr(Color.Gray);
    write('─');
    Cursor.GoXY(-5, +1);
    TxtClr(Color.Red);
    write('  |  ');
end;

procedure DrawHandGrabbingB(damaged: boolean);
begin
    TxtClr(damaged ? Color.Red : Color.Magenta);
    Draw.EraseLine(5);
    Cursor.GoTop(+1);
    Draw.Text('\ | /');
    TxtClr(Color.Gray);
    Cursor.GoLeft(+1);
    write('─');
    Cursor.GoLeft(+1);
    write('─');
    Cursor.GoXY(-4, +1);
    TxtClr(damaged ? Color.Red : Color.Magenta);
    Draw.Ascii(' \|/ ',
               '  |  ');
end;

procedure FlashHandGrabbingB;
begin
    loop 2 do
    begin
        Throw(() -> DrawHandGrabbingB(False));
        sleep(60);
        Throw(() -> DrawHandGrabbingB(True));
        sleep(60);
    end;
    Throw(() -> DrawHandGrabbingB(False));
    sleep(180);
end;

procedure DrawEdge := Draw.Text('─' * 5);

function Survived: boolean;
const
    WIDTH: byte = 48;
    MIN_GAP: byte = 5;
    MAX_HP: byte = 23;
    TOTAL_STAGES: byte = 14;
var
    start_time: DateTime;
    last_key_pressed_at: DateTime;
    last_leg_move_time: DateTime;
    time_to_stomp: DateTime;
    stage_delay: word := 200 + (failed_attempts * 20);
    k1, k2: Key;
    left_hand: byte := WIDTH div 2 - MIN_GAP;
    right_hand: byte := left_hand + MIN_GAP;
    leg_position: byte := left_hand + 3;
    leg_delay: word := 20 + (1 shl failed_attempts);
    leg_is_going_right: boolean;
    attack_stage: byte;
    time_for_next_stage: DateTime;
    grip: shortint := MAX_HP div 2;
    last_time_damaged: DateTime;
    hurt: boolean;
    
    function HandsGap: byte := right_hand - left_hand;
    
    procedure DrawHands;
    begin
        TxtClr(Color.Gray);
        Cursor.SetLeft(left_hand);
        write((left_hand = 0) ? '│' : ' ');
        if hurt then Throw(DrawHurtHandGrabbingA) else Throw(DrawHandGrabbingA);
        Cursor.GoLeft(HandsGap - 1);
        if (HandsGap > MIN_GAP) then write(' ') else Cursor.GoLeft(+1);
        if hurt then Throw(DrawHurtHandGrabbingA) else Throw(DrawHandGrabbingA);
        Cursor.GoLeft(+5);
        write((right_hand + 5 = WIDTH) ? '│' : ' ');
    end;
    
    procedure UpdateGrip(grip_change: shortint);
    begin
        while (grip + grip_change > MAX_HP) do grip_change -= 1;
        while (grip + grip_change < 0) do grip_change += 1;
        grip += grip_change;
        Cursor.SetLeft(WIDTH + 8);
        TxtClr(Color.Green);
        write('█' * grip);
        if (grip_change <> 0) and (grip > 0) then
        begin
            write(#8 * Abs(grip_change));
            TxtClr((grip_change > 0) ? Color.DarkCyan : Color.Yellow);
            write('█' * Abs(grip_change));
        end;
        TxtClr(Color.Red);
        write('█' * (MAX_HP - grip));
    end;
    
    function SecondsPassed: integer := Trunc(DateTime.Now.Subtract(start_time).TotalSeconds);
    
    function InitialPeriod: boolean := (Ord(k1) = 0) or (SecondsPassed < 6);
    
    function ShowHint: boolean := InitialPeriod or (SecondsPassed mod 15 in 0..5);

begin
    Result := False;
    writeln(NewLine * 4);
    TxtClr(Color.Gray);
    Draw.Ascii('┌' + '─' * WIDTH + '┐' + ' ' * 5 + '┌' + '─' * MAX_HP + '┐',
               '│' + ' ' * WIDTH + '│' + ' ' * 5 + '│' + ' ' * MAX_HP + '│',
               '└' + '─' * WIDTH + '┘' + ' ' * 5 + '└' + '─' * MAX_HP + '┘');
    Cursor.GoXY(WIDTH + 5 + 2, -1);
    TxtClr(Color.Green);
    Draw.Text(PadCenter('Х В А Т К А', MAX_HP + 2));
    writelnx2;
    UpdateGrip(0);
    DrawHands;
    writelnx2;
    writeln;
    BeepAsync(600, 800);
    leg_is_going_right := FiftyFifty(False, True);
    ClrKeyBuffer;
    start_time := DateTime.Now;
    time_to_stomp := start_time.AddSeconds(4);
    while (grip > 0) do
    begin
        if ShowHint then
        begin
            var clr: Color := FiftyFifty(Color.Cyan, Color.Magenta);
            Cursor.SetLeft(0);
            TxtClr(Color.Yellow);
            if InitialPeriod then
            begin
                print('ДВИГАЙСЯ НА');
                TxtClr(clr);
                print('A/D');
                TxtClr(Color.Yellow);
                print('ИЛИ');
                TxtClr(clr);
                write('←/→');
                TxtClr(Color.Yellow);
                print(', ЧТОБЫ УВЕРНУТЬСЯ ОТ НОГИ КОСТЯНА И');
                TxtClr(Color.DarkCyan);
                print('ВОССТАНОВИТЬ');
                TxtClr(Color.Green);
                write('ХВАТКУ');
                TxtClr(Color.Yellow);
                write('!');
            end
            else begin
                print('ТЫ ПРОТЯНУЛ');
                TxtClr(clr);
                write((SecondsPassed - SecondsPassed mod 15), ' СЕКУНД');
                TxtClr(Color.Yellow);
                print('!');
                TxtClr(Color.Green);
                print('ХВАТКА');
                TxtClr(Color.Yellow);
                print('БУДЕТ');
                TxtClr(Color.DarkCyan);
                print('ВОССТАНАВЛИВАТЬСЯ');
                TxtClr(Color.Yellow);
                write('БЫСТРЕЕ.');
            end;
        end
        else ClearLine(False);
        while KeyAvail do
        begin
            k1 := ReadKey;
            if (k1 <> k2) or (DateTime.Now.Subtract(last_key_pressed_at).TotalMilliseconds > 60) then
            begin
                last_key_pressed_at := DateTime.Now;
                k2 := k1;
                case k1 of
                    Key.LeftArrow, Key.NumPad4, Key.A, Key.OemMinus:
                        if (right_hand > 5) then
                            if (HandsGap > MIN_GAP) then right_hand -= 1 else left_hand -= 1;
                    Key.RightArrow, Key.NumPad6, Key.D, Key.OemPlus:
                        if (left_hand < (WIDTH - 10)) then
                            if (HandsGap > MIN_GAP) then left_hand += 1 else right_hand += 1;
                end;
                Cursor.GoTop(-3);
                DrawHands;
                Cursor.GoTop(+3);
                Cursor.SetLeft(0);
            end;
            _Log.PushKey(k1);
        end;
        if (attack_stage > 0) then
        begin
            if (DateTime.Now >= time_for_next_stage) then
            begin
                Cursor.SetLeft(leg_position);
                Cursor.GoTop(-5);
                if (attack_stage < TOTAL_STAGES) then attack_stage += 1 else attack_stage := 0;
                case attack_stage of
                    2, 4, 6:
                        begin
                            if (attack_stage = 2) then BeepAsync(900, stage_delay);
                            TxtClr(Color.Red);
                            write(' ↓ ↓ ↓');
                        end;
                    3, 5, 7: write(' ' * 6);
                    8:
                        begin
                            BeepAsync(300, stage_delay);
                            Cursor.GoTop(-3);
                            TxtClr(Color.Red);
                            Draw.Ascii('       ',
                                       ' │ │   ',
                                       ' │ └─┐ ',
                                       ' └───┘ ');
                            Cursor.GoXY(+1, +4);
                            write('X' * 5);
                            Cursor.GoTop(-1);
                        end;
                    12:
                        begin
                            Cursor.GoTop(-3);
                            hurt := False;
                            TxtClr(Color.Yellow);
                            Draw.Ascii(' │ │   ',
                                       ' │ └─┐ ',
                                       ' └───┘ ',
                                       '       ');
                            Cursor.GoXY(+1, +4);
                            TxtClr(Color.Gray);
                            DrawEdge;
                            Cursor.GoTop(+1);
                            DrawHands;
                            if (DateTime.Now >= last_time_damaged.AddMilliseconds(TOTAL_STAGES * stage_delay)) then
                                UpdateGrip(1 + Round(DateTime.Now.Subtract(start_time).TotalSeconds) div 15)
                            else UpdateGrip(0);
                            Cursor.GoTop(-2);
                        end;
                    13: if (grip >= MAX_HP) then Result := True;
                end;
                Cursor.GoTop(+5);
                time_for_next_stage := DateTime.Now.AddMilliseconds(stage_delay);
            end;
            if (attack_stage in 9..11) and (leg_position in (left_hand - 4)..(right_hand + 4))
            and (DateTime.Now >= last_time_damaged.AddMilliseconds(40)) and (grip > 0) then
            begin
                last_time_damaged := DateTime.Now;
                Cursor.GoTop(-3);
                case stage_delay of
                    0..20: UpdateGrip(-3);
                    21..80: UpdateGrip(-2);
                else UpdateGrip(-1);
                end;
                Result := False;
                hurt := True;
                DrawHands;
                Cursor.GoTop(+3);
            end
            else begin
                if hurt then hurt := False;
                if (attack_stage = 12) and Result then break;
            end;
        end
        else if (DateTime.Now >= time_to_stomp) then
        begin
            time_to_stomp := DateTime.Now.AddMilliseconds(TOTAL_STAGES * stage_delay + Random(1999, 4500));
            stage_delay -= stage_delay div 10;
            attack_stage := 1;
        end
        else if (DateTime.Now >= last_leg_move_time.AddMilliseconds(leg_delay)) then
        begin
            last_leg_move_time := DateTime.Now;
            if leg_is_going_right then
                if (leg_position + 5 < WIDTH) and (leg_position - Random(9, 18) < right_hand) then
                    leg_position += 1 else leg_is_going_right := False
            else if (leg_position > 0) and (leg_position + Random(9, 18) > left_hand) then
                leg_position -= 1 else leg_is_going_right := True;
            Cursor.GoTop(-8);
            Cursor.SetLeft(leg_position);
            TxtClr(Color.Yellow);
            Draw.Ascii(' │ │   ',
                       ' │ └─┐ ',
                       ' └───┘ ',
                       PadCenter(time_to_stomp.Subtract(DateTime.Now).ToString('s\.f'), 7));
            Cursor.GoTop(+8);
        end;
    end;
    _Log.Log('leg evading time: ' + DateTime.Now.Subtract(start_time).ToString);
    hurt := False;
    ClearLine(False);
    Cursor.GoTop(-3);
    Cursor.SetLeft(WIDTH + 8);
    for var i: byte := 0 to 11 do
    begin
        if (i mod 2 = 0) then TxtClr(Result ? Color.DarkCyan : Color.Yellow)
        else TxtClr(Result ? Color.Green : Color.Red);
        Draw.Text('█' * MAX_HP);
        sleep(100);
    end;
    if Result then
    begin
        TxtClr(Color.Yellow);
        Cursor.GoTop(-5);
        while not (leg_position in right_hand..(right_hand + MIN_GAP div 2)) do
        begin
            Cursor.SetLeft(leg_position);
            Draw.Ascii(' │ │   ',
                       ' │ └─┐ ',
                       ' └───┘ ',
                       '       ');
            if (leg_position < right_hand) then leg_position += 1 else leg_position -= 1;
            sleep(10);
        end;
        Cursor.SetLeft(right_hand + 1);
        Cursor.GoTop(+3);
        DrawHandGrabbingB(False);
        Cursor.GoTop(+1);
        TxtClr(Color.Gray);
        write('──');
        Cursor.GoLeft(+1);
        write('──');
        Cursor.GoXY(-5, +1);
        Draw.EraseLine(5);
        Cursor.GoTop(-4);
        sleep(80);
        BeepAsync(700, 300);
        DrawHandGrabbingA;
        Cursor.GoXY(-5, +1);
        TxtClr(Color.Gray);
        DrawEdge;
        sleep(300);
        writeln;
    end
    else begin
        DrawHands;
        Cursor.SetLeft(left_hand + 1);
        FlashHandGrabbingB;
        Cursor.GoLeft(HandsGap - 1);
        if (HandsGap > MIN_GAP) then write(' ') else Cursor.GoLeft(+1);
        FlashHandGrabbingB;
        Cursor.GoTop(+1);
        DrawEdge;
        Cursor.GoTop(+1);
        loop 12 do
        begin
            TxtClr(FiftyFifty(Color.Magenta, Color.Red));
            if (HandsGap < MIN_GAP shl 1) then
                right_hand += (HandsGap > MIN_GAP) ? FiftyFifty(+1, -1) : 1
            else right_hand -= 1;
            Cursor.SetLeft(right_hand);
            Draw.Ascii(' \ | / ',
                       '  \|/  ',
                       '   |   ');
            sleep(25);
        end;
        sleep(500);
        Cursor.SetLeft(left_hand + 1);
        Cursor.GoTop(-1);
        TxtClr(Color.Gray);
        DrawEdge;
        TxtClr(Color.Magenta);
        Cursor.GoTop(+1);
        Draw.Ascii('\ | /',
                   ' \|/ ',
                   '  |  ');
        Anim.Falling('\ | /' + ' ' * (HandsGap - MIN_GAP) + '\ | /',
                     ' \|/ ' + ' ' * (HandsGap - MIN_GAP) + ' \|/ ',
                     '  |  ' + ' ' * (HandsGap - MIN_GAP) + '  |  ');
        
    end;
    Cursor.GoTop(-7);
    sleep(500);
    ClearLines(9, True);
    TxtClr(Color.White);
    if Result then failed_attempts := 0 else failed_attempts += 1;
end;

end.