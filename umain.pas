unit umain;

{$mode objfpc}{$H+}

interface

uses 
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, wininjection,winmiscutils, utalkiewalkie, ntdll, windows,
  lclintf, Menus, ComCtrls,ufrmproc,ufrmlog,ufrmmem;


type

  { Tfrmmain }

  Tfrmmain = class(TForm)
    btnlog: TButton;
    btnproc: TButton;
    btnshowmem: TButton;
    lblwebsite: TLabel;
    procedure btnprocClick(Sender: TObject);
    procedure btnlogClick(Sender: TObject);
    procedure btnshowmemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lblwebsiteClick(Sender: TObject);
  private

  public

  end;

var
  frmmain: Tfrmmain;

implementation

{$R *.lfm}

{ Tfrmmain }


procedure init_inject;
var
     targetname:string;
     targethandle:thandle;
     targetpid:integer;
     th:thandle;
     ch:client_id;
     stat:dword;
begin
     if paramcount>0 then targetname:=paramstr(1) else targetname:='lsass.exe';
     setprivilege('sedebugprivilege',true);  //get debug privileges so we can inject into lsass
     targetpid:=getpidbyprocessname(targetname);
     targethandle:=openprocess(process_vm_write or process_vm_operation or PROCESS_CREATE_THREAD ,false,targetpid);
     if targethandle<1 then
     begin
          showmessage('Error opening '+targetname+': '+inttostr(getlasterror));
          halt;
     end;
     stat:=injectsys(targethandle,false,th,ch,getcurrentdir+'\memhacker.dll'+chr(0));
     if stat<>0 then
     begin
          showmessage('Error injecting dll: '+inttohex(stat,8));
          closehandle(targethandle);
          halt;
     end;
     closehandle(targethandle);
end;

procedure init_main;
begin        
    if tw_init_srv=false then
    begin
      showmessage('couldnt init srv, exiting');
      halt;
    end;
    init_inject;
end;

procedure Tfrmmain.FormCreate(Sender: TObject);
begin 
   if fileexists('memhacker.dll') then init_main
   else
   begin
     showmessage('Error: memhacker.dll not found');
     halt;
   end;
end;

procedure Tfrmmain.FormDestroy(Sender: TObject);
begin
  tw_exit;
end;

procedure Tfrmmain.FormShow(Sender: TObject);
begin
end;

procedure Tfrmmain.lblwebsiteClick(Sender: TObject);
begin
  openurl('https://caldevelopment.wordpress.com');
end;

procedure Tfrmmain.btnlogClick(Sender: TObject);
begin
  frmlog_.visible:=true;
end;

procedure Tfrmmain.btnshowmemClick(Sender: TObject);
begin
  frmmem.visible:=true;
end;


procedure Tfrmmain.btnprocClick(Sender: TObject);
begin
  frmprocthr.visible:=true;
end;

end.

