unit Chats;

interface

uses _Settings;

type
    Chat = class
    private
        fName: string;
        fWidth: byte;
        procedure Cleanup;
    public
        constructor Create(pen_pal_name: string);
        procedure DrawTop;
        procedure DrawBottom;
        procedure DrawSides;
        procedure Enter(const chat_entry: string);
        procedure Response(line1: string; line2: string := nil);
        property Name: string read fName;
    end;



implementation

uses Aliases, Cursor, Procs, Tutorial;

procedure Chat.DrawTop;
begin
    TxtClr(Color.DarkGray);
    BgClr(Color.Black);
    writeln('┌', '─' * fWidth, '┐');
end;

procedure Chat.DrawBottom;
begin
    TxtClr(Color.DarkGray);
    BgClr(Color.Black);
    writeln('└', '─' * fWidth, '┘');
end;

procedure Chat.DrawSides;
begin
    BgClr(Color.Black);
    Cursor.SetLeft(0);
    TxtClr(Color.DarkGray);
    write('│');
    BgClr(Color.DarkCyan);
    write(' ' * fWidth);
    BgClr(Color.Black);
    write('│');
    Cursor.SetLeft(2);
    TxtClr(Color.White);
    BgClr(Color.DarkCyan);
end;

procedure Chat.CleanUp;
begin
    DrawSides;
    BgClr(Color.Black);
    writeln;
    DrawBottom;
    TxtClr(Color.White);
    BgClr(Color.Black);
    writeln;
    Cursor.GoTop(-2);
end;

procedure Chat.Enter(const chat_entry: string);
begin
    writelnx2;
    DrawBottom;
    Cursor.GoTop(-3);
    DrawSides;
    TxtClr(Color.Blue);
    writeln('Вы');
    DrawSides;
    if SKIPCHATS then write(chat_entry)
    else begin
        var chi: byte := 0;
        if not Tutorial.ChatH.Shown then
        begin
            writelnx2;
            BgClr(Color.Black);
            Tutorial.Comment('печатать разными клавишами на клавиатуре, enter для ввода');
            ReadKey;
            ClearLine(True);
            Cursor.GoTop(-2);
            DrawSides;
            write(chat_entry[1]);
            chi += 1;
            Tutorial.ChatH.Show;
        end;
        ClrKeyBuffer;
        Cursor.Show;
        var ch1, ch2: Key;
        while (chi < chat_entry.Length) do
        begin
            if (chi mod 2 = 0) then begin
                repeat ch1 := ReadKey until (ch1 <> ch2);
                ch2 := ch1;
            end;
            chi += 1;
            write(chat_entry[chi]);
        end;
        repeat until (ReadKey in [Key.Enter, Key.Tab, Key.Select, Key.Escape]);
    end;
    Cursor.Hide;
    writeln;
    CleanUp;
end;

procedure Chat.Response(line1: string; line2: string);
begin
    if not SKIPCHATS then sleep(900);
    ClearLine(False);
    DrawSides;
    TxtClr(Color.Blue);
    writeln(Name);
    DrawSides;
    writeln(line1);
    if not NilOrEmpty(line2) then
    begin
        DrawBottom;
        if not SKIPCHATS then sleep(800);
        Cursor.GoTop(-1);
        DrawSides;
        writeln(line2);
    end;
    CleanUp;
    if not SKIPCHATS then sleep(600);
end;

constructor Chat.Create(pen_pal_name: string);
begin
    self.fName := pen_pal_name;
    self.fWidth := 50;
end;

end.