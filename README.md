# Backup_Script
This Bash script automates the process of creating backups for directories or files on your system. It allows users to schedule backups, compress files into tar archives, and store them in a specified backup location. The script also includes logging and notification features for monitoring backup success or failure.

Steps to use 
- Create a .my.cnf file in your home directory: nano ~/.my.cnf
- Add the following content to the .my.cnf file:
[client]
user= "user name"
password= "password"
host=
port=
- Secure the .my.cnf file: chmod 600 ~/.my.cnf
- Ensure the script is executable: chmod +x backup_script.sh
- Run the script: ./backup_script.sh
