
set dir [file dirname [file normalize [info script]]]

package ifneeded odfi::test::module::c 1.0.0 [list source $dir/modulec.tm ]