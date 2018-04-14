library memhackerdll;

{$mode objfpc}{$H+}
 

uses
  Classes,utalkiewalkie,wininjection,windows,sysutils,winmiscutils,ntdll;

function readmem(pid:dword;addr:qword;valuetype:dword;vlength:ptruint):string;
var
  bufdword:dword;
  buffloat:single;
  bufqword:qword;
  bufstring:array[0..15] of char;
  bytesread:ptruint;
  target:thandle;
  resp:string;
begin
  target:=getsysprocesshandle(pid);
  if target<1 then target:=openprocess(process_all_access,false,pid);
  if target<1 then
  begin
     result:='error opening process: '+inttostr(getlasterror);
     exit;
  end;
  if valuetype=vt_dword then
  begin
     if readprocessmemory(target,pointer(addr),@bufdword,vlength,bytesread) then
     resp:=inttostr(bufdword) else
     resp:='error rpm: '+inttostr(getlasterror);
  end;
  if valuetype=vt_float then
  begin
     if readprocessmemory(target,pointer(addr),@buffloat,vlength,bytesread) then
     resp:=floattostr(buffloat) else
     resp:='error rpm: '+inttostr(getlasterror);
  end;
  if valuetype=vt_qword then
  begin
     if readprocessmemory(target,pointer(addr),@bufqword,vlength,bytesread) then
     resp:=inttostr(bufqword) else
     resp:='error rpm: '+inttostr(getlasterror);
  end;
  if valuetype=vt_string then
  begin
     if readprocessmemory(target,pointer(addr),@bufstring,vlength,bytesread) then
     resp:=bufstring else
     resp:='error rpm: '+inttostr(getlasterror);
  end;
  result:=resp;
  closehandle(target);
end;

function writemem(pid:dword;addr:qword;valuetype:dword;value:string;vlength:ptruint):string;
var
  bufdword:dword;
  buffloat:single;
  bufqword:qword;
  bufstring:array[0..15] of char;
  byteswritten:ptruint;
  target:thandle;
  resp:string;
begin
  target:=getsysprocesshandle(pid);
  if target<1 then target:=openprocess(process_all_access,false,pid);
  if valuetype=vt_dword then
  begin
     bufdword:=strtoint(value);
     if writeprocessmemory(target,pointer(addr),@bufdword,vlength,byteswritten) then
     resp:='ok' else
     resp:='error '+inttostr(getlasterror);
  end;
  if valuetype=vt_float then
  begin
     buffloat:=strtofloat(value);
     if writeprocessmemory(target,pointer(addr),@buffloat,vlength,byteswritten) then
     resp:='ok' else
     resp:='error '+inttostr(getlasterror);
  end;
  if valuetype=vt_qword then
  begin
     bufqword:=strtoint64(value);
     if writeprocessmemory(target,pointer(addr),@bufqword,vlength,byteswritten) then
     resp:='ok' else
     resp:='error '+inttostr(getlasterror);
  end;
  if valuetype=vt_string then
  begin
     bufstring:=value;
     if writeprocessmemory(target,pointer(addr),@bufstring,vlength,byteswritten) then
     resp:='ok' else
     resp:='error '+inttostr(getlasterror);
  end;
  result:=resp;
  closehandle(target);
end;

function stillalive:boolean;
var
  myproc:thandle;
begin
    result:=true;
    myproc:=openprocess(process_all_access,false,getpidbyprocessname('memhacker.exe'));
    if myproc<1 then result:=false else closehandle(myproc);
end;

procedure _main;
begin
  try
    deletefile('memhackerdll_log.txt');
  finally
  end;
  if not stillalive then exit;
  //sysmsgbox('start'); //debug
  if not tw_init_cl then exit;
  //sysmsgbox('init ok');   //debug
  while 1=1 do
  begin
    sleep(10);
    if not stillalive then exit;
    if tdata(utalkiewalkie.data^).cmd<>0 then
    begin
       //sysmsgbox('cmd '+inttostr(tdata(utalkiewalkie.data^).cmd)); debug
       if tdata(utalkiewalkie.data^).cmd=2 then
            tdata(utalkiewalkie.data^).response:=readmem(tdata(utalkiewalkie.data^).pid,tdata(utalkiewalkie.data^).addr,tdata(utalkiewalkie.data^).valuetype,tdata(utalkiewalkie.data^).valuelength);
       //
       if tdata(utalkiewalkie.data^).cmd=1 then
            tdata(utalkiewalkie.data^).response:=writemem(tdata(utalkiewalkie.data^).pid,tdata(utalkiewalkie.data^).addr,tdata(utalkiewalkie.data^).valuetype,tdata(utalkiewalkie.data^).value,tdata(utalkiewalkie.data^).valuelength);
       //
       if tdata(utalkiewalkie.data^).cmd=3 then
            tdata(utalkiewalkie.data^).response:=inttohex(getsysprocesshandle(tdata(utalkiewalkie.data^).pid),4);
       //sysmsgbox(resp);   debug
       tdata(utalkiewalkie.data^).cmd:=0;
    end;
  end;

end;

procedure DllMain(dllparam: ptrint);register;
begin
  case dllparam of
    DLL_PROCESS_ATTACH:outputdebugstring('DLL_PROCESS_ATTACH');
    DLL_PROCESS_DETACH:_main;   //for some reason, even on attach it calls detach so i gotta use that even its unclean and will call the dll on real detach too
    DLL_THREAD_ATTACH:outputdebugstring('DLL_THREAD_ATTACH');
    DLL_THREAD_DETACH:outputdebugstring('DLL_THREAD_DETACH');
  end;
end;

exports _main;


begin
  dll_thread_attach_hook := @dllmain;
  //disablethreadlibrarycalls(hinstance);
end.

