{
  Copyright 2014 Stas'M Corp.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
}

unit LiteINI;

interface

uses
  SysUtils;

type
  SList = Array of String;
  INIValue = record
    Name: String;
    Value: String;
  end;
  INISection = record
    Name: String;
    Values: Array of INIValue;
  end;
  INIFile = Array of INISection;

procedure SListClear(var List: SList);
function SListAppend(var List: SList; S: String): Integer;
function SListFind(List: SList; Value: String): Integer;
function INIFindSection(INI: INIFile; Section: String): Integer;
function INIFindValue(INI: INIFile; Section: Integer; Value: String): Integer;
function INIAddSection(var INI: INIFile; Section: String): Integer;
function INIAddValue(var INI: INIFile; Section: Integer; ValueName, Value: String): Integer;
procedure INIUnload(var INI: INIFile);
procedure INILoad(var INI: INIFile; FileName: String);
function INISectionExists(INI: INIFile; Section: String): Boolean;
function INIValueExists(INI: INIFile; Section: String; Value: String): Boolean;
function INIReadSectionLowAPI(INI: INIFile; Section: Integer; var List: SList): Boolean;
function INIReadSection(INI: INIFile; Section: String): SList;
function INIReadStringLowAPI(INI: INIFile; Section, Value: Integer; var Str: String): Boolean;
function INIReadString(INI: INIFile; Section, Value, Default: String): String;
function INIReadInt(INI: INIFile; Section, Value: String; Default: Integer): Integer;
function INIReadDWord(INI: INIFile; Section, Value: String; Default: Cardinal): Cardinal;
function INIReadIntHex(INI: INIFile; Section, Value: String; Default: Integer): Integer;
function INIReadDWordHex(INI: INIFile; Section, Value: String; Default: Cardinal): Cardinal;
function INIReadBool(INI: INIFile; Section, Value: String; Default: Boolean): Boolean;
function INIReadBytes(INI: INIFile; Section, Value: String): TBytes;
function INIReadBytesDef(INI: INIFile; Section, Value: String; Default: TBytes): TBytes;

implementation

procedure SListClear(var List: SList);
begin
  SetLength(List, 0);
end;

function SListAppend(var List: SList; S: String): Integer;
begin
  SetLength(List, Length(List) + 1);
  List[Length(List) - 1] := S;
  Result := Length(List) - 1;
end;

function SListFind(List: SList; Value: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Length(List) - 1 do
    if List[I] = Value then begin
      Result := I;
      Break;
    end;
end;

function INIFindSection(INI: INIFile; Section: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Length(INI) - 1 do
    if INI[I].Name = Section then begin
      Result := I;
      Exit;
    end;
end;

function INIFindValue(INI: INIFile; Section: Integer; Value: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  if (Section < 0) or (Section >= Length(INI)) then
    Exit;
  for I := 0 to Length(INI[Section].Values) - 1 do
    if INI[Section].Values[I].Name = Value then begin
      Result := I;
      Exit;
    end;
end;

function INIAddSection(var INI: INIFile; Section: String): Integer;
begin
  Result := INIFindSection(INI, Section);
  if Result >= 0 then
    Exit;
  Result := Length(INI);
  SetLength(INI, Result + 1);
  INI[Result].Name := Section;
  SetLength(INI[Result].Values, 0);
end;

function INIAddValue(var INI: INIFile; Section: Integer; ValueName, Value: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  if (Section < 0) or (Section >= Length(INI)) then
    Exit;
  I := INIFindValue(INI, Section, ValueName);
  if I = -1 then begin
    Result := Length(INI[Section].Values);
    SetLength(INI[Section].Values, Result + 1);
    INI[Section].Values[Result].Name := ValueName;
    INI[Section].Values[Result].Value := Value;
  end else begin
    INI[Section].Values[I].Value := Value;
    Result := I;
  end;
end;

procedure INIUnload(var INI: INIFile);
begin
  SetLength(INI, 0);
end;

procedure INILoad(var INI: INIFile; FileName: String);
var
  F: TextFile;
  S, ValueName, Value: String;
  INIList: SList;
  I, Sect: Integer;
begin
  INIUnload(INI);
  if not FileExists(FileName) then
    Exit;
  AssignFile(F, FileName);
  Reset(F);
  // Read and filter lines
  while not EOF(F) do begin
    Readln(F, S);
    if (Pos(';', S) <> 1)
    and (Pos('#', S) <> 1)
    and (
      ((Pos('[', S) > 0) and (Pos(']', S) > 0)) or
      (Pos('=', S) > 0)
    )
    then
      SListAppend(INIList, S);
  end;
  CloseFile(F);
  // Parse 2 (parse format)
  Sect := -1;
  for I := 0 to Length(INIList) - 1 do begin
    S := Trim(INIList[I]);
    if Length(S) >= 2 then
      if (S[1] = '[') and (S[Length(S)] = ']') then begin
        S := Trim(Copy(S, 2, Length(S) - 2));
        Sect := INIAddSection(INI, S);
        Continue;
      end;
    S := INIList[I];
    if Pos('=', S) > 0 then begin
      ValueName := Trim(Copy(S, 1, Pos('=', S) - 1));
      Value := Copy(S, Pos('=', S) + 1, Length(S) - Pos('=', S));
      if Sect = -1 then
        Sect := INIAddSection(INI, '');
      INIAddValue(INI, Sect, ValueName, Value);
    end;
  end;
end;

function INISectionExists(INI: INIFile; Section: String): Boolean;
begin
  Result := INIFindSection(INI, Section) > -1;
end;

function INIValueExists(INI: INIFile; Section: String; Value: String): Boolean;
var
  Sect: Integer;
begin
  Sect := INIFindSection(INI, Section);
  Result := INIFindValue(INI, Sect, Value) > -1;
end;

function INIReadSectionLowAPI(INI: INIFile; Section: Integer; var List: SList): Boolean;
var
  I: Integer;
begin
  Result := False;
  SetLength(List, 0);
  if (Section < 0) or (Section >= Length(INI)) then
    Exit;
  for I := 0 to Length(INI[Section].Values) - 1 do
    SListAppend(List, INI[Section].Values[I].Name);
  Result := True;
end;

function INIReadSection(INI: INIFile; Section: String): SList;
var
  Sect: Integer;
begin
  Sect := INIFindSection(INI, Section);
  INIReadSectionLowAPI(INI, Sect, Result);
end;

function INIReadStringLowAPI(INI: INIFile; Section, Value: Integer; var Str: String): Boolean;
begin
  Result := False;
  if (Section < 0) or (Section >= Length(INI)) then
    Exit;
  if (Value < 0) or (Value >= Length(INI[Section].Values)) then
    Exit;
  Str := INI[Section].Values[Value].Value;
  Result := True;
end;

function INIReadString(INI: INIFile; Section, Value, Default: String): String;
var
  Sect, Val: Integer;
begin
  Sect := INIFindSection(INI, Section);
  Val := INIFindValue(INI, Sect, Value);
  if not INIReadStringLowAPI(INI, Sect, Val, Result) then
    Result := Default;
end;

function INIReadInt(INI: INIFile; Section, Value: String; Default: Integer): Integer;
var
  S: String;
  E: Integer;
begin
  S := INIReadString(INI, Section, Value, '');
  Val(S, Result, E);
  if E <> 0 then
    Result := Default;
end;

function INIReadDWord(INI: INIFile; Section, Value: String; Default: Cardinal): Cardinal;
var
  S: String;
  E: Integer;
begin
  S := INIReadString(INI, Section, Value, '');
  Val(S, Result, E);
  if E <> 0 then
    Result := Default;
end;

function INIReadIntHex(INI: INIFile; Section, Value: String; Default: Integer): Integer;
var
  S: String;
  E: Integer;
begin
  S := INIReadString(INI, Section, Value, '');
  Val('$'+S, Result, E);
  if E <> 0 then
    Result := Default;
end;

function INIReadDWordHex(INI: INIFile; Section, Value: String; Default: Cardinal): Cardinal;
var
  S: String;
  E: Integer;
begin
  S := INIReadString(INI, Section, Value, '');
  Val('$'+S, Result, E);
  if E <> 0 then
    Result := Default;
end;

function INIReadBool(INI: INIFile; Section, Value: String; Default: Boolean): Boolean;
var
  S: String;
  I: Cardinal;
  E: Integer;
begin
  S := INIReadString(INI, Section, Value, '');
  Val(S, I, E);
  if E <> 0 then
    Result := Default
  else
    Result := I > 0;
end;

function StringToBytes(S: String; var B: TBytes): Boolean;
var
  I: Integer;
begin
  Result := False;
  if Odd(Length(S)) then
    Exit;
  SetLength(B, Length(S) div 2);
  for I := 0 to Length(B) - 1 do begin
    B[I] := 0;
    case S[(I*2)+2] of
      '0': ;
      '1': B[I] := B[I] or $1;
      '2': B[I] := B[I] or $2;
      '3': B[I] := B[I] or $3;
      '4': B[I] := B[I] or $4;
      '5': B[I] := B[I] or $5;
      '6': B[I] := B[I] or $6;
      '7': B[I] := B[I] or $7;
      '8': B[I] := B[I] or $8;
      '9': B[I] := B[I] or $9;
      'A','a': B[I] := B[I] or $A;
      'B','b': B[I] := B[I] or $B;
      'C','c': B[I] := B[I] or $C;
      'D','d': B[I] := B[I] or $D;
      'E','e': B[I] := B[I] or $E;
      'F','f': B[I] := B[I] or $F;
      else Exit;
    end;
    case S[(I*2)+1] of
      '0': ;
      '1': B[I] := B[I] or $10;
      '2': B[I] := B[I] or $20;
      '3': B[I] := B[I] or $30;
      '4': B[I] := B[I] or $40;
      '5': B[I] := B[I] or $50;
      '6': B[I] := B[I] or $60;
      '7': B[I] := B[I] or $70;
      '8': B[I] := B[I] or $80;
      '9': B[I] := B[I] or $90;
      'A','a': B[I] := B[I] or $A0;
      'B','b': B[I] := B[I] or $B0;
      'C','c': B[I] := B[I] or $C0;
      'D','d': B[I] := B[I] or $D0;
      'E','e': B[I] := B[I] or $E0;
      'F','f': B[I] := B[I] or $F0;
      else Exit;
    end;
  end;
  Result := True;
end;

function INIReadBytes(INI: INIFile; Section, Value: String): TBytes;
var
  S: String;
begin
  S := INIReadString(INI, Section, Value, '');
  if not StringToBytes(S, Result) then
    SetLength(Result, 0);
end;

function INIReadBytesDef(INI: INIFile; Section, Value: String; Default: TBytes): TBytes;
var
  S: String;
begin
  S := INIReadString(INI, Section, Value, '');
  if not StringToBytes(S, Result) then
    Result := Default;
end;

end.
