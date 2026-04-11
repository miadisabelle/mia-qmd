#!/bin/bash

# Define variables for UID, GID, and username
USERNAME="mia"
UID_VAL="1111"
GID_VAL="1111"
COMMENT="Mia User"
HOME_DIR="/home/$USERNAME"

# Check if the group already exists, if not, create it
if ! getent group "$GID_VAL" > /dev/null; then
    echo "Creating group $USERNAME with GID $GID_VAL..."
    sudo groupadd -g "$GID_VAL" "$USERNAME"
    if [ $? -ne 0 ]; then
        echo "Error creating group $USERNAME."
        exit 1
    fi
else
    echo "Group with GID $GID_VAL already exists."
fi

# Check if the user already exists, if not, create it
if ! getent passwd "$UID_VAL" > /dev/null; then
    echo "Creating user $USERNAME with UID $UID_VAL and GID $GID_VAL..."
    useradd -u "$UID_VAL" -g "$GID_VAL" -c "$COMMENT" -m -d "$HOME_DIR" -s /bin/bash "$USERNAME"
    if [ $? -ne 0 ]; then
        echo "Error creating user $USERNAME."
        exit 1
    fi
    echo "User $USERNAME created successfully."
else
    echo "User with UID $UID_VAL already exists."
fi

echo "Script finished."
