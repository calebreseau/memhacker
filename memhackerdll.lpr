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
    if not stillalive then break;
    if tdata(data^).cmd<>0 then
    begin
       //sysmsgbox('cmd '+inttostr(tdata(data^).cmd)); debug
       if tdata(data^).cmd=2 then
       begin
          log('received cmd READ');
          log('Target PID: '+inttostr(tdata(data^).pid));
          log('Value type: '+inttostr(tdata(data^).valuetype));
          log('Value length: '+inttostr(tdata(data^).valuelength));
          log('Address: 0x'+inttohex(tdata(data^).addr,8));
          tdata(data^).response:=readmem(tdata(data^).pid,tdata(data^).addr,tdata(data^).valuetype,tdata(data^).valuelength);
          log(#13#10'///'#13#10);
       end;
       //
       if tdata(data^).cmd=1 then
       begin
          log('received cmd WRITE');
          log('Target PID: '+inttostr(tdata(data^).pid));
          log('Value: '+tdata(data^).value);
          log('Value type: '+inttostr(tdata(data^).valuetype));
          log('Value length: '+inttostr(tdata(data^).valuelength));
          log('Address: 0x'+inttohex(tdata(data^).addr,8));
          tdata(data^).response:=writemem(tdata(data^).pid,tdata(data^).addr,tdata(data^).valuetype,tdata(data^).value,tdata(data^).valuelength);
          log(#13#10'///'#13#10);
       end;
       if tdata(data^).cmd=4 then
       begin
          log('received cmd SEARCH');
          log('Target PID: '+inttostr(tdata(data^).pid));
          log('Value: '+tdata(data^).searchdata.value);
          log('Value type: '+inttostr(tdata(data^).searchdata.valuetype));
          log('Value length: '+inttostr(tdata(data^).searchdata.valuelength));
          log('Start address: '+inttostr(tdata(data^).searchdata.startaddr));
          log('End address: '+inttostr(tdata(data^).searchdata.endaddr));
          log('Advanced search: '+booltostr(tdata(data^).searchdata.advsearch,true));
          tdata(data^).response:=searchmem(tdata(data^).pid,tdata(data^).searchdata.value,tdata(data^).searchdata.valuetype,tdata(data^).searchdata.valuelength,tdata(data^).searchdata.startaddr,tdata(data^).searchdata.endaddr,tdata(data^).searchdata.advsearch);
          log(#13#10'///'#13#10);
       end;
       if tdata(data^).cmd=5 then
       begin
          log('received cmd RESEARCH');
          log('Target PID: '+inttostr(tdata(data^).pid));
          log('Value: '+tdata(data^).searchdata.value);
          log('Value type: '+inttostr(tdata(data^).searchdata.valuetype));
          log('Value length: '+inttostr(tdata(data^).searchdata.valuelength));
          tdata(data^).response:=researchmem(tdata(data^).pid,tdata(data^).searchdata.value,tdata(data^).searchdata.valuetype,tdata(data^).searchdata.valuelength);
          log(#13#10'///'#13#10);
       end;
       //
       if tdata(data^).cmd=3 then
       begin
          log('received cmd GETHANDLE');
          log('Target PID: '+inttostr(tdata(data^).pid));
          tdata(data^).response:=inttohex(getsysprocesshandle(tdata(data^).pid),4);
          log('Response: '+tdata(data^).response);
          log(#13#10'///'#13#10);
       end;
       //sysmsgbox(resp);   debug
       tdata(data^).cmd:=0;
    end;
  end;
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

