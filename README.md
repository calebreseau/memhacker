# memhacker

MemHacker is a 64bit memory editing tool that allows you to write or read almost any process memory, even processes that are protected by AVs or ACs.
To do so, it injects a DLL into a system process (LSASS right now, looking forward to use CSRSS since it has higher privileges) and does all the memory work from up here.
Before trying to open the target process, it tries to find an already opened handle because some processes can't be openend with certain privileges, even from LSASS.

Use it with caution as it is still in development and as you're dealing with a system process: if the DLL crashes, Windows will crash too.

You can inject in whatever process you want tho: just put the process name you want as a launch option, and it will inject in it instead of LSASS. This doesn't mean it will work for any process, for example CSRSS.
The target folder is just a target exe you can use to test injection on.

Have fun!
