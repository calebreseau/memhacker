library memhackerdll; 

{$mode objfpc}{$H+}
 

uses
  Classes,utalkiewalkie,windows,sysutils,winmiscutils,ntdll,umem;

function stillalive:boolean;
var
  myproc:thandle;
begin
    result:=true;
    myproc:=openprocess(process_all_access,false,getpidbyprocessname('memhacker.exe'));
    if myproc<1 then result:=false else closehandle(myproc);
end;

procedure _main;
var
  satick:dword;
  tmpstr:string;
  i:integer;
begin
  if not stillalive then exit;
  if not tw_init_cl then
  begin
       sysmsgbox('couldnt init communication, exiting');
       exit;
  end;
  satick:=0;
  //sysmsgbox('start'); //debug
  //sysmsgbox('init ok');   //debug
  log('enter main');
  while 1=1 do
  begin
    sleep(10);
    if satick=100 then
    begin
         satick:=0;
         //log('checking if gui is stillalive...');
         if not stillalive then
         begin
              log('gui isnt alive, exiting..');
              break;
         end;
    end
    else satick+=1;
    if tdata(data^).cmd<>0 then
    begin
       //sysmsgbox('cmd '+inttostr(tdata(data^).cmd)); debug
       if tdata(data^).cmd=cmd_READ then
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
       if tdata(data^).cmd=cmd_WRITE then
       begin
          log('received cmd WRITE');
          log('Target PID: '+inttostr(tdata(data^).pid));
          if tdata(data^).valuetype<>vt_bytearray then
            log('Value: '+tdata(data^).searchdata.value)
          else
          begin
            tmpstr:='Array:';
            for i:=1 to tdata(data^).valuelength do
            begin
              tmpstr+=' $'+inttohex(ord(tdata(data^).value[i]),2);
            end;
            log(tmpstr);
          end;
          log('Value type: '+inttostr(tdata(data^).valuetype));
          log('Value length: '+inttostr(tdata(data^).valuelength));
          log('Address: 0x'+inttohex(tdata(data^).addr,8));
          tdata(data^).response:=writemem(tdata(data^).pid,tdata(data^).addr,tdata(data^).valuetype,tdata(data^).value,tdata(data^).valuelength);
          log(#13#10'///'#13#10);
       end;
       if tdata(data^).cmd=cmd_SEARCH then
       begin
          log('received cmd SEARCH');
          log('Target PID: '+inttostr(tdata(data^).pid));
          if tdata(data^).searchdata.valuetype<>vt_bytearray then
            log('Value: '+tdata(data^).searchdata.value)
          else
          begin
            tmpstr:='Array:';
            for i:=1 to tdata(data^).searchdata.valuelength do
            begin
              tmpstr+=' $'+inttohex(ord(tdata(data^).searchdata.value[i]),2);
            end;
            log(tmpstr);
          end;
          log('Value type: '+inttostr(tdata(data^).searchdata.valuetype));
          log('Value length: '+inttostr(tdata(data^).searchdata.valuelength));
          log('Start address: '+inttostr(tdata(data^).searchdata.startaddr));
          log('End address: '+inttostr(tdata(data^).searchdata.endaddr));
          log('Advanced search: '+booltostr(tdata(data^).searchdata.advsearch,true));
          tdata(data^).response:=searchmem(tdata(data^).pid,tdata(data^).searchdata.value,tdata(data^).searchdata.valuetype,tdata(data^).searchdata.valuelength,tdata(data^).searchdata.startaddr,tdata(data^).searchdata.endaddr,tdata(data^).searchdata.advsearch);
          log(#13#10'///'#13#10);
       end;
       if tdata(data^).cmd=cmd_RESEARCH then
       begin
          log('received cmd RESEARCH');
          log('Target PID: '+inttostr(tdata(data^).pid));
          if tdata(data^).searchdata.valuetype<>vt_bytearray then
            log('Value: '+tdata(data^).searchdata.value)
          else
          begin
            tmpstr:='Array:';
            for i:=1 to tdata(data^).searchdata.valuelength do
            begin
              tmpstr+=' $'+inttohex(ord(tdata(data^).searchdata.value[i]),2);
            end;
            log(tmpstr);
          end;
          log('Value type: '+inttostr(tdata(data^).searchdata.valuetype));
          log('Value length: '+inttostr(tdata(data^).searchdata.valuelength));
          tdata(data^).response:=researchmem(tdata(data^).pid,tdata(data^).searchdata.value,tdata(data^).searchdata.valuetype,tdata(data^).searchdata.valuelength);
          log(#13#10'///'#13#10);
       end;
       //
       if tdata(data^).cmd=cmd_GETHANDLE then
       begin
          log('received cmd GETHANDLE');
          log('Target PID: '+inttostr(tdata(data^).pid));
          tdata(data^).response:=inttohex(getsysprocesshandle(tdata(data^).pid),4);
          log('Response: '+tdata(data^).response);
          log(#13#10'///'#13#10);
       end;

       if tdata(data^).cmd=cmd_GETBASEADDR then
       begin
          log('received cmd GETBASEADDR');
          log('Target PID: '+inttostr(tdata(data^).pid));
          log('Target process name: '+tdata(data^).value);
          tdata(data^).response:=getbaseaddr(tdata(data^).pid,tdata(data^).value);
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
  _main;
end;

exports _main;

begin
  dll_thread_attach_hook := @dllmain;
  _main;
end.

