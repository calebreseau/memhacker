unit utalkiewalkie;

{$mode objfpc}{$H+}

interface

uses 
  Classes, SysUtils,windows,winmiscutils;
 
type
    tretaddrs=array[0..1023] of string[18];
    tsearchdata=record
      startaddr:qword;
      endaddr:qword;
      value:string[64];
      valuelength:ptruint;
      valuetype:dword;
      index:integer;
      advsearch:boolean;
      retaddrs:tretaddrs;
      addrcount:integer;
      pgcurr,pgtotal:dword;
      stop:boolean;
    end;

    tlog=record
      index:integer;
      strings:array[0..1023] of string[255];
    end;

    tdata=record
      cmd:dword;
      pid:dword;
      addr:qword;
      valuetype:dword;
      valuelength:ptruint;
      value:string[64];
      response:string[255];
      _log:tlog;
      searchdata:tsearchdata;
    end;


  pdata=^tdata;

var
  fh:thandle;
  write:boolean;
  data:pointer;
  function tw_exit:boolean;
  function tw_init_srv:boolean;
  function tw_init_cl:boolean;
  procedure writedata(adata:tdata);
  function readresp:string;
  procedure writeresp(resp:string);
  procedure log(str:string);
  procedure addsaddr(str:string);

implementation

procedure log(str:string);
var
  i:integer;
begin
    with tdata(data^)._log do
    begin
         if index=1023 then
         begin
             for i:=0 to 1022 do strings[i]:=strings[i+1];
         end else index+=1;
         strings[index]:='['+FormatDateTime('hh:nn:ss', now)+']'+str;
    end;
end;

procedure addsaddr(str:string);
begin
    with tdata(data^).searchdata do
    begin
         if index=1023 then index:=0;
         retaddrs[index]:='$'+str;
         index+=1;
    end;
end;

function tw_init_srv:boolean;
begin
     result:=false;
     setprivilege('SeCreateGlobalPrivilege',true);
     fh:=createfilemapping(-1,nil,page_readwrite,0,sizeof(tdata),'Global\memhacker');
     if fh<1 then exit;
     //sysmsgbox('srv fh '+inttostr(dword(fh))); debug
     data:=mapviewoffile(fh,file_map_all_access,0,0,0);
     if data=nil then exit;
     tdata(data^).response:='';
     tdata(data^).cmd:=0;
     fillchar(tdata(data^)._log.strings,sizeof(tdata(data^)._log.strings),0);
     log('init log');
     tdata(data^)._log.index:=0;
     tdata(data^).searchdata.index:=0;
     tdata(data^).searchdata.addrcount:=0;
     tdata(data^).searchdata.pgtotal:=0;
     tdata(data^).searchdata.pgcurr:=0;
     tdata(data^).searchdata.stop:=false;
     fillchar(tdata(data^).searchdata.retaddrs,sizeof(tdata(data^).searchdata.retaddrs),chr(0));
     //sysmsgbox('data srv: '+inttostr(qword(data))+' err: '+inttostr(getlasterror)); debug
     result:=true;
end;

function tw_init_cl:boolean;
begin
     result:=false;
     setprivilege('SeCreateGlobalPrivilege',true);
     fh:=openfilemapping(file_map_all_access,false,'Global\memhacker');
     if fh<1 then exit;
     //sysmsgbox('cl fh '+inttostr(dword(fh))); debug
     data:=mapviewoffile(fh,file_map_all_access,0,0,0);
     if data=nil then exit;
     //sysmsgbox('data cl: '+inttostr(qword(data))+' err: '+inttostr(getlasterror)); debug
     tdata(data^).cmd:=0;
     result:=true;
end;

function tw_exit:boolean;
begin
    flushviewoffile(data,sizeof(data));
    closehandle(fh);
end;

function readresp:string;
begin
      result:=tdata(data^).response;
end;

procedure writedata(adata:tdata);
begin
    copymemory(data,@adata,sizeof(adata));
end;

procedure writeresp(resp:string);
begin
    tdata(data^).response:=resp;
end;

end.

