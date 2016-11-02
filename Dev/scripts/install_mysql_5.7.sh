#!/bin/bash

## parameters
MYSQL_ROOT_PASSWORD=$1

## constants
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

## Fix "dpkg-reconfigure: unable to re-open stdin: No file or directory"
export DEBIAN_FRONTEND=noninteractive

## add repositories
add-apt-repository ppa:nginx/stable -y
add-apt-repository -y ppa:ondrej/mysql-5.7
curl -sL https://deb.nodesource.com/setup_6.x | bash - # ( runs apt-get update automatically )

## install node
apt-get install -y nodejs

## install expect for non-interactive install
apt-get install expect -y

# Install MySQL
debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"
apt-get -qq install mysql-server > /dev/null # Install MySQL quietly

# Install Expect
apt-get -qq install expect > /dev/null

# Build Expect script
tee ~/secure_our_mysql.sh > /dev/null << EOF
set timeout -1

spawn $(which mysql_secure_installation)

expect "Enter password for user root:"
send "$MYSQL_ROOT_PASSWORD\r"

expect "Press y|Y for Yes, any other key for No:"
send "y\r"

expect "Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:"
send "2\r"

expect "Change the password for root ? ((Press y|Y for Yes, any other key for No) :"
send "n\r"

expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
send "y\r"

EOF

# Run Expect script.
# This runs the "mysql_secure_installation" script which removes insecure defaults.
expect ~/secure_our_mysql.sh

# Cleanup
rm -v ~/secure_our_mysql.sh # Remove the generated Expect script
# apt-get -qq purge expect > /dev/null # Uninstall Expect, commented out in case you need Expect

echo "MySQL setup completed. Insecure defaults are gone. Please remove this script manually when you are done with it (or at least remove the MySQL root password that you put inside it."