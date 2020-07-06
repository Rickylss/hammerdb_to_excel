#!/usr/bin/tclsh

package require biff

namespace path biff

#---------------------Export the data to Excel----------------------

proc export_data {log_fd row} {

  global tpm_base
  global nopm_base
  global response_time_base
  global index_map
  global excel_arr

  while { 1 } {
    set col 0
    while { [gets $log_fd data] >= 0} {
      if {[regexp {([0-9]*)\s(Active\sVirtual\sUsers\sconfigured)} $data sub0 sub1] == 1} {
        puts $data
        set col $index_map($sub1)
        break
      } else {
        continue
      }
    }

    while { [gets $log_fd data] >= 0} {
      if {[regexp {TEST\sRESULT\D*([0-9]*)\D*([0-9]*)\sNOPM} $data sub0 sub1 sub2] == 1} {
        # set tpm $sub1
        #puts $data
        append excel_arr [store_value [expr $row + $tpm_base] $col $sub1]
        # set nopm $sub2
        append excel_arr [store_value [expr $row + $nopm_base] $col $sub2]
        break
      } else {
        continue
      }
    }

    while { [gets $log_fd data] >= 0} {
      if {[regexp {([a-z]*)\s\S\s(\d*)\S(\d{2,}.\d{2,}%)\S\s(\d*)\S\s(\d*)\S\s(\d*)\S} $data sub0 procname exclusivetot per callnum avgpercall cumultot] == 1} {
        # set response time $sub1
        #puts $data
        append excel_arr [store_value [expr $row + $response_time_base] $col $avgpercall]
        break
      } else {
        continue
      }
    }

    if {[eof $log_fd]} {
      break
    }
  }
}

proc init_excel { iterat_times file_name vu_list} {
  global tpm_base
  global nopm_base
  global response_time_base
  global index_map
  global excel_arr

  # init Excel file
  set excel_fd [open [file join [pwd] [append file_name ".xls"]] w]
  append excel_arr [store_bof]

  append excel_arr [store_value $tpm_base 0 "tpm"]
  append excel_arr [store_value $nopm_base 0 "nopm"]
  append excel_arr [store_value $response_time_base 0 "response time"]

  foreach x $vu_list {
    incr index
    append excel_arr [store_value $tpm_base $index $x]
    append excel_arr [store_value $nopm_base $index $x]
    append excel_arr [store_value $response_time_base $index $x]
    # create an index map
    set index_map($x) $index
  }

  for {set i 1} {$i <= $iterat_times} {incr i} {

    append excel_arr [store_value [expr $i + $tpm_base] 0 "test_$i"]
    append excel_arr [store_value [expr $i + $nopm_base] 0 "test_$i"]
    append excel_arr [store_value [expr $i + $response_time_base] 0 "test_$i"]

    if {[file exists $i]} {
      set log_fd [open $i r]
    } else {
      puts "could no find $hammerdb_file"
      continue
    }

    # parse hammerdb.log file to Excel
    export_data $log_fd $i

    close $log_fd
  }

  append excel_arr [store_eof]

  fconfigure $excel_fd -translation binary
  puts -nonewline $excel_fd $excel_arr
  close $excel_fd
}

#set db_type mssqls
set db_type mysql
#set db_type ora
set vu_list {1 2 4 8 16 32 64 128 256 512}
set iterat_times 3
set clock [clock format [clock seconds] -format %m-%d-%H%M%S]
set excel_file_name "test_$clock"
set index_map(0) "None"
set excel_arr {}

set offset 3
set tpm_base 0
set nopm_base [expr $tpm_base + $iterat_times + 1 + $offset]
set response_time_base [expr $nopm_base + $iterat_times + 1 + $offset]

init_excel $iterat_times $excel_file_name $vu_list
