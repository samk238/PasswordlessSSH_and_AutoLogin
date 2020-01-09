# PasswordlessSSH_and_AutoLogin
Steps and Scripts to auto login and password less authentication

Script/command to perform above and a word doc to guide step by step ...

     1:  Step by Step word doc guide: SSH_keys_setup_for_password_less_login.pdf
     2:  Script mentioned in the doc: ssh_keys_copy.sh

<div dir="ltr" style="text-align: left;" trbidi="on"><br/></div>
<html xmlns:mso="urn:schemas-microsoft-com:office:office" xmlns:msdt="uuid:C2F41010-65B3-11d1-A29F-00AA00C14882">
<head>
</head>
<body>
  <details>
  <summary><b><font color="blue">AppInfo:copy_to_servers</font></b></summary>
  <br>Script/command to list running services w/ timestamps also helps in identifying the duplicate processes.<br>
   <br>&emsp;&ensp;&emsp;&ensp; 1:&emsp; Login to UNIX machine
   <br>&emsp;&ensp;&emsp;&ensp; 2:&emsp; sudo to super user
   <br>&emsp;&ensp;&emsp;&ensp; 3:&emsp; <b>cd ~ && vi appinfo.sh</b>
   <br>&emsp;&ensp;&emsp;&ensp; 5:&emsp; copy and paste the script from: <a href="https://drive.google.com/file/d/1HGMJgZ1JBgP6Nz5JYUXR87nrNx__iU3Z/preview" target="_blank">- appinfo.sh</a>
   <br>&emsp;&ensp;&emsp;&ensp; 6:&emsp; run the following commands on server. (during intial setup, afterward "appinfo")
   <br>&emsp;&ensp;&emsp;&ensp;&emsp;&ensp;&emsp;&ensp;<b> chmod 755 ~/appinfo.sh
   <br>&emsp;&ensp;&emsp;&ensp;&emsp;&ensp;&emsp;&ensp; . ~/appinfo.sh </b>
   <br>&emsp;&ensp;&emsp;&ensp; 8:&emsp; verfiy the result, incase of any misleading output, please update as needed.
   <br>&emsp;&ensp;&emsp;&ensp; 7:&emsp; from nextlogin/forthwith type "appinfo" to trigger "~/appinfo.sh"
   <br>&emsp;&ensp;&emsp;&ensp;&emsp;&emsp;&emsp; above can be achieved by removing the "#opt#" comment from script...
  </details><br><br>
</body>
<script type="text/javascript" src="https://platform.linkedin.com/badges/js/profile.js" async defer></script>
</html>
