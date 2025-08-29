unit Tutorial;

uses Aliases, Procs;

type
    Hint = record
    private
        fStatus: boolean := False;
    public
        property Shown: boolean read fStatus;
        procedure Show() := if not fStatus then fStatus := True;
    end;// class end

var
    CommandH, InventoryH, MenuH, ElevatorH, LookAroundH, AnimNextH, DialogueH, ChatH: Hint;

procedure Comment(params lines: array of string);
begin
    foreach l: string in lines do
    begin
        var temp: Color := CurClr;
        TxtClr(Color.DarkGreen);
        writeln('// ' + l);
        TxtClr(temp);
    end;
end;

procedure ShowCheckHint;
begin
    if not LookAroundH.Shown then
    begin
        Comment('команды "осмотреться" или "проверить" помогут вспомнить, что можно делать');
        LookAroundH.Show;
    end;
end;

end.