#!/bin/bash

#set -x

if [ $# -eq 0 ]; then
  echo "Usage: $(basename $0) <domain>"
  exit
fi

host="$1"
checkMaxPacketSize=1500
checkMinPacketSize=1232
verbose=1
pingcmd="ping -q -c 2 -t 1 -i 0.1 -s"
ping6cmd="ping6 -q -c 2 -i 0.1 -s"

function check {
  #Minimale Paketgröße testen
  if [[ ${verbose} -eq 1 ]];then
    echo "####################################################"
    echo "Prüfe die kleinstmögliche Paketgröße ${checkMinPacketSize}"
    echo "####################################################"
    echo ""
    echo "----------------------------------------------------------"
  fi
  if [[ $1 == "ipv6" ]]; then
    if [[ ${verbose} -eq 1 ]];then
      $ping6cmd ${checkMinPacketSize} ${host}
    else
      $ping6cmd ${checkMinPacketSize} ${host} > /dev/null
    fi
  else
    if [[ ${verbose} -eq 1 ]];then
      $pingcmd ${checkMinPacketSize} ${host}
    else
      $pingcmd ${checkMinPacketSize} ${host} > /dev/null
    fi
  fi

  if [[ $? -ne 0 ]]; then
    echo "Minimale Paketgröße ${checkMinPacketSize} ging nicht"
    return 1
  fi
  if [[ ${verbose} -eq 1 ]];then
    echo "----------------------------------------------------------"
    echo ""
    echo ""
  fi

  #Maximale Paketgröße testen
  if [[ ${verbose} -eq 1 ]];then
    echo "####################################################"
    echo "Prüfe die größtmögliche Paketgröße ${checkMaxPacketSize}"
    echo "####################################################"
    echo ""
    echo "----------------------------------------------------------"
  fi
  if [[ $1 == "ipv6" ]]; then
    if [[ ${verbose} -eq 1 ]];then
      $ping6cmd ${checkMaxPacketSize} ${host}
    else
      $ping6cmd ${checkMaxPacketSize} ${host} > /dev/null
    fi
  else
    if [[ ${verbose} -eq 1 ]];then
      $pingcmd ${checkMaxPacketSize} ${host}
    else
      $pingcmd ${checkMaxPacketSize} ${host} > /dev/null
    fi
  fi
  if [[ $? -eq 0 ]]; then
    echo "Paketgröße: ${checkMaxPacketSize}"
    return 1
  fi
  if [[ ${verbose} -eq 1 ]];then
    echo "----------------------------------------------------------"
    echo ""
    echo ""
  fi
  # Paketgröße ermitteln
  if [[ ${verbose} -eq 1 ]];then
    echo "####################################################"
    echo "ermittle Paketgröße"
    echo "####################################################"
    echo ""
  fi
  step=$(((${checkMaxPacketSize} - ${checkMinPacketSize}) / 2))
  [[ $((${step} % 2)) -eq 0 ]] || step=$((${step} + 1)) #falls ungerade um 1 erhöhen

  checkPacketSize=$((${checkMinPacketSize} + ${step}))

  while [[ ${step} -ge 1 ]]; do
    [[ ${verbose} -eq 1 ]] && echo "Step: $step"
    [[ ${verbose} -eq 1 ]] && echo "checkPacketSize: ${checkPacketSize}"
    step=$(($step / 2))
    if [[ ${step} -ne 1 ]];then
      [[ $((${step} % 2)) -eq 0 ]] || step=$((${step} + 1))
    fi
    if [[ ${verbose} -eq 1 ]];then
      echo ""
      echo ""
      echo "----------------------------------------------------------"
    fi
    if [[ $1 == "ipv6" ]]; then
      if [[ ${verbose} -eq 1 ]];then
        $ping6cmd ${checkPacketSize} ${host}
      else
        $ping6cmd ${checkPacketSize} ${host} > /dev/null
      fi
    else
      if [[ ${verbose} -eq 1 ]];then
        $pingcmd ${checkPacketSize} ${host}
      else
        $pingcmd ${checkPacketSize} ${host} > /dev/null
      fi
    fi
    if [[ $? -eq 0 ]]; then #ping ging
      if [[ $1 == "ipv6" ]]; then
        PacketSize=${checkPacketSize}
      else
        PacketSize=${checkPacketSize}
      fi
      checkPacketSize=$((${checkPacketSize} + ${step}))
    else
      checkPacketSize=$((${checkPacketSize} - ${step}))
    fi
    if [[ ${checkPacketSize} -gt ${checkMaxPacketSize} ]]; then
      continue
    fi
    if [[ ${checkPacketSize} -lt ${checkMinPacketSize} ]]; then
      continue
    fi
    if [[ ${verbose} -eq 1 ]];then
      echo "----------------------------------------------------------"
    fi
  done


  if [[ ${PacketSize} -ne 0 ]]; then
    echo -e "ermittlete Paketgröße: $PacketSize"
    echo ""
  else
    echo "Es konnte keine Paketgröße ermittelt werden"
  fi
}

check
check ipv6
