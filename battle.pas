unit Battle;

interface

uses Aliases, Items, Actors;

type
    ActionEnum = (NUL, ATK, DEF, SPE, INV);

/// создать новую битву против enemy с шкалами здоровья hp_self и hp_enemy пунктов
procedure Start(const enemy: Actor; hp_self: byte; hp_enemy: byte);
/// завершить текущую битву
procedure Finish;
/// выбрать действие из меню: ATK/DEF/INV
procedure Choose;
/// выбрать действие из меню: ATK/DEF/SPE/INV
procedure Choose(const special_string: string);
/// выбрать действие из меню: ATK/DEF/INV
/// таймер на seconds секунд, по истечению автоматически выбирается NUL
procedure Choose(seconds: byte);
/// выбрать действие из меню: ATK/DEF/SPE/INV
/// таймер на seconds секунд, по истечению автоматически выбирается NUL
procedure Choose(seconds: byte; const special_string: string);
/// последний сохранённый результат выбора в меню (в т.ч. NUL)
function LastChoice: ActionEnum;
/// последний сохранённый результат выбора предмета в меню инвентаря (в т.ч. nil)
function ChosenItem: Item?;
/// нанести врагу урон damage пунктов (только визуально)
procedure HitEnemy(damage: byte);
/// нанести игроку урон damage пунктов (только визуально)
procedure HitSelf(damage: byte);
/// восстановить игроку health пунктов здоровья (только визуально)
procedure HealSelf(health: byte);
/// остались ли пункты здоровья у игрока
function SelfAlive: boolean;
/// остались ли пункты здоровья у врага
function EnemyAlive: boolean;



implementation

uses Procs, Cursor, Inventory, Draw, Anim;
uses _Log;

type
    TimeSpan = System.TimeSpan;
    Instance = class
    private
        const ATTACK: string = 'атаковать';
        const DEFEND: string = 'защищаться';
        const USEITEM: string = 'использовать предмет';
        const BACKARROW: string = '<--';
        const PROMPT: string = '>>> ';
        const SQUARE: char = '■';
        const DEAD: char = 'X';
        
        selectres: ActionEnum;
        itemres: Item?;
        self_name, enemy_name: string;
        visible_enemy_name, visible_self_name: string;
        enemy_hp, self_hp: shortint;
        enemy_hp_max, self_hp_max: byte;
        message_point: (integer, integer);
        hp_bars_topleft: integer;
        
        static function BuildCommands(const special: string): array of string;
        static function BuildSubmenu: array of string;
        procedure MoveCursorToMsgPoint;
        procedure MoveCursorToStartingPoint;
        procedure PrintTime(const time: TimeSpan);
        static procedure DrawHpBar(const name: string; namecolor: Color; width, hp: byte);
        procedure DrawHpBars;
        procedure EraseMsg;
    public
        constructor Create(const player_name: string; hp1: byte; const opponent_name: string; hp2: byte);
        destructor Destroy;
        procedure Select(secs: byte; const special_action: string);
        procedure DamageSelf(dmg: byte);
        procedure DamageEnemy(dmg: byte);
        procedure MendSelf(hp: byte);
        procedure Visualize;
        procedure Revisualize;
        procedure EraseHpBars;
        property SelfHealth: shortint read self_hp;
        property EnemyHealth: shortint read enemy_hp;
    end;
// TYPE END

static function Instance.BuildCommands(const special: string): array of string;
var
    l: List<string>;
begin
    try
        l := new List<string>;
        l.Add(ATTACK);
        l.Add(DEFEND);
        if not NilOrEmpty(special) then l.Add(special);
        if not Inventory.IsEmpty then l.Add(USEITEM);
        Result := l.ToArray;
    finally
        if (l <> nil) then
        begin
            l.Clear;
            l := nil;
        end;
    end;
end;

static function Instance.BuildSubmenu: array of string := Inventory.GetItems.Select(q -> q.name).Prepend(BACKARROW).ToArray;

procedure Instance.MoveCursorToMsgPoint;
begin
    Cursor.SetLeft(message_point.Item1);
    Cursor.SetTop(message_point.Item2);
end;

procedure Instance.MoveCursorToStartingPoint;
begin
    Cursor.SetLeft(0);
    Cursor.SetTop(hp_bars_topleft);
end;

procedure Instance.PrintTime(const time: TimeSpan);
begin
    Throw(() ->
    begin
        MoveCursorToMsgPoint;
        if (time <= TimeSpan.Zero) then TxtClr(Color.Red)
        else if (time.TotalSeconds < 3) and (time.Milliseconds mod 250 > 125) then TxtClr(Color.Magenta)
        else TxtClr(Color.Yellow);
        write(time <= TimeSpan.Zero ? '00.00' : time.ToString('ss\.ff'));
    end);
end;

static procedure Instance.DrawHpBar(const name: string; namecolor: Color; width, hp: byte);
begin
    TxtClr(Color.White);
    var left_offset: smallint := (width - name.Length) div 2;
    Draw.Text(' ' * left_offset + '┌' + '─' * name.Length + '┐');
    Cursor.GoTop(+1);
    Throw(() -> 
    begin
        write('┌', '─' * (left_offset - 1), '┘');
        TxtClr(namecolor);
        write(name);
        TxtClr(Color.White);
        write('└', '─' * (left_offset - 1 - width mod 2 + name.Length mod 2), '┐');
    end);
    Cursor.GoTop(+1);
    write('│');
    TxtClr(Color.Green);
    write(Instance.SQUARE * hp);
    Cursor.GoLeft(width - hp);
    TxtClr(Color.White);
    write('│');
    Cursor.GoXY(-width - 2, +1);
    write('└', '─' * width, '┘');
end;

procedure Instance.DrawHpBars;
begin
    while (Cursor.Top + MIN_HEIGHT > Console.WindowTop + Console.WindowHeight)
    and (Console.WindowTop < hp_bars_topleft) do
    begin
        Console.WindowTop += 1;
        sleep(4);
    end;
    DrawHpBar(visible_self_name, Color.Green, self_hp_max, self_hp);
    MoveCursorToMsgPoint;
    Cursor.GoXY(+5, -2);
    DrawHpBar(visible_enemy_name, Color.Red, enemy_hp_max, enemy_hp);
    writeln;
end;

procedure Instance.Visualize;
begin
    Anim.Next3;
    hp_bars_topleft := Cursor.Top;
    DrawHpBars;
    Throw(() ->
    begin
        MoveCursorToMsgPoint;
        TxtClr(Color.Cyan);
        write(' V S ');
    end);
    Anim.Next3;
    Throw(() ->
    begin
        MoveCursorToMsgPoint;
        TxtClr(Color.Magenta);
        Draw.Text('FIGHT');
        BeepWait(400, 600);
        write(' ' * 5);
    end);
end;

procedure Instance.Revisualize;
begin
    EraseHpBars;
    hp_bars_topleft := Cursor.Top;
    message_point := (self_hp_max + 2, Cursor.Top + 2);
    DrawHpBars;
end;

procedure Instance.EraseHpBars;
begin
    Anim.Next3;
    Throw(() ->
    begin
        Cursor.SetTop(hp_bars_topleft);
        ClearLines(5, True);
        TxtClr(Color.DarkGray);
        writeln('─┘');
        TxtClr(Color.DarkGreen);
        writeln(self_name, ': ', (self_hp > 0) ? (Instance.SQUARE * self_hp) : DEAD);
        TxtClr(Color.DarkRed);
        writeln(enemy_name, ': ', (enemy_hp > 0) ? (Instance.SQUARE * enemy_hp) : DEAD);
        TxtClr(Color.DarkGray);
        writeln('─┐');
    end);
end;

procedure Instance.EraseMsg;
begin
    Throw(() ->
    begin
        MoveCursorToMsgPoint;
        Cursor.GoTop(-1);
        Draw.Erase(5, 3);
        Cursor.GoTop(+1);
    end);
end;

function ToVisibleName(const name: string; width: byte): string;
begin
    Result := name.ToUpper.ToCharArray.JoinToString(' ');
    if (Result.Length + 2 > width) then Result := name.ToUpper
    else repeat
            var next: string := Result.Replace(' ', '   ');
            if (next.Length + 2 > width) then break;
            Result := next;
        until False;
end;

constructor Instance.Create(const player_name: string; hp1: byte; const opponent_name: string; hp2: byte);
begin
    self_name := player_name;
    enemy_name := opponent_name;
    self_hp_max := hp1;
    enemy_hp_max := hp2;
    self_hp := self_hp_max;
    enemy_hp := enemy_hp_max;
    message_point := (self_hp_max + 2, Cursor.Top + 3);
    {$omp parallel sections}
    begin
        visible_self_name := ToVisibleName(self_name, self_hp_max);
        visible_enemy_name := ToVisibleName(enemy_name, enemy_hp_max);
    end;
end;

destructor Instance.Destroy;
begin
    itemres := nil;
    self_name := nil;
    enemy_name := nil;
    visible_enemy_name := nil;
    visible_self_name := nil;
    message_point := nil;
end;

procedure Instance.Select(secs: byte; const special_action: string);
var
    time_limit: boolean;
    submenu: boolean := False;
    point: shortint;
    k: Key;
    _CMDS: array of string := BuildCommands(special_action);
    _ITMS: array of string := BuildSubmenu;
    options: array of string;
    cur_prompt: string;
    starttime, endtime: DateTime;
begin
    time_limit := (secs > 0);
    selectres := NUL;
    itemres := nil;
    Revisualize;
    MoveCursorToMsgPoint;
    Cursor.GoTop(-1);
    TxtClr(Color.Blue);
    writeln('ВРЕМЯ', NewLine);
    WritelnX2;
    var o_p: () -> string := () -> cur_prompt + options[point];
    if time_limit then
    begin
        starttime := DateTime.Now;
        endtime := starttime.AddSeconds(secs);
    end
    else Throw(() -> 
        begin
            MoveCursorToMsgPoint;
            TxtClr(Color.Yellow);
            write('  ∞');
        end);
    try
        repeat
            point := 0;
            TxtClr(Color.Gray);
            options := submenu ? _ITMS : _CMDS;
            cur_prompt := submenu ? (TAB + PROMPT) : PROMPT;
            UpdScr;
            foreach st: string in options do writeln(cur_prompt, st);
            Cursor.GoTop(-options.Length);
            TxtClr(Color.Yellow);
            Draw.Text(o_p);
            ClrKeyBuffer;
            repeat
                if time_limit then PrintTime(endtime - DateTime.Now);
                if KeyAvail then
                begin
                    k := ReadKey;
                    Cursor.GoTop(+point);
                    TxtClr(Color.Gray);
                    Draw.Text(o_p);
                    Cursor.GoTop(-point);
                    case k of
                        {-} Key.Enter, Key.Tab, Key.Select, Key.Spacebar, Key.NumPad5:
                        break;
                        {-} Key.UpArrow, Key.NumPad8, Key.W, Key.LeftArrow, Key.NumPad4, Key.A, Key.OemMinus:
                        point -= 1;
                        {-} Key.DownArrow, Key.NumPad2, Key.S, Key.RightArrow, Key.NumPad6, Key.D, Key.OemPlus:
                        point += 1;
                    end; // case end
                    if (point < 0) then point := (options.Length - 1) // underflow
                    else if (point + 1 > options.Length) then point := 0; // overflow
                    Cursor.GoTop(+point);
                    TxtClr(Color.Yellow);
                    Draw.Text(o_p);
                    Cursor.GoTop(-point);
                end;
                if time_limit and (DateTime.Now >= endtime) then
                begin
                    ClearLines((options.Length + 1), True);
                    PrintTime(TimeSpan.Zero);
                    TxtClr(Color.White);
                    BeepWait(400, 1000);
                    exit;
                end;
            until False;
            case options[point] of
                BACKARROW, USEITEM:
                    begin
                        if submenu then
                        begin
                            ClearLines((options.Length + 1), True);
                            Cursor.GoTop(-_CMDS.Length);
                        end
                        else Cursor.GoTop(+_CMDS.Length);
                        submenu := not submenu;
                        continue;
                    end;
            else ClearLines((options.Length + 1), True);
            end; // case end
        until True;
    finally
        EraseMsg;
    end;
    TxtClr(Color.Gray);
    if not submenu then
    begin
        case options[point] of
            ATTACK: selectres := ATK;
            DEFEND: selectres := DEF;
        else selectres := SPE;
        end; // case end
        write(o_p, NewLine);
    end
    else if (point <> 0) then
    begin
        selectres := INV;
        Cursor.GoTop(-_CMDS.Length);
        ClearLines((_CMDS.Length + 1), True);
        write(PROMPT, USEITEM, ': ');
        TxtClr(Color.DarkYellow);
        writeln('[', options[point], ']');
        itemres := Inventory.GetItems.First(q -> q.Name.Equals(options[point]));
    end;
    writeln;
    TxtClr(Color.White);
    _Log.Log($'= битва: {selectres} [{itemres}]');
end;

function Upscaled(change: shortint; scale: word): string;
begin
    Result := (change > 0) ? '+' : '-';
    if Abs(change) > scale then Result += '9999'
    else begin
        var zeroes: byte;
        case (scale div Abs(change)) of
            1, 2: zeroes := 3;
            3, 4: zeroes := 2;
        else zeroes := 1;
        end; // case end
        var a := Round(10 ** zeroes);
        var b := a * 10 - 1;
        Result += Random(a, b).ToString;
    end;
end;

procedure CritMsg;
begin
    TxtClr(Color.Magenta);
    Cursor.GoTop(-1);
    write('КРИТ.');
    Cursor.GoXY(-5, +2);
    write('УРОН!');
end;

procedure CritHit(clr: Color);
begin
    var original_clr := CurClr;
    TxtClr(clr);
    writeln('Критический урон!');
    TxtClr(original_clr);
end;

procedure Instance.DamageSelf(dmg: byte);
begin
    BeepAsync(360, 400);
    var shown: string := Upscaled(-dmg, self_hp_max).PadRight(5);
    if (dmg > self_hp) then dmg := self_hp_max;
    var critical: boolean := (dmg >= self_hp_max div 2);
    if critical then CritHit(Color.Red);
    var squares: string := Instance.SQUARE * dmg;
    Throw(() ->
    begin
        EraseMsg;
        for var i: byte := 0 to 9 do
        begin
            MoveCursorToMsgPoint;
            TxtClr((i mod 2 = 0) ? Color.Yellow : Color.Red);
            Draw.Text(shown);
            if critical then Throw(CritMsg);
            Cursor.GoLeft(-1 - dmg);
            write(squares);
            sleep(100);
        end;
        Cursor.GoLeft(-dmg);
        write(' ' * dmg);
    end);
    _Log.Log($'= self_hp: {self_hp}->{self_hp-dmg}');
    self_hp -= dmg;
    EraseMsg;
end;

procedure Instance.DamageEnemy(dmg: byte);
begin
    BeepAsync(400, 400);
    var shown: string := Upscaled(-dmg, enemy_hp_max).PadLeft(5);
    if (enemy_hp - dmg < 0) then dmg := enemy_hp;
    var critical: boolean := (dmg >= self_hp_max div 2);
    if critical then CritHit(Color.Magenta);
    var squares: string := Instance.SQUARE * dmg;
    Throw(() ->
    begin
        EraseMsg;
        for var i: byte := 0 to 9 do
        begin
            MoveCursorToMsgPoint;
            TxtClr((i mod 2 = 0) ? Color.Yellow : Color.Red);
            Draw.Text(shown);
            if critical then Throw(CritMsg);
            Cursor.GoLeft(+shown.Length + 1 + enemy_hp - dmg);
            write(squares);
            sleep(100);
        end;
        Cursor.GoLeft(-dmg);
        write(' ' * dmg);
    end);
    _Log.Log($'= enemy_hp: {enemy_hp}->{enemy_hp-dmg}');
    enemy_hp -= dmg;
    EraseMsg;
end;

procedure Instance.MendSelf(hp: byte);
begin
    BeepAsync(700, 400);
    var shown: string := Upscaled(hp, self_hp_max).PadRight(5);
    while (self_hp + hp > self_hp_max) do hp -= 1;
    Throw(() ->
    begin
        EraseMsg;
        for var i: byte := 0 to 9 do
        begin
            MoveCursorToMsgPoint;
            TxtClr((i mod 2 = 0) ? Color.Yellow : Color.Green);
            Draw.Text(shown);
            Cursor.SetLeft(+1 + self_hp);
            write(((i mod 2 = 0) ? Instance.SQUARE : ' ') * hp);
            sleep(100);
        end;
        Cursor.GoLeft(-hp);
        write(Instance.SQUARE * hp);
    end);
    _Log.Log($'= self_hp: {self_hp}->{self_hp+hp}');
    self_hp += hp;
    EraseMsg;
end;

var
    current: Instance;



function CapSecs(secs: byte) := (secs < 60) ? secs : 60;

procedure Choose() := current.Select(0, nil);

procedure Choose(const special_string: string) := current.Select(0, nil);

procedure Choose(seconds: byte) := current.Select(CapSecs(seconds), nil);

procedure Choose(seconds: byte; const special_string: string) := current.Select(CapSecs(seconds), special_string);

function LastChoice: ActionEnum := current.selectres;

function ChosenItem: Item? := current.itemres;

procedure Start(const enemy: Actor; hp_self: byte; hp_enemy: byte);
begin
    current := new Instance(Actors.Sanya.name.ToUpper, hp_self, enemy.name.ToUpper, hp_enemy);
    current.Visualize;
end;

procedure Finish;
begin
    current.EraseHpBars;
    current.Destroy;
    current := nil;
end;

procedure HitEnemy(damage: byte) := current.DamageEnemy(damage);

procedure HitSelf(damage: byte) := current.DamageSelf(damage);

procedure HealSelf(health: byte) := current.MendSelf(health);

function SelfAlive: boolean := (current.SelfHealth > 0);

function EnemyAlive: boolean := (current.EnemyHealth > 0);

end.