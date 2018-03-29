unit ntdll;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,windows,jwawintype,jwapsapi;

type
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

      TFNAPCProc = TFarProc;
  SYSTEM_HANDLE=packed record
     uIdProcess:ULONG;
     ObjectType:byte;
     Flags     :byte;
     Handle    :ushort;
     pObject   :Pointer;
     GrantedAccess:ACCESS_MASK;
  end;
  PSYSTEM_HANDLE      = ^SYSTEM_HANDLE;
  SYSTEM_HANDLE_ARRAY = Array[0..0] of SYSTEM_HANDLE;
  PSYSTEM_HANDLE_ARRAY= ^SYSTEM_HANDLE_ARRAY;
  SYSTEM_HANDLE_INFORMATION=packed record
    uCount:ULONG;
    Handles:SYSTEM_HANDLE_ARRAY;
  end;
  PSYSTEM_HANDLE_INFORMATION=^SYSTEM_HANDLE_INFORMATION;
  ntstatus=integer;

 UNICODE_STRING=packed record
    Length       :Word;
    MaximumLength:Word;
    Buffer       :PWideChar;
 end;
 OBJECT_INFORMATION_CLASS = (ObjectBasicInformation,ObjectNameInformation,ObjectTypeInformation,ObjectAllTypesInformation,ObjectHandleInformation );
 OBJECT_NAME_INFORMATION=UNICODE_STRING;
 POBJECT_NAME_INFORMATION=^OBJECT_NAME_INFORMATION;

const
    STATUS_SUCCESS               = ntstatus($00000000);
    STATUS_BUFFER_OVERFLOW        = ntstatus($80000005);
    STATUS_INFO_LENGTH_MISMATCH   = ntstatus($C0000004);
    DefaulBUFFERSIZE              = $100000;

  function ntquerysysteminformation(systeminformationclass:system_information_class;systeminformation:pvoid;systeminformationlength:ulong;returnlength:pulong): ntstatus; stdcall;external 'ntdll.dll' name 'NtQuerySystemInformation';
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
  function NtQuerySystemInformation(SystemInformationClass:DWORD; SystemInformation:pointer; SystemInformationLength:DWORD;  ReturnLength:PDWORD):THandle; stdcall;external 'ntdll.dll' name 'NtQuerySystemInformation';
  function NtQueryObject(ObjectHandle:cardinal; ObjectInformationClass:OBJECT_INFORMATION_CLASS; ObjectInformation:pointer; Length:ULONG;ResultLength:PDWORD):THandle;stdcall;external 'ntdll.dll' name 'NtQueryObject';
  function findhandlefrompid(pid:dword):thandle;

implementation

function GetObjectInfo(hObject:cardinal; objInfoClass:OBJECT_INFORMATION_CLASS):LPWSTR;
var
 pObjectInfo:POBJECT_NAME_INFORMATION;
 HDummy     :THandle;
 dwSize     :DWORD;
begin
  Result:=nil;
  dwSize      := sizeof(OBJECT_NAME_INFORMATION);
  pObjectInfo := AllocMem(dwSize);
  HDummy      := NTQueryObject(hObject, objInfoClass, pObjectInfo,dwSize, @dwSize);

  if((HDummy = STATUS_BUFFER_OVERFLOW) or (HDummy = STATUS_INFO_LENGTH_MISMATCH)) then
    begin
   FreeMem(pObjectInfo);
   pObjectInfo := AllocMem(dwSize);
   HDummy      := NTQueryObject(hObject, objInfoClass, pObjectInfo,dwSize, @dwSize);
  end;

  if((HDummy >= STATUS_SUCCESS) and (pObjectInfo^.Buffer <> nil)) then
  begin
   Result := AllocMem(pObjectInfo^.Length + sizeof(WCHAR));
   CopyMemory(result, pObjectInfo^.Buffer, pObjectInfo^.Length);
  end;
  FreeMem(pObjectInfo);
end;

function findhandlefrompid(pid:dword):thandle;      //function from delphibasics
var
 sDummy      : string;
 hProcess    : THandle;
 hObject     : THandle;
 ResultLength: DWORD;
 aBufferSize : DWORD;
 aIndex      : Integer;
 pHandleInfo : PSYSTEM_HANDLE_INFORMATION;
 HDummy      : THandle;
 lpwsName    : PWideChar;
 lpwsType    : PWideChar;
 lpszProcess : PAnsiChar;
begin
    AbufferSize      := DefaulBUFFERSIZE;
  pHandleInfo      := AllocMem(AbufferSize);
  HDummy           := NTQuerySystemInformation(SystemHandleInformation, pHandleInfo,AbufferSize, @ResultLength);  //Get the list of handles

  if(HDummy = STATUS_SUCCESS) then  //If no error continue
    begin

      for aIndex:=0 to pHandleInfo^.uCount-1 do   //iterate the list
      begin
    hProcess := OpenProcess(PROCESS_DUP_HANDLE or PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, pHandleInfo^.Handles[aIndex].uIdProcess);  //open the process to get aditional info
    if(hProcess <> INVALID_HANDLE_VALUE) then  //Check valid handle
        begin
     hObject := 0;
     if DuplicateHandle(hProcess, pHandleInfo^.Handles[aIndex].Handle,GetCurrentProcess(), @hObject, STANDARD_RIGHTS_REQUIRED,FALSE, 0) then  //Get  a copy of the original handle
          begin
      lpwsName := GetObjectInfo(hObject, ObjectNameInformation); //Get the filename linked to the handle
      if (lpwsName <> nil)  then
            begin
       lpwsType    := GetObjectInfo(hObject, ObjectTypeInformation);
       lpszProcess := AllocMem(MAX_PATH);

       if GetModuleFileNameEx(hProcess, 0,lpszProcess, MAX_PATH)<>0 then  //get the name of the process
               sDummy:=ExtractFileName(lpszProcess)
              else
               sDummy:= 'System Process';

              if pHandleInfo^.Handles[aIndex].uIdProcess=pid then
              begin
                result:=pHandleInfo^.Handles[aIndex].Handle;
                break;
              FreeMem(lpwsName);
              FreeMem(lpwsType);
              FreeMem(lpszProcess);
      end;
      CloseHandle(hObject);
     end;
     CloseHandle(hProcess);
    end;
   end;
  end;
  FreeMem(pHandleInfo);


  end;
end;

end.

