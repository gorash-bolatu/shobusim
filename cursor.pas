﻿/// оболочка для управления курсором в консоли
unit Cursor;

var
    /// Скрывать ли курсор при каждой подгонке размера экрана
    HIDE_ON_UPDSCR: boolean := True;

/// показать курсор
procedure Show;
begin
    HIDE_ON_UPDSCR := False;
    Console.CursorVisible := True;
end;

/// скрыть курсор
procedure Hide;
begin
    HIDE_ON_UPDSCR := True;
    Console.CursorVisible := False;
end;

/// установка курсора по горизонтали
procedure SetLeft(pos: integer) := Console.CursorLeft := pos;

/// перемещение курсора по горизонтали
procedure GoLeft(move: integer) := Console.CursorLeft += move;

/// текущая позиция курсора по горизонтали
function Left := Console.CursorLeft;

/// установка курсора по вертикали
procedure SetTop(pos: integer) := Console.CursorTop := pos;

/// перемещение курсора по вертикали
procedure GoTop(move: integer) := Console.CursorTop += move;

/// текущая позиция курсора по вертикали
function Top := Console.CursorTop;

/// перемещение курсора по горизонтали и вертикали
procedure GoXY(x, y: integer) := Console.SetCursorPosition(Left + x, Top + y);

/// передвинуть "окно" консоли чтобы было видно где курсор
procedure Find;
const
    MARGIN = 2;
begin
    if (Cursor.Top > Console.WindowTop + MARGIN)
        xor (Cursor.Top <= Console.WindowTop + Console.WindowHeight - MARGIN) then
        if (Cursor.Top < Console.WindowHeight) then
            Console.WindowTop := 0
        else
            Console.WindowTop := Cursor.Top - Console.WindowHeight + MARGIN - 1;
    if (Cursor.Top + MARGIN >= Console.WindowTop + Console.WindowHeight) then Console.WindowTop += 1;
end;

end.