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
  pdata=^tdata;

const
  vt_dword:dword=1;
  vt_qword:dword=2;
  vt_string:dword=3;
  vt_float:dword=4;

var
  fh:thandle;
  write:boolean;
  data:pointer;
  function tw_init_srv:boolean;
  function tw_init_cl:boolean;
  procedure writedata(adata:tdata);
  function readresp:string;
  procedure writeresp(resp:string);

implementation

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

