unit utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

var
    foo:integer;
    function IsNumber(N : String) : Boolean;
    function strsplit(Input: string; const Delimiter: Char):TStrings;
implementation

function strsplit(Input: string; const Delimiter: Char):TStrings;
begin
    result:=tstringlist.Create;
   Assert(Assigned(result));
   //result.Clear;
   result.StrictDelimiter := true;
   result.Delimiter := Delimiter;
   result.DelimitedText := Input;
end;

function IsNumber(N : String) : Boolean;
var
    I : Integer;
begin
    Result := True;
    if Trim(N) = '' then
        Exit(False);

    if (Length(Trim(N)) > 1) and (Trim(N)[1] = '0') then
        Exit(False);

    for I := 1 to Length(N) do
    begin
         if not (N[I] in ['0'..'9']) then
         begin
             Result := False;
             Break;
         end;
    end;
end;

end.

