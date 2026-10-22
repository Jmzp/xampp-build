# 64-bits components and base classes for XAMPP

::itcl::class windows64XamppVcredist {
    inherit windowsXamppVcredist
    public variable vcVersion
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppVcredist
        set version 2012
        set vcVersion VC11
        set tarballName vcredist_x64_${version}.exe
    }
    public method install {} {
        set xamppoutputdir [file join [${be} cget -output] xampp]
        file copy -force [findTarball ${tarballName}] [file join [$be cget -output] vcredist_x64.exe]
        file copy -force [findTarball test_php_${vcVersion}.bat] [file join [$be cget -output] xampp test_php.bat]
        setReadmeVersion VCREDIST ${version}
    }
}

::itcl::class windows64XamppVcredist2015 {
    inherit windows64XamppVcredist
    constructor {environment} {
        chain $environment
    } {
        set version 2015
        set vcVersion VC14
        set tarballName vcredist_x64_${version}.exe
    }
}

::itcl::class windows64XamppVcredist2017 {
    inherit windows64XamppVcredist
    constructor {environment} {
        chain $environment
    } {
        set version 2017
        set vcVersion VC15
        set tarballName vcredist_x64_${version}.exe
        # if you find issues because VCRedist 2017 can't be found in the machine, ensure the Windows registry entry
        # being check in 'test_php_VC15.bat' exists
        # source: https://stackoverflow.com/questions/46178559/how-to-detect-if-visual-c-2017-redistributable-is-installed
    }
}

::itcl::class windows64XamppVcredist2019 {
    inherit windows64XamppVcredist
    constructor {environment} {
        chain $environment
    } {
        set version 2019
        set vcVersion VS16
        set tarballName vcredist_x64_${version}.exe
    }
}

::itcl::class windows64XamppVcredist2022 {
    inherit windows64XamppVcredist
    constructor {environment} {
        chain $environment
    } {
        set version 2022
        set vcVersion VS17
        set tarballName vcredist_x64_${version}.exe
    }
}

::itcl::class windows64XamppApache {
    inherit windowsXamppApache
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppApache
        set tarballName httpd-${version}-win64-VC11.zip
    }
}

::itcl::class windows64XamppApachePhp7 {
    inherit windows64XamppApache
    constructor {environment} {
	chain $environment
    } {
        set tarballName httpd-${version}-win64-VC14.zip
    }
    public method install {} {
        chain
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list "php5" "php7"]
    }
}
::itcl::class windows64XamppApachePhp8 {
    inherit windows64XamppApache
    constructor {environment} {
	chain $environment
    } {
        set tarballName httpd-${version}-win64-VS17.zip
    }
    public method preparefordist {} {
        chain
        xampptcl::util::substituteParametersInFile $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list "php8_module" "php_module"]
    }
    public method install {} {
        chain
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list "php5" "php8"]
        # PHP 8.0 is installed as 'php_module', and .7z and .zip assets don't run the preparefordist method
        xampptcl::util::substituteParametersInFile $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list "php8_module" "php_module"] 1
    }
}

::itcl::class windows64XamppApachePhp74 {
    inherit windows64XamppApachePhp7
    constructor {environment} {
	    chain $environment
    } {
        set tarballName httpd-${version}-win64-VC15.zip
    }
    public method preparefordist {} {
        chain
        # PHP 7.4.x prevents Apache and MariaDB from starting if vcruntime140.dll is present
        # "PHP Warning:  'vcruntime140.dll' 14.0 is not compatible with this PHP build linked with 14.16 in Unknown on line 0"
        file delete -force [file join $xamppoutputdir apache2/bin/vcruntime140.dll]
    }
}

::itcl::class windows64XamppApachePhp80 {
    inherit windows64XamppApachePhp8
    constructor {environment} {
	    chain $environment
    } {
        set tarballName httpd-${version}-win64-VS17.zip
    }
}
::itcl::class windows64XamppApachePhp81 {
    inherit windows64XamppApachePhp8
    constructor {environment} {
	    chain $environment
    } {
        set tarballName httpd-${version}-win64-VS17.zip
    }
}
::itcl::class windows64XamppApachePhp82 {
    inherit windows64XamppApachePhp8
    constructor {environment} {
	    chain $environment
    } {
        set tarballName httpd-${version}-win64-VS17.zip
    }
}
::itcl::class windows64XamppApachePhp83 {
    inherit windows64XamppApachePhp8
    constructor {environment} {
	    chain $environment
    } {
        set tarballName httpd-${version}-win64-VS17.zip
    }
}
::itcl::class windows64XamppApachePhp84 {
    inherit windows64XamppApachePhp8
    constructor {environment} {
	    chain $environment
    } {
        set tarballName httpd-${version}-win64-VS17.zip
    }
}

::itcl::class windows64XamppApachePhp85 {
    inherit windows64XamppApachePhp84
    constructor {environment} {
	    chain $environment
    } {
    }
}

::itcl::class windows64XamppPhpAddons {
    inherit windowsXamppPhpAddons
    constructor {environment} {
        chain $environment
    } {
    }

    public method install {} {
        chain
        # Ensure OpenSSL-x64 binary
        file copy -force [file join $xamppoutputdir apache bin openssl.exe] [file join $xamppoutputdir php extras openssl openssl.exe]
    }
}

::itcl::class windows64XamppMysql {
  inherit windowsXamppMysql
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppMysql
        set tarballName mysql-${version}-win64.zip
        set pathName mysql-${version}-win64
    }
}

::itcl::class windows64XamppMariaDb {
  inherit windows64XamppMysql
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppMariaDb
        set fullname MariaDB
        set version [versions::get "MariaDB" "10"]
        set tarballName mariadb-${version}-winx64.zip
        set pathName mariadb-${version}-winx64
        lappend additionalFileList vcruntime140_1.dll
    }
    public method install {} {
        chain
        xampptcl::util::substituteParametersInFile [file join $xamppoutputdir mysql bin my.ini] [list skip-federated #skip-federated]
        setReadmeVersion MARIADB ${version}
        file copy -force [findFile vcruntime140_1.dll] [file join $xamppoutputdir mysql bin vcruntime140_1.dll]
    }

}

::itcl::class windows64XamppMysql55 {
  inherit windowsXamppMysql55
    constructor {environment} {
        chain $environment
    } {
        set tarballName mysql-${version}-win64.zip
    }
}

::itcl::class windows64XamppPerl {
    inherit windowsXamppPerl
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPerl
        set version [versions::get "Perl" "portable"]
        set tarballName strawberry-perl-${version}-64bit-portable.zip
    }

    public method install {} {
        chain
        setReadmeVersion PERL ${version}
    }
}

::itcl::class windows64XamppPhp {
    inherit windowsXamppPhp
    public variable vcVersion
    public variable opensslVersion
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp
        set fullname PHP
        set version [::xampp::php::getXAMPPVersion 55]
        set vcVersion VC11
        set opensslVersion 1.0.2j
        set licenseRelativePath {}
        set tarballName php-${version}-Win64-${vcVersion}-x86.zip
    }

    public method install {} {
        chain
        file copy -force [file join [$be cget -src] windowsXamppPhp] [file join $xamppoutputdir php]
        file copy -force [file join [$be cget -src] windowsXamppPhp php.ini-development] [file join $xamppoutputdir php php.ini]

        foreach f [glob -directory [file join [$be cget -src] windowsXamppPhp] icu*.dll libsasl.dll] {
            file copy -force $f [file join $xamppoutputdir apache bin]
        }

        phpiniSubstitutions
        copyFilesFromWorkspace
	setReadmeVersion PHP "$version (${vcVersion} X86 64bit thread safe)"
	# SSL is determined by PHP version, so best to set it here
	setReadmeVersion OPENSSL ${opensslVersion}
    }
}

::itcl::class windows64XamppPhp7 {
  inherit windows64XamppPhp
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp7
        set vcVersion VC14
        set opensslVersion [versions::get "OpenSSL" stable]
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}

::itcl::class windows64XamppPhp8 {
  inherit windows64XamppPhp
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp8
        set vcVersion VS16
        set opensslVersion [versions::get "OpenSSL" stable]
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
    public method install {} {
        chain
        # Fix warning message related to SQLite not being properly loaded
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list \
          "LoadModule\\s+php_module" "LoadFile \"/xampp/php/libsqlite3.dll\"\nLoadModule php_module"] 1
    }
}

::itcl::class windows64XamppPhp74 {
  inherit windows64XamppPhp7
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp74
        set version [::xampp::php::getXAMPPVersion 74]
        set rev [::xampp::php::getXAMPPRevision 74]
        set vcVersion VC15
        set opensslVersion 1.1.0g
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
     public method install {} {
        chain
        # Fix warning message related to SQLite not being properly loaded
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list \
          "LoadModule\\s+php7_module" "LoadFile \"/xampp/php/libsqlite3.dll\"\nLoadModule php7_module"] 1
    }
}

::itcl::class windows64XamppPhp80 {
  inherit windows64XamppPhp8
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp80
        set version [::xampp::php::getXAMPPVersion 80]
        set rev [::xampp::php::getXAMPPRevision 80]
        set vcVersion VS16
        set opensslVersion 1.1.1p
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}

::itcl::class windows64XamppPhp81 {
  inherit windows64XamppPhp8
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp81
        set version [::xampp::php::getXAMPPVersion 81]
        set rev [::xampp::php::getXAMPPRevision 81]
        set vcVersion VS16
        set opensslVersion 1.1.1p
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}

::itcl::class windows64XamppPhp82 {
  inherit windows64XamppPhp8
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp82
        set version [::xampp::php::getXAMPPVersion 82]
        set rev [::xampp::php::getXAMPPRevision 82]
        set vcVersion VS16
        set opensslVersion 1.1.1p
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}

::itcl::class windows64XamppPhp83 {
  inherit windows64XamppPhp8
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp83
        set version [::xampp::php::getXAMPPVersion 83]
        set rev [::xampp::php::getXAMPPRevision 83]
        set vcVersion vs16
        set opensslVersion 1.1.1p
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}

::itcl::class windows64XamppPhp84 {
  inherit windows64XamppPhp8
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp84
        set version [::xampp::php::getXAMPPVersion 84]
        set rev [::xampp::php::getXAMPPRevision 84]
        set vcVersion vs17
        set opensslVersion 1.1.1p
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}
::itcl::class windows64XamppPhp85 {
  inherit windows64XamppPhp8
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp85
        set version [::xampp::php::getXAMPPVersion 85]
        set rev [::xampp::php::getXAMPPRevision 85]
        set vcVersion vs17
        set opensslVersion 1.1.1p
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}

::itcl::class windows64XamppCurl {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppCurl
        set version 8.19.0_1
        set licenseRelativePath {}
        set tarballName curl-${version}-win64-mingw
        set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
        lappend additionalFileList curl-ca-bundle-${cacertificatesVersion}.crt
        set mainComponentXMLName xampp-apache
    }

    public method install {} {
        chain
        set curlDir [file join ${xamppoutputdir} apache bin]
        file mkdir ${curlDir}
        set srcDir [file join [$be cget -src] ${tarballName} bin]
        set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
        file copy -force [findFile curl-ca-bundle-${cacertificatesVersion}.crt] [file join ${curlDir} curl-ca-bundle.crt]
        file copy -force [file join ${srcDir} curl.exe] [file join ${curlDir} curl.exe]
        file copy -force [file join ${srcDir} libcurl-x64.dll] [file join ${curlDir} libcurl.dll]
    }
}

::itcl::class windows64XamppPhpADODB {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhpADODB
        set version 518a
        set licenseRelativePath {}
        set tarballName adodb${version}.zip
        set mainComponentXMLName xampp-php
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] adodb5] [file join $xamppoutputdir php/pear/adodb]
        copyFilesFromWorkspace
        setReadmeVersion ADODB ${version}
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windows64XamppPhpXdebug {
  inherit windowsXamppComponent
    protected variable tarballBaseName {}
    protected variable libraryName {}
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhpXdebug
        set version 2.5.5-5.6
        set licenseRelativePath {}
        set tarballBaseName php_xdebug-${version}-vc11-x86_64
        set tarballName $tarballBaseName.zip
        set mainComponentXMLName xampp-php
    }
    public method extractDirectory {} {
        return [file join [$be cget -src] xdebug]
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] xdebug php_xdebug.dll] [file join $xamppoutputdir php/ext/php_xdebug.dll]
    }
}

::itcl::class windows64XamppPhp74Xdebug {
  inherit windows64XamppPhpXdebug
    constructor {environment} {
        chain $environment
    } {
        set version 2.8.1-7.4
        set libraryName php_xdebug-${version}-vc15-x86_64.dll
        set tarballName ${libraryName}
        lappend additionalFileList ${libraryName}
    }
    public method extract {} {}
    public method install {} {
        file copy -force [findFile ${libraryName}] [file join [$be cget -output] xampp php ext php_xdebug.dll]
    }
}

::itcl::class windows64XamppPhp80Xdebug {
  inherit windows64XamppPhpXdebug
    constructor {environment} {
        chain $environment
    } {
        set version 3.1.2-8.0
        set libraryName php_xdebug-${version}-vs16-x64.dll
        set tarballName ${libraryName}
        lappend additionalFileList ${libraryName}
    }
    public method extract {} {}
    public method install {} {
        file copy -force [findFile ${libraryName}] [file join [$be cget -output] xampp php ext php_xdebug.dll]
    }
}

::itcl::class windows64XamppPhp81Xdebug {
  inherit windows64XamppPhpXdebug
    constructor {environment} {
        chain $environment
    } {
        set version 3.1.2-8.q
        set libraryName php_xdebug-${version}-vs16-x64.dll
        set tarballName ${libraryName}
        lappend additionalFileList ${libraryName}
    }
    public method extract {} {}
    public method install {} {
        file copy -force [findFile ${libraryName}] [file join [$be cget -output] xampp php ext php_xdebug.dll]
    }
}

::itcl::class windows64XamppTomcat {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppTomcat
        set version [versions::get "Tomcat" "85"]
        set licenseRelativePath {}
        set tarballName apache-tomcat-${version}-windows-x64.zip
        set mainComponentXMLName xampp-tomcat
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] apache-tomcat-${version}] [file join $xamppoutputdir tomcat]
        copyFilesFromWorkspace
        setReadmeVersion TOMCAT ${version}
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace catalina_service.bat catalina_start.bat catalina_stop.bat
        copyFromWorkspace tomcat/catalina_start.bat tomcat/catalina_stop.bat tomcat/tomcat_service_install.bat tomcat/tomcat_service_uninstall.bat
    }
}

::itcl::class windows64XamppInstallerStack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist \
	    windows64XamppApache \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp \
	    windows64XamppPhpAddons \
	    windows64XamppPhpXdebug \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
	    windowsXamppStandard
    }
}

::itcl::class windows64XamppInstallerPhp74Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2017 \
	    windows64XamppApachePhp74 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp74 \
	    windows64XamppPhpAddons \
	    windows64XamppPhp74Xdebug \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
	    windowsXamppStandardPhp74
    }
}

::itcl::class windows64XamppInstallerPhp80Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp80 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp80 \
	    windows64XamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
        windowsXamppStandardPhp80
    }
}

::itcl::class windows64XamppInstallerPhp82Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp82 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp82 \
	    windows64XamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
        windowsXamppStandardPhp82
    }
}

::itcl::class windows64XamppInstallerPhp81Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp81 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp81 \
	    windows64XamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
        windowsXamppStandardPhp81
    }
}

::itcl::class windows64XamppInstallerPhp83Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2022 \
	    windows64XamppApachePhp83 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp83 \
	    windows64XamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
        windowsXamppStandardPhp83
    }
}

::itcl::class windows64XamppInstallerPhp84Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2022 \
	    windows64XamppApachePhp84 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp84 \
	    windows64XamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
        windowsXamppStandardPhp84
    }
}

::itcl::class windows64XamppInstallerPhp85Stack {
    inherit windows64XamppInstallerPhp84Stack
       constructor {environment} {
        chain $environment
       } {
           replaceComponent windows64XamppApachePhp84 windows64XamppApachePhp85
           replaceComponent windows64XamppPhp84 windows64XamppPhp85
           replaceComponent windowsXamppStandardPhp84 windowsXamppStandardPhp85
    }
}

# ---------------------------------------------------------------------------
# Multi-version installer (windows64XamppInstallerMultiStack)
#
# Bundles several PHP and MariaDB branches side by side:
#   xampp/php-versions/<major.minor>    one folder per PHP branch
#   xampp/mysql-versions/<major.minor>  one folder per MariaDB branch
# The payload does not contain xampp/php nor xampp/mysql: they are NTFS
# directory junctions created at install time (apps/xampp/xampp-php-multi.xml
# and apps/xampp/xampp-mysql-multi.xml) and re-pointed by xampp-switch.
# Every existing configuration keeps using \xampp\php and \xampp\mysql.
#
# Each versioned component is built exactly like its single-version parent
# (into xampp/php or xampp/mysql) and then moved to its versioned folder, so
# all the existing install logic (php.ini substitutions, workspace files...)
# is reused unchanged.
# ---------------------------------------------------------------------------

namespace eval ::xamppmulti {
    # Keep these lists in sync with apps/xampp/xampp-php-multi.xml,
    # apps/xampp/xampp-mysql-multi.xml and apps/xampp/multi/xampp-switch.ps1
    variable phpBranches {8.2 8.3 8.4 8.5}
    variable defaultPhpBranch 8.4
    variable mariadbBranches {10.11 11.8}
    variable defaultMariaDbBranch 10.11
}

# 8.4.27 -> 8.4, 10.11.16 -> 10.11
proc ::xamppmulti::branch {version} {
    return [join [lrange [split $version .] 0 1] .]
}

proc ::xamppmulti::defaultPhpBranch {} {
    variable defaultPhpBranch
    return $defaultPhpBranch
}

proc ::xamppmulti::defaultMariaDbBranch {} {
    variable defaultMariaDbBranch
    return $defaultMariaDbBranch
}

# Moves xampp/<dirName> (php or mysql) to xampp/<dirName>-versions/<branch>
proc ::xamppmulti::moveToVersionsDir {xamppoutputdir dirName version} {
    variable phpBranches
    variable mariadbBranches
    set branch [branch $version]
    set knownBranches [expr {$dirName == "php" ? $phpBranches : $mariadbBranches}]
    if {[lsearch -exact $knownBranches $branch] == -1} {
        error "$dirName $version does not belong to any multi-version branch ($knownBranches)"
    }
    set versionsDir [file join $xamppoutputdir ${dirName}-versions]
    set dest [file join $versionsDir $branch]
    file mkdir $versionsDir
    file delete -force $dest
    file rename [file join $xamppoutputdir $dirName] $dest
    return $dest
}

# Returns 1 if the directory tree contains at least one file
proc ::xamppmulti::containsFiles {dir} {
    if {[llength [glob -nocomplain -types f -directory $dir *]] > 0 \
            || [llength [glob -nocomplain -types {f hidden} -directory $dir *]] > 0} {
        return 1
    }
    foreach subdir [glob -nocomplain -types d -directory $dir *] {
        if {[containsFiles $subdir]} {
            return 1
        }
    }
    return 0
}

# Copies the content of src into dest, overwriting existing files (same
# semantics as the add-on components copying on top of a PHP folder)
proc ::xamppmulti::mergeDirectory {src dest} {
    file mkdir $dest
    set entries [lsort -unique [concat \
        [glob -nocomplain -tails -directory $src *] \
        [glob -nocomplain -tails -types hidden -directory $src *]]]
    foreach entry $entries {
        if {$entry == "." || $entry == ".."} {
            continue
        }
        set from [file join $src $entry]
        set to [file join $dest $entry]
        if {[file isdirectory $from]} {
            mergeDirectory $from $to
        } else {
            file copy -force $from $to
        }
    }
}

# The shared PHP add-on components (extras, PEAR, ADODB) write into xampp/php
# after all PHP branches have been moved away. xampp/php is kept as an
# (initially empty) staging folder for them and merged into every branch by
# windows64XamppMultiVersionsLayout.
proc ::xamppmulti::preparePhpInstall {srcDir outputDir} {
    # All PHP zips are extracted to the same folder, start from a clean one
    file delete -force [file join $srcDir windowsXamppPhp]
    set staging [file join $outputDir xampp php]
    if {[file exists $staging]} {
        if {[containsFiles $staging]} {
            error "Unexpected files in $staging: PHP add-ons must be installed after every multi-version PHP component"
        }
        file delete -force $staging
    }
}

proc ::xamppmulti::finishPhpInstall {xamppoutputdir version} {
    moveToVersionsDir $xamppoutputdir php $version
    # Folders the add-on components expect to exist
    file mkdir [file join $xamppoutputdir php extras]
}

# Rewrites install/xamppbasic.inc (the list of files install/install.php
# relocates) so every entry under \php\ and \mysql\ is listed once per branch
# under \php-versions\<branch>\ and \mysql-versions\<branch>\ instead. The
# junction paths are dropped so the active branch is not relocated twice.
proc ::xamppmulti::versionedRelocationList {content} {
    variable phpBranches
    variable mariadbBranches
    set result {}
    foreach line [split $content \n] {
        if {[regexp {^(.*"\$partwampp\\)(php|mysql)(\\.*)$} $line -> head dir tail]} {
            set branches [expr {$dir == "php" ? $phpBranches : $mariadbBranches}]
            foreach b $branches {
                # "\\" before the branch: PHP would read "\10" or "\11" as octal escapes
                lappend result "${head}${dir}-versions\\\\${b}${tail}"
            }
        } else {
            lappend result $line
        }
    }
    return [join $result \n]
}

::itcl::class windows64XamppPhp82Multi {
  inherit windows64XamppPhp82
    constructor {environment} {
        chain $environment
    } {
    }
    public method install {} {
        ::xamppmulti::preparePhpInstall [$be cget -src] [$be cget -output]
        chain
        ::xamppmulti::finishPhpInstall $xamppoutputdir $version
    }
}

::itcl::class windows64XamppPhp83Multi {
  inherit windows64XamppPhp83
    constructor {environment} {
        chain $environment
    } {
    }
    public method install {} {
        ::xamppmulti::preparePhpInstall [$be cget -src] [$be cget -output]
        chain
        ::xamppmulti::finishPhpInstall $xamppoutputdir $version
    }
}

::itcl::class windows64XamppPhp84Multi {
  inherit windows64XamppPhp84
    constructor {environment} {
        chain $environment
    } {
    }
    public method install {} {
        ::xamppmulti::preparePhpInstall [$be cget -src] [$be cget -output]
        chain
        ::xamppmulti::finishPhpInstall $xamppoutputdir $version
    }
}

::itcl::class windows64XamppPhp85Multi {
  inherit windows64XamppPhp85
    constructor {environment} {
        chain $environment
    } {
    }
    public method install {} {
        ::xamppmulti::preparePhpInstall [$be cget -src] [$be cget -output]
        chain
        ::xamppmulti::finishPhpInstall $xamppoutputdir $version
    }
}

::itcl::class windows64XamppMariaDb1011Multi {
  inherit windows64XamppMariaDb
    constructor {environment} {
        chain $environment
    } {
    }
    public method install {} {
        chain
        ::xamppmulti::moveToVersionsDir $xamppoutputdir mysql $version
    }
}

# No prebuilt 11.x data directory exists: it is initialized at install time
# with mariadb-install-db.exe (see apps/xampp/xampp-mysql-multi.xml)
::itcl::class windows64XamppMariaDb118Multi {
  inherit windows64XamppMariaDb1011Multi
    constructor {environment} {
        chain $environment
    } {
        set version [versions::get "MariaDB" "11"]
        set tarballName mariadb-${version}-winx64.zip
        set pathName mariadb-${version}-winx64
    }
}

# xampp-mariadbdata-win64-10.11 was created with MariaDB 10.11, install it
# into that branch only
::itcl::class windows64XamppMysqlData1011Multi {
  inherit windowsXamppMysqlData
    protected variable dataBranch 10.11
    constructor {environment} {
        chain $environment
    } {
    }
    public method install {} {
        windowsXamppComponent::install
        set mysqlDir [file join $xamppoutputdir mysql-versions $dataBranch]
        file delete -force [file join $mysqlDir data]
        file copy -force [file join [$be cget -src] mysqldata] [file join $mysqlDir data]
        file copy -force [file join [$be cget -src] mysqldata] [file join $mysqlDir backup]
        copyFilesFromWorkspace
    }
}

# Final layout step, it must run after every PHP add-on component
::itcl::class windows64XamppMultiVersionsLayout {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppMultiVersionsLayout
        set version 1
        set licenseRelativePath {}
        set tarballName {}
    }
    public method findTarball {{file {}}} {
        return ""
    }
    public method extract {} {}
    public method getTextFiles {} {}
    public method install {} {
        chain
        mergeSharedPhpAddons
        copyDefaultPhpRuntimeLibraries
        removeDuplicatedSqliteLoadFile
        writeVersionedRelocationList
        copySwitcher
    }
    protected method mergeSharedPhpAddons {} {
        set staging [file join $xamppoutputdir php]
        if {![file exists $staging]} {
            return
        }
        foreach branch $::xamppmulti::phpBranches {
            ::xamppmulti::mergeDirectory $staging [file join $xamppoutputdir php-versions $branch]
        }
        file delete -force $staging
    }
    # Every PHP branch copied its libraries into apache/bin, make sure the
    # default branch ones win (xampp-switch copies them again on each switch)
    protected method copyDefaultPhpRuntimeLibraries {} {
        set defaultPhpDir [file join $xamppoutputdir php-versions [::xamppmulti::defaultPhpBranch]]
        foreach f [glob -nocomplain -directory $defaultPhpDir icu*.dll libsasl.dll libssh2.dll] {
            file copy -force $f [file join $xamppoutputdir apache bin]
        }
    }
    # windows64XamppPhp8 adds this LoadFile line once per installed PHP branch
    protected method removeDuplicatedSqliteLoadFile {} {
        set conf [file join $xamppoutputdir apache conf extra httpd-xampp.conf]
        set text [xampptcl::file::read $conf]
        regsub -all {(LoadFile "/xampp/php/libsqlite3\.dll"\r?\n)+} $text {\1} text
        xampptcl::file::write $conf $text
    }
    protected method writeVersionedRelocationList {} {
        set incFile [file join $xamppoutputdir install xamppbasic.inc]
        xampptcl::file::write $incFile [::xamppmulti::versionedRelocationList [xampptcl::file::read $incFile]]
    }
    # xampp-switch.bat/.ps1 go to the XAMPP root, shipped by xampp-common.xml
    protected method copySwitcher {} {
        foreach f {xampp-switch.bat xampp-switch.ps1} {
            file copy -force [file join [$be cget -projectDir] apps xampp multi $f] [file join $xamppoutputdir $f]
        }
    }
}

::itcl::class windows64XamppInstallerMultiStack {
    inherit windows64XamppInstallerPhp84Stack
       constructor {environment} {
        chain $environment
       } {
           # The default branch goes first so readme_*.txt report its versions
           replaceComponent windows64XamppMariaDb {windows64XamppMariaDb1011Multi windows64XamppMariaDb118Multi}
           replaceComponent windowsXamppMysqlData windows64XamppMysqlData1011Multi
           replaceComponent windows64XamppPhp84 {windows64XamppPhp84Multi windows64XamppPhp82Multi windows64XamppPhp83Multi windows64XamppPhp85Multi}
           replaceComponent windowsXamppStandardPhp84 {windows64XamppMultiVersionsLayout windowsXamppStandardPhp84}
    }
}


::itcl::class windows64XamppPortableInstallerStack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist \
	    windows64XamppApache \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp \
	    windows64XamppPhpAddons \
	    windowsXamppPhpXdebug \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppPortable
    }
}

::itcl::class windows64XamppPortableInstallerPhp74Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2017 \
	    windows64XamppApachePhp74 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp74 \
	    windowsXamppPhpAddons \
	    windows64XamppPhp74Xdebug \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppPortablePhp74
    }
}

::itcl::class windows64XamppPortableInstallerPhp80Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp80 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp80 \
	    windowsXamppPhpAddons \
        windows64XamppPhp80Xdebug \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppPortablePhp80
    }
}

::itcl::class windows64XamppPortableInstallerPhp81Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp81 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp81 \
	    windowsXamppPhpAddons \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppPortablePhp81
    }
}
::itcl::class windows64XamppPortableInstallerPhp82Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp82 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp82 \
	    windowsXamppPhpAddons \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppPortablePhp82
    }
}
