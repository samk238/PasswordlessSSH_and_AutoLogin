##################################
# Author: Sampath Kunapareddy    #
# sampath.a926@gmail.com         #
##################################

#!/bin/bash
#set -x
dir="~"

EXPECTHME=$(which expect 2>/dev/null)
if [[ -z $EXPECTHME ]]; then
  clear 
  echo -e "\n\nNo expect home, host isnt suitable to run the script.. exiting now.."
  sleep 5
  exit 1
fi
export SSHEXPECT="./homecheck_script.expect"
export SUID=`whoami`
rm $SSHEXPECT 2>/dev/null

#Trap to clean files in case of unexpected exits.
trap 'rm -f $SSHEXPECT; exit 1' 1 2 3 6

homecheck_script() {
echo '
#!/usr/bin/expect
#/usr/bin/env tclsh
#Usage ./Expectscript.expect server userid password
#package require Expect
set timeout 5 
set prompt {[$❯#] }
#set prompt { [(%|#|\\$)] }
set host     [lindex $argv 0]
set user     [lindex $argv 1]
set password [lindex $argv 2]
set cmd [lindex $argv 3]
#puts "I am performing a command..."
spawn ssh $user@$host 
expect {
  "yes/no" {
	  send "yes\r" 
          expect "*?assword" 
	  send "$password\r" 
	  expect "*denied*"  { exit 3 }
  } 
  "*?assword" { 
	send "$password\r"
	expect "*denied*"  { exit 3 }
  }
  "*not known*" {
        exit 10
  }
}
expect "$prompt" {
    send "ls -ldrt $cmd\r"
    expect {
	"*No*" { 
		#$send_user "exit 1\n"
		exit 1 
	} 
	"*home*" { 
		#send_user "exit 2\n"
		exit 2 
	}
	default { exit 3 }
    }
}
' > $SSHEXPECT
chmod 755 $SSHEXPECT
}

expectcheck() {
  ./${SSHEXPECT} "$1" "$2" "$3" "$4" &>/dev/null
  res=`echo $?`
  if [ $res -eq 2 ]; then
    echo -e "\e[1;32m Home dir exists\e[0m" 
    echo $1 >> /tmp_stage/$2/Homedir_exists.txt
  elif [ $res -eq 1 ]; then
    echo -e "\e[1;31m Home dir is not available\e[0m" 
    echo $1 >> /tmp_stage/$2/Homedir_notavailable.txt
  else
    echo -e "\e[1;31m Invalid password/ hostname, please verify....\e[0m" 
    echo $1 >> /tmp_stage/$2/Invalidpassword_or_hostname.txt
    #exit 1
  fi
}

if [ $# -eq 2 ]; then
  homecheck_script
  echo -n "Please enter password to ssh on to servers:"
  read -s "pass"
  clear
  mkdir -p /tmp_stage/$2
  touch /tmp_stage/$2/Homedir_exists.txt
  touch /tmp_stage/$2/Homedir_notavailable.txt
  touch /tmp_stage/$2/Invalidpassword_or_hostname.txt
  echo "" > /tmp_stage/$2/Homedir_exists.txt;echo "" > /tmp_stage/$2/Homedir_notavailable.txt;echo "" > /tmp_stage/$2/Invalidpassword_or_hostname.txt
  echo -e "\n\e[1;32mResults will be placed under: \"/tmp_stage/$2\" location\e[0m\n\tHomedir_exists.txt\n\tHomedir_notavailable.txt\n\tInvalidpassword_or_hostname.txt\n"
  sleep 5
  if [ -f $1 ]; then
    for i in $(cat $1 | grep -v "#"); do
      echo -e -n "\e[1;34mWorking on $i:\e[0m" 
      #ssh -q -o ConnectTimeout=5 -oBatchMode=yes "$2"@"$i" "ls" &>/dev/null
      ping -c 1 $i  &>/dev/null
      if [ $? -eq 0 ]; then
        check=`ssh -oBatchMode=yes "$2"@"$i" "$dir" &>/dev/null` &>/dev/null
        if [[ ! -z $check ]]; then
           echo -e "\e[1;32m Home dir exists\e[0m" 
           echo $i >> /tmp_stage/$2/Homedir_exists.txt
        else
           expectcheck "$i" "$2" "$pass" "$dir" 
        fi
      else 
        echo -e "\e[1;31m Invalid host to ssh from this jump box...\e[0m" 
        echo $i >> /tmp_stage/$2/Invalidpassword_or_hostname.txt
      fi
    done
  else
    echo -e -n "\e[1;34mWorking on $1:\e[0m"
      #ssh -q -o ConnectTimeout=5 -oBatchMode=yes "$2"@"$1" "ls" &>/dev/null
      ping -c 1 $1  &>/dev/null
      if [ $? -eq 0 ]; then
        check=`ssh -oBatchMode=yes "$2"@"$1" "$dir" &>/dev/null` &>/dev/null
        if [[ ! -z $check ]]; then
           echo -e "\e[1;32m Home dir exists\e[0m" 
           echo $1 >> /tmp_stage/$2/Homedir_exists.txt
        else
           expectcheck "$1" "$2" "$pass" "$dir"
        fi
      else
        echo -e "\e[1;31m Invalid host to ssh from this jump box...\e[0m" 
        echo $1 >> /tmp_stage/$2/Invalidpassword_or_hostname.txt
      fi
  fi
else
  echo -e "\e[1;31mPlease enter as below\n\t$0 \"server\" \"uid\" \e[0m"
  echo -e "\n\e[1;31m\tEnter \"password\" as prompted\e[0m......\n"
fi
echo -e "\n\e[1;32mResults can be found under: \"/tmp_stage/$2\" location\e[0m\n\tHomedir_exists.txt\n\tHomedir_notavailable.txt\n\tInvalidpassword_or_hostname.txt\n"
