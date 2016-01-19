#!/usr/bin/env zsh -f

###############################################################################
# This code is licensed under the GPL v2.  See LICENSE.txt for details.
#
# Copyright 2007 Nathaniel Gray.
# Copyright 2012-2014 Anthony Gelibert.
#
# Expects   $1 = path to resources dir of bundle
#           $2 = name of file to colorize
#           $3 = 1 if you want enough for a thumbnail, 0 for the full file
#
# Produces HTML on stdout with exit code 0 on success
###############################################################################

# Fail immediately on failure of sub-command
setopt err_exit

# Set the read-only variables
rsrcDir="$1"
target="$2"
thumb="$3"
cmd="$pathHL"

function debug() {
    if [ "x$qlcc_debug" != "x" ]; then
        if [ "x$thumb" = "x0" ]; then
            echo "QLColorCode: $@" 1>&2
        fi;
    fi
}

debug "Starting colorize.sh by setting reader"
reader=(cat ${target})

debug "Handling special cases"
case ${target} in
    *.graffle | *.ps )
        exit 1
        ;;
    *.nfo | *.atl | *.log | *.ld | *.map | *.MF )
        lang=txt
        ;;
    *.d )
        lang=make
        ;;
    *.fxml )
        lang=fx
        ;;
    *.s | *.s79 )
        lang=assembler
        ;;
    *.sb )
        lang=lisp
        ;;
    *.java )
        lang=java
        plugin=(--plug-in java_library)
        ;;
    *.class )
        lang=java
        reader=(/usr/local/bin/jad -ff -dead -noctor -p -t ${target})
        plugin=(--plug-in java_library)
        ;;
    *.pde | *.ino )
        lang=c
        ;;
    *.c | *.cpp )
        lang=${target##*.}
        plugin=(--plug-in cpp_syslog --plug-in cpp_ref_cplusplus_com --plug-in cpp_ref_local_includes)
        ;;
    *.rdf | *.xul | *.ecore )
        lang=xml
        ;;
    *.ascr | *.scpt )
        lang=applescript
        reader=(/usr/bin/osadecompile ${target})
        ;;
    *.plist )
        lang=xml
        reader=(/usr/bin/plutil -convert xml1 -o - ${target})
        ;;
    *.sql )
        if grep -q -E "SQLite .* database" <(file -b ${target}); then
            exit 1
        fi
        lang=sql
        ;;
    *.m )
        lang=objc
        ;;
    *.pch | *.h )
        if grep -q "@interface" <(${target}) &> /dev/null; then
            lang=objc
        else
            lang=h
        fi
        ;;
    *.pl )
        lang=pl
        plugin=(--plug-in perl_ref_perl_org)
        ;;
    *.py )
        lang=py
        plugin=(--plug-in python_ref_python_org)
        ;;
    *.sh | *.zsh | *.bash | *.csh | *.fish | *.bashrc )
        lang=sh
        plugin=(--plug-in bash_functions --plug-in bash_ref_linuxmanpages_com)
        ;;
    *.scala )
        lang=scala
        plugin=(--plug-in scala_ref_scala_lang_org)
        ;;
    *.cfg | *.properties | *.conf )
        lang=ini
        ;;
    *.kmt )
        lang=scala
        ;;
    * )
        lang=${target##*.}
        ;;
esac

debug "Resolved ${target} to language $lang"

cmdOpts=(${plugin} --plug-in outhtml_modern_fonts --plug-in outhtml_codefold --plug-in reduce_filesize --syntax=${lang} --quiet --include-style --font="${font}" --font-size=${fontSizePoints} --style=${hlTheme} --encoding=${textEncoding} ${=extraHLFlags} --validate-input)

go4it () {
    debug "Generating the preview"
    if [ ${thumb} = "1" ]; then
        ${reader} | head -n 100 | head -c 20000 | ${cmd} ${cmdOpts} && exit 0
    elif [ -n "${maxFileSize}" ]; then
        ${reader} | head -c ${maxFileSize} | ${cmd} -T "${target}" ${cmdOpts} && exit 0
    else
            ${reader} | ${cmd} -T "${target}" ${cmdOpts} && exit 0
 	   fi
}

setopt no_err_exit
# We only try one time as we use --validate-input option that fall to plain text if invalid input.
go4it
debug Reached the end of the file.  That should not happen.
exit 101
