#################################################################################
#                                                                               #
# Author: Sampath Kunapareddy                                                   #
# sampath.a926@gmail.com                                                        #
#                                                                               #
# This script will help in copying:                                             #
#   -> USER KEY to AUTOLOGIN and                                                #
#   -> PUBLIC KEY to SSH Servers keys to servers without asking for passwords   #
# Appends keys to authorized_keys file                                          #
#                                                                               #
#                                                                               #
#################################################################################

#!/bin/bash
#set -x

EXPECTHME=$(which expect 2>/dev/null)
if [[ -z $EXPECTHME ]]; then
  clear 
  echo -e "\n\nNo expect home, host isnt suitable to run the script.. exiting now.."
  sleep 5
  exit 1
fi
export SSHEXPECT="ssh_keys_copy_script.expect"
export SUID=`whoami`
rm $SSHEXPECT 2>/dev/null

sshexpect() {
echo '
#!/usr/bin/expect
#!/usr/bin/env tclsh
#Usage ./Expectscript.expect server userid password
#exp_internal -f debug.log 0
set timeout 10
package require Expect
#set prompt {> }
set keyfiletossh "~/.ssh/id_rsa.pub"
set userautologin "~/.ssh/authorized_keys"
set host     [lindex $argv 0]
set user     [lindex $argv 1]
set password [lindex $argv 2]
set needpubkeycopy [lindex $argv 3]
set needuserkeycopy [lindex $argv 4]
spawn ssh $user@$host
expect {
  "*yes/no*" {
    send "yes\r"
    expect "*?assword*"
    send "$password\r"
    expect {
      "*denied*" { 
        exit 10 
      }
      "*?assword*" { 
        exit 10 
      }
      "*" {
        send "\n"
      }
    }
  }
  "*?assword*" {
    send "$password\r"
    expect {
       "*denied*"  { 
          exit 10 
       }
       "*?assword*" { 
          exit 10 
       }
       "*" {
          send "\n"
       }       
    }   
  }
  "*not known*" {
    exit 10
  }
  "> " {
    send "\n"
  }
}

if {$needpubkeycopy == 0 && $needuserkeycopy == 1} {
    set fd [open $userautologin]
    gets $fd userkey
    close $fd
    sleep 1
    send " mkdir -p ~/.ssh\r"
    sleep 1
    expect "*"
    send " cat >> ~/.ssh/authorized_keys <<EOF\r$userkey\rEOF\r"
    sleep 1
    expect "*"
    exit 1
}

if { $needpubkeycopy == 1 && $needuserkeycopy == 0} {
    set fd [open $keyfiletossh]
    gets $fd pubkey
    close $fd
    sleep 1
    send " mkdir -p ~/.ssh\r"
    sleep 1
    expect "*"
    send " cat >> ~/.ssh/authorized_keys <<EOF\r$pubkey\rEOF\r"
    sleep 1
    expect "*"
    exit 1
}

if {$needpubkeycopy == 1 && $needuserkeycopy == 1} {
    set fd [open $keyfiletossh]
    gets $fd pubkey
    close $fd
    sleep 1
    send " mkdir -p ~/.ssh\r"
    sleep 1
    expect "*"
    send " cat >> ~/.ssh/authorized_keys <<EOF\r$pubkey\rEOF\r"
    sleep 1
    expect "*"
    set fd [open $userautologin]
    gets $fd userkey
    close $fd
    expect "*"
    send " cat >> ~/.ssh/authorized_keys <<EOF\r$userkey\rEOF\r"
    sleep 1
    expect "*"
    exit 3
}
send "exit\r"
' > $SSHEXPECT
chmod 755 $SSHEXPECT
}

keyscheck() {
  sshexpect
  ukey=`ssh -q -oBatchMode=yes "$2"@"$1" "cat ~/.ssh/authorized_keys" | grep "$(cat ~/.ssh/authorized_keys | grep rsa-key)"` &>/dev/null
  pkey=`ssh -q -oBatchMode=yes "$2"@"$1" "cat ~/.ssh/authorized_keys" | grep "$(cat ~/.ssh/id_rsa.pub)"` &>/dev/null
  if [[ ! -z $ukey ]] && [[ ! -z $pkey ]]; then
    if [ $IC -le 3 ]; then 
      echo -e "\e[1;32mKeys Already Exists..skipping $1 and proceeding to next server..\e[0m"
      resultcheck 12
    fi
  elif [[ -z $ukey ]] && [[ ! -z $pkey ]]; then
    if [ $IC -le 3 ]; then
      echo -e "\e[1;32mPUBLIC key to SSH exists..copying only USER key to AUTOLOGIN server..\e[0m"; sleep 1
      ${EXPECTHME} ${SSHEXPECT} "$1" "$2" "$pass" 0 1 &>/dev/null
      resultcheck `echo $?`
    else
      resultcheck 11
    fi
  elif [[ ! -z $ukey ]] && [[ -z $pkey ]]; then
    if [ $IC -le 3 ]; then
      echo -e "\e[1;32mUSER key to AUTOLOGIN exists..copying only PUBLIC key to SSH on server..\e[0m"; sleep 1
      ${EXPECTHME} ${SSHEXPECT} "$1" "$2" "$pass" 1 0 &>/dev/null
      resultcheck `echo $?`
    else
      resultcheck 11
    fi
  else
    if [ $IC -le 3 ]; then
      echo -e "\e[1;32mCopying BOTH PUBLIC key to SSH and USER key to AUTOLOGIN server..\e[0m"; sleep 1
      ${EXPECTHME} ${SSHEXPECT} "$1" "$2" "$pass" 1 1 &>/dev/null
      resultcheck `echo $?`
    else
      resultcheck 11
    fi
  fi
}

resultcheck() {
  if [ $1 -eq 1 ]; then
    while [ $IC -le 3 ]; do ((++IC));keyscheck $ISERVER $IUSER; done
    #echo -e "\e[1;32m USER key copied....\e[0m"
  elif [ $1 -eq 2 ]; then
    while [ $IC -le 3 ]; do ((++IC));keyscheck $ISERVER $IUSER; done
    #echo -e "\e[1;32m PUBLIC key copied....\e[0m"
  elif [ $1 -eq 3 ]; then
    while [ $IC -le 3 ]; do ((++IC));keyscheck $ISERVER $IUSER; done
    #echo -e "\e[1;32m Both USER key and PUBLIC key are copied....\e[0m"
  elif [ $1 -eq 11 ]; then
    echo -e "\e[1;31m Tried 3 times.. still unable to copy the key/keys.. please login and check server for details...\e[0m"
  elif [ $1 -eq 12 ]; then
    echo -e "\e[1;32m Done\e[0m"
  else
    echo -e "\e[1;31m Invalid password/ hostname, please verify....\e[0m"
  fi
}

keygencheck() {
  echo -e "\n"
  echo -e "###############################"
  echo -e "#   RUN Following \e[1;32mCommands:\e[0m   #"
  echo -e "###############################"
  echo -e "\e[1;32mssh-keygen -t rsa\e[0m"
  echo -e "Generating public/private rsa key pair."
  echo -e "Enter file in which to save the key (/export/home/${SUID}/.ssh/id_rsa): \e[1;32mPRESS ENTER\e[0m"
  echo -e "Enter passphrase (empty for no passphrase): \e[1;32mPRESS ENTER\e[0m"
  echo -e "Enter same passphrase again: \e[1;32mPRESS ENTER\e[0m"
  echo -e "\n\e[1;34mPublic and Private Key Pair files will be generated after completion of above... \e[0m\n"
  echo -e "Creating authorized_keys file:"
  echo -e "\e[1;32mtouch authorized_keys\e[0m"
  echo -e "\e[1;32mcat id_rsa.pub > authorized_keys\e[0m"
  echo -e "\e[1;31mOn your Desktop:\e[0m"
  echo -e "\e[1m   Generate Public/Private Key pair using \"PuTTYgen\" utility... save both keys\e[0m"
  echo -e "\e[1m   Copy **PublicKey** and vim to \"authorized_keys\" file...\e[0m"
  echo -e "\e[1m   Change Putty Configurations to use ***PrivateKey \".ppk\"*** file saved on your desktop\e[0m"
  echo -e "     --found under \"Connection->SSH->Auth\" and save the session"
  echo -e "     --to auto-fill user \"Connection->Data->Auto-login username\" and save the session"
  echo -e "\n\e[1;34mAuthorized Keys file creation is completion\e[0m"
  echo -e "\n\e[1;34mPlease re-run the script post completion of above.\e[0m"
  echo -e "\n"
}

SSHPWD=`pwd`
if [[ $(echo ${SSHPWD##*/}) == ".ssh" ]]; then
  if [ -f id_rsa.pub ] && [ -f id_rsa ] && [ -f authorized_keys ]; then
    if [ $# -eq 2 ]; then
    echo -n "Please enter password to ssh on to servers:"
    read -s "pass"
    echo ""
    #clear
      if [[ -f $1 ]]; then
        for i in $(cat $1 | grep -v "#"); do
          echo -e "\e[1;34mWorking on $i:\e[0m"
          #ssh -q -o ConnectTimeout=5 -oBatchMode=yes "$2"@"$i" "ls" &>/dev/null
          ping -c 1 $i  &>/dev/null
          if [ $? -eq 0 ]; then
            ISERVER=$i
            IUSER=$2
            IC=1
            keyscheck $ISERVER $IUSER
          else 
            echo -e "\e[1;31m Invalid host/ unable to ssh from this jump box...\e[0m"
          fi
        done
      else
        for iser in $1; do
          echo -e "\e[1;34mWorking on $iser:\e[0m"
          #ssh -q -o ConnectTimeout=5 -oBatchMode=yes "$2"@"$1" "ls" &>/dev/null
          ping -c 1 $iser  &>/dev/null
          if [ $? -eq 0 ]; then
            ISERVER=$iser
            IUSER=$2
            IC=1
            keyscheck $ISERVER $IUSER
          else 
            echo -e "\e[1;31m Invalid host/ unable to ssh from this jump box...\e[0m"
          fi
        done
      fi
    else
      echo -e "\n\e[1;31mPlease enter as below:\n\n 1st_script--> $0\n  2nd_input--> Single_Server (or) Multiple Servers in \"\" (or) File with list of Servers\n  3rd_input--> \"user_id\" \e[0m"
      echo -e "\n\e[1;31mEnter \"password\" as prompted......\e[0m\n"
      echo -e "\n\e[1;31mExample: $0  uxuat1139  $SUID\e[0m"
	  echo -e "\e[1;31mExample: $0  \"uxuat1139 uxuat1139\" $SUID\e[0m"
	  echo -e "\e[1;31mExample: $0  servers_list.txt  $SUID\e[0m"
      echo -e "\n\n"
    fi
  else
    clear
    echo -e "\nNO Public, Private and Authorized Keys...\n\"id_rsa.pub\", \"id_rsa\" and \"authorized_keys\" files doesn't exists... please follow as below..."
    keygencheck
  fi
else
  clear
  echo -e "\n\nPlease check the PWD its not ~/.ssh... please switch to \"cd ~/.ssh\" and run the script"
  echo -e "Create a dir if needed.. \"mkdir -p ~/.ssh\"\n"
fi
rm $SSHEXPECT 2>/dev/null