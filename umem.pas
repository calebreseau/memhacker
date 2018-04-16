unit umem;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,utalkiewalkie,ntdll,windows;

const
  vt_dword:dword=1;
  vt_qword:dword=2;
  vt_string:dword=3;
  vt_float:dword=4;

var
  foo:integer;
  function readmem(pid:dword;addr:qword;valuetype:dword;vlength:ptruint):string;
  function writemem(pid:dword;addr:qword;valuetype:dword;value:string;vlength:ptruint):string;
  function searchmem(pid:dword;value:string;valuetype:dword;vlength:dword;startaddr:qword;endaddr:qword;advsearch:boolean):string;

implementation

function searchmem(pid:dword;value:string;valuetype:dword;vlength:dword;startaddr:qword;endaddr:qword;advsearch:boolean):string;
var
  target:thandle;
  MemInfo: MEMORY_BASIC_INFORMATION;
  MemStart: pointer;
  i:qword;
  bufdword:dword;
  buffloat:single;
  bufqword:qword;
  bufstring:array[0..15] of char;
  bytesread:ptruint;
  ret:ptruint;
  tmp:string;
  j:integer;
  errcount:integer;
begin
    errcount:=0;
    memstart:=pointer(startaddr);
    log('enter searchmem');
    target:=getsysprocesshandle(pid);
    log('targethandle from getsysprocesshandle: '+inttohex(target,4));
    if target=0 then
    begin
      target:=openprocess(process_vm_read or process_vm_operation or PROCESS_QUERY_INFORMATION,false,pid);
      log('target handle from openprocess: '+inttohex(target,4));
    end;
    if target=0 then
    begin
      log('target handle=0, leaving');
      exit;
    end;
    ret:=VirtualQueryEx(target, MemStart, MemInfo, SizeOf(MemInfo));
    while (ret>0) and (meminfo.baseaddress+meminfo.regionsize<pointer(endaddr)) do
    begin
      if (MemInfo.State = MEM_COMMIT) and (meminfo.Protect=PAGE_READWRITE)
        and (meminfo.Protect<>PAGE_GUARD) then
        begin
          if (0<>MemInfo.Protect and PAGE_READWRITE) then
          begin
            i:=0;
            while meminfo.baseaddress+meminfo.RegionSize>meminfo.baseaddress+i do
            begin
                if valuetype=vt_dword then
                begin
                   if readprocessmemory(target,pointer(meminfo.baseaddress+i),@bufdword,vlength,bytesread) then
                   begin
                     if value=inttostr(bufdword) then
                     begin
                       tmp:=inttohex(qword(meminfo.baseaddress)+i,16);
                       while tmp[1]='0' do delete(tmp,1,1);
                       log('found at 0x'+tmp);
                       addsaddr(tmp);
                     end;
                   end
                   else
                   begin
                     log('error rpm: '+inttostr(getlasterror)+' at '+inttohex(qword(meminfo.baseaddress)+i,16));
                     errcount+=1;
                   end;
                end;
                if valuetype=vt_float then
                begin
                   if readprocessmemory(target,pointer(meminfo.baseaddress+i),@buffloat,vlength,bytesread) then
                   begin
                     if value=floattostr(buffloat) then
                     begin
                       tmp:=inttohex(qword(meminfo.baseaddress)+i,16);
                       while tmp[1]='0' do delete(tmp,1,1);
                       log('found at 0x'+tmp);
                       addsaddr(tmp);
                     end;
                   end
                   else
                   begin
                     log('error rpm: '+inttostr(getlasterror)+' at '+inttohex(qword(meminfo.baseaddress)+i,16));
                     errcount+=1;
                   end;
                end;
                if valuetype=vt_qword then
                begin
                   if readprocessmemory(target,pointer(meminfo.baseaddress+i),@bufqword,vlength,bytesread) then
                   begin
                     if value=inttostr(bufqword) then
                     begin
                       tmp:=inttohex(qword(meminfo.baseaddress)+i,16);
                       while tmp[1]='0' do delete(tmp,1,1);
                       log('found at 0x'+tmp);
                       addsaddr(tmp);
                     end;
                   end
                   else
                   begin
                     log('error rpm: '+inttostr(getlasterror)+' at '+inttohex(qword(meminfo.baseaddress)+i,16));
                     errcount+=1;
                   end;
                end;
                if valuetype=vt_string then
                begin
                   if readprocessmemory(target,pointer(meminfo.baseaddress+i),@bufstring,vlength,bytesread) then
                   begin
                     if value=bufstring then
                     begin
                       tmp:=inttohex(qword(meminfo.baseaddress)+i,16);
                       while tmp[1]='0' do delete(tmp,1,1);
                       log('found at 0x'+tmp);
                       addsaddr(tmp);
                     end;
                   end
                   else
                   begin
                     log('error rpm: '+inttostr(getlasterror)+' at '+inttohex(qword(meminfo.baseaddress)+i,16));
                     errcount+=1;
                   end;
                end;
                if advsearch then i+=1 else i+=vlength;
            end;
          end;
        end;
      MemStart:= MemStart + MemInfo.RegionSize;
      ret:=VirtualQueryEx(target, MemStart, MemInfo, SizeOf(MemInfo));
    end;
    result:='errcount: '+inttostr(errcount);
    log('exit, result: '+result);
end;

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

end.

