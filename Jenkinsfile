void pullCode(String dir) {
    checkout poll: false, 
    	scm: [$class: "GitSCM", 
    	branches: [[name: "*/dev"]], doGenerateSubmoduleConfigurations: false,  
    	extensions: [[$class: "RelativeTargetDirectory", relativeTargetDir: dir]], 
    	submoduleCfg: [], 
    	userRemoteConfigs: [[url: "https://github.com/richnou/odfi-manager.git"]]]
}

if (env.GIT_PREVIOUS_SUCCESSFUL_COMMIT==null) {
    dchopts="--auto"
}
else {
    dchopts="-since=${env.GIT_PREVIOUS_SUCCESSFUL_COMMIT}"
}

stage("Debian Source Package") {
    
    node("debian") {
        pullCode("source")
        sh "cd source && DCHOPTS=$dchopts make deb-src"
        archiveArtifacts artifacts: "source/.deb/*.dsc,source/.deb/*.changes,source/.deb/*.xy", onlyIfSuccessful: true
    }
}

architecture="amd64"

/*
// Debian
//---------------------
stage("Oldstable (Jessie)") {

    distribution="oldstable"

    node("debian") {
        sh "cd source && DISTRIBUTION=$distribution ARCHITECTURE=$architecture MIRRORSITE=http://ftp.de.debian.org/debian/  make deb-build"
        archiveArtifacts artifacts: "source/.deb/$distribution/$architecture/*.deb", onlyIfSuccessful: true
    }
}


stage("Stable") {

    distribution="stable"

    node("debian") {
        sh "cd source && DISTRIBUTION=$distribution ARCHITECTURE=$architecture MIRRORSITE=http://ftp.de.debian.org/debian/  make deb-build"
        archiveArtifacts artifacts: "source/.deb/$distribution/$architecture/*.deb", onlyIfSuccessful: true
    }
}

stage("Testing") {
    distribution="testing"
    node("debian") {
        sh "cd source && DISTRIBUTION=$distribution ARCHITECTURE=$architecture MIRRORSITE=http://ftp.de.debian.org/debian/ make deb-build"
        archiveArtifacts artifacts: "source/.deb/$distribution/$architecture/*.deb", onlyIfSuccessful: true
    }
}

// Ubuntu
//-----------
mirrorSite="http://nova.clouds.archive.ubuntu.com/ubuntu/"
stage("Ubuntu Trusty (14.04.5 LTS)") {
    distribution="trusty"
    node("debian") {
        sh "cd source && DISTRIBUTION=$distribution ARCHITECTURE=$architecture MIRRORSITE=$mirrorSite make deb-build"
        archiveArtifacts artifacts: "source/.deb/$distribution/$architecture/*.deb", onlyIfSuccessful: true
    }
}
stage("Ubuntu Xenial (16.04 LTS)") {
    distribution="xenial"
    node("debian") {
        sh "cd source && DISTRIBUTION=$distribution ARCHITECTURE=$architecture MIRRORSITE=$mirrorSite make deb-build"
        archiveArtifacts artifacts: "source/.deb/$distribution/$architecture/*.deb", onlyIfSuccessful: true
    }
}
stage("Ubuntu Yakkety (16.10)") {
    distribution="yakkety"
    node("debian") {
        sh "cd source && DISTRIBUTION=$distribution ARCHITECTURE=$architecture MIRRORSITE=$mirrorSite make deb-build"
        archiveArtifacts artifacts: "source/.deb/$distribution/$architecture/*.deb", onlyIfSuccessful: true
    }
}
stage("Ubuntu Zesty (17.04)") {
    distribution="zesty"
    node("debian") {
        sh "cd source && DISTRIBUTION=$distribution ARCHITECTURE=$architecture MIRRORSITE=$mirrorSite make deb-build"
        archiveArtifacts artifacts: "source/.deb/$distribution/$architecture/*.deb", onlyIfSuccessful: true
    }
}

*/
