unit Scenes;

type
    
    /// НЕ НАСЛЕДОВАТЬ
    Scene = abstract class
    private
        next: scene;
    public
        procedure SetNext(const value: Scene) := self.next := value;
        
        function Chain: sequence of Scene;
        begin
            var n: Scene := self;
            repeat
                yield n;
                n := n.next;
            until n = nil;
        end;
        
        procedure Run; abstract;
    end;
    
    /// класс сцены проходимой без геймоверов 
    Cutscene = sealed class(Scene)
    private
        body: procedure;
    public
        constructor Create(proc: procedure);
        begin
            inherited Create;
            body := proc;
        end;
        
        procedure Run; override := body();
    end;// class end
    
    /// класс сцены, в которой можно получить геймовер
    PlayableScene = sealed class(Scene)
    private
        boolfunc: function: boolean;
        res: boolean;
    public
        constructor Create(func: function: boolean);
        begin
            inherited Create;
            boolfunc := func;
        end;
        
        procedure Run(); override := res := boolfunc();
        
        property Passed: boolean read res;
    end;//class end

// TYPE END

function Link(params scenearr: array of Scene): Scene;
begin
    for var i: integer := 0 to (scenearr.Length - 2) do
        scenearr[i].SetNext(scenearr[i + 1]);
    Result := scenearr[0];
end;

end.