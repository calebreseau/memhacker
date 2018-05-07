# Presentation
## What is memhacker?

MemHacker is a memory editing tool.

## What can you do with memhacker?

With memhacker, you can search, read or write any process' memory, if the process injected the DLL in (LSASS by default) owns a handle with the right access on the process you wanna act on. That means that if you dont touch anything, you will be able to write and read almost all processes mem, even most games and programs protected by anticheats and antiviruses.

## How does it work?

Memhacker injects a DLL into LSASS or into a chosen process, and does all the memory work from up here.
Before trying to open the target process from the process you're injected in, it tries to find an already existing handle because some processes can't be openend with certain privileges, even from LSASS.

# Documentation

## Injection

If you wanna inject into LSASS, you have nothing do to: just launch the program as an administrator and here you go.
If you wanna inject into another process, just pass the name of the process you want to inject in as a command line parameter when you launch the program. If the process is elevated you will have to launch memhacker with admin rights too.

## Choosing the process to act on

To chosse the process, you just have to input its name to the "Process name" text box. You can also choose in the opened processes list by clicking the little arrow in the textbox. If you type while the combobox is expanded, the list will be filtered by what you type.

## Reading

First, input the address you want to read memory at in the "address" text box. Be sure there is a dollar before the address! 
  > Example: $DEADBEEF
  
Then select the type of the value you want to read. If it's a string, specify the length of the string you want to read in the textbox next to the "string" radiobutton.
If the value type is byte array, you gotta input the bytes in hex, just like addresses.
  > Example: $E3 $DD $F4 $12 $DE $AD
After that, just click the read button, and if there is no error, the value will display in the "response" textbox.
If there is an error, you can check what the error is in the log.

## Writing

First, input the address you want to write memory at in the "address" text box. Be sure there is a dollar before the address! 
  > Example: $DEADBEEF
  
Then select the type of the value you want to write. If it's a string, specify the length of the string you want to write in the textbox next to the "string" radiobutton.
Then, input the value you want to write into the "value" textbox.
If the value type is byte array, you gotta input the bytes in hex, just like addresses.
  > Example: $E3 $DD $F4 $12 $DE $AD
Finally, just click the "write" button. If there is no error, "ok" will be displayed in the response textbox. If there is an error, the error code will be displayed in the response box.

 ## Searching
 
 First, choose the value type like reading and writing, and input the value you want to search in the "value" textbox.
 If the value type is byte array, you gotta input the bytes in hex, just like addresses.
  > Example: $E3 $DD $F4 $12 $DE $AD
 Then choose if you want to do a new search (search all memory) or to search in previous values.
 If you check "advanced check" memhacker will search all the addresses, 1 per 1. If you dont, the step will be the length of the value you chose.
 If you click an address, it will read the value.
 To wipe the addresses, double click the listbox.
 
 ## Logging
 
 Everything that the DLL does will be logged in the "log" text box.
 It's useful to see where errors occurs.
 You can clear it and save it to a text file.
 
 ## Errors

 Whenever an error occurs, it will be displayed as a number.
 If you want more info about the error, use this the "net helpmsg" command in the command prompt (aka cmd.exe).
   > Example: net helpmsg 123
   
 Here are a list of the most common errors and a possible cause:
 * Error 5: Access denied: usually that means the process you're injected into doesnt own a handle of the target process and dosent have to rights to open it. Try with a different process.
 * Error 299 or 998: usually that means the memory zone you're reading isnt accessible.
 
 If there's an error you cant fix, you can ask for help via mail or via one of my socials.
 
 # Links
 
 * Twitter: https://www.twitter.com/calebreseau
 * E-Mail: calebreseau@gmail.com
 * Discord: cal_#7823
 
 
Have fun!

Here's what memhacker looks like:
![screenshot](https://caldevelopment.files.wordpress.com/2018/04/memhacker_0-5.png)
