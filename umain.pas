unit umain;

{$mode objfpc}{$H+}

interface

uses 
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, wininjection,winmiscutils,utalkiewalkie,ntdll,windows,umem;

type

  { Tfrmmain }


  thrui=class(tthread) 
    procedure execute;override;
  end;

  thrlog=class(tthread)
    procedure execute;override;
  end;

  Tfrmmain = class(TForm)
    btnsearch: TButton;
    btnsavelog: TButton;
    btnwrite: TButton;
    btnread: TButton;
    btnrefresh: TButton;
    btnhandle: TButton;
    btnlog: TButton;
    chkadvsearch: TCheckBox;
    grpsearch: TGroupBox;
    grplog: TGroupBox;
    grpsvtype: TGroupBox;
    lstaddrs: TListBox;
    txtsstart: TLabeledEdit;
    lbllength: TLabel;
    lblslength: TLabel;
    mmlog: TMemo;
    rbsdword: TRadioButton;
    rbsfloat: TRadioButton;
    rbsqword: TRadioButton;
    rbsstring: TRadioButton;
    txtlength: TEdit;
    grpvtype: TGroupBox;
    grpmemutils: TGroupBox;
    txtslength: TEdit;
    txtresp: TLabeledEdit;
    rbdword: TRadioButton;
    rbqword: TRadioButton;
    rbfloat: TRadioButton;
    rbstring: TRadioButton;
    txtsend: TLabeledEdit;
    txtsvalue: TLabeledEdit;
    txtvalue: TLabeledEdit;
    txtaddr: TLabeledEdit;
    lblpname: TLabel;
    txtprocess: TComboBox;
    procedure btnhandleClick(Sender: TObject);
    procedure btnreadClick(Sender: TObject);
    procedure btnrefreshClick(Sender: TObject);
    procedure btnsavelogClick(Sender: TObject);
    procedure btnsearchClick(Sender: TObject);
    procedure btnwriteClick(Sender: TObject);
    procedure btnlogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lstaddrsClick(Sender: TObject);
    procedure lstaddrsDblClick(Sender: TObject);
    procedure lstaddrsSelectionChange(Sender: TObject; User: boolean);
    procedure txtaddrChange(Sender: TObject);
    procedure txtlengthChange(Sender: TObject);
    procedure txtprocessChange(Sender: TObject);
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
    init_inject;
    with thrui.create(false) do freeonterminate:=true;
    with thrlog.create(false) do freeonterminate:=true;
end;

procedure thrui.execute;
var
     lastindex:integer;
     i:integer;
begin
    lastindex:=0;
  while true do
  begin
    sleep(100);
    try
        setlasterror(0);
        if data<>nil then
        begin
          frmmain.txtresp.text:=string(tdata(data^).response);
        end;
        with tdata(data^).searchdata do
        begin
          if index<>lastindex then
          begin
            frmmain.lstaddrs.clear;
            for i:=0 to index do frmmain.lstaddrs.Items.add(retaddrs[i]);
            lastindex:=index;
          end;
        end;
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
      with tdata(data^)._log do
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
end;

procedure Tfrmmain.lstaddrsClick(Sender: TObject);
begin
    if lstaddrs.itemindex<0 then exit;
    if length(lstaddrs.items[lstaddrs.itemindex])<2 then exit;
    txtaddr.Text:=lstaddrs.items[lstaddrs.itemindex];
    rbdword.checked:=rbsdword.checked;
    rbqword.checked:=rbsqword.checked;
    rbfloat.checked:=rbsfloat.checked;
    rbstring.checked:=rbsstring.checked;
    txtlength.text:=txtslength.text;
    btnreadclick(nil);
end;

procedure Tfrmmain.lstaddrsDblClick(Sender: TObject);
begin
  lstaddrs.clear;
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

procedure Tfrmmain.lstaddrsSelectionChange(Sender: TObject; User: boolean);
begin

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

procedure Tfrmmain.txtprocessChange(Sender: TObject);
begin

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
  adata.searchdata:=tdata(data^).searchdata;
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

procedure Tfrmmain.btnsearchClick(Sender: TObject);
var
  adata:tdata;
  asearchdata:tsearchdata;
begin
  asearchdata.value:=txtsvalue.text;
  if rbsstring.checked then
  begin
       asearchdata.valuetype:=vt_string;
       asearchdata.valuelength:=strtoint64(txtslength.text);
  end;
  if rbsdword.checked then
  begin
       asearchdata.valuetype:=vt_dword;
       asearchdata.valuelength:=4;
  end;
  if rbsqword.checked then
  begin
       asearchdata.valuetype:=vt_qword;
       asearchdata.valuelength:=8;
  end;
  if rbsfloat.checked then
  begin
       asearchdata.valuetype:=vt_float;
       asearchdata.valuelength:=4;
  end;
  asearchdata.advsearch:=chkadvsearch.checked;
  asearchdata.startaddr:=strtoint64(txtsstart.text);
  if strtoint64(txtsend.text)>strtoint64(txtsstart.text) then
    asearchdata.endaddr:=strtoint64(txtsend.text)
    else asearchdata.endaddr:=9223372036854775807;
  adata.searchdata:=asearchdata;
  adata.cmd:=4;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  writedata(adata);
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
  adata.searchdata:=tdata(data^).searchdata;
  writedata(adata);
end;

procedure Tfrmmain.btnhandleClick(Sender: TObject);
var
  adata:tdata;
begin
  adata.cmd:=3;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  adata.searchdata:=tdata(data^).searchdata;
  writedata(adata);
end;

end.

