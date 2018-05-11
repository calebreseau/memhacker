unit uprocess;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,ntdll,winmiscutils,utalkiewalkie,windows,jwawintype
  ,wininjection,jwatlhelp32,jwapsapi;

const
  PROCESS_SUSPEND_RESUME=$0800;

var
  foo:integer;
  function getinfos(pname:string):tprocessinfo;
  function getthreads(pname:string):tthreadinfos;
  function dllinject(pid:dword;value:fixedstring):string;
  function getbaseaddr(pid:dword; MName: String): string;
  function getmainthreadid(pid:dword):dword;
  function getsysprocesshandle(pid:dword;access:dword=process_all_access):thandle;
  function getsysthreadhandle(tid:dword;access:dword=thread_all_access):thandle;
  function resumeprocessfrompid(pid:dword):string;
  function suspendprocessfrompid(pid:dword):string;
  function terminateprocessfrompid(pid:dword;exitcode:dword):string;
  function terminatethreadfromtid(tid:dword;exitcode:dword):string;
  function suspendthreadfromtid(tid:dword):string;
  function resumethreadfromtid(tid:dword):string;

implementation

function getthreads(pname:string):tthreadinfos;
var
  hThreadSnapshot:thandle;
  tentry:threadentry32;
  th:thandle;
  i:integer;
  pid,ownerpid:dword;
begin
  log('enter getthreads');
  pid:=getpidbyprocessname(pname);
  if pid<1 then
  begin
    log('couldnt get pid, exiting');
    exit;
  end
  else log('found pid: '+inttostr(pid));
  fillchar(result,sizeof(tthreadinfos),0);
  i:=0;
  hthreadsnapshot:=createtoolhelp32snapshot(th32CS_snapthread,pid);
  log('hthreadsnapshot: '+inttostr(hthreadsnapshot));
  log('lasterror: '+inttostr(getlasterror));
  tentry.dwSize:=sizeof(threadentry32);
  log('ok');
  if thread32first(hthreadsnapshot,tentry)=false then log('error thread32first: '+inttostr(getlasterror));;
  ownerpid:=tentry.th32OwnerProcessID;
  if tentry.th32OwnerProcessID=pid then
  begin
    log('ownerpid=pid');
    result[i].tid:=tentry.th32threadid;
    log('found thread with id '+inttostr(result[i].tid));
    th:=getsysthreadhandle(tentry.th32ThreadID);
    if th<1 then
      result[i].handle:=0
    else
    begin
      result[i].handle:=th;
      log('found handle for thread: '+inttostr(th));
    end;
  end;
  log('ok');
  i+=1;
  while thread32next(hthreadsnapshot,tentry)=true do
  begin
    if tentry.th32OwnerProcessID=pid then
    begin
      result[i].tid:=tentry.th32threadid;
      log('found thread with id '+inttostr(result[i].tid));
      th:=getsysthreadhandle(tentry.th32ThreadID);
      if th<1 then
        result[i].handle:=0
      else
      begin
        result[i].handle:=th;
        log('found handle for thread: '+inttostr(th));
      end;
      i+=1;
    end;
  end;
  tdata(data^).thrlastmodified:=gettickcount64;
  log('last modified thrinfo on '+inttostr(gettickcount64));
  log('leave getthreads');
end;

function terminatethreadfromtid(tid:dword;exitcode:dword):string;
var
  target:thandle;
  alreadyopened:boolean;
begin
    log('enter terminatethreadfromtid');
    alreadyopened:=false;
    target:=getsysthreadhandle(tid,thread_terminate);
    if target<1 then
    begin
       log('didnt find handle with getsysthreadhandle, opening thread');
       target:=openthread(thread_terminate,false,tid);
       alreadyopened:=false;
       log('openthread handle: '+inttohex(target,4));
    end
    else  log('found handle: '+inttohex(target,4));
    if target<1 then
    begin
       log('error opening thread: '+inttostr(getlasterror)+', exiting');
       result:='';
       exit;
    end;
    if terminatethread(target,exitcode) then
    begin
      log('successfully terminated thread');
      result:='successfully terminated thread';
    end
    else
    begin
      log('error terminating thread: '+inttostr(getlasterror));
      result:='error terminating thread: '+inttostr(getlasterror);
    end;
    log('lasterror: '+inttostr(getlasterror));
    if not alreadyopened then closehandle(target);
    log('leave terminatethreadfromtid');
end;

function suspendthreadfromtid(tid:dword):string;
var
  target:thandle;
  alreadyopened:boolean;
begin
    log('enter suspendthreadfromtid');
    alreadyopened:=false;
    target:=getsysthreadhandle(tid,thread_suspend_resume);
    if target<1 then
    begin
       log('didnt find handle with getsysthreadhandle, opening thread');
       target:=openthread(thread_suspend_resume,false,tid);
       alreadyopened:=false;
       log('openthread handle: '+inttohex(target,4));
    end
    else  log('found handle: '+inttohex(target,4));
    if target<1 then
    begin
       log('error opening thread: '+inttostr(getlasterror)+', exiting');
       result:='';
       exit;
    end;
    if suspendthread(target)<>-1 then
    begin
      log('successfully suspended thread');
      result:='successfully suspended thread';
    end
    else
    begin
      log('error suspending thread: '+inttostr(getlasterror));
      result:='error suspending thread: '+inttostr(getlasterror);
    end;
    log('lasterror: '+inttostr(getlasterror));
    if not alreadyopened then closehandle(target);
    log('leave suspendthreadfromtid');
end;

function resumethreadfromtid(tid:dword):string;
var
  target:thandle;
  alreadyopened:boolean;
begin
    log('enter resumethreadfromtid');
    alreadyopened:=false;
    target:=getsysthreadhandle(tid,thread_suspend_resume);
    if target<1 then
    begin
       log('didnt find handle with getsysthreadhandle, opening thread');
       target:=openthread(thread_suspend_resume,false,tid);
       alreadyopened:=false;
       log('openthread handle: '+inttohex(target,4));
    end
    else  log('found handle: '+inttohex(target,4));
    if target<1 then
    begin
       log('error opening thread: '+inttostr(getlasterror)+', exiting');
       result:='';
       exit;
    end;
    if resumethread(target)<>-1 then
    begin
      log('successfully resumed thread');
      result:='successfully resumed thread';
    end
    else
    begin
      log('error resuming thread: '+inttostr(getlasterror));
      result:='error resuming thread: '+inttostr(getlasterror);
    end;
    log('lasterror: '+inttostr(getlasterror));
    if not alreadyopened then closehandle(target);
    log('leave resumethreadfromtid');
end;

function getmainthreadid(pid:dword):dword;
var
  hThreadSnapshot:thandle;
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
   setlasterror(0);
   hthreadsnapshot:=createtoolhelp32snapshot(th32CS_snapthread,pid);
   log('hthreadsnapshot: '+inttostr(hthreadsnapshot));
   log('lasterror: '+inttostr(getlasterror));
   tentry.dwSize:=sizeof(threadentry32);
   result:=0;
   th:=0;
   ctime.dwLowDateTime:=4294967295;
   ctime.dwhighdatetime:=4294967295;
   if thread32first(hthreadsnapshot,tentry)=false then log('error thread32first: '+inttostr(getlasterror));;
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

function terminateprocessfrompid(pid:dword;exitcode:dword):string;
var
  target:thandle;
  alreadyopened:boolean;
begin
    log('enter terminateprocessfrompid');
    alreadyopened:=false;
    target:=getsysprocesshandle(pid,process_terminate);
    if target<1 then
    begin
       log('didnt find handle with getsysprocesshandle, opening process');
       target:=openprocess(process_terminate,false,pid);
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
    if terminateprocess(target,exitcode) then
    begin
      log('successfully terminated process');
      result:='successfully terminated process';
    end
    else
    begin
      log('error terminating process: '+inttostr(getlasterror));
      result:='error terminating process: '+inttostr(getlasterror);
    end;
    if not alreadyopened then closehandle(target);
    log('leave terminateprocessfrompid');
end;

function suspendprocessfrompid(pid:dword):string;
var
  target:thandle;
  alreadyopened:boolean;
begin
    log('enter suspendprocessfrompid');
    alreadyopened:=false;
    target:=getsysprocesshandle(pid,process_suspend_resume);
    if target<1 then
    begin
       log('didnt find handle with getsysprocesshandle, opening process');
       target:=openprocess(process_suspend_resume,false,pid);
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
    if nt_success(ntsuspendprocess(target)) then
    begin
      log('successfully suspended process');
      result:='successfully suspended process';
    end
    else
    begin
      log('error suspending process: '+inttostr(getlasterror));
      result:='error suspending process: '+inttostr(getlasterror);
    end;
    if not alreadyopened then closehandle(target);
    log('leave suspendprocessfrompid');
end;

function resumeprocessfrompid(pid:dword):string;
var
  target:thandle;
  alreadyopened:boolean;
begin
    log('enter resumeprocessfrompid');
    alreadyopened:=false;
    target:=getsysprocesshandle(pid,process_suspend_resume);
    if target<1 then
    begin
       log('didnt find handle with getsysprocesshandle, opening process');
       target:=openprocess(process_suspend_resume,false,pid);
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
    if nt_success(ntresumeprocess(target)) then
    begin
      log('successfully resumed process');
      result:='successfully resumed process';
    end
    else
    begin
      log('error resuming process: '+inttostr(getlasterror));
      result:='error resuming process: '+inttostr(getlasterror);
    end;
    if not alreadyopened then closehandle(target);
    log('leave resumeprocessfrompid');
end;

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

function getsysprocesshandle(pid:dword;access:dword=process_all_access):thandle;
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
             if (_process.GrantedAccess=access)
               or (_process.grantedaccess and access=access)
               or (_process.grantedaccess=process_all_access) then
             begin
               result:=_handle;
               break;
             end;
           end;
         end;
       end;
     except
         errcount+=1;
     end;
   end;
   if handleinfo<>nil then virtualfree(handleinfo,size_t(handleinfosize),mem_release);
end;

function getsysthreadhandle(tid:dword;access:dword=thread_all_access):thandle;
var
  handleinfosize:ulong;
  handleinfo:psystem_handle_information;
  status:ntstatus;
  i:qword;
  errcount:integer;
  _handle:thandle;
  _pid:dword;
  _thread:SYSTEM_HANDLE;
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
       _thread:=handleinfo^.handles[i];
       _handle:=_thread.handle;
       if _handle>0 then strtype:=GetObjectInfo(_handle, ObjectTypeInformation);
       if lowercase(strtype)='thread' then
       begin
         _pid:=getthreadid(_handle);
         if _thread.uidprocess=currpid then
         begin
           if _pid=tid then
           begin
             if (_thread.GrantedAccess=access)
               or (_thread.grantedaccess and access=access)
               or (_thread.grantedaccess=thread_all_access) then
             begin
               result:=_handle;
               break;
             end;
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
  log('trying to get main thread handle from host');
  hthread:=openthread(thread_set_context or thread_get_context or THREAD_SUSPEND_RESUME,false,getsysthreadhandle(getmainthreadid(pid)));
  if hthread<1 then
  begin
    log('trying to open main thread');
    hthread:=openthread(thread_set_context or thread_get_context or THREAD_SUSPEND_RESUME,false,getmainthreadid(pid));
  end;
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

end.

