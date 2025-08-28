unit Dialogue;

interface

uses Actors;

/// открывает новый диалог
procedure Open;
/// закрывает открытый диалог
procedure Close;
/// перед первым Say в цепочке нужно открыть диалог через Dialogue.Open
/// после последнего Say в цепочке нужно закрыть диалог через Dialogue.Close
/// цветной текст внутри фигурных скобок {}
procedure Say(const speaker: Actor; params phrases: array of string);
/// Dialogue.Say, но не требует Dialogue.Open и Dialogue.Close
/// цветной текст внутри фигурных скобок {}
procedure FastSay(const speaker: Actor; params phrases: array of string);
/// перед первым BulletTime в цепочке нужно открыть диалог через Dialogue.Open
/// после последнего BulletTime в цепочке нужно закрыть диалог через Dialogue.Close
/// цветной текст внутри фигурных скобок {}
/// возвращает строку в фигурных скобках {} по нажатию Enter/Tab/пробела
/// возвращает nil если ничего не было нажато
/// возвращает пустую строку если клавиша нажата там где нет фразы в фигурных скобках
function BulletTime(const speaker: Actor; params phrases: array of string): string;
/// не требует Dialogue.Open и Dialogue.Close
procedure OraMuda;
/// не требует Dialogue.Open и Dialogue.Close
procedure Echoes;



implementation

uses Aliases, Anim, Draw, Cursor, Procs, _Settings;

type
    BaseInstance = abstract class
    private
        fBoxWidth, fNameWidth: byte;
    protected
        const CHAR_DELAY: byte = 30;
        procedure SetBoxWidth(longest_len: integer); virtual := fBoxWidth := longest_len + 2;
        property BoxWidth: byte read fBoxWidth;
        procedure SetNameWidth(name_len: byte) := fNameWidth := name_len;
        property NameWidth: byte read fNameWidth;
        
        function Handled(const s: string): boolean; abstract;
        
        procedure WriteActor(const speaker: Actor);
        begin
            SetNameWidth(speaker.name.Length + 2);
            TxtClr(Color.White);
            writeln;
            Draw.Box(NameWidth, 1);
            Cursor.GoTop(-2);
            Cursor.SetLeft(2);
            TxtClr(speaker.clr);
            writeln(speaker.name);
        end;
        
        procedure WriteChar(ch: char);
        begin
            case ch of
                '{': TxtClr(Color.Cyan);
                '}': TxtClr(Color.Yellow);
            else write(ch);
            end;
            if not KeyAvail then sleep(CHAR_DELAY);
        end;
        
        procedure SayLines(const speaker: Actor; const phrases: array of string);
        begin
            if DEBUGMODE then
                if (phrases.Length = 0) then raise new Exception('НЕТ СТРОК В DIALOGUE.SAY()');
            SetBoxWidth(phrases.Max.Length);
            WriteActor(speaker);
            if DEBUGMODE then
                if (BoxWidth + 3) > MIN_WIDTH then
                    raise new Exception('СЛИШКОМ БОЛЬШАЯ СТРОКА ДИАЛОГА: "' + phrases.Max
                                         + '" [' + phrases.Max.Length + '].');
            TxtClr(Color.White);
            if (BoxWidth = NameWidth) then
                writeln('├', '─' * NameWidth, '┤')
            else if (BoxWidth < NameWidth) then
                writeln('├', '─' * BoxWidth, '┬', '─' * (NameWidth - BoxWidth - 1), '┘')
            else
                writeln('├', '─' * NameWidth, '┴', '─' * (BoxWidth - NameWidth - 1), '┐');
            foreach n: string in phrases do
            begin
                writeln('│', ' ' * BoxWidth, '│');
                writeln('└', '─' * BoxWidth, '┘');
                Cursor.GoTop(-2);
                Cursor.SetLeft(2);
                TxtClr(Color.Yellow);
                if Handled(n) then break;
                TxtClr(Color.White);
            end;
        end;
    
    end;
    
    DialogueInstance = class(BaseInstance)
    private
        const LINE_END_DELAY: word = 400;
    protected
        procedure SetBoxWidth(longest_len: integer); override := inherited SetBoxWidth(longest_len + 1);
        
        function Handled(const s: string): boolean; override;
        begin
            Result := False;
            ClrKeyBuffer;
            foreach c: char in s do WriteChar(c);
            if not s.EndsWith('-') then
            begin
                System.Threading.SpinWait.SpinUntil(() -> KeyAvail, LINE_END_DELAY);
                write(' ');
                TxtClr(Color.Cyan);
                Anim.Next1;
            end;
            writeln;
            TxtClr(Color.White);
        end;
    
    public
        
        procedure Jojo;
        const
            LEN: byte = 64;
        begin
            SetBoxWidth(LEN);
            for var k: boolean := False to True do
            begin
                WriteActor(k ? Actors.Sanya : Actors.Kostya);
                TxtClr(Color.White);
                writeln('├', '─' * NameWidth, '┴', '─' * (BoxWidth - NameWidth - 1), '┐');
                writeln('│', ' ' * BoxWidth, '│');
                writeln('└', '─' * BoxWidth, '┘');
                WritelnX2;
                Cursor.SetLeft(2);
                Cursor.GoTop(-3);
            end;
            Cursor.GoTop(-1);
            TxtClr(Color.Yellow);
            for var l: byte := 0 to LEN do
            begin
                if l > (LEN - 5) then write('!') else write('ОРА'[(l mod 3) + 1]);
                Cursor.GoTop(-5);
                Cursor.GoLeft(-1);
                if l > (LEN - 5) then write('!') else write('МУДАК'[(l mod 5) + 1]);
                Cursor.GoTop(+5);
                sleep(CHAR_DELAY);
            end;
        end;
        
        procedure Echo(const speaker: Actor; params s_arr: array of string);
        const
            ECHOSTR: string = 'Эхо';
            ECHOLEN: byte = 3;
            PADDING: byte = 2;
        begin
            SayLines(speaker, s_arr);
            Cursor.GoTop(-4);
            TxtClr(Color.White);
            SetNameWidth(ECHOLEN + PADDING);
            Cursor.SetLeft(BoxWidth + ECHOLEN);
            writeln('┌', '─' * NameWidth, '┐');
            Cursor.SetLeft(BoxWidth + ECHOLEN);
            write('│', ' ' * NameWidth, '│');
            Cursor.SetLeft(BoxWidth + ECHOLEN + PADDING);
            TxtClr(Color.DarkYellow);
            writeln(ECHOSTR);
            TxtClr(Color.White);
            var longest_len := (s_arr.Max.Length + 3);
            for var m: byte := 0 to 2 do
            begin
                Cursor.SetLeft(BoxWidth + 3);
                case m of
                    0: writeln('├', '─' * NameWidth, '┴', '─' * (longest_len - NameWidth - 1), '┐');
                    1: writeln('│', ' ' * longest_len, '│');
                    2: writeln('└', '─' * longest_len, '┘');
                end;//case end
            end;
            Cursor.GoTop(-2);
            Cursor.SetLeft(BoxWidth + ECHOLEN + PADDING);
            TxtClr(Color.DarkCyan);
            Anim.Text(s_arr.Max, CHAR_DELAY);
            sleep(LINE_END_DELAY);
            TxtClr(Color.Cyan);
            write(' ');
            Anim.Next1;
            ClrKeyBuffer;
            writeln;
        end;
    
    end;
    
    BulletTimeInstance = class(BaseInstance)
    private
        const LINE_END_DELAY: word = 1000;
        fCaught: string := nil;
    protected
        function Handled(const s: string): boolean; override;
        begin
            if DEBUGMODE then
                if (s.Count(q -> q = '{') > 2) or (s.Count(q -> q = '}') > 2) then
                    raise new Exception('СЛИШКОМ МНОГО ФИГУРНЫХ СКОБОК {}: "' + s + '"')
                else if (s.Count(q -> q = '{') <> s.Count(q -> q = '}')) then
                    raise new Exception('НЕЗАКРЫТЫЕ ФИГУРНЫЕ СКОБКИ {}: "' + s + '"');
            for var c: integer := 1 to s.Length do
            begin
                WriteChar(s[c]);
                if System.Threading.SpinWait.SpinUntil(() ->
                (KeyAvail and (ReadKey in [Key.Enter, Key.Tab, Key.Select, Key.Spacebar])), 
                (c = s.Length) ? LINE_END_DELAY : CHAR_DELAY + 0) then
                begin
                    var opener: integer := s.IndexOf('{');
                    var closer: integer := s.LastIndexOf('}');
                    var highlighted: string := s[(opener + 2):(closer + 1):1];
                    if s.Contains('{') and (c > opener) then begin
                        Cursor.SetLeft(2);
                        TxtClr(Color.Yellow);
                        write(s.Left(opener));
                        TxtClr(Color.DarkCyan);
                        BgClr(Color.White);
                        write(highlighted);
                        TxtClr(Color.Yellow);
                        BgClr(Color.Black);
                        write(s.Substring(closer + 1));
                        fCaught := highlighted;
                    end
                    else fCaught := '';
                    break;
                end;
            end;
            writeln;
            Result := (fCaught <> nil);
        end;
    
    public
        property Caught: string read fCaught;
    end;
// type end

var
    current: DialogueInstance;

// todo убрать в релизе
procedure __CheckIsDialogueOpened;
begin
    if not DEBUGMODE then exit;
    if (current = nil) then raise new Exception('НЕТ ОТКРЫТОГО ДИАЛОГА');
end;

// todo убрать в релизе
procedure __CheckIsDialogueClosed;
begin
    if not DEBUGMODE then exit;
    if (current <> nil) then raise new Exception('ДИАЛОГ УЖЕ ОТКРЫТ');
end;

procedure Open;
begin
    __CheckIsDialogueClosed;
    current := new DialogueInstance;
    Anim.Next3;
    Cursor.GoTop(-1);
end;

procedure Close;
begin
    __CheckIsDialogueOpened;
    WritelnX2;
    TxtClr(Color.White);
    current := nil;
end;

procedure Say(const speaker: Actor; params phrases: array of string);
begin
    __CheckIsDialogueOpened;
    current.SayLines(speaker, phrases);
end;

procedure FastSay(const speaker: Actor; params phrases: array of string);
begin
    Open;
    current.SayLines(speaker, phrases);
    Close;
end;

function BulletTime(const speaker: Actor; params phrases: array of string): string;
begin
    __CheckIsDialogueOpened;
    var current_bt: BulletTimeInstance := new BulletTimeInstance;
    current_bt.SayLines(speaker, phrases);
    if (current_bt.Caught <> nil) then
    begin
        writeln;
        Anim.Objection;
    end;
    TxtClr(Color.White);
    Result := current_bt.Caught;
    current_bt := nil;
end;

procedure OraMuda;
begin
    Open;
    current.Jojo;
    Close;
    Anim.Next3;
end;

procedure Echoes;
begin
    Open;
    current.Echo(Actors.Sanya, 'Грррр...', 'КОООСТЯЯЯЯЯЯЯЯЯЯЯЯЯЯЯЯ!!!');
    current.Echo(Actors.Kostya, 'СССССАААНЯ!');
    Close;
end;

initialization

finalization
    current := nil;

end.