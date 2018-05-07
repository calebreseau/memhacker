unit umain;

{$mode objfpc}{$H+}

interface

uses 
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, wininjection, winmiscutils, utalkiewalkie, ntdll, windows, umem,
  lclintf, Menus, ComCtrls, strutils;

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
    btnresearch: TButton;
    btnclearlog: TButton;
    btnstopsearch: TButton;
    btnbaseaddr: TButton;
    chkbottom: TCheckBox;
    chkadvsearch: TCheckBox;
    grpsearch: TGroupBox;
    grplog: TGroupBox;
    grpsvtype: TGroupBox;
    lbladdrcount: TLabel;
    lblwebsite: TLabel;
    lstaddrs: TListBox;
    pgbsearch: TProgressBar;
    rbsarray: TRadioButton;
    rbarray: TRadioButton;
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
    procedure btnbaseaddrClick(Sender: TObject);
    procedure btnclearlogClick(Sender: TObject);
    procedure btnhandleClick(Sender: TObject);
    procedure btnreadClick(Sender: TObject);
    procedure btnrefreshClick(Sender: TObject);
    procedure btnresearchClick(Sender: TObject);
    procedure btnsavelogClick(Sender: TObject);
    procedure btnsearchClick(Sender: TObject);
    procedure btnstopsearchClick(Sender: TObject);
    procedure btnwriteClick(Sender: TObject);
    procedure btnlogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure grplogClick(Sender: TObject);
    procedure lblwebsiteClick(Sender: TObject);
    procedure lstaddrsClick(Sender: TObject);
    procedure lstaddrsDblClick(Sender: TObject);
    procedure lstaddrsKeyPress(Sender: TObject; var Key: char);
    procedure lstaddrsSelectionChange(Sender: TObject; User: boolean);
    procedure mmlogChange(Sender: TObject);
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

function strsplit(Input: string; const Delimiter: Char):TStrings;
begin
    result:=tstringlist.Create;
   Assert(Assigned(result));
   //result.Clear;
   result.StrictDelimiter := true;
   result.Delimiter := Delimiter;
   result.DelimitedText := Input;
end;

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
     targethandle:=openprocess(process_vm_write or process_vm_operation or PROCESS_CREATE_THREAD ,false,targetpid);
     if targethandle<1 then
     begin
          showmessage('Error opening '+targetname+': '+inttostr(getlasterror));
          halt;
     end;
     stat:=injectsys(targethandle,false,th,ch,getcurrentdir+'\memhacker.dll'+chr(0));
     if stat<>0 then
     begin
          showmessage('Error injecting dll: '+inttohex(stat,8));
          closehandle(targethandle);
          halt;
     end;
     closehandle(targethandle);
end;


procedure init_main;
begin        
    if tw_init_srv=false then
    begin
      showmessage('couldnt init srv, exiting');
      halt;
    end;
    init_inject;
    with thrui.create(false) do freeonterminate:=true;
    with thrlog.create(false) do freeonterminate:=true;
end;

procedure thrui.execute;
var
     lastindex:integer;
     i:integer;
     strs:tstringlist;
begin
    strs:=tstringlist.create;
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
          frmmain.pgbsearch.max:=pgtotal;
          frmmain.pgbsearch.position:=pgcurr;
          frmmain.lbladdrcount.caption:='Found '+inttostr(addrcount)+' occurences';
          if index<>lastindex then
          begin
            strs.clear;
            for i:=0 to index do strs.add(retaddrs[i]);
            frmmain.lstaddrs.Items:=strs;
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
     lastindex,lastpos:integer;
     i:integer;
     strs:tstringlist;
begin
  strs:=tstringlist.create;
  lastindex:=0;
  while true do
  begin
    sleep(100);
    try
      with tdata(data^)._log do
      begin
        if (index<>lastindex) then
        begin
          strs.clear;
          lastpos:=frmmain.mmlog.selstart;
          for i:=0 to index do strs.add(strings[i]);
          frmmain.mmlog.Lines:=strs;
          if frmmain.chkbottom.checked then
              frmmain.mmlog.selstart:=frmmain.mmlog.Lines.Text.length
          else
              frmmain.mmlog.selstart:=lastpos;
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
     mmlog.Lines.clear;
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

procedure Tfrmmain.grplogClick(Sender: TObject);
begin

end;

procedure Tfrmmain.lblwebsiteClick(Sender: TObject);
begin
  openurl('https://caldevelopment.wordpress.com');
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
     if messagedlg('memhacker','Delete addresses ?',mtconfirmation,mbyesnocancel,0)<>mryes then exit;
     tdata(data^).searchdata.index:=0;
     tdata(data^).searchdata.addrcount:=0;
     tdata(data^).searchdata.pgtotal:=0;
     tdata(data^).searchdata.pgcurr:=0;
     fillchar(tdata(data^).searchdata.retaddrs,sizeof(tdata(data^).searchdata.retaddrs),chr(0));
end;

procedure Tfrmmain.lstaddrsKeyPress(Sender: TObject; var Key: char);
begin

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

procedure Tfrmmain.mmlogChange(Sender: TObject);
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
  tmparray:array[0..1023] of byte;
  bytes:tstrings;
  i:integer;
begin
  bytes:=tstringlist.create;
  fillchar(tmparray,1024,0);
  if rbarray.checked=false then adata.value:=txtvalue.text;
  if rbstring.checked then
  begin
       adata.valuetype:=vt_string;
       adata.valuelength:=strtoint64(txtlength.text);
  end;
  if rbdword.checked then
  begin
       adata.valuetype:=vt_dword;
       adata.valuelength:=sizeof(dword);
  end;
  if rbqword.checked then
  begin
       adata.valuetype:=vt_qword;
       adata.valuelength:=sizeof(qword);
  end;
  if rbfloat.checked then
  begin
       adata.value:=inttostr(round(strtofloat(txtvalue.text)));
       adata.valuetype:=vt_float;
       adata.valuelength:=sizeof(single);
  end;
  if rbarray.checked then
  begin
       adata.valuelength:=strtoint64(txtlength.text);
       adata.valuetype:=vt_bytearray;
       bytes:=strsplit(txtvalue.text,' ');
       for i:=0 to bytes.Count-1 do
       begin
         if (ansicontainsstr(bytes[i],'$')) and (length(bytes[i])=3) then
         begin
           tmparray[i]:=strtoint(bytes[i]);
         end else tmparray[i]:=$00;
       end;
       copymemory(@(adata.value[1]),@tmparray,adata.valuelength);
  end;
  adata.addr:=strtoint64(txtaddr.text);
  adata.cmd:=cmd_WRITE;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  adata.searchdata:=tdata(data^).searchdata;
  adata._log:=tdata(data^)._log;
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

procedure Tfrmmain.btnresearchClick(Sender: TObject);
var
  tmparray:array[0..1023] of byte;
  bytes:tstrings;
  i:integer;
begin
    tdata(data^).searchdata.stop:=false;
    if tdata(data^).searchdata.valuetype=vt_bytearray then
    begin
       tdata(data^).searchdata.valuelength:=strtoint64(txtlength.text);
       tdata(data^).searchdata.valuetype:=vt_bytearray;
       bytes:=strsplit(txtvalue.text,' ');
       for i:=0 to bytes.Count-1 do
       begin
         if (ansicontainsstr(bytes[i],'$')) and (length(bytes[i])=3) then
         begin
           tmparray[i]:=strtoint(bytes[i]);
         end else tmparray[i]:=$00;
       end;
       copymemory(@(tdata(data^).searchdata.value[1]),@tmparray,tdata(data^).searchdata.valuelength);
    end else tdata(data^).searchdata.value:=txtsvalue.text;
    tdata(data^).searchdata.pgcurr:=0;
    tdata(data^).cmd:=cmd_RESEARCH;
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
  tmparray:array[0..1023] of byte;
  bytes:tstrings;
  i:integer;
begin
  adata:=tdata(data^);
  bytes:=tstringlist.create;
  fillchar(tmparray,1024,0);
  if rbsarray.checked=false then adata.value:=txtvalue.text;
  asearchdata.stop:=false;
  asearchdata.value:=txtsvalue.text;
  asearchdata.pgcurr:=0;
  if rbsstring.checked then
  begin
       asearchdata.valuetype:=vt_string;
       asearchdata.valuelength:=strtoint64(txtslength.text);
  end;
  if rbsdword.checked then
  begin
       asearchdata.valuetype:=vt_dword;
       asearchdata.valuelength:=sizeof(dword);
  end;
  if rbsqword.checked then
  begin
       asearchdata.valuetype:=vt_qword;
       asearchdata.valuelength:=sizeof(qword);
  end;
  if rbsfloat.checked then
  begin
       asearchdata.valuetype:=vt_float;
       asearchdata.valuelength:=sizeof(single);
  end;
  if rbarray.checked then
  begin
       asearchdata.valuelength:=strtoint64(txtslength.text);
       asearchdata.valuetype:=vt_bytearray;
       bytes:=strsplit(txtsvalue.text,' ');
       for i:=0 to bytes.Count-1 do
       begin
         if (ansicontainsstr(bytes[i],'$')) and (length(bytes[i])=3) then
         begin
           tmparray[i]:=strtoint(bytes[i]);
         end else tmparray[i]:=$00;
       end;
       copymemory(@(asearchdata.value[1]),@tmparray,asearchdata.valuelength);
  end;
  asearchdata.advsearch:=chkadvsearch.checked;
  asearchdata.startaddr:=strtoint64(txtsstart.text);
  if strtoint64(txtsend.text)>strtoint64(txtsstart.text) then
    asearchdata.endaddr:=strtoint64(txtsend.text)
    else asearchdata.endaddr:=9223372036854775807;
  adata.searchdata:=asearchdata;
  adata.cmd:=cmd_SEARCH;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  writedata(adata);
end;

procedure Tfrmmain.btnstopsearchClick(Sender: TObject);
begin
  tdata(data^).searchdata.stop:=true;
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
       adata.valuelength:=sizeof(dword);
       adata.valuetype:=vt_dword;
  end;
  if rbqword.checked then
  begin
       adata.valuelength:=sizeof(qword);
       adata.valuetype:=vt_qword;
  end;
  if rbfloat.checked then
  begin
       adata.valuelength:=sizeof(single);
       adata.valuetype:=vt_float;
  end;
  if rbarray.checked then
  begin
       adata.valuelength:=strtoint64(txtlength.text);
       adata.valuetype:=vt_bytearray;
  end;
  adata.addr:=strtoint64(txtaddr.text);
  adata.cmd:=cmd_READ;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  adata.searchdata:=tdata(data^).searchdata;
  adata._log:=tdata(data^)._log;
  writedata(adata);
end;

procedure Tfrmmain.btnhandleClick(Sender: TObject);
var
  adata:tdata;
begin
  adata.cmd:=cmd_GETHANDLE;
  adata.pid:=getpidbyprocessname(txtprocess.text);
  adata.searchdata:=tdata(data^).searchdata;
  adata._log:=tdata(data^)._log;
  writedata(adata);
end;

procedure Tfrmmain.btnclearlogClick(Sender: TObject);
begin
  if tdata(data^).cmd<>0 then exit;
  tdata(data^)._log.index:=0;
  fillchar(tdata(data^)._log.strings,sizeof(tdata(data^)._log.strings),0);
end;

procedure Tfrmmain.btnbaseaddrClick(Sender: TObject);
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

end.

