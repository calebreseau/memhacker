program memhacker;
 
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, umain, ufrmproc, ufrmlog, ufrmmem
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(Tfrmmain, frmmain);
  Application.CreateForm(Tfrmprocthr, frmprocthr);
  Application.CreateForm(Tfrmlog_, frmlog_);
  Application.CreateForm(Tfrmmem, frmmem);
  Application.Run;
end.

