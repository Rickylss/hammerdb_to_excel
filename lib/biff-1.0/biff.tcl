# Create the namespace
namespace eval ::biff {
    set version 1.0
}

# integer to BIFF2
proc ::biff::store_int {row col int {bold 0}} {
    if {$row > 65535 || $col > 255} {return}
    if {abs($int) > 65535} {
        set float [expr {double($int)}]
        return [store_float $row $col $float $bold]
    }
    # INTEGER record: record_type(2) + record_size(2) + row_number(2)
    #     + col_number(2) + format(3) + integer_number(2)
    return [binary format s*c*s "0x0002 9 $row $col" "0 [expr {$bold<<6}] 0" $int]
}

# double to BIFF2
proc ::biff::store_float {row col float {bold 0}} {
    # NUMBER record: record_type(2) + record_size(2) + row_number(2)
    #     + col_number(2) + format(3) + float_number(8)
    return [binary format s*c*d "0x0003 15 $row $col" "0 [expr {$bold<<6}] 0" $float]
}

# text to BIFF2
proc ::biff::store_text {row col text {bold 0}} {
    set len [string bytelength $text]
    if {$len > 255} {
        # maximum label length is 255
        set text [string range $text 0 254]
        set len 255
    }
    set sz [expr {8+$len}]
    # LABEL record: record_type(2) + record_size(2) + row_number(2)
    #     + col_number(2) + format(3) + text_length(1) + text($text_length)
    return [binary format s*c*ca* "0x0004 $sz $row $col" "0 [expr {$bold<<6}] 0" $len $text]
}

# beginning of file
proc ::biff::store_bof {} {
    # BOF record
    set head [binary format s* "0x0009 4 0x0000 0x0010"]
    # CODEPAGE record
    append head [binary format s* "0x0042 2 1251"]
    # FONT records: plain and bold
    append head [binary format s*ca* "0x0031 10 200 0x0000" 5 "Arial"]
    append head [binary format s*ca* "0x0031 10 200 0x0001" 5 "Arial"]
    return $head
}

# test formula "=B1+D1", in RPN: "B1 D1 +"
# proc ::biff::store_formula {} {
#     # FORMULA record
#     return [binary format s*c*dc*sc*sc* "0x0006 26 1 0" "0 0 0" 0 "1 9 0x44" 0 "1 0x44" 0 "3 0x03"]
# }

# end of file
proc ::biff::store_eof {} {
    # EOF record
    return [binary format s 0x000A]
}

# choose appropriate function based on value type
proc ::biff::store_value {row col val {bold 0}} {
    if {[string is integer -strict $val]} {
        return [store_int $row $col $val $bold]
    }
    if {[string is double -strict $val]} {
        return [store_float $row $col $val $bold]
    }
    return [store_text $row $col $val $bold]
}

package provide biff $biff::version
package require Tcl 8.0