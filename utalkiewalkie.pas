unit utalkiewalkie;

{$mode objfpc}{$H+}

interface

uses 
  Classes, SysUtils,windows,winmiscutils;
 
type

  tdata=record
    cmd:dword;
    pid:dword;
    addr:qword;
    valuetype:dword;
    valuelength:ptruint;
    value:string[64];
    response:string[64];
  end;
  tlog=record
    index:integer;
    strings:array[0..1023] of string[255];
  end;
  pdata=^tdata;
  plog=^tlog;

const
  vt_dword:dword=1;
  vt_qword:dword=2;
  vt_string:dword=3;
  vt_float:dword=4;

var
  fh:thandle;
  fh_log:thandle;
  write:boolean;
  data:pointer;
  datalog:pointer;
  function tw_exit_log:boolean;
  function tw_exit:boolean;
  function tw_init_srv:boolean;
  function tw_init_srv_log:boolean;
  function tw_init_cl:boolean;
  function tw_init_cl_log:boolean;
  procedure writedata(adata:tdata);
  function readresp:string;
  procedure writeresp(resp:string);
  procedure log(str:string);

implementation

procedure log(str:string);
begin
    with tlog(datalog^) do
    begin
         if index=1023 then index:=0;
         strings[index]:=str;
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
     //sysmsgbox('data srv: '+inttostr(qword(data))+' err: '+inttostr(getlasterror)); debug
     result:=true;
end;

function tw_init_cl_log:boolean;
var
  i:integer;
begin
     result:=false;
     setprivilege('SeCreateGlobalPrivilege',true);
     fh_log:=openfilemapping(file_map_all_access,false,'Global\memhackerlog');
     if fh_log<1 then exit;
     //sysmsgbox('cl fh '+inttostr(dword(fh))); debug
     datalog:=mapviewoffile(fh_log,file_map_all_access,0,0,0);
     if datalog=nil then exit;
     for i:=0 to 1023 do tlog(datalog^).strings[i]:='';
     tlog(datalog^).index:=0;
     //sysmsgbox('data cl: '+inttostr(qword(data))+' err: '+inttostr(getlasterror)); debug
     result:=true;
end;

function tw_init_srv_log:boolean;
var
  i:integer;
begin
     result:=false;
     setprivilege('SeCreateGlobalPrivilege',true);
     fh_log:=createfilemapping(-1,nil,page_readwrite,0,sizeof(tlog),'Global\memhackerlog');
     if fh_log<1 then exit;
     //sysmsgbox('srv fh '+inttostr(dword(fh))); debug
     datalog:=mapviewoffile(fh_log,file_map_all_access,0,0,0);
     if datalog=nil then exit;
     for i:=0 to 1023 do tlog(datalog^).strings[i]:='';
     tlog(datalog^).index:=0;
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

function tw_exit_log:boolean;
begin
    flushviewoffile(datalog,sizeof(datalog));
    closehandle(fh_log);
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

