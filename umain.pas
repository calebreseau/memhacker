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

  Tfrmmain = class(TForm)
    btnwrite: TButton;
    btnread: TButton;
    btnrefresh: TButton;
    lbllength: TLabel;
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
    procedure btnreadClick(Sender: TObject);
    procedure btnrefreshClick(Sender: TObject);
    procedure btnwriteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
     lsasshandle:thandle;
     lsasspid:integer;
     th:thandle;
     ch:client_id;
     stat:dword;
begin
     setprivilege('sedebugprivilege',true);  //get debug privileges so we can inject into lsass
     lsasspid:=getpidbyprocessname('lsass.exe');
     lsasshandle:=openprocess(process_all_access,false,lsasspid);
     if lsasshandle<1 then
     begin
          showmessage('Error opening LSASS: '+inttostr(getlasterror));
          halt;
     end;
     stat:=injectsys(lsasshandle,false,th,ch,getcurrentdir+'\memhacker.dll'+chr(0));
     if stat<>0 then
     begin
          showmessage('Error injecting dll: '+inttostr(stat));
          closehandle(lsasshandle);
          halt;
     end;
     closehandle(lsasshandle);
end;


procedure init_main;
begin        
    tw_init_srv;
    init_inject;
    with thrui.create(false) do freeonterminate:=true;
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

end.

