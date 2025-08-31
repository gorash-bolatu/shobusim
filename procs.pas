unit Procs;

interface

uses Aliases;

/// цвет текста
procedure TxtClr(clr: Color);
/// цвет фона
procedure BgClr(clr: Color);
/// текущий цвет текста
function CurClr: Color;
/// текущая ширина буфера консоли
function BufWidth: integer;
/// асихронный Console.Beep()
procedure BeepAsync(frequency: word; duration: integer);
/// ожидающий Console.Beep()
procedure BeepWait(frequency: word; duration: integer);
/// подогнать размер окна
procedure UpdScr;
/// вычислить значение функции func с временно отключенной перерисовкой экрана
function ComputeWithoutUpdScr<T>(func: () -> T): T;
/// выполнить proc с временно отключенной перерисовкой экрана
procedure DoWithoutUpdScr(proc: procedure);
/// выполнить proc, затем вернуть назад позицию курсора и цвет текста
procedure Throw(proc: procedure);
/// очистка строки
procedure ClearLine(previous_line: boolean);
/// очистка нескольких строк подряд
procedure ClearLines(lines: integer; return_cursor: boolean);
/// нажата ли любая клавиша
function KeyAvail: boolean;
/// очистка экрана
procedure ClrScr;
/// считывание нажатой клавиши
function ReadKey: Key;
/// очищение очереди символов в консоли
procedure ClrKeyBuffer;
/// "нажмите Y/N"
function YN: boolean;
/// нарисовать линию из знаков равно
procedure WriteEqualsLine;
/// writeln дважды
procedure WritelnX2;
/// разбиение текста на строки чтобы он вписывался в доступную ширину
function WordWrap(const str: string; width: longword; separator: string := NewLine): string;
/// выравнивает строку по центру с заполнением проблеами по длине n
function PadCenter(const s: string; n: integer): string;
/// случайный 50% шанс на возврат a или b
function FiftyFifty<T>(a, b: T): T;
/// сборка мусора вручную
procedure CollectGarbage;
/// ввод + парсинг команды с подсказкой prompt
procedure ReadCmd(prompt: string := '');
/// последний сохранённый результат успешно введённой команды
function LastCmdResult: string;
/// возвращает ввёденную строку с подсказкой prompt
function ReadInput(prompt: string := ''): string;
/// обёртка для комнат побега
procedure EscapeRoom(proc: procedure);
/// принудительно перевести windows в спящий режим
procedure SleepMode;
/// обработчик исключений
procedure Catch(const ex: Exception);



implementation

uses Cursor, MyTimers, Inventory, Parser, Anim;
uses _Log, _Assemblies;

var
    /// Сюда загоняется результат ReadCmd
    cmdres: string;
    /// Таймер для постоянного восстановления размеров окна
    upd_scr_tmr: MyTimers.Timer;


procedure TxtClr(clr: Color) := Console.ForegroundColor := clr;

procedure BgClr(clr: Color) := Console.BackgroundColor := clr;

function CurClr: Color := Console.ForegroundColor;

function BufWidth: integer := Console.BufferWidth;

procedure BeepAsync(frequency: word; duration: integer);
begin
    System.Threading.Tasks.Task.Run(() -> Console.Beep(frequency, duration));
end;

procedure BeepWait(frequency: word; duration: integer);
begin
    Console.Beep(frequency, duration);
    sleep(duration);
end;

function ElapsedMS: longword := longword(Milliseconds);

procedure UpdScr;
begin
    if (BufWidth < MIN_WIDTH) then
    begin
        Console.BufferWidth := MIN_WIDTH;
        Console.WindowWidth := BufWidth;
    end;
    if (Console.WindowHeight < MIN_HEIGHT) then Console.WindowHeight := MIN_HEIGHT;
    if (Cursor.Top + MaxByte >= Console.BufferHeight) then Console.BufferHeight += MaxByte;
    if Cursor.HIDE_ON_UPDSCR then Console.CursorVisible := False;
    Cursor.Find;
end;

procedure ClearLine(previous_line: boolean);
begin
    UpdScr;
    Cursor.SetLeft(0);
    if previous_line then Cursor.GoTop(-1);
    write(' ' * (BufWidth - 1));
    Cursor.SetLeft(0)
end;

procedure ClearLines(lines: integer; return_cursor: boolean);
begin
    UpdScr;
    var original_cursor_top: integer := Cursor.Top;
    Cursor.SetLeft(0);
    loop lines do writeln(' ' * (BufWidth - 1));
    Cursor.SetLeft(0);
    if return_cursor then Cursor.SetTop(original_cursor_top);
end;

function KeyAvail: boolean := Console.KeyAvailable;

procedure ClrScr := Console.Clear;

function ReadKey: Key := Console.ReadKey(True).Key;

procedure ClrKeyBuffer := while KeyAvail do ReadKey;

function YN: boolean;
begin
    ClrKeyBuffer;
    repeat
        case ComputeWithoutUpdScr(() -> ReadKey) of
            Key.Y: Result := True;
            Key.N: Result := False;
        else continue
        end;
    until True;
end;

procedure WriteEqualsLine;
begin
    var original_cur_top: integer := Cursor.Top;
    write('=' * BufWidth);
    if (Cursor.Top = original_cur_top) then writeln;
end;

procedure WritelnX2 := writeln(NewLine);

function WordWrap(const str: string; width: longword; separator: string): string;
begin
    if NilOrEmpty(str) or (width = 0) then exit;
    // разбить текст на строки
    var lines: array of string := Regex.Split(str, '\r\n|\r|\n');
    // для каждой строки:
    {$omp parallel for}
    for var i: integer := 0 to (lines.Length - 1) do
    begin
        // загоняем строку в line и работаем с line
        var line: string := lines[i].TrimEnd;
        // в изначальную ячейку массива будем загонять результат
        lines[i] := '';
        while (line.Length > width) do
        begin
            // точка разделения - изначально на точке предела
            var split_point: longword := width;
            // поиск пробелов влево от точки предела до начала строки
            for var j: longword := split_point downto 1 do
                // если пробел найден, ставим там точку разделения
                if char.IsWhiteSpace(line[j]) then
                begin
                    split_point := j;
                    break;
                end;
            // разбиваем по точке разделения на верхнюю и нижнюю строку, удаляем лишние пробелы
            var upper: string := line.Left(split_point).TrimEnd;
            var lower: string := line.Right(line.Length - split_point).TrimStart;
            // в итоговую строку загоняем верхнюю
            lines[i] += upper + separator;
            // c нижней строкой продолжаем работать
            line := lower;
        end;
        // line стала короче предела, загоняем в итоговую строку
        lines[i] += line;
    end;
    Result := string.Join(separator, lines);
end;

function PadCenter(const s: string; n: integer): string;
begin
    var spaces := n - s.Length;
    var left_padding := (spaces div 2) + s.Length;
    Result := s.PadLeft(left_padding).PadRight(n);
end;

function FiftyFifty<T>(a, b: T): T := (Random(2) = 0) ? a : b;

procedure CollectGarbage;
begin
    System.GC.Collect(GC.MaxGeneration, System.GCCollectionMode.Forced, True);
    System.GC.WaitForPendingFinalizers;
    System.GC.Collect(GC.MaxGeneration, System.GCCollectionMode.Forced, True);
    System.GC.WaitForFullGCComplete
end;

procedure ReadCmd(prompt: string);
var
    res: string;
begin
    repeat
        repeat
            writelnx2;
            TxtClr(Color.Gray);
            ClearLine(True);
            print('>');
            if not NilOrEmpty(prompt) then print(prompt);
            ClrKeyBuffer;
            Cursor.Show;
            res := ComputeWithoutUpdScr(() -> ReadlnString);
            Cursor.Hide;
            try
                res := res.TrimEnd(#10, #13);
            except
                on exc: Exception do
                begin
                    _Log.Log('!! ошибка: ' + exc.GetType.ToString);
                    TxtClr(Color.Red);
                    writeln('// Ошибка: ', exc.GetType, '.');
                    continue
                end
            end; // try end
            if res.IsMatch('[\u0000-\u001F]') then
            begin
                TxtClr(Color.Red);
                writeln('// Недопустимый символ.');
                _Log.Log('!! ошибка: Недопустимый символ');
                continue;
            end;
            if NilOrEmpty(res.Trim) then
                Cursor.GoTop(-((res.Length + prompt.Length + 2) div BufWidth) - 2)
            else break;
        until False;
        writeln;
        _Log.Log('> ' + res);
        if not res.IsMatch('[А-я]') then
        begin
            if NilOrEmpty(prompt) then _Log.Log('[] (нет кириллицы)') else _Log.Log($'(префикс:"{prompt}") [] (нет кириллицы)');
            res := '';
            break
        end;
        res := res.RegexReplace('[^\p{L}]', ''); // удаляет всё кроме букв
        res := res.Trim.ToLower;
        while (res.Contains('  ')) do res := res.Replace('  ', ' ');
        res := res.Replace('ё', 'е').Replace('тся', 'ться');
        res := ParseCmd(res);
        if NilOrEmpty(prompt) then _Log.Log($'[{res}]') else _Log.Log($'(префикс:"{prompt}") [{res}]');
        if (res = 'INV') or (res = 'CHECK_INV') then Inventory.Output
        else break;
    until False;
    TxtClr(Color.White);
    cmdres := res;
    prompt := nil;
end;

function LastCmdResult: string := cmdres;

function ReadInput(prompt: string): string;
begin
    writelnx2;
    ClearLine(True);
    var original_top: integer := Cursor.Top;
    repeat
        TxtClr(Color.Gray);
        print('>');
        if not NilOrEmpty(prompt) then print(prompt);
        ClrKeyBuffer;
        Cursor.Show;
        Result := ComputeWithoutUpdScr(() -> ReadlnString);
        Cursor.Hide;
        try
            Result := Result.TrimEnd(#10, #13);
        except
            on exc: Exception do
            begin
                _Log.Log('!! ошибка: ' + exc.GetType.ToString);
                TxtClr(Color.Red);
                writeln('// Ошибка: ', exc.GetType, '.');
                writeln;
                continue
            end
        end; // try end
        Result := Result.Replace(TAB, ' ').RegexReplace('[\u0000-\u001F]', '').Trim;
        if NilOrEmpty(Result) then
            repeat
                ClearLine(True);
            until (Cursor.Top <= original_top)
        else break;
    until False;
    writeln;
    _Log.Log('> ' + Result);
    if NilOrEmpty(prompt) then _Log.Log($'[{Result}]')
    else _Log.Log($'(префикс:"{prompt}") [{Result}]');
    TxtClr(Color.White);
    prompt := nil;
end;


procedure Catch(const ex: Exception);
begin
    _Log.Log('!! ОШИБКА:');
    _Log.Log(TAB + ex.ToString);
    if Console.IsOutputRedirected then writeln(ex.ToString)
    else begin
        BgClr(Color.Black);
        ClrScr;
        TxtClr(Color.Cyan);
        writeln(#7);
        writeln('// Ой! Произошла ошибка.');
        writeln('// Свяжитесь с разработчиком и предоставьте следующее сообщение:');
        TxtClr(Color.Red);
        writeln;
        writeln(ex.GetType);
        writeln(ex.Message);
        writeln(ex.StackTrace);
        TxtClr(Color.DarkRed);
        _Log.DumpThmera;
        Cursor.Show;
        sleep(1000);
        Anim.Next3;
    end;
end;

function ComputeWithoutUpdScr<T>(func: () -> T): T;
begin
    upd_scr_tmr.Disable;
    Result := func;
    upd_scr_tmr.Enable;
end;

procedure DoWithoutUpdScr(proc: procedure);
begin
    upd_scr_tmr.Disable;
    proc();
    upd_scr_tmr.Enable;
end;

procedure Throw(proc: procedure);
begin
    var l, t: integer;
    var c: Color;
    (l, t, c) := (Cursor.Left, Cursor.Top, CurClr);
    proc();
    Cursor.SetLeft(l);
    Cursor.SetTop(t);
    TxtClr(c);
end;

function STARTUP: boolean;
begin
    Result := False;
    if Console.IsOutputRedirected then
    begin
        writeln('Программа запущена не в консольном окне. Shift+F9?');
        exit;
    end;
    writeln('Загрузка...');
    if IsUnix then
    begin
        TxtClr(Color.Red);
        writeln('Программа запущена не на операционной системе Windows.');
        TxtClr(Color.Cyan);
        writeln('Всё равно продолжить? (Y/N)');
        if not YN then exit;
        _Log.WarnedUnix := True;
    end;
    BgClr(Color.Black);
    try
        if not IsUnix then Console.InputEncoding := System.Text.Encoding.GetEncoding(1251);
        Console.OutputEncoding := System.Text.Encoding.UTF8;
    except
        {ignore}
    end;
    if not (System.Globalization.CultureInfo.CurrentUICulture.Name.IsMatch('RU|BY|KZ', RegexOptions.IgnoreCase)) then
    begin
        TxtClr(Color.Cyan);
        writeln('This program is available only in Russian. Continue anyway? (Y/N)');
        if not YN then exit;
        _Log.WarnedLanguage := True;
    end;
    while (Console.LargestWindowWidth <= MIN_WIDTH) do
    begin
        _Log.WarnedWindowSize := True;
        sleep(10);
        TxtClr(Color.Red);
        writeln('Ошибка: превышено максимальное значение размера окна.');
        writeln('Возможно, размер шрифта консоли слишком большой.');
        writeln('Кликните правой кнопкой мыши по заголовку окна, затем выберите "Свойства", перейдите на вкладку "Шрифт", уменьшите его размер и нажмите "ОК".');
        ClrKeyBuffer;
        ReadKey;
        ClrScr;
    end;
    upd_scr_tmr := new MyTimers.Timer(3, UpdScr);
    upd_scr_tmr.Enable;
    UpdScr;
    Randomize;
    Result := True;
end;

procedure EscapeRoom(proc: procedure);
begin
    Anim.Next3;
    TxtClr(Color.Yellow);
    writeln('=== SEEK A WAY OUT! ===');
    writeln;
    BeepWait(580, 230);
    BeepWait(460, 230);
    BeepWait(280, 230);
    BeepWait(300, 380);
    TxtClr(Color.White);
    proc();
    TxtClr(Color.Yellow);
    writeln('=== YOU FOUND IT ===');
    BeepWait(300, 200);
    Anim.Next3;
end;

function SetSuspendState(hiberate, forceCritical, disableWakeEvent: boolean): boolean;
    external 'Powrprof.dll' name 'SetSuspendState';

procedure SleepMode := SetSuspendState(false, true, true);



initialization
    if not STARTUP then Halt(0);

finalization
    if not Console.IsOutputRedirected then _Log.Log('=== стоп');
    _Log.Dispose;
    if (upd_scr_tmr <> nil) then
    begin
        upd_scr_tmr.Destroy;
        upd_scr_tmr := nil;
    end;
    CollectGarbage;

end.