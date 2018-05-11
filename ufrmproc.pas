unit ufrmproc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls,utalkiewalkie,winmiscutils,windows;

type

  thrui=class(tthread)
    procedure execute;override;
  end;
  { Tfrmprocthr }

  Tfrmprocthr = class(TForm)
    btnbrowse: TButton;
    btninject: TButton;
    btnrefresh: TButton;
    btnrefreshinfos: TButton;
    btnresume: TButton;
    btnresumethread: TButton;
    btnsuspend: TButton;
    btnsuspthread: TButton;
    btnterminate: TButton;
    btntermthread: TButton;
    btnthrinfos: TButton;
    btngethandle: TButton;
    cmbtid: TComboBox;
    grpinjection: TGroupBox;
    grpprocinfos: TGroupBox;
    grpthreadutils: TGroupBox;
    lblpname: TLabel;
    lbltid: TLabel;
    txtbaseaddr: TLabeledEdit;
    txthandle: TLabeledEdit;
    txtmaintid: TLabeledEdit;
    txtPath: TLabeledEdit;
    txtPID: TLabeledEdit;
    txtprocess: TComboBox;
    txtthrhandle: TLabeledEdit;
    procedure btnbaseaddrClick(Sender: TObject);
    procedure btnbrowseClick(Sender: TObject);
    procedure btngethandleClick(Sender: TObject);
    procedure btnhandleClick(Sender: TObject);
    procedure btninjectClick(Sender: TObject);
    procedure btnrefreshinfosClick(Sender: TObject);
    procedure btnresumeClick(Sender: TObject);
    procedure btnresumethreadClick(Sender: TObject);
    procedure btnsuspendClick(Sender: TObject);
    procedure btnsuspthreadClick(Sender: TObject);
    procedure btnterminateClick(Sender: TObject);
    procedure btnrefreshClick(Sender: TObject);
    procedure btntermthreadClick(Sender: TObject);
    procedure btnthrinfosClick(Sender: TObject);
    procedure cmbtidChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  frmprocthr: Tfrmprocthr;

implementation

procedure thrui.execute;
var
     i:integer;
     strs:tstringlist;
     lasterror:integer;
     _lastmodified:integer;
begin
  _lastmodified:=0;
  strs:=tstringlist.create;
  while true do
  begin
    //frmprocthr.lbltid.caption:=inttostr(gettickcount);
    sleep(100);
    if data<>nil then
    begin
      try
          setlasterror(0);
          with frmprocthr do
          begin
            txtbaseaddr.text:=string(tdata(data^).processinfos.baseaddr);
            txthandle.text:='$'+inttohex(qword(tdata(data^).processinfos.syshandle),4);
            txtpid.text:=inttostr(tdata(data^).processinfos.pid);
            txtmaintid.text:=inttostr(tdata(data^).processinfos.maintid);
            //
            strs.clear;
            if _lastmodified<>tdata(data^).thrlastmodified then
            begin
              _lastmodified:=tdata(data^).thrlastmodified;
              for i:=0 to 1023 do
              begin
                if tdata(data^).threadinfos[i].tid<>0 then
                begin
                  strs.Add(inttostr(tdata(data^).threadinfos[i].tid));
                end;
              end;
              cmbtid.items:=strs;
              if cmbtid.Items.count>0 then cmbtid.itemindex:=0;
            end;
          end;
      except
          lasterror:=getlasterror;
          if lasterror<>0 then showmessage('Error reading response: '+inttostr(lasterror));
      end;
    end;
  end;
  showmessage('leaving proc ui thread');
end;
procedure Tfrmprocthr.btnrefreshClick(Sender: TObject);
var
  processes:tstringlist;
  i:integer;
begin
  processes:=tstringlist.create;
  enumprocesses(processes);
  txtprocess.Items.clear;
  for i:=0 to processes.Count-1 do txtprocess.Items.Add(processes[i]);
  processes.Free;
  if txtprocess.items.Count>0 then txtprocess.ItemIndex:=0;
end;

procedure Tfrmprocthr.btntermthreadClick(Sender: TObject);
begin
  tdata(data^).pid:=strtoint(cmbtid.text);
  tdata(data^).value:=inttostr(0);
  tdata(data^).cmd:=cmd_TERMINATETHREAD;
end;

procedure Tfrmprocthr.btnthrinfosClick(Sender: TObject);
begin
  tdata(data^).value:=txtprocess.text;
  tdata(data^).cmd:=cmd_GETTHRINFOS;
end;

procedure Tfrmprocthr.cmbtidChange(Sender: TObject);
begin
end;

procedure Tfrmprocthr.FormCreate(Sender: TObject);
begin
  with thrui.create(false) do freeonterminate:=true;
  btnrefreshclick(sender);
end;

procedure Tfrmprocthr.btnrefreshinfosClick(Sender: TObject);
var
  adata:tdata;
begin
  adata._log:=tdata(data^)._log;
  adata.searchdata:=tdata(data^).searchdata;
  adata.threadinfos:=tdata(data^).threadinfos;
  adata.thrlastmodified:=tdata(data^).thrlastmodified;
  adata.value:=txtprocess.text;
  adata.cmd:=cmd_GETINFOS;
  writedata(adata);
end;

procedure Tfrmprocthr.btnresumeClick(Sender: TObject);
begin
  tdata(data^).pid:=getpidbyprocessname(txtprocess.text);
  tdata(data^).cmd:=cmd_RESUMEPROCESS;
end;

procedure Tfrmprocthr.btnresumethreadClick(Sender: TObject);
begin
  tdata(data^).pid:=strtoint(cmbtid.text);
  tdata(data^).cmd:=cmd_RESUMETHREAD;
end;

procedure Tfrmprocthr.btnsuspendClick(Sender: TObject);
begin
  tdata(data^).pid:=getpidbyprocessname(txtprocess.text);
  tdata(data^).cmd:=cmd_SUSPENDPROCESS;
end;

procedure Tfrmprocthr.btnsuspthreadClick(Sender: TObject);
begin
  tdata(data^).pid:=strtoint(cmbtid.text);
  tdata(data^).cmd:=cmd_SUSPENDTHREAD;
end;

procedure Tfrmprocthr.btnterminateClick(Sender: TObject);
begin
  tdata(data^).pid:=getpidbyprocessname(txtprocess.text);
  tdata(data^).value:='0';
  tdata(data^).cmd:=cmd_TERMINATEPROCESS;
end;

procedure Tfrmprocthr.btnhandleClick(Sender: TObject);
var
  adata:tdata;
begin
  adata.cmd:=cmd_GETHANDLE;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  adata.searchdata:=tdata(data^).searchdata;
  adata._log:=tdata(data^)._log;
  writedata(adata);
end;

procedure Tfrmprocthr.btninjectClick(Sender: TObject);
var
  adata:tdata;
begin
  if not fileexists(txtpath.text) then
  begin
    showmessage('DLL not found!');
    exit;
  end;
  adata.cmd:=cmd_INJECT;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  adata.value:=txtpath.text;
  adata.valuelength:=length(txtpath.text);
  adata.searchdata:=tdata(data^).searchdata;
  adata._log:=tdata(data^)._log;
  adata.processinfos:=tdata(data^).processinfos;
  writedata(adata);
end;

procedure Tfrmprocthr.btnbaseaddrClick(Sender: TObject);
var
  adata:tdata;
begin
  adata.cmd:=cmd_GETBASEADDR;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  adata.value:=txtprocess.text;
  adata.searchdata:=tdata(data^).searchdata;
  adata._log:=tdata(data^)._log;
  writedata(adata);
end;

procedure Tfrmprocthr.btnbrowseClick(Sender: TObject);
var
  dialog:topendialog;
begin
  dialog:=topendialog.create(frmprocthr);
  dialog.DefaultExt:='.dll';
  dialog.InitialDir:=getcurrentdir;
  if dialog.execute then txtpath.text:=dialog.filename;
  dialog.free;
end;

procedure Tfrmprocthr.btngethandleClick(Sender: TObject);
begin
  txtthrhandle.Text:=inttostr(tdata(data^).threadinfos[cmbtid.itemindex].handle);
end;

{$R *.lfm}

end.

