unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,winmitigations
  ,windows,winmiscutils in '..\winmiscutils.pas';

type

  { TForm1 }

  TForm1 = class(TForm)  
    btndword: TButton;
    btnstring: TButton;
    btnqword: TButton;
    btnsingle: TButton;
    chknewvalue: TCheckBox;
    Memo1: TMemo;
    procedure btndwordClick(Sender: TObject);
    procedure btnqwordClick(Sender: TObject);
    procedure btnsingleClick(Sender: TObject);
    procedure btnstringClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  toto:dword;
  totoqword:qword;
  totosingle:single;
  totostring:ansistring;
  lastclicked:integer;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btndwordClick(Sender: TObject);
begin
  if chknewvalue.checked then toto:=random(9999);
  memo1.Lines.Clear ;
  memo1.Lines.Add(inttostr(toto));
  Memo1.Lines.Add('addr $'+inttohex(qword(addr(toto)),8));
  Memo1.Lines.Add('pointer $'+inttohex(qword(@toto),8));
end;

procedure TForm1.btnqwordClick(Sender: TObject);
begin
  if chknewvalue.checked then totoqword:=random(9999);
  memo1.Lines.Clear ;
  memo1.Lines.Add(inttostr(totoqword));
  Memo1.Lines.Add('addr $'+inttohex(qword(addr(totoqword)),8));
  Memo1.Lines.Add('pointer $'+inttohex(qword(@totoqword),8));
end;

procedure TForm1.btnsingleClick(Sender: TObject);
begin
  if chknewvalue.checked then totosingle:=random(9999);
  memo1.Lines.Clear ;
  memo1.Lines.Add(floattostr(totosingle));
  Memo1.Lines.Add('addr $'+inttohex(qword(addr(totosingle)),8));
  Memo1.Lines.Add('pointer $'+inttohex(qword(@totosingle),8));
end;

procedure TForm1.btnstringClick(Sender: TObject);
begin
  if chknewvalue.checked then totostring:=chr(random(94)+33)+chr(random(94)+33)+chr(random(94)+33)+chr(random(94)+33);
  memo1.Lines.Clear ;
  memo1.Lines.Add(totostring);
  Memo1.Lines.Add('addr $'+inttohex(qword(addr(totostring)),8));
  Memo1.Lines.Add('pointer $'+inttohex(qword(@totostring),8));
  memo1.lines.add('str[2]='+totostring[2])
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  dwpolicy:dword;
begin
  randomize;
  dwpolicy:=0;
  setprocessmitigationpolicy(processaslrpolicy,@dwpolicy,4);
  showmessage(inttohex(openprocess(process_all_access,false,getpidbyprocessname('notepad.exe')),4));
end;

end.

