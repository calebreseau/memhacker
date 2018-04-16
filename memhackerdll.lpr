library memhackerdll; 

{$mode objfpc}{$H+}
 

uses
  Classes,utalkiewalkie,wininjection,windows,sysutils,winmiscutils,ntdll, umem;

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
       if tdata(utalkiewalkie.data^).cmd=4 then
       begin
          log('received cmd SEARCH');
          log('Target PID: '+inttostr(tdata(utalkiewalkie.data^).pid));
          log('Value: '+tdata(utalkiewalkie.data^).searchdata.value);
          log('Value type: '+inttostr(tdata(utalkiewalkie.data^).searchdata.valuetype));
          log('Value length: '+inttostr(tdata(utalkiewalkie.data^).searchdata.valuelength));
          log('Start address: '+inttostr(tdata(utalkiewalkie.data^).searchdata.startaddr));
          log('End address: '+inttostr(tdata(utalkiewalkie.data^).searchdata.endaddr));
          log('Advanced search: '+booltostr(tdata(utalkiewalkie.data^).searchdata.advsearch,true));
          tdata(utalkiewalkie.data^).response:=searchmem(tdata(utalkiewalkie.data^).pid,tdata(utalkiewalkie.data^).searchdata.value,tdata(utalkiewalkie.data^).searchdata.valuetype,tdata(utalkiewalkie.data^).searchdata.valuelength,tdata(utalkiewalkie.data^).searchdata.startaddr,tdata(utalkiewalkie.data^).searchdata.endaddr,tdata(utalkiewalkie.data^).searchdata.advsearch);
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

