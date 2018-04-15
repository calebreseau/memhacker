unit umain;

{$mode objfpc}{$H+}

interface

uses 
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, wininjection,winmiscutils,utalkiewalkie,ntdll,windows;

type

  { Tfrmmain }


  thrui=class(tthread) 
    procedure execute;override;
  end;

  thrlog=class(tthread)
    procedure execute;override;
  end;

  Tfrmmain = class(TForm)
    btnsavelog: TButton;
    btnwrite: TButton;
    btnread: TButton;
    btnrefresh: TButton;
    btnhandle: TButton;
    btnlog: TButton;
    grplog: TGroupBox;
    lbllength: TLabel;
    mmlog: TMemo;
    txtlength: TEdit;
    grpvtype: TGroupBox;
    grpmemutils: TGroupBox;
    txtresp: TLabeledEdit;
    rbdword: TRadioButton;
    rbqword: TRadioButton;
    rbfloat: TRadioButton;
    rbstring: TRadioButton;
    txtvalue: TLabeledEdit;
    txtaddr: TLabeledEdit;
    lblpname: TLabel;
    txtprocess: TComboBox;
    procedure btnhandleClick(Sender: TObject);
    procedure btnreadClick(Sender: TObject);
    procedure btnrefreshClick(Sender: TObject);
    procedure btnsavelogClick(Sender: TObject);
    procedure btnwriteClick(Sender: TObject);
    procedure btnlogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure txtaddrChange(Sender: TObject);
    procedure txtlengthChange(Sender: TObject);
  private

  public

  end;

var
  frmmain: Tfrmmain;

implementation

{$R *.lfm}

{ Tfrmmain }

procedure init_inject;
var
     targetname:string;
     targethandle:thandle;
     targetpid:integer;
     th:thandle;
     ch:client_id;
     stat:dword;
begin
     if paramcount>0 then targetname:=paramstr(1) else targetname:='lsass.exe';
     setprivilege('sedebugprivilege',true);  //get debug privileges so we can inject into lsass
     targetpid:=getpidbyprocessname(targetname);
     targethandle:=openprocess(process_all_access,false,targetpid);
     if targethandle<1 then
     begin
          showmessage('Error opening '+targetname+': '+inttostr(getlasterror));
          halt;
     end;
     stat:=injectsys(targethandle,false,th,ch,getcurrentdir+'\memhacker.dll'+chr(0));
     if stat<>0 then
     begin
          showmessage('Error injecting dll: '+inttostr(stat));
          closehandle(targethandle);
          halt;
     end;
     closehandle(targethandle);
end;


procedure init_main;
begin        
    tw_init_srv;
    tw_init_srv_log;
    init_inject;
    with thrui.create(false) do freeonterminate:=true;
    with thrlog.create(false) do freeonterminate:=true;
end;

procedure thrui.execute;
begin
  while true do
  begin
    sleep(100);
    try
        setlasterror(0);
        if data<>nil then frmmain.txtresp.text:=string(tdata(data^).response);
    except
        showmessage('Error reading response: '+inttostr(getlasterror));
    end;
  end;
end;

procedure thrlog.execute;
var
     lastindex:integer;
     i:integer;
begin
  lastindex:=0;
  while true do
  begin
    sleep(100);
    try
      with tlog(datalog^) do
      begin
        if index<>lastindex then
        begin
          frmmain.mmlog.clear;
          for i:=0 to index do frmmain.mmlog.Lines.add(strings[i]);
          lastindex:=index;
        end;
      end;
    except
      showmessage('Error reading log: '+inttostr(getlasterror));
    end;
  end;
end;

procedure Tfrmmain.FormCreate(Sender: TObject);
begin
     btnrefreshclick(sender);
     if fileexists('memhacker.dll') then init_main
     else
     begin
       showmessage('Error: memhacker.dll not found');
       halt;
     end;
end;

procedure Tfrmmain.FormDestroy(Sender: TObject);
begin
  tw_exit;
  tw_exit_log;
end;


procedure Tfrmmain.txtaddrChange(Sender: TObject);
begin
  if length(txtaddr.Text)=0 then txtaddr.text:='$';
end;

procedure Tfrmmain.txtlengthChange(Sender: TObject);
begin
  if txtlength.text='' then txtlength.text:='0';
  if strtoint(txtlength.text)>16 then txtlength.text:='16';
end;

procedure Tfrmmain.btnwriteClick(Sender: TObject);
var
  adata:tdata;
begin
  adata.value:=txtvalue.text;
  if rbstring.checked then
  begin
       adata.valuetype:=vt_string;
       adata.valuelength:=strtoint64(txtlength.text);
  end;
  if rbdword.checked then
  begin
       adata.valuetype:=vt_dword;
       adata.valuelength:=4;
  end;
  if rbqword.checked then
  begin
       adata.valuetype:=vt_qword;
       adata.valuelength:=8;
  end;
  if rbfloat.checked then
  begin
       adata.valuetype:=vt_float;
       adata.valuelength:=4;
  end;
  adata.addr:=strtoint64(txtaddr.text);
  adata.cmd:=1;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  writedata(adata);
end;

procedure Tfrmmain.btnlogClick(Sender: TObject);
begin
    if frmmain.width=652 then
    begin
      frmmain.width:=311;
      btnlog.caption:='Show log';
    end
    else
    begin
      frmmain.width:=652;
      btnlog.caption:='Hide log';
    end;
end;

procedure Tfrmmain.btnrefreshClick(Sender: TObject);
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

procedure Tfrmmain.btnsavelogClick(Sender: TObject);
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

procedure Tfrmmain.btnreadClick(Sender: TObject);
var
  adata:tdata;
begin
  if rbstring.checked then
  begin
       adata.valuelength:=strtoint64(txtlength.text);
       adata.valuetype:=vt_string;
  end;
  if rbdword.checked then
  begin
       adata.valuelength:=4;
       adata.valuetype:=vt_dword;
  end;
  if rbqword.checked then
  begin
       adata.valuelength:=8;
       adata.valuetype:=vt_qword;
  end;
  if rbfloat.checked then
  begin
       adata.valuelength:=4;
       adata.valuetype:=vt_float;
  end;
  adata.addr:=strtoint64(txtaddr.text);
  adata.cmd:=2;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  writedata(adata);
end;

procedure Tfrmmain.btnhandleClick(Sender: TObject);
var
  adata:tdata;
begin
  adata.cmd:=3;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  writedata(adata);
end;

end.

