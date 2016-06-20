#!/bin/bash

#title          :upload-file.sh
#description    :upload file or folder from host to container
#author         :Sysolyatin Dmitrey
#version        :1.0
#usage          :bash upload-file.sh -s /path/onhost -t targetpath -c container_name
#notes          :Install Vim and Emacs to use this script.
#bash_version   :4.3.11(1)-release
#==============================================================================

NO_ARGS=3

usage() {
  echo "upload file or directory to container"
  echo ""
  echo "Usage: `basename $0` -s /path/onhost -t targetpath -c container_name"
  echo -e "    \033[1mParameters:\033[0m"
  echo "    -s source path"
  echo "    -t target path"
  echo "    -c container_name"
}

req_arg=0
while getopts "s:t:c:" Option
do
  case $Option in
    s     ) req_arg=$((req_arg + 1)); source_path=$OPTARG;;
    t     ) req_arg=$((req_arg + 1)); target_path=$OPTARG;;
    c     ) req_arg=$((req_arg + 1)); container_name=$OPTARG;;
    *     ) echo "Selected an invalid option."
            usage
            exit $E_OPTERROR;;
  esac
done
shift $(($OPTIND - 1))

if [ $req_arg -lt "$NO_ARGS" ]
then
  usage
  exit $E_OPTERROR
fi

if [ ! -e "$source_path" ]; then
  echo "file or directory $source_path doesn't exists"
  exit 1
fi

if [ -d "$source_path" ]; then
  temp=$(mktemp)
  pushd $(dirname $source_path)
  tar -cvf $temp $(basename $source_path) > /dev/null 2>&1
  lxc file push $temp $container_name$temp && \
  lxc exec $container_name -- tar -xvf $temp -C $target_path > /dev/null 2>&1
  popd
  exit 0;
fi

if [ -f "$source_path" ]; then
  lxc file push $source_path $container_name$target_path
  exit 0;
fi
