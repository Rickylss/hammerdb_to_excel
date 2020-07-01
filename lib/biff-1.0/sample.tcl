# A simple Excel/BIFF2 writer in pure Tcl.
# This code is in the public domain.

lappend auto_path [pwd]

package require biff
namespace path biff

append xls [store_bof] \
        [store_value 0 0 "bold text" 1] \
        [store_value 0 2 "plain text"] \
        [store_value 0 1 168] \
        [store_value 0 3 32] \
        [store_value 2 0 3.1415 1] \
        [store_eof]

set fd [open testxl.xls w]
fconfigure $fd -translation binary
puts -nonewline $fd $xls
close $fd
exit