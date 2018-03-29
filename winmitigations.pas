unit winmitigations;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,windows;

type
  PROCESS_MITIGATION_POLICY =
  (ProcessDEPPolicy,
    ProcessASLRPolicy,
    ProcessDynamicCodePolicy,
    ProcessStrictHandleCheckPolicy,
    ProcessSystemCallDisablePolicy,
    ProcessMitigationOptionsMask,
    ProcessExtensionPointDisablePolicy,
    ProcessControlFlowGuardPolicy,
    ProcessSignaturePolicy,
    ProcessFontDisablePolicy,
    ProcessImageLoadPolicy,
    MaxProcessMitigationPolicy);

  PROCESS_MITIGATION_BINARY_SIGNATURE_POLICY=record
    flags:dword;
    microsoftsignedonly:dword;
    mitigationoptin:dword;
    reservedflags:dword;
  end;
  PPROCESS_MITIGATION_BINARY_SIGNATURE_POLICY=^PROCESS_MITIGATION_BINARY_SIGNATURE_POLICY;


var
  foo:dword;
  function setprocessmitigationpolicy(mitigationpolicy:process_mitigation_policy;
    value:pointer;//PPROCESS_MITIGATION_BINARY_SIGNATURE_POLICY;
    length:size_t):boolean;stdcall;external 'kernel32.dll' name 'SetProcessMitigationPolicy';

  function getprocessmitigationpolicy(ahandle:thandle;mitigationpolicy:process_mitigation_policy;
    output:pointer;
    length:size_t):boolean;stdcall;external 'kernel32.dll' name 'GetProcessMitigationPolicy';

implementation

end.

