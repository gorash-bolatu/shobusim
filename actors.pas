unit Actors;

uses Aliases;

type

    Actor = record
        name: string;
        clr: Color;
    end;

const
    Anon: Actor = (name: '???'; clr: Color.Green);
    Sanya: Actor = (name: 'Саня'; clr: Color.Magenta);
    Kostya: Actor = (name: 'Костя'; clr: Color.Red);
    Roma: Actor = (name: 'Рома'; clr: Color.Green);
    Trip: Actor = (name: 'Трип'; clr: Color.Green);
    Rita: Actor = (name: 'Рита'; clr: Color.Green);
    Ildar: Actor = (name: 'Ильдар'; clr: Color.Green);
    Vlad: Actor = (name: 'Влад'; clr: Color.Green);
    Miha: Actor = (name: 'Миха'; clr: Color.Green);
    // TODO добавить ещё
    MatrixRoma: Actor = (name: 'МеРомаВинген'; clr: Color.Green);
    MatrixTrip: Actor = (name: 'Мотвеус'; clr: Color.Green);
    MatrixRita: Actor = (name: 'Тританити'; clr: Color.Green);
    MatrixKostyl: Actor = (name: 'Агент Сергеев'; clr: Color.Red);

end.