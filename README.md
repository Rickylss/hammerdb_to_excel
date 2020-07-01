# What's this ?

There is an HammerDB auto script `script/oracle.tcl` and a Tcl library named  biff. The auto script is used to run hammerdb test and prase the test result from hammerdb.log to an Excel file by lib biff.

# What's BIFF

BIFF(**Binary Interchange File Format**) is the file format of early Excel(from verison 2 to 2003). Nowadays, Excel use the Office Open XML SpreadsheetML File Format instead. 

so, Unfortunately, the biff only works on very old version of Excel.

I copy the source code from https://wiki.tcl-lang.org/page/Excel%2FBIFF2+writer+in+pure+Tcl . And, simply make it an library.

# What's next

Though, it is worked fine for me. It does not support new version of Excel. And I am goning to work it out.

# Usage

put the `biff-1.0` to lib。

execute the auto script under HammerDB with command:

```
$ ./hammerdbcli auto ./script/oracle.tcl
```

