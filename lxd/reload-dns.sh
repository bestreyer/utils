#!/bin/bash

#title          :reload-dns.sh
#description    :reload dns
#author         :Sysolyatin Dmitrey <sysolyatin.dima@yandex.ru>
#version        :1.0
#usage          :bash reload-dns.sh
#notes          :Install Vim and Emacs to use this script.
#bash_version   :4.3.11(1)-release
#==============================================================================

NO_ARGS=3
usage() {
  echo "Reload dns for lxd containers"
  echo ""
  echo "Usage: `basename $0` -z tst.ru -s 172.18.0.4 -k IkbFEzeq0NfKBXRMRJWnHQ=="
  echo -e "    \033[1mParameters:\033[0m"
  echo "    -z dns zone"
  echo "    -s dns server ip"
  echo "    -k dns rndc-key"
}

if [ $# -lt "$NO_ARGS" ]  # Сценарий вызван без аргументов?
then
  usage                   # Если запущен без аргументов - вывести справку
  exit $E_OPTERROR        # и выйти с кодом ошибки
fi


while getopts "z:s:k:" Option
do
  case $Option in
    z     ) zone=$OPTARG;;
    s     ) dns_server=$OPTARG;;
    k     ) dns_key=$OPTARG;;
    *     ) echo "Selected an invalid option."
            usage
            exit $E_OPTERROR;;
  esac
done
shift $(($OPTIND - 1))

echo "$zone $dns_server $dns_key"

normal_view=$(lxc list --columns=n4 | sed 's/[|+]//g' | sed 's/(eth0)//g' | tr ' ' '\n' | sed  '/^$/d' | sed -n '1~3!p' | sed '1,2d')
count=$(echo $normal_view | wc -w)

START=1
i=$START
while [[ $i -le $count ]]
do
   container_name=$(echo "$normal_view" | sed -n "$i"p)
   i=$(expr $i + 1)
   ip=$(echo "$normal_view" | sed -n "$i"p)
   i=$(expr $i + 1)
   nsupdate <<EOF
        key rndc-key $dns_key
        server $dns_server
        zone $zone
        update delete $container_name.$zone A
        update add $container_name.$zone 3600 A $ip
        send
EOF
done

