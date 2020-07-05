package ifneeded Oratcl 4.6 \
    [list load [file join $dir Oratcl46.dll]]
package ifneeded Oratcl::utils 4.6 \
    [list source [file join $dir oratcl_utils.tcl]]

