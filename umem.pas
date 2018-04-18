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
  function researchmem(pid:dword;value:string;valuetype:dword;vlength:dword):string;
  function readmem(pid:dword;addr:qword;valuetype:dword;vlength:ptruint):string;
  function writemem(pid:dword;addr:qword;valuetype:dword;value:string;vlength:ptruint):string;
  function searchmem(pid:dword;value:string;valuetype:dword;vlength:dword;startaddr:qword;endaddr:qword;advsearch:boolean):string;

implementation

function researchmem(pid:dword;value:string;valuetype:dword;vlength:dword):string;
var
  bufdword:dword;
  buffloat:single;
  bufqword:qword;
  bufstring:array[0..15] of char;
  bytesread:ptruint;
  target:thandle;
  resp:string;
  i:integer;
  searchdata:tsearchdata;
begin
  log('Enter researchmem');
  target:=getsysprocesshandle(pid);
  if target<1 then
  begin
     log('didnt find handle with getsysprocesshandle, opening process');
     target:=openprocess(process_vm_read,false,pid);
     log('openprocess handle: '+inttohex(target,4));
  end
  else  log('found handle: '+inttohex(target,4));
  if target<1 then
  begin
     log('error opening process: '+inttostr(getlasterror)+', exiting');
     result:='';
     exit;
  end;
  searchdata:=tdata(data^).searchdata;
  tdata(data^).searchdata.index:=0;
  for i:=0 to 1023 do tdata(data^).searchdata.retaddrs[i]:='';
  log('addr count: '+inttostr(searchdata.index+1));
  tdata(data^).searchdata.pgtotal:=tdata(data^).searchdata.index;
  tdata(data^).searchdata.pgcurr:=0;
  tdata(data^).searchdata.addrcount:=0;
  for i:=0 to searchdata.index do
  begin
      tdata(data^).searchdata.pgcurr:=i;
      if length(searchdata.retaddrs[i])>2 then
      begin
          log('reading addr '+inttostr(i+1)+'/'+inttostr(searchdata.index+1)+': '+searchdata.retaddrs[i]);
          if valuetype=vt_dword then
          begin
             if readprocessmemory(target,pointer(strtoint64(searchdata.retaddrs[i])),@bufdword,vlength,bytesread) then
             begin
               //log('rpm ok, '+inttostr(bytesread)+' bytes read');
               if inttostr(bufdword)=value then
               begin
                 addsaddr(searchdata.retaddrs[i]);
                 log('found at: '+searchdata.retaddrs[i]);
                 tdata(data^).searchdata.addrcount+=1;
               end;
             end
             else
             begin
               resp:='';
               log('error rpm: '+inttostr(getlasterror));
             end;
          end;
          if valuetype=vt_float then
          begin
             if readprocessmemory(target,pointer(strtoint64(searchdata.retaddrs[i])),@buffloat,vlength,bytesread) then
             begin
               //log('rpm ok, '+inttostr(bytesread)+' bytes read');
               if floattostr(buffloat)=value then
               begin
                 addsaddr(searchdata.retaddrs[i]);
                 log('found at: '+searchdata.retaddrs[i]);
                 tdata(data^).searchdata.addrcount+=1;
               end;
             end
             else
             begin
               resp:='';
               log('error rpm: '+inttostr(getlasterror));
             end;
          end;
          if valuetype=vt_qword then
          begin
             if readprocessmemory(target,pointer(strtoint64(searchdata.retaddrs[i])),@bufqword,vlength,bytesread) then
             begin
               //log('rpm ok, '+inttostr(bytesread)+' bytes read');
               if inttostr(bufqword)=value then
               begin
                 addsaddr(searchdata.retaddrs[i]);
                 log('found at: '+searchdata.retaddrs[i]);
                 tdata(data^).searchdata.addrcount+=1;
               end;
             end
             else
             begin
               resp:='';
               log('error rpm: '+inttostr(getlasterror));
             end;
          end;
          if valuetype=vt_string then
          begin
             if readprocessmemory(target,pointer(strtoint64(searchdata.retaddrs[i])),@bufstring,vlength,bytesread) then
             begin
               //log('rpm ok, '+inttostr(bytesread)+' bytes read');
               if bufstring=value then
               begin
                 addsaddr(searchdata.retaddrs[i]);
                 log('found at: '+searchdata.retaddrs[i]);
                 tdata(data^).searchdata.addrcount+=1;
               end;
             end
             else
             begin
               resp:='';
               log('error rpm: '+inttostr(getlasterror));
             end;
          end;
      end;
  end;
  result:=resp;
  log('result: '+result);
  closehandle(target);
  log('leaving researchmem');
end;
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
  meminfos:array of memory_basic_information;
  alreadyopened:boolean;
begin
    alreadyopened:=true;
    setlength(meminfos,0);
    errcount:=0;
    log('enter searchmem');
    target:=getsysprocesshandle(pid);
    if target<1 then
    begin
       log('didnt find handle with getsysprocesshandle, opening process');
       target:=openprocess(process_vm_read or process_vm_operation or process_query_information,false,pid);
       alreadyopened:=false;
       log('openprocess handle: '+inttohex(target,4));
    end
    else  log('found handle: '+inttohex(target,4));
    if target<1 then
    begin
       log('error opening process: '+inttostr(getlasterror)+', exiting');
       result:='';
       exit;
    end;
    setlength(meminfos,1);
    memstart:=pointer(startaddr);
    ret:=VirtualQueryEx(target, MemStart, meminfo, SizeOf(meminfo));
    if (meminfo.State = MEM_COMMIT) and (meminfo.Protect=PAGE_READWRITE)
      and (meminfo.Protect<>PAGE_GUARD)
      and ((0<>meminfo.Protect and PAGE_READWRITE))
      then meminfos[high(meminfos)]:=meminfo;
    while (ret>0) and (meminfo.baseaddress+meminfo.regionsize<pointer(endaddr)) do
    begin
      setlength(meminfos,length(meminfos)+1);
      MemStart:= MemStart + meminfo.RegionSize;
      ret:=VirtualQueryEx(target, MemStart, meminfo, SizeOf(meminfo));
      if (meminfo.State = MEM_COMMIT) and (meminfo.Protect=PAGE_READWRITE)
        and (meminfo.Protect<>PAGE_GUARD)
        and ((0<>meminfo.Protect and PAGE_READWRITE))
        then meminfos[high(meminfos)]:=meminfo;
    end;
    log('found '+inttostr(length(meminfos))+' mem zones');
    tdata(data^).searchdata.addrcount:=0;
    tdata(data^).searchdata.pgcurr:=0;
    tdata(data^).searchdata.pgtotal:=length(meminfos);
    for j:=low(meminfos) to high(meminfos) do
    begin
      tdata(data^).searchdata.pgcurr:=j;
      i:=0;
      while meminfos[j].baseaddress+meminfos[j].RegionSize>meminfos[j].baseaddress+i do
      begin
          if valuetype=vt_dword then
          begin
             if readprocessmemory(target,pointer(meminfos[j].baseaddress+i),@bufdword,vlength,bytesread) then
             begin
               if value=inttostr(bufdword) then
               begin
                 tmp:=inttohex(qword(meminfos[j].baseaddress)+i,16);
                 while tmp[1]='0' do delete(tmp,1,1);
                 log('found at 0x'+tmp);
                 tdata(data^).searchdata.addrcount+=1;
                 addsaddr(tmp);
               end;
             end
             else
             begin
               log('error rpm: '+inttostr(getlasterror)+' at '+inttohex(qword(meminfos[j].baseaddress)+i,16));
               errcount+=1;
             end;
          end;
          if valuetype=vt_float then
          begin
             if readprocessmemory(target,pointer(meminfos[j].baseaddress+i),@buffloat,vlength,bytesread) then
             begin
               if value=floattostr(buffloat) then
               begin
                 tmp:=inttohex(qword(meminfos[j].baseaddress)+i,16);
                 while tmp[1]='0' do delete(tmp,1,1);
                 log('found at 0x'+tmp);
                 tdata(data^).searchdata.addrcount+=1;
                 addsaddr(tmp);
               end;
             end
             else
             begin
               log('error rpm: '+inttostr(getlasterror)+' at '+inttohex(qword(meminfos[j].baseaddress)+i,16));
               errcount+=1;
             end;
          end;
          if valuetype=vt_qword then
          begin
             if readprocessmemory(target,pointer(meminfos[j].baseaddress+i),@bufqword,vlength,bytesread) then
             begin
               if value=inttostr(bufqword) then
               begin
                 tmp:=inttohex(qword(meminfos[j].baseaddress)+i,16);
                 while tmp[1]='0' do delete(tmp,1,1);
                 log('found at 0x'+tmp);
                 tdata(data^).searchdata.addrcount+=1;
                 addsaddr(tmp);
               end;
             end
             else
             begin
               log('error rpm: '+inttostr(getlasterror)+' at '+inttohex(qword(meminfos[j].baseaddress)+i,16));
               errcount+=1;
             end;
          end;
          if valuetype=vt_string then
          begin
             if readprocessmemory(target,pointer(meminfos[j].baseaddress+i),@bufstring,vlength,bytesread) then
             begin
               if value=bufstring then
               begin
                 tmp:=inttohex(qword(meminfos[j].baseaddress)+i,16);
                 while tmp[1]='0' do delete(tmp,1,1);
                 log('found at 0x'+tmp);
                 tdata(data^).searchdata.addrcount+=1;
                 addsaddr(tmp);
               end;
             end
             else
             begin
               log('error rpm: '+inttostr(getlasterror)+' at '+inttohex(qword(meminfos[j].baseaddress)+i,16));
               errcount+=1;
             end;
          end;
          if advsearch then i+=1 else i+=vlength;
      end;
    end;
    if not alreadyopened then closehandle(target);
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
  alreadyopened:boolean;
begin
  alreadyopened:=true;
  log('Enter readmem');
  target:=getsysprocesshandle(pid);
  if target<1 then
  begin
     log('didnt find handle with getsysprocesshandle, opening process');
     target:=openprocess(process_vm_read or process_query_information,false,pid);
     alreadyopened:=false;
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
  if not alreadyopened then closehandle(target);
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
  alreadyopened:boolean;
begin
  alreadyopened:=true;
  log('Enter writemem');
  target:=getsysprocesshandle(pid);
  if target<1 then
  begin
     log('didnt find handle with getsysprocesshandle, opening process');
     target:=openprocess(process_vm_write or process_vm_operation,false,pid);
     alreadyopened:=false;
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
  if not alreadyopened then closehandle(target);
  log('leaving writemem');
end;

end.

