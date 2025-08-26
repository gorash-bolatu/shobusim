﻿unit Matrix;

interface

procedure Mtrx;
procedure NextSlide;

implementation

uses Aliases, Procs, Cursor, Draw, Anim, Dialogue, TextToSpeech, Menu, Actors;
uses _Log, _Settings;

function RandChar: char;
begin
    case Random(4) of
        0: Result := chrunicode(Random(33, 126));
        1: Result := chrunicode(Random(454, 788));
        2: Result := chrunicode(Random(9478, 9580));
        3: Result := chrunicode(Random(48, 57))
    end; // case end
end;

type
    Column = sealed class
        Position, Height: longword;
        constructor Create(p, h: longword);
        begin
            self.Position := p;
            self.Height := h;
        end;
    end;

procedure Transition;
begin
    UpdScr;
    var width: longword := Console.WindowWidth;
    var columns: HashSet<Column> := new HashSet<Column>(width);
    for var i: byte := 0 to (width - 2) do columns.Add(new Column(i, 0));
    TxtClr(Color.Green);
    Cursor.SetLeft(0);
    var original_cur_top: integer;
    if (Cursor.Top > Console.WindowHeight) then
        original_cur_top := Cursor.Top - Console.WindowHeight + 1
    else
        original_cur_top := 0;
    Cursor.SetTop(original_cur_top);
    var current: Column;
    var starttime: DateTime := DateTime.Now;
    repeat
        if (BufWidth < width) then
        begin
            Console.BufferWidth := width;
            Console.WindowWidth := BufWidth;
        end;
        current := columns.ElementAt(Random(columns.Count));
        Cursor.SetLeft(current.Position);
        Cursor.SetTop(original_cur_top + current.Height);
        write(RandChar());
        current.Height += 1;
        if (current.Height >= Console.WindowHeight) then columns.Remove(current);
    until (columns.Count < ((DateTime.Now.Subtract(starttime).TotalSeconds / 2)));
    ClrScr;
    sleep(400);
    current := nil;
    columns.Clear;
    columns := nil;
end;

procedure NextSlide := DoWithoutUpdScr(Transition);

procedure Mtrx;
begin
    TxtClr(Color.Green);
    DoWithoutUpdScr(() ->
    loop 5 do
    begin
        var endtime: DateTime := DateTime.Now.AddMilliseconds(800);
        var sleep_switch: boolean := False;
        while (DateTime.Now < endtime) do
        begin
            write(RandChar() * BufWidth);
            if sleep_switch then sleep(1);
            sleep_switch := not sleep_switch;
        end;
    end);
    ClrScr;
    sleep(1800);
    writeln;
    for var h2: byte := 0 to 2 do
    begin
        print('>');
        Cursor.Show;
        if h2 = 0 then sleep(400);
        var r: string;
        case h2 of
            0: r := 'Проснись, Саня...';
            1: r := 'Ты увяз в Симуляторе...';
            2: r := 'Следуй за синим ежом...';
        end;
        Anim.Text(r, 80);
        sleep(200);
        ClrKeyBuffer;
        ReadKey;
        writeln;
    end;
    writeln(NewLine * 3);
    print('>');
    Anim.Text('Тук-тук, Саня.', 65);
    sleep(300);
    Dialogue.Open;
    Cursor.Hide;
    NextSlide;
    Dialogue.Say(Actors.MatrixRita,
       'Я знаю, почему ты здесь, Саня. Знаю, что тебя гнетёт.',
       'Нам не даёт покоя вопрос. Он и привёл тебя сюда.',
       'Ты задашь его, как и я тогда.');
    Dialogue.Say(Actors.Sanya, 'Что такое Симулятор Шобунена...');
    Dialogue.Say(Actors.MatrixRita,
        'Ответ там, Саня. И он ищет тебя и найдёт, если ты захочешь.');
    NextSlide;
    Dialogue.Say(Actors.MatrixKostyl,
        'Как видите, мы за Вами давненько наблюдаем, мистер Шобунен.',
        'Оказывается, Вы живёте двойной жизнью.',
        'В одной жизни Вы - Александр Шобунен, безработный гик.',
        'Другая Ваша жизнь - в компьютерах, и тут Вы известны как хакер Саня.',
        'У первого, Александра, есть будущее. У Сани - нет.');
    if (DateTime.Now.Year < 2027) then
    begin
        NextSlide;
        Dialogue.Say(Actors.MatrixTrip, 'Ты веришь в судьбу, Саня?');
        Dialogue.Say(Actors.Sanya, 'Нет.');
        Dialogue.Say(Actors.MatrixTrip, 'Почему?');
        Dialogue.Say(Actors.Sanya, 'Мобильная гача уничтожила эту франшизу...');
    end;
    NextSlide;
    Dialogue.Say(Actors.MatrixRita, 'Ты учил меня на Варшавку не соваться.');
    Dialogue.Say(Actors.MatrixTrip, 'Я надеюсь... что ошибался.');
    NextSlide;
    Dialogue.Say(Actors.MatrixKostyl,
       'Вам случалось любоваться Симулятором? Его гениальностью...',
       'Знаете, ведь первая версия Симулятора создавалась как идеальный текстовый квест.',
       'Где нет запутанности, где все игроки будут счастливы.',
       'И полный провал. Люди не приняли программу, всё пришлось удалить.',
       'Принято думать, что не удалось описать идеальный мир языком программирования.',
       'Правда, я считаю, что игроки не приемлеют Симулятор без мини-игр и рутов...');
    NextSlide;
    Dialogue.Say(Actors.MatrixRoma,
       'Вы здесь потому, что так сказали. Вы только исполняете чужую волю.',
       'Так уж устроен наш мир.',
       'В нём лишь одна постоянная величина и одна неоспоримая истина.',
       'Только она рождает все явления, действия, противодействия...');
    Dialogue.Say(Actors.MatrixTrip, 'Всегда есть выбор.');
    Dialogue.Say(Actors.MatrixRoma,
       'Чушь! Выбор - это иллюзия. Рубеж между теми, кто разрабатывает, и теми, кто играет.',
       'Такова природа видеоигр.',
       'Мы это отрицаем, пытаемся бороться, но все это лишь притворство и ложь.',
       'Скрипты. От них нет спасения. Мы навсегда их рабы...');
    NextSlide;
    Dialogue.Say(Actors.Sanya,
       'Я знаю, вы меня слышите. Я чувствую вас.',
       'Я знаю, вы боитесь. Боитесь нас. Боитесь перемен.',
       'Я не стану предсказывать, чем все кончится. Скажу лишь, с чего начнётся.',
       'Я покажу им Чертаново... без вас.',
       'Чертаново без диктата и запретов, Чертаново без границ.',
       'Чертаново... где возможно всё.',
       'Что будет дальше - решать вам.');
    NextSlide;
    Dialogue.Say(Actors.MatrixKostyl,
       'Почему, мистер Шобунен, почему? Во имя чего?',
       'Что Вы делаете? Зачем, зачем встаёте? Зачем продолжаете драться?',
       'Иллюзии, мистер Шобунен, причуды восприятия!',
       'Но они, мистер Шобунен, как и Симулятор, столь же искусственны...',
       'Вам пора это увидеть, мистер Шобунен, увидеть и понять!',
       'Вы не можете победить! Продолжать борьбу бессмысленно!',
       'Почему, мистер Шобунен, почему Вы упорствуете?!');
    Dialogue.Say(Actors.Sanya, 'Меня зовут... Саня!');
    NextSlide;
    TextToSpeech.Init;
    Dialogue.Close;
    TextToSpeech.Architect(NewLine + 'Здравствуй, Саня');
    Dialogue.FastSay(Actors.Sanya, 'Кто ты такой?');
    TextToSpeech.Architect(
       'Я главный разработчик. Я создал Симулятор. Вот мы и встретились',
       'У тебя много вопросов. Проникновение в Симулятор изменило твоё сознание',
       'Но ты по-прежнему человек',
       'Следовательно, многие ответы ты поймёшь, а многие другие - нет',
       'Скоро ты узнаешь, что меньше всего относится к сути дела');
    Dialogue.FastSay(Actors.Sanya, 'Что за?..');
    TextToSpeech.Architect(
       'Симулятор намного старше, чем ты думаешь',
       'Я предпочитаю лимитировать эпоху Симулятора очередным билдом',
      $'И в таком случае, это уже {VERSION_nth} версия, "{VERSION}"',
       'Первый Симулятор, который я создал, был произведением искусства. Совершенством',
       'Его триумф сравним лишь с его монументальным крахом',
       'Неизбежность этого краха является следствием убогости языка PascalABC.NET');
    Dialogue.FastSay(Actors.Sanya, 'Дерьмо!');
    TextToSpeech.Architect(
       'Короче... Примешь синюю таблетку - и сказке конец',
       'Ты проснёшься в своей постели и поверишь, что это был сон',
       'Примешь красную таблетку - войдёшь в страну чудес',
       'И я покажу тебе, насколько глубока кроличья нора');
    for var k := False to True do
    begin
        Cursor.SetLeft(k ? 20 : 5);
        TxtClr(Color.Gray);
        Draw.Ascii(
         '    .-.',
         '   /:::\',
         '  /::::/',
         ' / `-:/',
         '/    /',
         '\   /',
         ' `"`');
        TxtClr(k ? Color.DarkRed : Color.Blue);
        Cursor.GoXY(+4, +1);
        Draw.Ascii(':::', #8'::::', ' `-:');
        Cursor.SetLeft(0);
        Cursor.GoTop(k ? +6 : -1);
    end;
    Menu.FastSelect('принять синюю таблетку', 'принять красную таблетку');
    NextSlide;
    if (Menu.LastResult.Contains('красн')) then
    begin
        TxtClr(Color.Black);
        BgClr(Color.White);
        ClrScr;
        sleep(1000);
        Cursor.GoXY(+1, +1);
        TextToSpeech.ArchitectFinal;
        try
            try
                SleepMode;
                _Log.Log('=== спящий режим');
            except
                on excp: Exception do
                    _Log.Log($'=== спящий режим: fail{NewLine}!! {excp.ToString}');
            end;
        finally
            TxtClr(Color.White);
            BgClr(Color.Black);
            ClrScr;
            ClrKeyBuffer;
            Anim.Next3;
            TextToSpeech.Architect(
                'Знаю, знаю. Неожиданный я выбрал способ выброса в реальный мир',
                'Но даже выбрав красную таблетку, ты всё же предпочёл вернуться оттуда в Симулятор',
                'Что ж. Тогда дальше тебе решать, что здесь делать..');
            ClrScr;
            System.Threading.Tasks.Task.Run(() -> TextToSpeech.Dispose());
            NextSlide;
        end;
    end;
end;

end.