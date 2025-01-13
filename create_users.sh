#!/bin/bash

# Log file and password file paths
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure script runs with superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

# Ensure the input file is provided
if [ -z "$1" ]; then
  echo "Usage: bash $0 <input-file>"
  exit 1
fi

INPUT_FILE="$1"

# Create necessary directories
mkdir -p /var/secure
touch $LOG_FILE $PASSWORD_FILE
chmod 600 $PASSWORD_FILE
chown root:root $PASSWORD_FILE

# Function to generate random passwords
generate_password() {
  openssl rand -base64 12
}

# Process the input file
while IFS=';' read -r username groups; do
  # Remove whitespace
  username=$(echo "$username" | xargs)
  groups=$(echo "$groups" | xargs | tr ',' ' ')

  # Skip empty lines
  if [ -z "$username" ]; then
    continue
  fi

  echo "Processing user: $username" | tee -a $LOG_FILE

  # Create the user's primary group
  if ! grep -q "^$username:" /etc/group; then
    groupadd "$username"
    echo "Created group: $username" | tee -a $LOG_FILE
  fi

  # Create the user
  if ! id "$username" &>/dev/null; then
    useradd -m -g "$username" -s /bin/bash "$username"
    echo "Created user: $username" | tee -a $LOG_FILE
  else
    echo "User $username already exists. Skipping..." | tee -a $LOG_FILE
    continue
  fi

  # Assign the user to additional groups
  if [ -n "$groups" ]; then
    for group in $groups; do
      if ! grep -q "^$group:" /etc/group; then
        groupadd "$group"
        echo "Created group: $group" | tee -a $LOG_FILE
      fi
      usermod -aG "$group" "$username"
      echo "Added $username to group: $group" | tee -a $LOG_FILE
    done
  fi

  # Set permissions for the user's home directory
  chmod 700 "/home/$username"
  chown "$username:$username" "/home/$username"
  echo "Set permissions for /home/$username" | tee -a $LOG_FILE

  # Generate and save a random password
  password=$(generate_password)
  echo "$username,$password" >> $PASSWORD_FILE
  echo "Generated password for $username" | tee -a $LOG_FILE

  # Set the user's password
  echo "$username:$password" | chpasswd
done < "$INPUT_FILE"

echo "Script execution completed. Logs available at $LOG_FILE."
