# Automating User Management in Linux with a Bash Script
AIM: 
DevOps Task: 
Your company has employed many new developers. As a SysOps engineer, write a bash script called create_users.sh that reads a text file containing the employee’s usernames and group names, where each line is formatted as user;groups. The script should create users and groups as specified, set up home directories with appropriate permissions and ownership, generate random passwords for the users, and log all actions to /var/log/user_management.log. Additionally, store the generated passwords securely in /var/secure/user_passwords.txt. Ensure error handling for scenarios like existing users and provide clear documentation and comments within the script.
•	Each User must have a personal group with the same group name as the username, this group name will not be written in the text file.
•	A user can have multiple groups, each group delimited by comma “,” 
•	Usernames and user groups are separated by semicolon “;”- Ignore whitespace e.g. light; sudo,dev,www-data idimma; sudo mayowa; dev,www-data For the first line, light is username and groups are sudo, dev, www-data.

Managing user accounts and permissions in a Linux environment can become cumbersome, especially for organizations onboarding multiple users simultaneously. This bash script, create_users.sh, automates the process of:
1.	Creating users and their corresponding primary groups.
2.	Assigning users to additional groups.
3.	Setting up home directories with appropriate permissions.
4.	Generating secure random passwords for each user.
5.	Storing user credentials securely.
This script simplifies administrative tasks, reduces human error, and ensures consistent configuration.

 Step by step Explanation of the script
1.	Script initialization: This line specifies the shell interpreter to use for executing the script.
 #! /bin/bash
2. Define the log and password file location: Thes variables define the locations of the log and password files. logs document actions, while the password files store generated credentials securely.
LOG_FILE=”/var/log/user_management.log”
PASSWORD_FILE=”/var/secure/user_passwords.csv”
3. Validate input file: This line of code ensures an input file is provided as a command-line argument.
if [ -z “$1” ]; then
 echo “Usage: bash $0 users.txt”
 exit 1
fi
4. Create necessary directories and files: The /var/secure directory and associated files are created with restricted permissions to ensure sensitive data is protected. 
mkdir -p /var/secure
touch $LOG_FILE $PASSWORD_FILE
chmod 600 $PASSWORD_FILE
chown root:root $PASSWORD_FILE
5. Generate random passwords: This line of code is a function to generate and secure random passwords using OpenSSL.
generate_password() {
 openssl rand -base64 12
}
6. Process the Input file: This Script reads the input file line by line. IFS=’;’ this splits each line into username and groups based on the semicolon delimiter.
while IFS=’;’ read -r username groups; do
7. Create primary groups and users: This check if the users primary group exits and create if it does not exist and it also create user with a home directory and assign the primary group.
if ! grep -q “^$username:” /etc/group; then
 groupadd “$username”
 echo “Created group: $username” | tee -a $LOG_FILE
fi
if ! id “$username” &>/dev/null; then
 useradd -m -g “$username” -s /bin/bash “$username”
 echo “Created user: $username” | tee -a $LOG_FILE
fi
8. Assign users to additional groups: User are added to additional groups specified in the input file.
for group in $groups; do
 if ! grep -q “^$group:” /etc/group; then
 groupadd “$group”
 echo “Created group: $group” | tee -a $LOG_FILE
 fi
 usermod -aG “$group” “$username”
 echo “Added $username to group: $group” | tee -a $LOG_FILE
9. Configuring home directory permission and generate and store password: This script sets secure permissions on the user's home directory to protect personal files and random passwords are generated, saved in the password file, and applied to user account.
chmod 700 “/home/$username”
chown “$username:$username” “/home/$username”
password=$(generate_password)
echo “$username,$password” >> $PASSWORD_FILE
echo “$username:$password” | chpasswd
10. Log completion: A final message indicates that the script has finished running.
    
**Run the Script**
1.	bash create_user.sh users.txt
 Creating the user and files
2. cat /var/log/user_management.log
 Checking the user_management.log

3. sudo cat /var/secure/user_passwords.csv
 Randow password for each user.

 
