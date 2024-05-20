#!/bin/bash

#Hani Amer - ha20-00431
#Ali Ameer - aa19-00110


# Step 1: Create a Debian based container on LXD. we chose to Debian Bookworm.
lxc launch images:debian/12 cont-ite306-debian12

# Step 2: Installing mysql database in the debian container.
lxc exec cont-ite306-debian12 -- bash -c "apt-get update && apt-get install -y default-mysql-server"

# Step 3: Inable the mysql database to start automatically on boot.
lxc exec cont-ite306-debian12 -- bash -c "systemctl enable mysql"

# Step 4: Set the container to run on core #1 and limit ram usage to 2GB.
lxc config set cont-ite306-debian12 limits.cpu 1
lxc config set cont-ite306-debian12 limits.memory=2GiB

# Step 6: Create an ubuntu container and add a user with a random number as lxd-<random number>.
# command-line in class didnt work, so i got this from lxd ubuntu docs
lxc launch ubuntu:24.04 cont-ite306-ubuntu2404 
RANDOM_NUM=$RANDOM
USER_NAME="lxd-$RANDOM_NUM"
lxc exec cont-ite306-ubuntu2404 -- bash -c "useradd -m $USER_NAME"

# Ensure the directory exists so we can start storing the logs
lxc exec cont-ite306-debian12 -- bash -c "mkdir -p /var/log/db"

# Step 5: every 10 mins, create file with the name as the current date and save last 100 logs in it in /var/log/db
(crontab -l 2>/dev/null; echo "*/10 * * * * lxc exec cont-ite306-debian12 -- bash -c 'journalctl -u mysql -n 100 --reverse > /var/log/db/log-database-\$(date +\\%Y\\%m\\%d\\%H\\%M\\%S).log'") | crontab -

# Step 7: every 20 mins, check if the mysql server is down. if yes, create error.txt in the user we created in ubuntu
(crontab -l 2>/dev/null; echo "*/20 * * * * lxc exec cont-ite306-debian12 -- systemctl is-active mysql || lxc exec cont-ite306-ubuntu2404 -- bash -c 'touch /home/$USER_NAME/error.txt'") | crontab -


# Refrences 
# Crontab for time management --> https://www.geeksforgeeks.org/crontab-in-linux-with-examples/
# LXD docs --> https://documentation.ubuntu.com/lxd/en/latest/tutorial/first_steps/
# mysql installation --> chatgpt
# everything else --> in class recordings