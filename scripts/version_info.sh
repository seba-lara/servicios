#!/bin/bash

declare version='unknown'
declare mode='version'
declare out_file=''
declare cwd='./'
declare archival=''

declare tag=''
declare hgid='0000000+'
declare ltag='0.0.0'
declare dist='0'


##############################################################################
# Parse options
##############################################################################

while getopts ':f:H:d:' opt; do
    case $opt in
        H)
            mode='header'
            out_file=${OPTARG}
            ;;
        \?)
            echo "Invalid option: -${OPTARG}" >&2
            exit 1
            ;;
        d)
            cwd=${OPTARG}
            ;;
        f)
            archival=${OPTARG}
            ;;
        :)
            echo "Option -${OPTARG} requires an argument" >&2
            exit 1
            ;;
    esac
done

##############################################################################
# Get version string
##############################################################################

#si es un repo
if [[ -z ${archival} ]]; then
    tempTag=`git --git-dir=${cwd}/.git --work-tree=${cwd} describe --tags --always --dirty --broken`
    tempTag=${tempTag/-/+}
    tempTag=${tempTag/-g/@}
    tempTag=${tempTag/-dirty/+}
    tempTag=${tempTag/-broken/+}
    tempTag=${tempTag/+dirty/+}
    tempTag=${tempTag/+broken/+}
    tag=$tempTag
    version=$tag
else
    tag=`sed -n 's/^tag: \(.*\)/\1/p' ${archival}`
    hgid=`sed -n 's/^node: \(.\{12\}\).*/\1/p' ${archival}`
    ltag=`sed -n 's/^latesttag: \(.*\)/\1/p' ${archival}`
    dist=`sed -n 's/^latesttagdistance: \(.*\)/\1/p' ${archival}`

    if [[ $tag =~ [0-9\.] ]]; then
        #Revisión tiene tag de versión
        version=$tag
        if [[ $hgid =~ \+$ ]]; then
            #Revisión con cambios
            version="${version}+"
        fi
    else
        #Revisión no tiene tag de versión
        if [[ $ltag == 'null' ]]; then
            ltag='0.0.0'
        fi
        version="${ltag}+${dist}@${hgid}"
        if [[ $hgid =~ \+$ ]]; then
            #Revisión con cambios
            datetag=`date +%Y%m%d`
            version="${version}${datetag}"
        fi
    fi
fi




##############################################################################
# Output text
##############################################################################

case $mode in
    'version')
        echo $version
        ;;
    'header')
        header_string="#ifndef __VERSION_H
#define __VERSION_H

#define VERSION_STRING \"${version}\"

#endif
"
        if [[ $out_file == '--' ]]; then
            echo "${header_string}"
        elif grep -q "${version}" $out_file; then
            echo "Version file already up to date, not doing anything" >&2
        else
            echo "${header_string}" > $out_file
        fi
        ;;
esac
