#!/bin/bash

clear
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 
  exit 1
fi

# Check if the 'box_type' argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <operating system: L=linux, W=windows, A=Apple>"
  exit 1
fi
trader_type="$1"


# Ask user for their GitHub token without displaying it
echo "What is your GitHub token?"
# read -s github_token  # -s flag hides the input

# Validate the token
echo "Validating GitHub token..."
validation_result=$(curl -s -H "Authorization: token $github_token" https://api.github.com/user)

if [[ "$validation_result" == *'"login":'* ]]; then
    echo "Token is valid."
    # You can now use $github_token in your script
else
    echo "Token is invalid or does not have access."
    exit 1
fi


username="spangle"

## don't ask for password when using sudo reboot

# Check if the sudoers file already exists
if [ ! -f /etc/sudoers.d/nopsd ]; then
    # If it doesn't exist, create the sudoers file
    echo "$username ALL=(ALL) NOPASSWD: /sbin/reboot" > $HOME/nopsd

    # Now copy this file to /etc/sudoers.d/
    cp $HOME/nopsd /etc/sudoers.d/

    # Set the correct permissions for the sudoers file
    chmod 0440 /etc/sudoers.d/nopsd

    # Remove the temporary file
    rm $HOME/nopsd

    echo "password setup so no need for sudo..."
fi
# echo


## Setup read only and read-write ##

# Define the sudoers file path
sudoers_file="/etc/sudoers.d/"$username"_mount"

# Check if the sudoers file already exists
if [ ! -f "$sudoers_file" ]; then
    # If it doesn't exist, create the sudoers file
    temp_sudoers=$(mktemp)

    # Add the current user to the sudoers file for the mount command
    echo "$username ALL=(ALL) NOPASSWD: /bin/mount" > "$temp_sudoers"
    

    # Set the permissions of the temporary file
    chmod 0440 "$temp_sudoers"

    # Move the temporary file to the sudoers.d directory
    mv "$temp_sudoers" "$sudoers_file"

    echo "Passwordless mount setup for user $username..."
fi
# echo


## make apt-get to be used without password

# Define the sudoers file path
sudoers_file="/etc/sudoers.d/"$username"_apt-get"

# Check if the sudoers file already exists
if [ ! -f "$sudoers_file" ]; then
    # If it doesn't exist, create the sudoers file
    temp_sudoers=$(mktemp)

    # Add the current user to the sudoers file for the mount command
    echo "$username ALL=(ALL) NOPASSWD: /usr/bin/apt-get" > "$temp_sudoers"
    

    # Set the permissions of the temporary file
    chmod 0440 "$temp_sudoers"

    # Move the temporary file to the sudoers.d directory
    sudo mv "$temp_sudoers" "$sudoers_file"

    echo "Passwordless apt-get setup for user $username..."
fi
echo





## GITHUB ##

# Capture the output of `whoami` command into a variable named "current_user"
# current_user=trumeter

# read -p "Do you want to generate a new SSH key? (y/n): " response
# if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
# then
  # rm /root/.ssh/id_rsa
  # rm /root/.ssh/id_rsa.pub
  
  # Generate a new SSH key
  echo "Generating a new SSH key..."
  
  # Ask for the email associated with the GitHub account
  # echo "Please enter the email associated with your GitHub account:"
  # read email
  
  # Ensure the user's home directory has a .ssh directory
  sudo -u $username mkdir -p /home/$username/.ssh
  
  # Generate the SSH key as the spangle user
  # sudo -u $username ssh-keygen -t rsa -b 4096 -C "$email" -f /home/$username/.ssh/id_rsa -N ""
  sudo -u $username ssh-keygen -t rsa -b 4096 -C "jemamena@gmail.com" -f /home/$username/.ssh/id_rsa -N ""
  
  echo "SSH key generated successfully."
  
  public_key=$(sudo -u $username cat /home/$username/.ssh/id_rsa.pub)
  
  # Start the ssh-agent and add the SSH key to it
  sudo -u $username bash -c 'eval "$(ssh-agent -s)" && ssh-add /home/$current_user/.ssh/id_rsa'
  
  # Set appropriate permissions on the .ssh directory and its contents
  chown -R $username:$username /home/$username/.ssh
  chmod 700 /home/$username/.ssh
  chmod 600 /home/$username/.ssh/*
  
  # Use the GitHub API to add the SSH key to the account
  curl -X POST -H "Authorization: token $github_token" \
    --data "{\"title\":\"`hostname`\",\"key\":\"$public_key\"}" \
    https://api.github.com/user/keys
# else
#     echo "SSH key generation skipped"
# fi



#Take the file setup.sh
echo "Downloading setup.sh..."

curl -H "Authorization: token $github_token" \
     -H 'Accept: application/vnd.github.v3.raw' \
     -o setup.sh \
     -L https://api.github.com/repos/jemamena/palaisDeSpangle/contents/spangleHub/scripts/bash/setup.sh



## EXECUTE SETUP.SH ##
echo
echo "Executing setup.sh..."

chmod +x setup.sh
#echo "su" $username "-c ./setup.sh" $box_type
# su "$username" -c "/home/$username/setup.sh $trader_type"
su "$username" -c "/home/$username/setup.sh 
