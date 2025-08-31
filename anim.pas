unit Anim;

interface

type
    Direction = (UP, RIGHT, DOWN, LEFT);

procedure Text(const s: string; delay: word);
procedure Next1;
procedure Next3;
procedure Objection;
procedure TakeThat;
procedure Slash(left, top: integer; dir: Direction);
procedure Falling(params sprite: array of string);



implementation

uses Aliases, Procs, Tutorial, Cursor, Draw;

procedure Text(const s: string; delay: word);
begin
    foreach c: char in s do
    begin
        write(c);
        sleep(delay);
    end
end;

function CursorIsAboveBound: boolean := (Console.WindowTop + Console.WindowHeight >= Cursor.Top);

procedure Next1;
begin
    ClrKeyBuffer;
    DoWithoutUpdScr(() ->
    begin
        UpdScr;
        var cycle: boolean;
        repeat
            if System.Threading.SpinWait.SpinUntil(() -> KeyAvail, 330) then break
            else if CursorIsAboveBound then
            begin
                write(cycle ? #8#32#8 : '>');
                cycle := not cycle;
            end;
        until False;
        if cycle then write(#8#32#8);
    end);
    ClrKeyBuffer;
end;

procedure Next3;
begin
    writelnx2;
    if not Tutorial.AnimNextH.Shown then
    begin
        Tutorial.Comment('любая клавиша чтобы продолжить');
        Cursor.GoTop(-1);
    end;
    Cursor.GoTop(-1);
    TxtClr(Color.Gray);
    ClrKeyBuffer;
    DoWithoutUpdScr(() ->
    begin
        var len: byte;
        repeat
            if (BufWidth < MIN_WIDTH) then Console.BufferWidth := MIN_WIDTH;
            System.Threading.SpinWait.SpinUntil(() -> KeyAvail, 230);
            if CursorIsAboveBound then
            begin
                if (len = 3) then
                begin
                    write(#8 * 3, ' ' * 3, #8 * 3);
                    len := 0;
                end
                else begin
                    write('>');
                    len += 1;
                end;
            end;
        until KeyAvail;
        ClearLine(False);
        UpdScr;
    end);
    if not Tutorial.AnimNextH.Shown then
    begin
        Cursor.GoTop(+1);
        ClearLine(False);
        Cursor.GoTop(-1);
        Tutorial.AnimNextH.Show;
    end;
    TxtClr(Color.White);
    ClrKeyBuffer
end;

procedure ObjectionSplash(takethat: boolean);
begin
    var msg: string;
    if takethat then msg := 'TAKE THAT!'
    else case Random(3) of
            0: msg := 'OBJECTION!';
            1: msg := 'HOLD IT!';
            2: msg := 'NO, THAT''S WRONG!';
        end; // case end
    writeln;
    var frame: byte := 0;
    repeat
        var left_mov: integer;
        if (frame > 8) and (Cursor.Left > 0) then left_mov := -1
        else if (Cursor.Left = 0) then left_mov := +1
        else left_mov := Random(-1, +1);
        var top_mov: integer := Random(1, 2);
        Cursor.GoXY(left_mov, top_mov);
        Draw.ObjectionSplash(msg);
        sleep(35);
        Draw.Erase(30, 3);
        Cursor.GoTop(-top_mov);
        Draw.ObjectionSplash(msg);
        sleep(30);
        if (frame > 8) and (Cursor.Left = 0) then break;
        Draw.Erase(30, 3);
        frame += 1;
    until False;
    BeepWait(800, 500);
    Cursor.GoTop(+4);
end;

procedure Objection := ObjectionSplash(False);

procedure TakeThat := ObjectionSplash(True);

procedure Slash(left, top: integer; dir: Direction);
const
    delay: byte = 35;
begin
    Cursor.SetLeft(left);
    Cursor.SetTop(top);
    var chr_a: char;
    case Random(3) of
        0: chr_a := '/';
        1: chr_a := '\';
        2:
            case dir of
                Direction.LEFT, Direction.RIGHT: chr_a := '-';
                Direction.DOWN, Direction.UP: chr_a := '|';
            end;
    end;
    var orig_cur_left: integer := Cursor.Left;
    var orig_cur_top: integer := Cursor.Top;
    var orig_color: Color := CurClr;
    TxtClr(Color.Red);
    for var erase: boolean := False to True do
    begin
        var chr_b: char := (erase ? ' ' : chr_a);
        case chr_a of
            '/':
                case dir of
                    Direction.UP, Direction.RIGHT:
                        begin
                            Cursor.GoXY(-2, +2);
                            loop 4 do
                            begin
                                Text(chr_b, delay);
                                Cursor.GoTop(-1);
                            end;
                            Text(chr_b, delay);
                        end;
                    Direction.DOWN, Direction.LEFT:
                        begin
                            Cursor.GoXY(+2, -2);
                            loop 4 do
                            begin
                                Text(chr_b, delay);
                                Cursor.GoXY(-2, +1);
                            end;
                            Text(chr_b, delay);
                        end;
                end;
            '\':
                case dir of
                    Direction.UP, Direction.LEFT:
                        begin
                            Cursor.GoXY(+2, +2);
                            loop 4 do
                            begin
                                Text(chr_b, delay);
                                Cursor.GoXY(-2, -1);
                            end;
                            Text(chr_b, delay);
                        end;
                    Direction.DOWN, Direction.RIGHT:
                        begin
                            Cursor.GoXY(-2, -2);
                            loop 4 do
                            begin
                                Text(chr_b, delay);
                                Cursor.GoTop(+1);
                            end;
                            Text(chr_b, delay);
                        end;
                end;
            '-':
                if (dir = Direction.RIGHT) then
                begin
                    Cursor.GoLeft(-3);
                    Text(chr_b * 7, delay);
                end
                else begin
                    Cursor.GoLeft(+3);
                    loop 6 do
                    begin
                        Text(chr_b, delay);
                        Cursor.GoLeft(-2);
                    end;
                    Text(chr_b, delay);
                end;
            '|':
                if (dir = Direction.DOWN) then
                begin
                    Cursor.GoTop(-2);
                    loop 4 do
                    begin
                        Text(chr_b, delay);
                        Cursor.GoXY(-1, +1);
                    end;
                    Text(chr_b, delay);
                end
                else begin
                    Cursor.GoTop(+2);
                    loop 4 do
                    begin
                        Text(chr_b, delay);
                        Cursor.GoXY(-1, -1);
                    end;
                    Text(chr_b, delay);
                end;
        end; // case chr end
        if not erase then sleep(delay * 6);
        Cursor.SetLeft(orig_cur_left);
        Cursor.SetTop(orig_cur_top);
    end;
    TxtClr(orig_color);
end;

procedure Falling(params sprite: array of string);
begin
    var max_len: integer := sprite.Max(q -> q.Length);
    sprite := sprite.Prepend(' ' * max_len).ToArray;
    DoWithoutUpdScr(() ->
    begin
        var original_cur_top: integer := Cursor.Top;
        var original_win_top: integer := Console.WindowTop;
        var altitude: () -> integer := () -> (Console.WindowTop + Console.WindowHeight - Cursor.Top);
        UpdScr;
        while (altitude > 0) do
        begin
            Draw.Ascii(sprite);
            Cursor.GoTop(+1);
            Console.WindowTop := original_win_top;
            sleep(65 div (altitude div MIN_HEIGHT + 1));
        end;
        Console.CursorTop := original_cur_top;
        UpdScr;
    end);
end;

end.