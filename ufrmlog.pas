unit ufrmlog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,utalkiewalkie,
  windows;

type

  thrlog=class(tthread)
    procedure execute;override;
  end;

  { Tfrmlog_ }

  Tfrmlog_ = class(TForm)
    btnclearlog: TButton;
    btnsavelog: TButton;
    chkbottom: TCheckBox;
    grplog: TGroupBox;
    mmlog: TMemo;
    procedure btnclearlogClick(Sender: TObject);
    procedure btnsavelogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  frmlog_: Tfrmlog_;
  createlogthr:boolean;

implementation

{$R *.lfm}

{ Tfrmlog_ }

procedure thrlog.execute;
var
     lastindex,lastpos:integer;
     i:integer;
     strs:tstringlist;
begin
  frmlog_.mmlog.Lines.clear;
  strs:=tstringlist.create;
  lastindex:=0;
  while true do
  begin
    sleep(100);
    if frmlog_.visible then
    begin
      try
        with tdata(data^)._log do
        begin
          if (index<>lastindex) then
          begin
            strs.clear;
            lastpos:=frmlog_.mmlog.selstart;
            for i:=0 to index do strs.add(strings[i]);
            frmlog_.mmlog.Lines:=strs;
            if frmlog_.chkbottom.Checked then
                frmlog_.mmlog.selstart:=frmlog_.mmlog.Lines.Text.length
            else
                frmlog_.mmlog.selstart:=lastpos;
            lastindex:=index;
          end;
        end;
      except
        showmessage('Error reading log: '+inttostr(getlasterror));
      end;
    end;
  end;
end;

procedure Tfrmlog_.btnsavelogClick(Sender: TObject);
var
  fg:tsavedialog;
begin
  fg:=tsavedialog.create(self);
  fg.DefaultExt:='.log';
  fg.InitialDir:=sysutils.getcurrentdir;
  fg.FileName:='memhacker.log';
  if fg.execute=true then
  begin
    mmlog.Lines.SaveToFile(fg.filename);
  end;
end;

procedure Tfrmlog_.FormCreate(Sender: TObject);
begin
  with thrlog.create(false) do freeonterminate:=true;
end;

procedure Tfrmlog_.btnclearlogClick(Sender: TObject);
begin
  if tdata(data^).cmd<>0 then exit;
  tdata(data^)._log.index:=0;
  fillchar(tdata(data^)._log.strings,sizeof(tdata(data^)._log.strings),0);
end;


end.

