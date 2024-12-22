#!/bin/bash
# Express setup of GZCTF
# for Ubuntu 2x.xx LTS
# by Cyr1s https://github.com/Cyr1s-dev
# 
# Version 0.1 (2024-12-19)
# 
# Usage: just run deploy.sh :)
# 

# get user name
BASE_USER="$(who am i | awk '{print $1}')"
if [ -z "$BASE_USER" ]; then
    BASE_USER="root"
fi

# check for root
IAM=$(whoami)
if [ ${IAM} != "root" ]; then
    echo "You must be root to use this script"
    exit 1
fi

# check for updates
echo "Updating system packages..."
apt-get update
if [ $? -ne 0 ]; then
    echo "System update failed"
    exit 1
fi

apt-get upgrade -y
if [ $? -ne 0 ]; then
    echo "System upgrade failed"
    exit 1
fi

# Check network connectivity
echo "Checking network connectivity..."
ping -c 4 8.8.8.8
if [ $? -ne 0 ]; then
    echo "Network is not reachable."
    exit 1
fi

echo "Checking Docker website connectivity..."
curl -I https://www.docker.com
if [ $? -ne 0 ]; then
    echo "Cannot connect to Docker website."
    exit 1
fi

# Install Docker
echo "Installing Docker..."
apt install docker.io docker-compose -y
if [ $? -ne 0 ]; then
    echo "Docker installation failed"
    exit 1
fi

echo "Docker installed successfully!"
docker --version
docker-compose --version

# Set GZCTF installation directory
echo -n "Please enter installation directory (default /home/$BASE_USER/GZCTF): "
read install_dir

if [ -z "$install_dir" ]; then
    install_dir="/home/$BASE_USER/GZCTF"
fi

# Create installation directory
echo "Creating directory: $install_dir"
mkdir -p "$install_dir"
if [ $? -ne 0 ]; then
    echo "Directory creation failed"
    exit 1
fi

original_dir="$(pwd)"

# Copy appsettings.json and docker-compose.yml to the installation directory
cp "$original_dir/appsettings.json" "$install_dir"
cp "$original_dir/docker-compose.yml" "$install_dir"

cd "$install_dir"
echo "Switched to directory: $(pwd)"

# Get user input for PostgreSQL password, GZCTF public entry, and admin password
echo -n "Please enter PostgreSQL password (default: Admin123): "
read -s postgres_password
echo
if [ -z "$postgres_password" ]; then
    postgres_password="Admin123"
fi

# Export PostgreSQL password to avoid manual input
export PGPASSWORD="$postgres_password"

# Automatically detect server IP
public_entry=$(hostname -I | awk '{print $1}')
if [ -z "$public_entry" ]; then
    echo "Failed to detect server IP. Please enter manually."
    while true; do
        echo -n "Please enter GZCTF server ip: "
        read public_entry
        # Regex match for IPv4 address
        if [[ "$public_entry" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            # Check if each segment is between 0 and 255
            IFS='.' read -r -a octets <<< "$public_entry"
            valid=true
            for octet in "${octets[@]}"; do
                if (( octet < 0 || octet > 255 )); then
                    valid=false
                    break
                fi
            done
            if $valid; then
                break
            else
                echo "Invalid IP address. Each octet must be between 0 and 255. Please try again."
            fi
        else
            echo "Invalid IP address format. Please enter in the format X.X.X.X where X is between 0 and 255."
        fi
    done
else
    echo "Detected server IP: $public_entry"
fi

while true; do
    echo -n "Please enter GZCTF admin password (must contain uppercase, lowercase letters, and numbers): "
    read -s gzctf_admin_password
    echo
    if [[ ${#gzctf_admin_password} -ge 8 && "$gzctf_admin_password" =~ [A-Z] && "$gzctf_admin_password" =~ [a-z] && "$gzctf_admin_password" =~ [0-9] ]]; then
        break
    else
        echo "Password does not meet the requirements. Please try again."
    fi
done

# Update appsettings.json with user input
sed -i "s/\"Password\": \"Admin123\"/\"Password\": \"$postgres_password\"/" "$install_dir/appsettings.json"
sed -i "s/\"PublicEntry\": \"127.0.0.1\"/\"PublicEntry\": \"$public_entry\"/" "$install_dir/appsettings.json"

# Update docker-compose.yml with user input
sed -i "s/POSTGRES_PASSWORD=Admin123/POSTGRES_PASSWORD=$postgres_password/" "$install_dir/docker-compose.yml"
sed -i "s/GZCTF_ADMIN_PASSWORD=Admin123/GZCTF_ADMIN_PASSWORD=$gzctf_admin_password/" "$install_dir/docker-compose.yml"

echo "Configuration updated successfully!"

# Switch to installation directory and execute docker-compose
cd "$install_dir"
sudo docker-compose up -d

# Get PostgreSQL container IP
db_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' gzctf_db_1)
if [ -z "$db_ip" ]; then
    echo "Failed to retrieve PostgreSQL container IP"
    exit 1
fi
echo "PostgreSQL container IP: $db_ip"

# Install PostgreSQL client
echo "Installing PostgreSQL client..."
sudo apt install postgresql-client -y
if [ $? -ne 0 ]; then
    echo "PostgreSQL client installation failed"
    exit 1
fi

# Add multiple log checks before waiting
echo "Checking PostgreSQL container logs for startup confirmation..."
docker logs gzctf_db_1 --tail 20

# Wait for PostgreSQL database to be ready
echo "Waiting for PostgreSQL database to be ready..."
until psql -h "$db_ip" -p 5432 -U postgres -d gzctf -c "\q" > /dev/null 2>&1; do
    echo "PostgreSQL is not ready yet. Waiting..."
    sleep 5
    # Add a log check
    docker logs gzctf_db_1 --tail 5
done
echo "PostgreSQL database is ready."

# Connect to PostgreSQL database
echo "Connecting to PostgreSQL database..."
psql -h "$db_ip" -p 5432 -U postgres -d gzctf -c "\q"
if [ $? -ne 0 ]; then
    echo "Failed to connect to PostgreSQL database"
    exit 1
fi
echo "Successfully connected to PostgreSQL database."

# Update AspNetUsers role
echo "Updating AspNetUsers role in PostgreSQL database..."
psql -h "$db_ip" -p 5432 -U postgres -d gzctf -c "UPDATE \"AspNetUsers\" SET \"Role\"=3 WHERE \"UserName\"='admin';"
if [ $? -ne 0 ]; then
    echo "Failed to update AspNetUsers role in PostgreSQL database"
    exit 1
fi
echo "AspNetUsers role updated successfully."

# information
echo "PostgreSQL password: $postgres_password"
echo "GZCTF admin password: $gzctf_admin_password"
