unit ufrmmem;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls,utalkiewalkie,strutils,umem,windows,winmiscutils,utils;

type

  { Tfrmmem }

  thrui=class(tthread)
    procedure execute;override;
  end;

  Tfrmmem = class(TForm)
    btnread: TButton;
    btnrefresh: TButton;
    btnresearch: TButton;
    btnsearch: TButton;
    btnstopsearch: TButton;
    btnwrite: TButton;
    chkadvsearch: TCheckBox;
    grpmemutils: TGroupBox;
    grpsearch: TGroupBox;
    grpsvtype: TGroupBox;
    grpvtype: TGroupBox;
    lbladdrcount: TLabel;
    lbllength: TLabel;
    lblpname: TLabel;
    lblslength: TLabel;
    lstaddrs: TListBox;
    pgbsearch: TProgressBar;
    rbarray: TRadioButton;
    rbdword: TRadioButton;
    rbfloat: TRadioButton;
    rbqword: TRadioButton;
    rbsarray: TRadioButton;
    rbsdword: TRadioButton;
    rbsfloat: TRadioButton;
    rbsqword: TRadioButton;
    rbsstring: TRadioButton;
    rbstring: TRadioButton;
    txtaddr: TLabeledEdit;
    txtlength: TEdit;
    txtprocess: TComboBox;
    txtresp: TLabeledEdit;
    txtsend: TLabeledEdit;
    txtslength: TEdit;
    txtsstart: TLabeledEdit;
    txtsvalue: TLabeledEdit;
    txtvalue: TLabeledEdit;
    procedure btnreadClick(Sender: TObject);
    procedure btnrefreshClick(Sender: TObject);
    procedure btnresearchClick(Sender: TObject);
    procedure btnsearchClick(Sender: TObject);
    procedure btnstopsearchClick(Sender: TObject);
    procedure btnwriteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lstaddrsClick(Sender: TObject);
    procedure lstaddrsDblClick(Sender: TObject);
    procedure txtaddrChange(Sender: TObject);
    procedure txtlengthChange(Sender: TObject);
    procedure txtvalueChange(Sender: TObject);
  private

  public

  end;

var
  frmmem: Tfrmmem;
  init:boolean;

implementation

procedure thrui.execute;
var
     lastindex:integer;
     i:integer;
     strs:tstringlist;
     lasterror:integer;
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
          frmmem.txtresp.text:=string(tdata(data^).response);
        end;
        with tdata(data^).searchdata do
        begin
          frmmem.pgbsearch.max:=pgtotal;
          frmmem.pgbsearch.position:=pgcurr;
          frmmem.lbladdrcount.caption:='Found '+inttostr(addrcount)+' occurences';
          if index<>lastindex then
          begin
            strs.clear;
            for i:=0 to index do strs.add(retaddrs[i]);
            frmmem.lstaddrs.Items:=strs;
            lastindex:=index;
          end;
        end;
    except
        lasterror:=getlasterror;
        if lasterror<>0 then showmessage('Error reading response: '+inttostr(lasterror));
    end;
  end;
end;

procedure tfrmmem.lstaddrsClick(Sender: TObject);
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

procedure tfrmmem.lstaddrsDblClick(Sender: TObject);
begin
     if messagedlg('memhacker','Delete addresses ?',mtconfirmation,mbyesnocancel,0)<>mryes then exit;
     tdata(data^).searchdata.index:=0;
     tdata(data^).searchdata.addrcount:=0;
     tdata(data^).searchdata.pgtotal:=0;
     tdata(data^).searchdata.pgcurr:=0;
     fillchar(tdata(data^).searchdata.retaddrs,sizeof(tdata(data^).searchdata.retaddrs),chr(0));
end;
procedure tfrmmem.txtaddrChange(Sender: TObject);
begin
  if length(txtaddr.Text)=0 then txtaddr.text:='$';
end;

procedure tfrmmem.txtlengthChange(Sender: TObject);
begin
  if txtlength.text='' then txtlength.text:='0';
  if strtoint(txtlength.text)>16 then txtlength.text:='16';
end;

procedure tfrmmem.txtvalueChange(Sender: TObject);
begin
  if ansicontainsstr(txtvalue.text,'.') then
    txtvalue.text:=stringreplace(txtvalue.text,'.',',',[rfreplaceall,rfignorecase]);
end;

procedure tfrmmem.btnwriteClick(Sender: TObject);
var
  adata:tdata;
  tmparray:array[0..1023] of byte;
  bytes:tstrings;
  i:integer;
  txtval:fixedstring;
  dataval:fixedstring;
begin
  bytes:=tstringlist.create;
  fillchar(tmparray,1024,0);
  if rbstring.checked=false then adata.value:=txtvalue.text;
  if rbstring.checked then
  begin
       adata.valuetype:=vt_string;
       adata.valuelength:=strtoint64(txtlength.text);
       adata.value:=txtvalue.text
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
  adata.processinfos:=tdata(data^).processinfos;
  writedata(adata);
end;

procedure Tfrmmem.FormCreate(Sender: TObject);
begin
  with thrui.create(false) do freeonterminate:=true;
  btnrefreshclick(sender);
end;

procedure tfrmmem.btnrefreshClick(Sender: TObject);
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

procedure tfrmmem.btnresearchClick(Sender: TObject);
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

procedure tfrmmem.btnsearchClick(Sender: TObject);
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

procedure tfrmmem.btnstopsearchClick(Sender: TObject);
begin
  tdata(data^).searchdata.stop:=true;
end;

procedure tfrmmem.btnreadClick(Sender: TObject);
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
  adata.processinfos:=tdata(data^).processinfos;
  writedata(adata);
end;

{$R *.lfm}

end.

