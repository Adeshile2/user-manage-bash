 #!/bin/bash

# Check if user is root to get full access and permissions
 if (( "$UID != 0" ))
then
    echo "Error: script requires root privilege"
fi
exit 1
 # Save all arguments in an array
ARGS=("$@")

# # Check whether no arguments are supplied
if [ "$#" -eq 0 ]; then
  echo "No arguments supplied"
  exit 1
fi

# # Define a variable for the file
FILE=${ARGS[0]}

# # Check if the file exists
if [ ! -f "$FILE" ]; then
  echo "Error: File $FILE does not exist."
  exit 1
fi

# # Get the MIME type and check if it is text/plain
file_type=$(file -b --mime-type "$1")
if [[ "$file_type" != "text/plain" ]]; then
    echo "Error: required file type is not text/plain"
    exit 1 
fi


# #Create file directory
create_file_directory() {
    sudo mkdir -p $(dirname $1) && touch $*
    echo "File and path created: $*"
}

# # Create log file
log_path=/var/log/user_management.log
create_file_directory $log_path

# # Create users data file
user_pass=var/secure/user_passwords.txt

log() {
    sudo printf "$*\n" >> $log_path
}

user_data() {
    sudo printf "$1,$2\n" >> $3
}

# #Generate random password 
genpasswd() { 
	local l=$1
       	[ "$l" == "" ] && l=16
      	tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs 
}

# # Main function to create user

    create_user(){
        username="$1"
        password=$(genpasswd)
 # If username exists, do nothing
    if [ ! $(cat /etc/passwd | grep -w $username) ]; then
        
        # User is created with a group as their name
        sudo useradd -m -s /bin/bash $username
 # Set the user's password
        echo "$username:$password" | sudo chpasswd
        msg="User '$username' created with the password '$password'"
        echo $msg
        log $msg
       
       # Save user data
        dir=/home/$username/$user_data_path
        create_file_directory $dir 
        user_data $username $password $dir

         # Set file group to user and give read only access
        sudo chgrp $username $dir
        sudo chmod 640 $dir
    fi

    }

    #If group exists, do nothing 
 if [ ! $(cat /etc/group | grep -w $1) ]; then
 sudo groupadd $1
  msg="Group created '$1'"
        echo $msg
        log $msg
    fi

create_group() {
    # Create group
    # If group exists, do nothing
    if [ ! $(cat /etc/group | grep -w $1) ]; then
        sudo groupadd $1
        msg="Group created '$1'"
        echo $msg
        log $msg
    fi
}

 #  Add user to group
    add_user_to_group() {
   
   sudo usermod -aG $2 $1
   msg="'$1' added to '$2'"
   echo $msg
   log $msg
}

# # Read the FILE
while IFS= read -r line || [ -n "$line" ]; 
do

# Assign variable for <user>
username=$(printf "%s" "$line"| cut -d \; -f 1)
echo "----- Process started for: '$username' -----"

# Create User
create_user $username

# Assign variable for <groups>
usergroups=$(printf "%s" "$line"| cut -d \; -f 2)
# Create user groups
for group in ${usergroups//,/ } ; do 
    create_group $group
    add_user_to_group $username $group
done

echo "----- Process Done with '$username' -----"

done < $FILE