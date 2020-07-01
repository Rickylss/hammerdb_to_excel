#!/usr/bin/tclsh

package require biff

namespace path biff

#--------------------HammerDB auto test----------------------------
# control the run time of vu
proc runtimer {seconds} {
  set x 0
  set timerstop 0
  while {!$timerstop} {
    incr x
    after 1000
    if {![expr {$x % 60}]} {
      set y [expr $x / 60]
      puts "Timer: $y minutes elapsed"
    }
    update
    if {[ vucomplete ] || $x eq $seconds} {set timerstop 1}
  }
  return
}

# start autopilot 
proc autopilot { vu_list } {
  puts "-------------SETTING CONFIGURATION----------------"
  dbset db ora
  dbset bm TPC-C
  diset tpcc ora_driver timed
  diset tpcc timeprofile true
  loadscript

  puts "------------------SEQUENCE STARTED-----------------"
  foreach z $vu_list {
    puts "$z VU TEST"
    vuset vu $z
    vuset logtotemp 1
    vucreate
    vurun
    runtimer 600
    vudestroy
    after 5000
  }
  puts "-------------------TEST SEQUENCE COMPLETE-----------"
}

#---------------------Export the data to Excel----------------------

proc export_data { log_fd row} {

  global tpm_base
  global nopm_base
  global index_map
  global excel_arr

  while { [gets $log_fd data] >= 0} {
    set col 0
    if {[regexp {([0-9]*)\s(Active\sVirtual\sUsers\sconfigured)} $data sub0 sub1]} {
      set col $index_map($sub1)
    } else {
      continue
    }

    while { [gets $log_fd data] >= 0} {
      if {[regexp {TEST\sRESULT\D*([0-9]*)\D*([0-9]*)\sNOPM} $data sub0 sub1 sub2]} {
        # set tpm $sub1
        append excel_arr [store_value [expr $row + $tpm_base] $col $sub1]
        # set nopm $sub2
        append excel_arr [store_value [expr $row + $nopm_base] $col $sub2]
        break
      } else {
        continue
      }
    }
  }
}

#-----------------------------entry---------------------------------

proc entry { iterat_times file_name vu_list} {

  global tpm_base
  global nopm_base
  global index_map
  global excel_arr

  set hammerdb_file ""
  set excel_fd [open [file join [pwd] [append file_name ".xls"]] w]
  set row 0

  # get the path of hammerdb.log file
  switch -regexp $::tcl_platform(os) {
    (Windows.NT) {
      set hammerdb_file C:/hammerdb.log
    }
    (Linux) {
      set hammerdb_file /tmp/hammerdb.log
    }
    default {
      puts "can not find hammerdb.log in platform $tcl_platform(os)"
      exit 0
    }
  }

  # init Excel file
  append excel_arr [store_bof]

  foreach x $vu_list {
    incr index
    append excel_arr [store_value $tpm_base $index $x]
    append excel_arr [store_value $nopm_base $index $x]
    # create an index map
    set index_map($x) $index
  }

  for {set i 1} {$i <= $iterat_times} {incr i} {

    append excel_arr [store_value [expr $i + $tpm_base] 0 "test_$i"]
    append excel_arr [store_value [expr $i + $nopm_base] 0 "test_$i"]
    # start test and log file to hammerdb.log
    autopilot $vu_list

    if {[file exists $hammerdb_file]} {
      file rename $hammerdb_file $i
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

#-------------------------------------------------------------------
puts "*************************start**************************"

set vu_list {1 2 4 8 16 32 64 128 256 512}
set iterat_times 1
set excel_file_name "test"
set index_map(0) "None"
set excel_arr {}

set offset 3
set tpm_base 0
set nopm_base [expr $tpm_base + $iterat_times + 1 + $offset]

entry $iterat_times $excel_file_name $vu_list

puts "**************************done**************************"