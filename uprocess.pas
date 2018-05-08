unit uprocess;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,ntdll,winmiscutils,utalkiewalkie,windows,jwawintype
  ,wininjection,jwatlhelp32,jwapsapi;

var
  foo:integer;
  function getinfos(pname:string):tprocessinfo;
  function dllinject(pid:dword;value:fixedstring):string;
  function getbaseaddr(pid:dword; MName: String): string;
  function getmainthreadid(pid:dword):dword;
  function getsysprocesshandle(pid:dword):thandle;

implementation

function getinfos(pname:string):tprocessinfo;
begin
  fillchar(result,0,sizeof(result));
  log('enter getinfos');
  result.pid:=getpidbyprocessname(pname);
  log('pid: '+inttostr(result.pid));
  result.baseaddr:=getbaseaddr(result.pid,pname);
  log('base addr: '+result.baseaddr);
  result.maintid:=getmainthreadid(result.pid);
  log('main tid: '+inttostr(result.maintid));
  result.syshandle:=getsysprocesshandle(result.pid);
  log('syshandle: '+inttohex(qword(result.syshandle),4));
  log('exit getinfos');
end;

function getsysprocesshandle(pid:dword):thandle;
var
  handleinfosize:ulong;
  handleinfo:psystem_handle_information;
  status:ntstatus;
  i:qword;
  errcount:integer;
  _handle:thandle;
  _pid:dword;
  _process:SYSTEM_HANDLE;
  strtype:string;
  currpid:dword;
begin
   currpid:=getcurrentprocessid;
   result:=0;
   handleinfosize:=DefaulBUFFERSIZE;
   handleinfo:=virtualalloc(nil,size_t(handleinfosize),mem_commit,page_execute_readwrite);
   status:=ntquerysysteminformation(systemhandleinformation,handleinfo,handleinfosize,nil);
   while status=STATUS_INFO_LENGTH_MISMATCH do
   begin
     handleinfosize*=2;
     if handleinfo<>nil then virtualfree(handleinfo,size_t(handleinfosize),mem_release);
     setlasterror(0);
     handleinfo:=virtualalloc(nil,size_t(handleinfosize),mem_commit,page_execute_readwrite);
     status:=ntquerysysteminformation(systemhandleinformation,handleinfo,handleinfosize,nil);
   end;
   if not nt_success(status) then
   begin
       sysmsgbox('error getting handle: '+inttohex(status,8));
       exit;
   end;
   errcount:=0;
   for i:=0 to handleinfo^.uCount-1 do
   begin
     try
       _process:=handleinfo^.handles[i];
       _handle:=_process.handle;
       if _handle>0 then strtype:=GetObjectInfo(_handle, ObjectTypeInformation);
       if lowercase(strtype)='process' then
       begin
         _pid:=getprocessid(_handle);
         if _process.uidprocess=currpid then
         begin
           if _pid=pid then
           begin
             result:=_handle;
             break;
           end;
         end;
       end;
     except
         errcount+=1;
     end;
   end;
   if handleinfo<>nil then virtualfree(handleinfo,size_t(handleinfosize),mem_release);
end;

function dllinject(pid:dword;value:fixedstring):string;
var
  target:thandle;
  hthread:thandle;
  alreadyopened:boolean;
begin
  log('Enter dllinject');
  alreadyopened:=true;
  target:=getsysprocesshandle(pid);
  if target<1 then
  begin
     log('didnt find handle, opening process');
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
  log('trying to get main thread handle');
  hthread:=openthread(thread_set_context or thread_get_context or THREAD_SUSPEND_RESUME,false,getmainthreadid(pid));
  if hthread<1 then
  begin
    log('couldnt get main thread handle, trying to find any thread handle.');
    hthread:=tryopenthread(pid,thread_set_context or thread_get_context or THREAD_SUSPEND_RESUME);
  end;

  if hthread<1 then
  begin
     log('didnt find handle, exiting');
     exit;
  end
  else log('found thread handle: '+inttostr(hthread));
  if injectctx(target,hthread,value) then
  begin
     log('inject ok');
     result:='inject ok';
  end
  else
  begin
    log('error injecting');
    result:='error injecting';
  end;
  if not alreadyopened then closehandle(target);
  closehandle(hthread);
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

function getmainthreadid(pid:dword):dword;
var
  hThreadSnapshot:thandle;
  currentpid:dword;
  tentry:threadentry32;
  _tid:dword;
  _creationtime,_exittime,_kerneltime,_usertime:windows.FILETIME;
  ctime:windows.FILETIME;
  _ctime:windows.FILETIME;
  th:thandle;
begin
   fillchar(ctime,sizeof(ctime),0);
   fillchar(_ctime,sizeof(ctime),0);
   fillchar(_creationtime,sizeof(windows.FILETIME),0);
   hthreadsnapshot:=createtoolhelp32snapshot(th32CS_snapthread,pid);
   log('hthreadsnapshot: '+inttostr(hthreadsnapshot));
   tentry.dwSize:=sizeof(threadentry32);
   result:=0;
   th:=0;
   ctime.dwLowDateTime:=4294967295;
   ctime.dwhighdatetime:=4294967295;
   th:=openthread(THREAD_QUERY_INFORMATION,false,_tid);
   if thread32first(th,tentry)=false then log('error thread32first: '+inttostr(getlasterror));;
   if tentry.th32OwnerProcessID=pid then
   begin
       result:=tentry.th32ThreadID;
       //exit
   end;
   while thread32next(hthreadsnapshot,tentry)=true do
   begin
     if tentry.th32OwnerProcessID=pid then
     begin
       _tid:=tentry.th32ThreadID;
       setlasterror(0);
       th:=openthread(THREAD_QUERY_INFORMATION,false,_tid);
       if th>1 then
       begin
           if getthreadtimes(th,_creationtime,_exittime,_kerneltime,_usertime)=false then
              log('getthreadtimes error: '+inttostr(getlasterror));
           if comparefiletime(@_creationtime,@ctime)=-1 then result:=_tid;
           ctime:=_creationtime;
       end;
     end;
   end;
end;

end.

