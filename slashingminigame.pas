unit SlashingMinigame;

interface

uses Actors;

type
    TypedString = ((NORM, TRUTH, RAGE), string);

procedure Init(const enemy: Actor);
procedure Load(params lines: array of TypedString);
procedure Play;
procedure Dispose;
function Completed: boolean;



implementation

uses Anim, MyTimers, Procs, Cursor, Draw, _Settings;
uses _Log;

type
    Instance = sealed class
    private
        const UPD_HP_INTERVAL: word = 500;
        const ATTACK_COOLDOWN: word = 200;
        const BOX_WIDTH: word = 53;
        const BOX_HEIGHT: word = 15; // ~BOX_WIDTH/3.5
        const HORIZ_PADDING: byte = 4;
        const LOW_HP_ZONE: byte = 9;
        
        enemy_name: string;
        health_cap: byte;
        health: shortint;
        health_line: integer;
        time_for_attack: DateTime;
        failed_attempts: word;
        loaded: List<array of TypedString>;
        upd_health_tmr: MyTimers.Timer;
        
        function HealthInBounds: boolean;
        function Middle: byte;
        function IsTimeToAttack: boolean;
        procedure UpdateHealth;
        procedure FlashHealthbar(is_win: boolean);
        procedure DrawHealthbar;
        procedure RedBorderDamage;
        procedure SlashAt(left, top: integer; textdir, animdir: Direction; hurt: boolean);
        procedure PlayLine(const s: TypedString; d: Direction);
        procedure PlayBatch(const batch: array of TypedString);
    public
        property MoreThanHalf: boolean read (health > Middle);
        procedure SetOpponent(const opponent: Actor);
        procedure AddBatch(const batch: array of TypedString);
        constructor Create;
        destructor Destroy;
        procedure Play;
    end;// class end


function IsDirectionKey(k: Key?): boolean :=
k.HasValue and (k.Value in [Key.LeftArrow, Key.RightArrow, Key.UpArrow, Key.DownArrow,
Key.W, Key.A, Key.S, Key.D, Key.NumPad2, Key.NumPad4, Key.NumPad6, Key.NumPad8]);

function ConvertKeyToDirection(k: Key): Direction;
begin
    if DEBUGMODE and not IsDirectionKey(k) then
        raise new Exception('КЛАВИША НЕИЗВЕСТНОГО НАПРАВЛЕНИЯ');
    case k of
        Key.UpArrow, Key.W, Key.NumPad8: Result := Direction.UP;
        Key.RightArrow, Key.D, Key.NumPad6: Result := Direction.RIGHT;
        Key.DownArrow, Key.S, Key.NumPad2: Result := Direction.DOWN;
        Key.LeftArrow, Key.A, Key.NumPad4: Result := Direction.LEFT;
    end; // case end
end;

function Instance.HealthInBounds: boolean := health in 3..(health_cap - 1);

function Instance.Middle: byte := health_cap div 2;

function Instance.IsTimeToAttack: boolean := (DateTime.Now > time_for_attack);

procedure Instance.UpdateHealth;
begin
    if (health > health_cap) then health := health_cap
    else if (health > 0) then health -= 1;
end;

procedure Instance.FlashHealthbar(is_win: boolean);
begin
    TxtClr(Color.Gray);
    Cursor.SetTop(health_line);
    Cursor.SetLeft(6);
    for var i: byte := 0 to 10 do
    begin
        if is_win then BgClr((i mod 2 = 0) ? Color.DarkGreen : Color.Green)
        else BgClr((i mod 2 = 0) ? Color.DarkRed : Color.Red);
        Draw.Text(' ' * health_cap);
        sleep(100);
    end;
    BgClr(Color.Black);
end;

procedure Instance.DrawHealthbar;
begin
    if not HealthInBounds then exit;
    Throw(() ->
    begin
        var h: shortint := health;
        Cursor.SetTop(health_line);
        Cursor.SetLeft(6);
        BgClr(Color.Gray);
        if MoreThanHalf then
        begin
            write(' ' * (Middle - 1));
            BgClr(Color.Magenta);
            write(' ');
            BgClr(Color.Gray);
            write(' ' * (h - Middle - 2));
            BgClr(Color.Green);
            write('   ');
            BgClr(Color.Gray);
            write(' ' * (health_cap - h - 2));
            if (h + 2 = health_cap) then write(' ');
        end
        else if (h = Middle) then
        begin
            write(' ' * (Middle - 2));
            BgClr(Color.Red);
            write(' ');
            BgClr(Color.Magenta);
            write(' ');
            BgClr(Color.Red);
            write(' ');
            BgClr(Color.Gray);
            write('   ');
        end
        else begin
            write(' ' * (h - 3));
            BgClr(Color.Red);
            write('   ');
            BgClr(Color.Gray);
            write(' ' * (Middle - h - 1));
            BgClr(Color.Magenta);
            write(' ');
            BgClr(Color.Gray);
            write(' ');
        end;
    end);
    BgClr(Color.Black);
end;

procedure Instance.RedBorderDamage;
begin
    if (health < 2) then exit;
    BeepAsync(300, 100);
    Throw(() ->
    begin
        loop 2 do
            for var g: boolean := False to True do
            begin
                TxtClr(g ? Color.Gray : Color.Red);
                Cursor.SetTop(health_line - BOX_HEIGHT - 1);
                Cursor.SetLeft(0);
                write('┌', '─' * BOX_WIDTH, '┐');
                Cursor.GoXY(-1, +1);
                Draw.TextVert('│' * BOX_HEIGHT);
                Cursor.SetLeft(0);
                Draw.TextVert('│' * BOX_HEIGHT);
                Cursor.SetTop(health_line - 1);
                write('├', '─' * BOX_WIDTH, '┤');
                writeln;
                write('│');
                Cursor.GoLeft(+BOX_WIDTH);
                writeln('│');
                writeln('└', '─' * (6 + health_cap + enemy_name.Length), '┘');
                loop (health <= LOW_HP_ZONE ? 1 : 3) do
                begin
                    health -= 1;
                    DrawHealthbar;
                    sleep(20);
                end;
            end;
    end);
    ClrKeyBuffer;
end;

procedure Instance.SlashAt(left, top: integer; textdir, animdir: Direction; hurt: boolean);
begin
    upd_health_tmr.Disable;
    ClrKeyBuffer;
    if hurt then
    begin
        loop (health_cap div 3) do
        begin
            health -= 1;
            DrawHealthbar;
            sleep(1);
        end;
        BeepAsync(260, 900);
    end
    else if (health > health_cap) then health := health_cap else
    begin
        loop 2 do
        begin
            health += 1;
            DrawHealthbar;
            sleep(1);
        end;
        if (health < LOW_HP_ZONE) then health += 1;
        DrawHealthbar;
        BeepAsync(500, 150);
    end;
    Anim.Slash(left, top, animdir);
    case textdir of
        Direction.UP, Direction.DOWN:
            begin
                Cursor.SetTop(health_line - BOX_HEIGHT);
                Cursor.GoLeft(-1);
                Draw.Erase(3, BOX_HEIGHT - 1);
            end;
        Direction.RIGHT, Direction.LEFT:
            begin
                Cursor.SetLeft(1);
                Cursor.GoTop(-2);
                Draw.Erase(BOX_WIDTH, 5);
            end;
    end; // case end
    time_for_attack := DateTime.Now.AddMilliseconds(ATTACK_COOLDOWN);
    upd_health_tmr.Enable;
end;

procedure Instance.PlayLine(const s: TypedString; d: Direction);
const
    DELAY: byte = 25;
var
    timeout: word = 800 + (failed_attempts * 200);
    reverse: boolean := (d = Direction.UP) or (d = Direction.LEFT);
    is_rage: boolean := s.Item1 = RAGE;
    is_truth := s.Item1 = TRUTH;
    len := s.Item2.Length;
    midpoint: (integer, integer);
    already_written: byte := 1;
    offset: shortint := 0;
    slashed: boolean := False;
    k: Key?;
begin
    ClrKeyBuffer;
    UpdScr;
    TxtClr(is_rage ? Color.Red : Color.Yellow);
    foreach c: char in (reverse ? s.Item2.Inverse : s.Item2) do
    begin
        DrawHealthbar;
        offset := (already_written div 2);
        case d of
            Direction.UP: midpoint := (Cursor.Left, Cursor.Top + offset);
            Direction.DOWN: midpoint := (Cursor.Left, Cursor.Top - offset);
            Direction.LEFT: midpoint := (Cursor.Left + offset, Cursor.Top);
            Direction.RIGHT: midpoint := (Cursor.Left - offset, Cursor.Top);
        end;
        write(c);
        already_written += 1;
        if KeyAvail and (already_written > 3) then
        begin
            k := ReadKey;
            _Log.PushKey(k.Value);
        end;
        if IsDirectionKey(k) and (IsTimeToAttack) then
            if is_rage then RedBorderDamage else break;
        if is_rage then k := nil;
        case d of
            Direction.UP, Direction.DOWN: Cursor.GoXY(-1, (reverse ? -1 : +1));
            Direction.LEFT: Cursor.GoLeft(-2);
        end;
        case d of
            Direction.UP, Direction.DOWN: sleep(DELAY + DELAY div 2);
            Direction.LEFT, Direction.RIGHT: sleep(DELAY);
        end;
        if not HealthInBounds then exit;
    end;
    if IsDirectionKey(k) and (IsTimeToAttack) then
        if is_rage then RedBorderDamage
        else begin
            SlashAt(midpoint.Item1, midPoint.Item2, d, ConvertKeyToDirection(k.Value), is_truth);
            slashed := True;
        end
    else begin
        var ti := DateTime.Now;
        repeat
            DrawHealthbar;
            if not HealthInBounds then exit;
            if KeyAvail then
            begin
                k := ReadKey;
                _Log.PushKey(k.Value);
                if IsDirectionKey(k) and (IsTimeToAttack) then
                    if is_rage then RedBorderDamage
                    else begin
                        SlashAt(midpoint.Item1, midpoint.Item2, d, ConvertKeyToDirection(k.Value), is_truth);
                        slashed := True;
                        break;
                    end;
            end;
        until (IsTimeToAttack) and (DateTime.Now > ti.AddMilliseconds(timeout));
    end;
    if not slashed then
    begin
        TxtClr(Color.DarkYellow);
        case d of
            Direction.UP, Direction.DOWN:
                begin
                    Cursor.GoTop(reverse ? +1 : -len);
                    Draw.TextVert(s.Item2);
                end;
            Direction.RIGHT, Direction.LEFT:
                begin
                    Cursor.GoLeft(reverse ? +1 : -len);
                    write(s.Item2);
                end;
        end; // case end
    end;
end;

procedure Instance.PlayBatch(const batch: array of TypedString);
const
    UP_BOUNDARY: integer = Cursor.Top;
    DOWN_BOUNDARY: integer = UP_BOUNDARY + BOX_HEIGHT;
var
    curdir: Direction;
    rnds: HashSet<integer>;
begin
    if (batch.Max(q -> q.ToString.Length) < BOX_HEIGHT - 4)
        then curdir := FiftyFifty(Direction.UP, Direction.DOWN)
    else curdir := FiftyFifty(Direction.LEFT, Direction.RIGHT);
    try
        rnds := new HashSet<integer>;
        case curdir of
            Direction.UP, Direction.DOWN:
                foreach i: integer in Range(HORIZ_PADDING, (BOX_WIDTH - HORIZ_PADDING), 4) do
                    rnds.Add(i);
            Direction.LEFT, Direction.RIGHT:
                foreach i: integer in Range(UP_BOUNDARY + 3, DOWN_BOUNDARY - 2, 3) do
                    rnds.Add(i);
        end;
        for var x: byte := 0 to (batch.Length - 1) do
        begin
            var r: integer := rnds.ElementAt(Random(rnds.Count));
            case curdir of
                Direction.UP, Direction.DOWN: Cursor.SetLeft(r);
                Direction.LEFT, Direction.RIGHT: Cursor.SetTop(r);
            end;
            rnds.Remove(r);
            var len: integer := batch[x].ToString.Length;
            case curdir of
                Direction.UP: Cursor.SetTop(Random(UP_BOUNDARY + len + 2, DOWN_BOUNDARY - 3));
                Direction.RIGHT: Cursor.SetLeft(Random(HORIZ_PADDING - 1, BOX_WIDTH - HORIZ_PADDING - len + 2));
                Direction.DOWN: Cursor.SetTop(Random(UP_BOUNDARY + 3, DOWN_BOUNDARY - len - 2));
                Direction.LEFT: Cursor.SetLeft(Random(HORIZ_PADDING + len, BOX_WIDTH - HORIZ_PADDING));
            end;
            PlayLine(batch[x], curdir);
            if not HealthInBounds then exit;
            DrawHealthbar;
            case curdir of
                Direction.UP: curdir := Direction.DOWN;
                Direction.RIGHT: curdir := Direction.LEFT;
                Direction.DOWN: curdir := Direction.UP;
                Direction.LEFT: curdir := Direction.RIGHT;
            end;
        end;
    finally
        if (rnds <> nil) then
        begin
            rnds.Clear;
            rnds := nil;
        end;
    end;
end;

procedure Instance.AddBatch(const batch: array of TypedString);
begin
    if DEBUGMODE then
    begin
        if (batch.Length = 0) then
            raise new Exception('НЕТ СТРОК В SLASHINGMINIGAME.LOAD()')
        else if batch.Any(q -> q.ToString.Length = 0) then
            raise new Exception('ПУСТАЯ СТРОКА В SLASHINGMINIGAME.LOAD()')
        else if (batch.Length > ((BOX_WIDTH div 4) - 1)) then
            raise new Exception('SLASHINGMINIGAME.LOAD(): СЛИШКОМ МНОГО ВЕРТ. СТРОК'
                                + $' (МАКС {(BOX_WIDTH div 4) - 1} ПОЛУЧЕНО {batch.Length})')
        else if (batch.Max(q -> q.ToString.Length) >= BOX_HEIGHT - 4) then
        begin
            if (batch.Length > BOX_HEIGHT div 3 - 1) then
                raise new Exception('SLASHINGMINIGAME.LOAD(): СЛИШКОМ МНОГО ГОРИЗ. СТРОК'
                                + $' (МАКС {(BOX_HEIGHT div 3) - 1} ПОЛУЧЕНО {batch.Length})');
            if (batch.Max(q -> q.ToString.Length) > BOX_WIDTH - 6) then
                raise new Exception('SLASHINGMINIGAME.LOAD(): СТРОКА "' + batch.MaxBy(q -> q.ToString.Length).ToString
                                + '" НЕ ВЛЕЗАЕТ ПРИ DIRECTION=left/right');
        end;
    end;
    loaded.Add(batch);
end;

constructor Instance.Create;
begin
    health_cap := BOX_WIDTH - 6;
    health := Middle;
    loaded := new List<array of TypedString>;
    upd_health_tmr := new MyTimers.Timer(UPD_HP_INTERVAL, UpdateHealth);
end;

destructor Instance.Destroy;
begin
    if (loaded <> nil) then
    begin
        loaded.Clear;
        loaded := nil;
    end;
    if (upd_health_tmr <> nil) then
    begin
        upd_health_tmr.Destroy;
        upd_health_tmr := nil;
    end;
    enemy_name := nil;
end;

procedure Instance.SetOpponent(const opponent: Actor);
begin
    enemy_name := opponent.name.ToUpper;
    health_cap := BOX_WIDTH - (6 + enemy_name.Length);
    health := Middle;
end;

procedure Instance.Play;
begin
    if not DEBUGMODE then exit;
    if (loaded = nil) or (loaded.Count = 0) then
        raise new Exception('НЕ ЗАГРУЖЕНЫ СТРОКИ ЧЕРЕЗ Load()');
    if NilOrEmpty(enemy_name) then
        raise new Exception('НЕ УКАЗАНО ИМЯ ПРОТИВНИКА');
    Anim.Next3;
    Throw(() ->
    begin
        Draw.Box(BOX_WIDTH, BOX_HEIGHT - 1);
        Cursor.GoTop(-1);
        Draw.Box((6 + health_cap + enemy_name.Length), 1);
        Cursor.GoTop(-3);
        writeln('├', '─' * (6 + health_cap + enemy_name.Length), '┤');
        health_line := Cursor.Top;
        DrawHealthbar;
        Cursor.SetLeft(1);
        TxtClr(Actors.Sanya.color);
        print(Actors.Sanya.name.ToUpper);
        BgClr(Color.Gray);
        write(' ' * health_cap);
        TxtClr(Color.Red);
        BgClr(Color.Black);
        writeln(' ', enemy_name)
    end);
    upd_health_tmr.Enable;
    time_for_attack := DateTime.Now;
    foreach strarr: array of TypedString in loaded do
    begin
        Cursor.SetTop(health_line - BOX_HEIGHT);
        Cursor.SetLeft(1);
        DrawHealthBar;
        Draw.Erase(BOX_WIDTH - 1, BOX_HEIGHT - 1);
        PlayBatch(strarr);
        if not HealthInBounds then break;
    end;
    FlashHealthbar(MoreThanHalf);
    Cursor.SetTop(health_line - BOX_HEIGHT - 1);
    Cursor.SetLeft(0);
    TxtClr(Color.White);
    ClearLines(BOX_HEIGHT + 5, True);
    if MoreThanHalf then failed_attempts := 0 else failed_attempts += 1;
end;

var
    current: Instance;
    success: boolean;

procedure Load(params lines: array of TypedString) := current.AddBatch(lines);

procedure Play;
begin
    if DEBUGMODE and (current = nil) then
        raise new Exception('НЕТ ИНИЦИАЛИЗРОВАННОЙ МИНИ-ИГРЫ (см. Init())');
    current.Play;
    success := current.MoreThanHalf;
end;

procedure Init(const enemy: Actor);
begin
    current := new Instance;
    current.SetOpponent(enemy);
end;

procedure Dispose;
begin
    success := False;
    if (current = nil) then exit;
    current.Destroy;
    current := nil;
end;

function Completed: boolean := success;

end.