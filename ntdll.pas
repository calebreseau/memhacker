unit ntdll;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,windows,winmiscutils,jwawintype,jwapsapi,strutils;

type

   OBJECT_INFORMATION_CLASS = (ObjectBasicInformation,ObjectNameInformation,ObjectTypeInformation,ObjectAllTypesInformation,ObjectHandleInformation );
  SYSTEM_INFORMATION_CLASS = (
    SystemBasicInformation,
    SystemProcessorInformation, 
    SystemPerformanceInformation,
    SystemTimeOfDayInformation,
    SystemNotImplemented1,
    SystemProcessesAndThreadsInformation,
    SystemCallCounts,
    SystemConfigurationInformation,
    SystemProcessorTimes,
    SystemGlobalFlag,
    SystemNotImplemented2,
    SystemModuleInformation,
    SystemLockInformation,
    SystemNotImplemented3,
    SystemNotImplemented4,
    SystemNotImplemented5,
    SystemHandleInformation,
    SystemObjectInformation,
    SystemPagefileInformation,
    SystemInstructionEmulationCounts,
    SystemInvalidInfoClass1,
    SystemCacheInformation,
    SystemPoolTagInformation,
    SystemProcessorStatistics,
    SystemDpcInformation,
    SystemNotImplemented6,
    SystemLoadImage,
    SystemUnloadImage,
    SystemTimeAdjustment,
    SystemNotImplemented7,
    SystemNotImplemented8,
    SystemNotImplemented9,
    SystemCrashDumpInformation,
    SystemExceptionInformation,
    SystemCrashDumpStateInformation,
    SystemKernelDebuggerInformation,
    SystemContextSwitchInformation,
    SystemRegistryQuotaInformation,
    SystemLoadAndCallImage,
    SystemPrioritySeparation,
    SystemNotImplemented10,
    SystemNotImplemented11,
    SystemInvalidInfoClass2,
    SystemInvalidInfoClass3,
    SystemTimeZoneInformation,
    SystemLookasideInformation,
    SystemSetTimeSlipEvent,
    SystemCreateSession,
    SystemDeleteSession,
    SystemInvalidInfoClass4,
    SystemRangeStartInformation,
    SystemVerifierInformation,
    SystemAddVerifier,
    SystemSessionProcessesInformation
    );

    client_id=record
      uniqueprocess:uint64;
      uniquethread:uint64;
    end;

    pclient_id=^client_id;
    OBJECT_NAME_INFORMATION=UNICODE_STRING;
 POBJECT_NAME_INFORMATION=^OBJECT_NAME_INFORMATION;



const
    STATUS_SUCCESS               = ntstatus($00000000);
    STATUS_BUFFER_OVERFLOW        = ntstatus($80000005);
    STATUS_INFO_LENGTH_MISMATCH   = ntstatus($C0000004);
    DefaulBUFFERSIZE              = $100000;

  function ntquerysysteminformation(systeminformationclass:system_information_class;systeminformation:pvoid;systeminformationlength:ulong;returnlength:pulong): ntstatus; stdcall;external 'ntdll.dll' name 'NtQuerySystemInformation';
  function ntqueryobject(ObjectHandle:cardinal; ObjectInformationClass:OBJECT_INFORMATION_CLASS; ObjectInformation:pointer; Length:ULONG;ResultLength:PDWORD):ntstatus; stdcall;external 'ntdll.dll' name 'NtQueryObject';
  function ntsuspendprocess(ProcessHandle: THANDLE):boolean; stdcall;external 'ntdll.dll' name 'NtSuspendProcess';
  function NtResumeProcess(ProcessHandle: THANDLE):boolean; stdcall;external 'ntdll.dll' name 'NtResumeProcess';
  function rtlcreateuserthread(ProcessHandle: THANDLE;
     SecurityDescriptor: PSECURITY_DESCRIPTOR;
     CreateSuspended: Boolean;
     StackZeroBits: ULONG;
     StackReserved: SIZE_T; StackCommit: SIZE_T;
     StartAddress: pointer;
     StartParameter: pointer;
     ThreadHandle: PHANDLE;
     ClientID: PCLIENT_ID):ntstatus; stdcall;external 'ntdll.dll' name 'RtlCreateUserThread';
  function getsysprocesshandle(pid:dword):thandle;
  function GetProcessId(Process: THandle): DWORD; stdcall; external 'kernel32.dll' name 'GetProcessId';

implementation

function GetObjectInfo(hObject:cardinal; objInfoClass:OBJECT_INFORMATION_CLASS):string;
var
 pObjectInfo:POBJECT_NAME_INFORMATION;
 HDummy     :THandle;
 dwSize     :DWORD;
 _result:LPWSTR;
begin
  dwSize      := sizeof(OBJECT_NAME_INFORMATION);
  pObjectInfo := AllocMem(dwSize);
  HDummy      := NTQueryObject(hObject, objInfoClass, pObjectInfo,dwsize, @dwSize);

  if((HDummy = STATUS_BUFFER_OVERFLOW) or (HDummy = STATUS_INFO_LENGTH_MISMATCH)) then
    begin
   FreeMem(pObjectInfo);
   pObjectInfo := AllocMem(dwSize);
   HDummy      := NTQueryObject(hObject, objInfoClass, pObjectInfo,dwSize, @dwSize);
  end;

  if((HDummy >= STATUS_SUCCESS) and (pObjectInfo^.Buffer <> nil)) then
  begin
   _Result := AllocMem(pObjectInfo^.Length + sizeof(WCHAR));
   CopyMemory(_result, pObjectInfo^.Buffer, pObjectInfo^.Length);
   result:=string(_result);
   if _result<>nil then freemem(_result);
  end;
  if pobjectinfo<>nil then FreeMem(pObjectInfo);
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

end.

