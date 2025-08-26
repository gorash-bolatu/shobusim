﻿{$REFERENCE LightJson.dll} // https://github.com/MarcosLopezC/LightJson
{$RESOURCE parse_cmd.json}
{$DEFINE MEASURE_JSON_PARSE} // TODO
unit Parser;

interface

/// парсить строку согласно parse_cmd.json
function ParseCmd(const s: string): string;
/// парсить строку согласно parse_tts.json
function ParseTts(const s: string): string;



implementation

// примерная структура json:
//[
//    {
//        "to": "USE",
//        "from": ["взять", "забрать", "получить"]
//        
//    },
//    {
//        "to": "JUMP",
//        "from": "прыгнуть"
//    }
//    ...
//]

uses Procs, Resources;
uses _Log;

var
    cmd_json, tts_json: LightJson.JsonArray;

function ParseCmd(const s: string): string;
begin
    var words: List<string> := new List<string>;
    foreach token: string in s.Split do
        foreach entry: LightJson.JsonValue in cmd_json do
        begin
            var from: LightJson.JsonValue := entry.Item['from'];
            if (from.IsJsonArray
            ? from.AsJsonArray.Contains(token)
            : from.AsString.Equals(token)) then
            begin
                words.Add(entry.Item['to'].AsString);
                break;
            end;
        end;
    Result := string.Join('_', words);
    words.Clear;
    words := nil;
end;

function ParseTts(const s: string): string;
begin
    Result := s;
    foreach entry: LightJson.JsonValue in tts_json do
    begin
        var t: string := entry.Item['to'].AsString;
        var f: LightJson.JsonValue := entry.Item['from'];
        if f.IsJsonArray then
            foreach w: LightJson.JsonValue in f.AsJsonArray do
                Result := Result.Replace(w.AsString, t)
        else Result := Result.Replace(f.AsString, t);
    end;
end;

// todo убрать в релизе
function IsValidEntry(const entry: LightJson.JsonValue): boolean;
begin
    Result := False;
    if (entry.IsNull or not entry.IsJsonObject) then exit;
    var obj: LightJson.JsonObject := entry.AsJsonObject;
    if not (obj.ContainsKey('from') and obj.ContainsKey('to')) then exit;
    if not ((obj['from'].IsJsonArray or obj['from'].IsString) and obj['to'].IsString) then exit;
    Result := True;
end;

{$IFDEF MEASURE_JSON_PARSE}

function FetchAndParse(const resource_name: string): LightJson.JsonArray;
begin
    var res: System.Text.StringBuilder := new System.Text.StringBuilder;
    if not Console.IsOutputRedirected then
    begin
        res.Append('[Parser] ');
        res.Append(resource_name);
        res.Append(': Загрузка... ');
    end;
    var watch := new Stopwatch;
    watch.Start;
    var json: string := TextFromResourceFile(resource_name);
    watch.Stop;
    if not Console.IsOutputRedirected then
    begin
        res.Append(watch.Elapsed.TotalMilliseconds);
        res.Append('ms Парсинг... ');
    end;
    watch.Restart;
    Result := LightJson.JsonValue.Parse(json).AsJsonArray;
    watch.Stop;
    if not Console.IsOutputRedirected then
    begin
        res.Append(watch.Elapsed.TotalMilliseconds);
        res.Append('ms Проверка... ');
    end;
    watch.Restart;
    foreach i: LightJson.JsonValue in Result do
        if not IsValidEntry(i) then raise new LightJson.Serialization.JsonParseException;
    watch.Stop;
    if not Console.IsOutputRedirected then
    begin
        res.Append(watch.Elapsed.TotalMilliseconds);
        res.Append('ms');
    end;
    _Log.PushString(res.ToString);
    res.Clear;
    res := nil;
    watch := nil;
end;

{$ELSE}

function FetchAndParse(const resource_name: string): LightJson.JsonArray;
begin
    Result := LightJson.JsonValue.Parse(TextFromResourceFile(resource_name)).AsJsonArray;
    foreach i: LightJson.JsonValue in Result do
        if not IsValidEntry(i) then raise new LightJson.Serialization.JsonParseException;
    
end;

{$ENDIF}

initialization
    cmd_json := FetchAndParse('parse_cmd.json');
    {$IFDEF MEASURE_JSON_PARSE}
    _Log.PushString(NewLine);
    {$ENDIF}
    tts_json := FetchAndParse('parse_tts.json');

finalization
    cmd_json.Clear;
    cmd_json := nil;
    tts_json.Clear;
    tts_json := nil;

end.