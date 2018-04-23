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
  buf:array[0..254] of byte;
  bytesread:ptruint;
  target:thandle;
  resp:string;
  i:integer;
  searchdata:tsearchdata;
  alreadyopened:boolean;
  readvalue:string;
begin
  log('Enter researchmem');
  fillchar(buf,255,0);
  alreadyopened:=true;
  target:=getsysprocesshandle(pid);
  if target<1 then
  begin
     log('didnt find handle, opening process');
     target:=openprocess(process_vm_read or process_vm_operation,false,pid);
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
  searchdata:=tdata(data^).searchdata;
  tdata(data^).searchdata.index:=0;
  for i:=0 to 1023 do tdata(data^).searchdata.retaddrs[i]:='';
  log('addr count: '+inttostr(searchdata.index+1));
  tdata(data^).searchdata.pgtotal:=tdata(data^).searchdata.index;
  tdata(data^).searchdata.pgcurr:=0;
  tdata(data^).searchdata.addrcount:=0;
  for i:=0 to searchdata.index do
  begin
      if tdata(data^).searchdata.stop=true then
      begin
          log('Stopping search');
          break;
      end;
      tdata(data^).searchdata.pgcurr:=i;
      if length(searchdata.retaddrs[i])>2 then
      begin
          log('reading addr '+inttostr(i+1)+'/'+inttostr(searchdata.index+1)+': '+searchdata.retaddrs[i]);
          if readprocessmemory(target,pointer(strtoint64(searchdata.retaddrs[i])),@buf,vlength,bytesread) then
          begin
            if valuetype=vt_dword then readvalue:=inttostr(dword((@buf)^));
            if valuetype=vt_qword then readvalue:=inttostr(qword((@buf)^));
            if valuetype=vt_float then readvalue:=floattostr(single((@buf)^));
            if valuetype=vt_string then readvalue:=string((@buf)^);
            if value=readvalue then
            begin
              addsaddr(stringreplace(searchdata.retaddrs[i],'$','',[rfreplaceall,rfignorecase]));
              log('found at: '+searchdata.retaddrs[i]);
              tdata(data^).searchdata.addrcount+=1;
            end;
          end
          else
          begin
            log('error rpm: '+inttostr(getlasterror));
          end;
      end;
  end;
  result:='found '+inttostr(tdata(data^).searchdata.addrcount)+' addresses';
  log('result: '+result);
  if not alreadyopened then closehandle(target);
  log('leaving researchmem');
end;
function searchmem(pid:dword;value:string;valuetype:dword;vlength:dword;startaddr:qword;endaddr:qword;advsearch:boolean):string;
var
  target:thandle;
  MemInfo: MEMORY_BASIC_INFORMATION;
  MemStart: pointer;
  i:qword;
  buf:array[0..254] of byte;
  bytesread:ptruint;
  ret:ptruint;
  tmp:string;
  readvalue:string;
  j:integer;
  errcount:integer;
  meminfos:array of memory_basic_information;
  alreadyopened:boolean;
begin
    fillchar(buf,255,0);
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
        if tdata(data^).searchdata.stop=true then
        begin
            break;
            log('Stopping search');
        end;
    end;
    log('found '+inttostr(length(meminfos))+' mem zones');
    tdata(data^).searchdata.addrcount:=0;
    tdata(data^).searchdata.pgcurr:=0;
    tdata(data^).searchdata.pgtotal:=length(meminfos);
    for j:=low(meminfos) to high(meminfos) do
    begin
      tdata(data^).searchdata.pgcurr:=j;
      i:=0;
      if tdata(data^).searchdata.stop=true then
      begin
               log('Stopping search');
               break;
      end;
      while meminfos[j].baseaddress+meminfos[j].RegionSize>meminfos[j].baseaddress+i do
      begin
           if tdata(data^).searchdata.stop=true then
           begin
               log('Stopping search');
               break;
           end;
           if readprocessmemory(target,pointer(meminfos[j].baseaddress+i),@buf,vlength,bytesread) then
           begin
               if valuetype=vt_dword then readvalue:=inttostr(dword((@buf)^));
               if valuetype=vt_qword then readvalue:=inttostr(qword((@buf)^));
               if valuetype=vt_float then readvalue:=floattostr(single((@buf)^));
               if valuetype=vt_string then readvalue:=string((@buf)^);
               if value=readvalue then
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
           if advsearch then i+=1 else i+=vlength;
      end;
    end;
    if not alreadyopened then closehandle(target);
    result:='found '+inttostr(tdata(data^).searchdata.addrcount)+' addresses';
    log('exit, result: '+result);
end;

function readmem(pid:dword;addr:qword;valuetype:dword;vlength:ptruint):string;
var
  buf:array[0..254] of byte;
  bytesread:ptruint;
  target:thandle;
  alreadyopened:boolean;
begin
  fillchar(buf,255,0);
  alreadyopened:=true;
  log('Enter readmem');
  target:=getsysprocesshandle(pid);
  if target<1 then
  begin
     log('didnt find handle with getsysprocesshandle, opening process');
     target:=openprocess(process_vm_read or process_vm_operation,false,pid);
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
  if readprocessmemory(target,pointer(addr),@buf,vlength,bytesread) then
  begin
       log('rpm ok, '+inttostr(bytesread)+' bytes read');
       if valuetype=vt_dword then result:=inttostr(dword((@buf)^));
       if valuetype=vt_qword then result:=inttostr(qword((@buf)^));
       if valuetype=vt_float then result:=floattostr(single((@buf)^));
       if valuetype=vt_string then result:=string((@buf)^);
       log('result: '+result);
  end
  else log('error rpm: '+inttostr(getlasterror));
  if not alreadyopened then closehandle(target);
  log('exit readmem');
end;

function writemem(pid:dword;addr:qword;valuetype:dword;value:string;vlength:ptruint):string;
var
  buf:array[0..254] of byte;
  byteswritten:ptruint;
  target:thandle;
  alreadyopened:boolean;
begin
  fillchar(buf,255,0);
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
  if valuetype=vt_dword then move(strtoint(value),buf,vlength);
  if valuetype=vt_qword then move(strtoint64(value),buf,vlength);
  if valuetype=vt_float then move(strtoint(value),buf,vlength);
  if valuetype=vt_string then move(value,buf,vlength);
  if writeprocessmemory(target,pointer(addr),@buf,vlength,byteswritten) then
  begin
       log('wpm ok, '+inttostr(byteswritten)+' bytes written');
       result:='ok';
  end
  else log('error wpm: '+inttostr(getlasterror));
  if not alreadyopened then closehandle(target);
  log('exit writemem');
end;

end.

