unit umem;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,utalkiewalkie,ntdll,windows,jwapsapi,strutils;

type
  fixedstring=string[64];
const
  vt_dword:dword=1;
  vt_qword:dword=2;
  vt_string:dword=3;
  vt_float:dword=4;
  vt_bytearray:dword=5;

var
  foo:integer;
  function researchmem(pid:dword;value:string;valuetype:dword;vlength:dword):string;
  function readmem(pid:dword;addr:qword;valuetype:dword;vlength:ptruint):string;
  function writemem(pid:dword;addr:qword;valuetype:dword;value:fixedstring;vlength:ptruint):string;
  function searchmem(pid:dword;value:fixedstring;valuetype:dword;vlength:dword;startaddr:qword;endaddr:qword;advsearch:boolean):string;
  function getbaseaddr(pid:dword; MName: String): string;

implementation

function ByteToHex(InByte:byte):shortstring;
const Digits:array[0..15] of char='0123456789ABCDEF';
begin
 result:=digits[InByte shr 4]+digits[InByte and $0F];
end;

function getbaseaddr(pid:dword; MName: String): string;
var
  Modules         : Array of HMODULE;
  cbNeeded, i     : Cardinal;
  ModuleInfo      : TModuleInfo;
  ModuleName      : Array[0..MAX_PATH] of Char;
  target:thandle;
  alreadyopened:boolean;
begin
  log('enter getbaseaddr');
  Result := '';
  SetLength(Modules, 1024);
  alreadyopened:=true;
  target:=getsysprocesshandle(pid);
  if target<1 then
  begin
     log('didnt find handle, opening process');
     target:=openprocess(process_vm_read or process_vm_operation or PROCESS_QUERY_INFORMATION,false,pid);
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
  if (target <> 0) then
  begin
    EnumProcessModules(target, @Modules[0], 1024 * SizeOf(HMODULE), cbNeeded); //Getting the enumeration of modules
    SetLength(Modules, cbNeeded div SizeOf(HMODULE)); //Setting the number of modules
    for i := 0 to Length(Modules) - 1 do //Start the loop
    begin
      GetModuleBaseName(target, Modules[i], ModuleName, SizeOf(ModuleName)); //Getting the name of module
      if AnsiCompareText(MName, ModuleName) = 0 then //If the module name matches with the name of module we are looking for...
      begin
        GetModuleInformation(target, Modules[i], ModuleInfo, SizeOf(ModuleInfo)); //Get the information of module
        Result := '$'+inttohex(qword(ModuleInfo.lpBaseOfDll),16); //Return the information we want (The image base address)
        break;
      end;
    end;
  end;
  if not alreadyopened then closehandle(target);
end;
function researchmem(pid:dword;value:string;valuetype:dword;vlength:dword):string;
var
  buf:array[0..63] of byte;
  bytesread:ptruint;
  target:thandle;
  resp:string;
  i:integer;
  searchdata:tsearchdata;
  alreadyopened:boolean;
  readvalue:string;
begin
  log('Enter researchmem');
  fillchar(readvalue,64,0);
  fillchar(buf,64,0);
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
            if valuetype=vt_bytearray then
            begin
              readvalue:=value;
              copymemory(@(readvalue[1]),@buf,vlength);
            end;
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
function searchmem(pid:dword;value:fixedstring;valuetype:dword;vlength:dword;startaddr:qword;endaddr:qword;advsearch:boolean):string;
var
  target:thandle;
  MemInfo: MEMORY_BASIC_INFORMATION;
  MemStart: pointer;
  i:qword;
  buf:array[0..63] of byte;
  bytesread:ptruint;
  ret:ptruint;
  tmp:string;
  readvalue:fixedstring;
  j:integer;
  errcount:integer;
  meminfos:array of memory_basic_information;
  alreadyopened:boolean;
begin
    fillchar(readvalue,64,0);
    fillchar(buf,64,0);
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
               if valuetype=vt_bytearray then
               begin
                 readvalue:=value;
                 copymemory(@(readvalue[1]),@buf,vlength);
               end;
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
  i:integer;
begin
  result:='';
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
  if valuetype=vt_bytearray then
  begin
    if readprocessmemory(target,pointer(addr),@buf,vlength,bytesread) then
    begin
      log('rpm ok, '+inttostr(bytesread)+' bytes read');
      for i:=0 to vlength-1 do
      begin
        result+='$'+bytetohex(buf[i]);
        if i<vlength-1 then result+=' ';
      end;
      log('result: '+result);
    end
    else log('error rpm: '+inttostr(getlasterror));
  end
  else
  begin
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
  end;
  if not alreadyopened then closehandle(target);
  log('exit readmem');
end;

function writemem(pid:dword;addr:qword;valuetype:dword;value:fixedstring;vlength:ptruint):string;
var
  i:integer;
  buf:array[0..254] of byte;
  byteswritten:ptruint;
  target:thandle;
  alreadyopened:boolean;
  tmpstr:string;
begin
  //log(tmpstr);
  //log(value);
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
  log('handle ok');
  if valuetype=vt_dword then move(strtoint(value),buf,vlength);
  if valuetype=vt_qword then move(strtoint64(value),buf,vlength);
  if valuetype=vt_float then move(strtoint(value),buf,vlength);
  if valuetype=vt_string then move(value,buf,vlength);
  if valuetype=vt_bytearray then
  begin
    for i:=1 to tdata(data^).valuelength do
    begin
      buf[i-1]:=byte(ord(tdata(data^).value[i]));
    end;
  end;
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

