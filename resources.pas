﻿unit Resources;

interface

/// получить поток байтов из встроенного файла ресурсов
function GetResourceStream(const resource_name: string): System.IO.Stream;
/// получить строку текста из встроенного файла ресурсов
function TextFromResourceFile(const resource_name: string): string;



implementation

uses _Settings;

function GetResourceStream(const resource_name: string): System.IO.Stream;
begin
    Result := System.Reflection.Assembly.GetEntryAssembly.GetManifestResourceStream(resource_name);
    if DEBUGMODE then
        if (Result = nil) then
            raise new System.Resources.MissingManifestResourceException(
            'НЕТ РЕСУРСА: ' + resource_name);
end;

function TextFromResourceFile(const resource_name: string): string;
var
    resource_stream: System.IO.Stream;
    mem_stream: System.IO.MemoryStream;
begin
    try
        resource_stream := GetResourceStream(resource_name);
        mem_stream := new System.IO.MemoryStream;
        resource_stream.CopyTo(mem_stream);
        Result := System.Text.Encoding.UTF8.GetString(mem_stream.ToArray);
    finally
        if (resource_stream <> nil) then
        begin
            // resource_stream.Close;
            resource_stream.Dispose;
            resource_stream := nil;
        end;
        if (mem_stream <> nil) then
        begin
            // mem_stream.Close;
            mem_stream.Dispose;
            mem_stream := nil;
        end;
    end;
end;

function GetAllResourceNames: array of string;
begin
    Result := System.Reflection.Assembly.GetEntryAssembly.GetManifestResourceNames;
end;

function HasDuplicates<T>(s: sequence of T): boolean := s.GroupBy(q -> q).Any(q -> q.Skip(1).Any);

// todo убрать в релизе
procedure ValidateResource(const r: string);
var
    resource_stream: System.IO.Stream;
begin
    try
        resource_stream := GetResourceStream(r);
        if (resource_stream = nil) then
            raise new System.Resources.MissingManifestResourceException('НЕТ РЕСУРСА: ' + r)
        else if HasDuplicates(GetAllResourceNames) then
            raise new System.Reflection.AmbiguousMatchException('НАЙДЕНЫ ДУБЛИКАТЫ РЕСУРСА: ' + r)
        else if (resource_stream.Length = 0) then
            raise new System.Reflection.TargetException('ПУСТОЙ РЕСУРС: ' + r);
    finally
        resource_stream.Dispose;
        resource_stream := nil;
    end;
end;

initialization
    if Console.IsOutputRedirected or (not DEBUGMODE) then exit;
    println('[DEBUG]', 'Ресурсы:', '[' + GetAllResourceNames.JoinToString(', ') + ']');
    foreach res: string in GetAllResourceNames do ValidateResource(res);

end.