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
  log('Enter readmem');
  target:=getsysprocesshandle(pid);
  if target<1 then
  begin
     log('didnt find handle with getsysprocesshandle, opening process');
     target:=openprocess(process_all_access,false,pid);
     log('openprocess handle: '+inttohex(target,4));
  end
  else  log('found handle: '+inttohex(target,4));
  if target<1 then
  begin
     log('error opening process: '+inttostr(getlasterror)+', exiting');
     result:='';
     exit;
  end;
  if valuetype=vt_dword then
  begin
     log('valuetype=dword');
     if readprocessmemory(target,pointer(addr),@bufdword,vlength,bytesread) then
     begin
       log('rpm ok, '+inttostr(bytesread)+' bytes read');
       resp:=inttostr(bufdword)
     end
     else
     begin
       resp:='';
       log('error rpm: '+inttostr(getlasterror));
     end;
  end;
  if valuetype=vt_float then
  begin
     log('valuetype=float');
     if readprocessmemory(target,pointer(addr),@buffloat,vlength,bytesread) then
     begin
       log('rpm ok, '+inttostr(bytesread)+' bytes read');
       resp:=floattostr(buffloat)
     end
     else
     begin
       resp:='';
       log('error rpm: '+inttostr(getlasterror));
     end;
  end;
  if valuetype=vt_qword then
  begin
     log('valuetype=qword');
     if readprocessmemory(target,pointer(addr),@bufqword,vlength,bytesread) then
     begin
       log('rpm ok, '+inttostr(bytesread)+' bytes read');
       resp:=inttostr(bufqword)
     end
     else
     begin
       resp:='';
       log('error rpm: '+inttostr(getlasterror));
     end;
  end;
  if valuetype=vt_string then
  begin
     log('valuetype=string');
     if readprocessmemory(target,pointer(addr),@bufstring,vlength,bytesread) then
     begin
       log('rpm ok, '+inttostr(bytesread)+' bytes read');
       resp:=bufstring
     end
     else
     begin
       resp:='';
       log('error rpm: '+inttostr(getlasterror));
     end;
  end;
  result:=resp;
  log('result: '+result);
  closehandle(target);
  log('leaving readmem');
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
  log('Enter writemem');
  target:=getsysprocesshandle(pid);
  if target<1 then
  begin
     log('didnt find handle with getsysprocesshandle, opening process');
     target:=openprocess(process_all_access,false,pid);
     log('openprocess handle: '+inttohex(target,4));
  end
  else  log('found handle: '+inttohex(target,4));
  if target<1 then
  begin
     log('error opening process: '+inttostr(getlasterror)+', exiting');
     result:='';
     exit;
  end;
  if valuetype=vt_dword then
  begin
     log('valuetype=dword');
     bufdword:=strtoint(value);
     if writeprocessmemory(target,pointer(addr),@bufdword,vlength,byteswritten) then
     begin
       log('wpm ok, '+inttostr(byteswritten)+' bytes written');
       resp:='ok'
     end
     else
     begin
       log('wpm error'+inttostr(getlasterror)+', '+inttostr(byteswritten)+' bytes written');
       resp:='error '+inttostr(getlasterror);
     end;
  end;
  if valuetype=vt_float then
  begin
     log('valuetype=float');
     buffloat:=strtofloat(value);
     if writeprocessmemory(target,pointer(addr),@buffloat,vlength,byteswritten) then
     begin
       log('wpm ok, '+inttostr(byteswritten)+' bytes written');
       resp:='ok'
     end
     else
     begin
       log('wpm error'+inttostr(getlasterror)+', '+inttostr(byteswritten)+' bytes written');
       resp:='error '+inttostr(getlasterror);
     end;
  end;
  if valuetype=vt_qword then
  begin
     log('valuetype=qword');
     bufqword:=strtoint64(value);
     if writeprocessmemory(target,pointer(addr),@bufqword,vlength,byteswritten) then
     begin
       log('wpm ok, '+inttostr(byteswritten)+' bytes written');
       resp:='ok'
     end
     else
     begin
       log('wpm error'+inttostr(getlasterror)+', '+inttostr(byteswritten)+' bytes written');
       resp:='error '+inttostr(getlasterror);
     end;
  end;
  if valuetype=vt_string then
  begin
     log('valuetype=string');
     bufstring:=value;
     if writeprocessmemory(target,pointer(addr),@bufstring,vlength,byteswritten) then
     begin
       log('wpm ok, '+inttostr(byteswritten)+' bytes written');
       resp:='ok'
     end
     else
     begin
       log('wpm error'+inttostr(getlasterror)+', '+inttostr(byteswritten)+' bytes written');
       resp:='error '+inttostr(getlasterror);
     end;
  end;
  result:=resp;
  log('result: '+result);
  closehandle(target);
  log('leaving writemem');
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
  if not tw_init_cl_log then exit;
  //sysmsgbox('init ok');   //debug
  log('enter main');
  while 1=1 do
  begin
    sleep(10);
    if not stillalive then exit;
    if tdata(utalkiewalkie.data^).cmd<>0 then
    begin
       //sysmsgbox('cmd '+inttostr(tdata(utalkiewalkie.data^).cmd)); debug
       if tdata(utalkiewalkie.data^).cmd=2 then
       begin
          log('received cmd READ');
          log('Target PID: '+inttostr(tdata(utalkiewalkie.data^).pid));
          log('Value type: '+inttostr(tdata(utalkiewalkie.data^).valuetype));
          log('Value length: '+inttostr(tdata(utalkiewalkie.data^).valuelength));
          log('Address: 0x'+inttohex(tdata(utalkiewalkie.data^).addr,8));
          tdata(utalkiewalkie.data^).response:=readmem(tdata(utalkiewalkie.data^).pid,tdata(utalkiewalkie.data^).addr,tdata(utalkiewalkie.data^).valuetype,tdata(utalkiewalkie.data^).valuelength);
          log(#13#10'///'#13#10);
       end;
       //
       if tdata(utalkiewalkie.data^).cmd=1 then
       begin
          log('received cmd WRITE');
          log('Target PID: '+inttostr(tdata(utalkiewalkie.data^).pid));
          log('Value: '+tdata(utalkiewalkie.data^).value);
          log('Value type: '+inttostr(tdata(utalkiewalkie.data^).valuetype));
          log('Value length: '+inttostr(tdata(utalkiewalkie.data^).valuelength));
          log('Address: 0x'+inttohex(tdata(utalkiewalkie.data^).addr,8));
          tdata(utalkiewalkie.data^).response:=writemem(tdata(utalkiewalkie.data^).pid,tdata(utalkiewalkie.data^).addr,tdata(utalkiewalkie.data^).valuetype,tdata(utalkiewalkie.data^).value,tdata(utalkiewalkie.data^).valuelength);
          log(#13#10'///'#13#10);
       end;
       //
       if tdata(utalkiewalkie.data^).cmd=3 then
       begin
          log('received cmd GETHANDLE');
          log('Target PID: '+inttostr(tdata(utalkiewalkie.data^).pid));
          tdata(utalkiewalkie.data^).response:=inttohex(getsysprocesshandle(tdata(utalkiewalkie.data^).pid),4);
          log('Response: '+tdata(utalkiewalkie.data^).response);
          log(#13#10'///'#13#10);
       end;
       //sysmsgbox(resp);   debug
       tdata(utalkiewalkie.data^).cmd:=0;
    end;
  end;
  tw_exit_log;
  tw_exit;
  log(#1310'Leaving DLL'#13#10);
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

