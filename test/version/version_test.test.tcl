package require odfi::utests 1.0.0

set location [file dirname [info script]]
source $location/../../private/odfi.tm

odfi::utests::suite version_parse {

    :test "simple release version parse" {
        
        ::odfi::module a {
            :version 1.0.3
        }
        
        set version [$a getVersion]
        :assertNXObject $version
        
        :assert "Major version is 1" 1 [$version getMajor]
    }
}


odfi::utests::run