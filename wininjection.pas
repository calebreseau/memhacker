unit wininjection;

{$mode objfpc}{$H+}

interface
 
uses
  Classes, SysUtils,windows,winmiscutils,utalkiewalkie,ntdll;


  function injectsys(ahandle:thandle;susp:boolean;th:thandle;ch:client_id;dll:string):dword;
  function injectctx(hprocess, hthread: thandle; dll: string): boolean;
  function injectapc( hprocess,hthread:thandle;dllpath:string):boolean;

implementation



function injectapc( hprocess,hthread:thandle;dllpath:string):boolean;
var
    lpDllAddr,lploadLibraryAddr:pointer;
    byteswritten:ptruint;
    dll:string;
begin
   log('enter injectapc');
   dll:=dllpath+#0;
   log('dll: '+dllpath);
   result:=false;
    //memory address for dll
    lpDllAddr := VirtualAllocEx(hProcess, nil, length(dll), MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE);
    log('lpDllAddr:'+inttohex(nativeuint(lpDllAddr),8));
    if WriteProcessMemory(hProcess, lpDllAddr, @dll[1], length(dll), byteswritten) then
      log('WPM OK, '+inttostr(byteswritten )+' bytes written')
    else
    begin
      log('WPM Error '+inttostr(getlasterror)+', '+inttostr(byteswritten )+' bytes written, exiting');
      exit;
    end;
    //memory address of loadlibrary
    lploadLibraryAddr := GetProcAddress(GetModuleHandle('kernel32.dll'), 'LoadLibraryA');
    log('loadLibraryAddress:'+inttohex(nativeuint(lploadLibraryAddr),8));
    //
    setlasterror(0);
    if QueueUserAPC(lploadLibraryAddr, hThread, ulong_ptr(lpdlladdr))=0
       then result:=false
       else result:=true;
    log('Last error: '+inttostr(getlasterror));
end;

function injectctx(hprocess, hthread: thandle; dll: string): boolean;
const
  codeX64_2:array [0..62] of byte =
    // sub rsp, 28h
    ($48, $83, $ec, $28,
    // mov [rsp + 18], rax
    $48, $89, $44, $24, $18,
    // mov [rsp + 10h], rcx
    $48, $89, $4c, $24, $10,
    // mov rcx, 11111111111111111h  -> DLL
    $48, $b9, $11, $11, $11, $11, $11, $11, $11, $11,
    // mov rax, 22222222222222222h  -> Loadlibrary
    $48, $b8, $22, $22, $22, $22, $22, $22, $22, $22,
    // call rax
    $ff, $d0,
    // mov rcx, [rsp + 10h]
    $48, $8b, $4c, $24, $10,
    // mov rax, [rsp + 18h]
    $48, $8b, $44, $24, $18,
    // add rsp, 28h
    $48, $83, $c4, $28,
    // mov r11, 333333333333333333h  -> RIP
    $49, $bb, $33, $33, $33, $33, $33, $33, $33, $33,
    // jmp r11
    $41, $ff, $e3);
var
  lpDllAddr, stub, lploadLibraryAddr: pointer;
   dwdlladdr, dwloadlibraryaddr: nativeuint;
  oldip,byteswritten: nativeuint;
  ctx: PContext;
  Storage: Pointer;
  i:byte;
  tmp:string;
  lasterror:integer;
begin
  log('enter injectctx');
  result:=true;
  //memory address for dll
  lpDllAddr := VirtualAllocEx(hProcess, nil, length(dll), MEM_COMMIT, PAGE_READWRITE);
  if lpDllAddr = nil then
  begin
       log('lpDllAddr is null: error'+inttostr(getlasterror)+', exiting');
       exit;
  end;
  WriteProcessMemory(hProcess, lpDllAddr, @dll[1], length(dll), byteswritten);
  // write dll path
  if (byteswritten <> length(dll)) then
  begin
     log('WriteProcessMemory failed: written '+inttostr(byteswritten)+' bytes, error '+inttostr(getlasterror)+', exiting');
     exit;
  end;

  dwdlladdr := nativeuint(lpDllAddr);
  log('DLL Path successfully written at $' + inttohex(nativeuint(lpDllAddr), 16));
  //memory address of code
  stub := VirtualAllocEx(hProcess, nil, length(codeX64_2 ), MEM_COMMIT,PAGE_EXECUTE_READWRITE);
  if stub = nil then
  begin
       log('error: couldnt allocate memory zone to write shellcode, error '+inttostr(getlasterror)+', exiting');
       result:=false;
       exit;
  end
  else
    log('successfully allocated mem for shellcode at $' + inttohex(nativeuint(stub), 16));
  //memory address of loadlibrary
  lploadLibraryAddr := GetProcAddress(GetModuleHandle('kernel32.dll'), 'LoadLibraryA');
  dwloadlibraryaddr := nativeuint(lploadLibraryAddr);
  log('LoadLibraryA Address:' + inttohex( nativeuint(lploadLibraryAddr), 16));
  ctx := AllocMemAlign(SizeOf(TContext), 16, Storage);
  ctx^.ContextFlags := CONTEXT_CONTROL;
  //
  if GetThreadContext(hThread, ctx^)=false then
  begin
       log('GetThreadContext failed:'+inttostr(getlasterror)+', exiting');
       result:=false;
       exit;
  end;
  oldIP := ctx^.Rip;
  log('Initial RIP:' + inttohex(nativeuint(oldip), 16));
  //RIP
  copymemory(@codeX64_2 [$34], @oldip, sizeof(nativeuint));
  //dwdlladdr
  copymemory(@codeX64_2 [$10], @dwdlladdr, sizeof(nativeuint));
  //dwloadlibraryaddr
  copymemory(@codeX64_2 [$1a], @dwloadlibraryaddr, sizeof(nativeuint));
  WriteProcessMemory(hProcess, stub, @codeX64_2[0], length(codeX64_2 ), byteswritten);
  if byteswritten<>length(codeX64_2) then
  begin
     log('WriteProcessMemory failed: written '+inttostr(byteswritten)+' bytes, error '+inttostr(getlasterror)+', exiting');
     exit;
  end;
  // write code
  ctx^.rip := nativeuint(stub);
  setlasterror(0);
  suspendthread(hthread);
  lasterror:=getlasterror;
  if lasterror=0 then
    log('successfully suspended thread')
  else
  begin
    log('suspend failed with error '+inttostr(lasterror)+', exiting');
    exit;
  end;
  if SetThreadContext(hThread, ctx^)=false then
  begin
   log('SetThreadContext failed:'+inttostr(getlasterror)+', exiting');
   result:=false;
   exit;
  end
  else log('SetThreadContext ok');
   setlasterror(0);
   resumethread(hthread);
   lasterror:=getlasterror;
   if lasterror<>0 then
   begin
     log('resume failed: '+inttostr(lasterror)+', exiting');
     result:=false;
     exit;
   end
   else log('successfully resumed thread');
   log('leaving injectctx');
  end;

function injectsys(ahandle:thandle;susp:boolean;th:thandle;ch:client_id;dll:string):dword;
var
	alloc:POINTER;
        byteswritten:ptruint;
        last:boolean;
        loadlibrarypointer:pointer;
        size:qword;
        status:int64;
        //buf:ansistring;
begin
        log('enter injectsys');
       result:=0;
        status:=0;
        size:=length(dll)+sizeof(char);
	last:=setprivilege('sedebugprivilege',true);
        if last=false then log('error setprivilege');
	loadlibrarypointer:=getprocaddress(getmodulehandle('kernel32.dll'),'LoadLibraryA');
        alloc:=nil;
        alloc:=VirtualAllocEx(ahandle, nil, size, MEM_RESERVE or MEM_COMMIT, PAGE_EXECUTE_READWRITE);
        if alloc=nil
                    then log('VirtualAllocEx failed: '+inttostr(getlasterror))
                    else log('VirtualAllocEx:'+inttohex(dword(alloc),8));
        last:=writeprocessmemory(ahandle,alloc,@dll[1],size,byteswritten);
        if last=false then log('error wpm');
	status:=rtlcreateuserthread(ahandle,nil,susp,0,0,0,loadlibrarypointer,alloc,@th,@ch);
        result:=status;
        virtualfreeex(ahandle,alloc,size,mem_release);
end;


end.

