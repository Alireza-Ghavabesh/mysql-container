#!/bin/bash

# Start MariaDB service
/etc/init.d/mariadb start

# Check if the root password is already set
if mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
  echo "Root password is already set. Skipping mysql_secure_installation."
else
  # Automate the mysql_secure_installation process
  SECURE_MYSQL=$(expect -c "
  set timeout 10
  spawn mysql_secure_installation
  expect {
    \"Enter current password for root (enter for none):\" {
      send \"\r\"
      exp_continue
    }
    \"Switch to unix_socket authentication \

\[Y/n\\]

:\" {
      send \"n\r\"
      exp_continue
    }
    \"Change the root password? \

\[Y/n\\]

:\" {
      send \"Y\r\"
      exp_continue
    }
    \"New password:\" {
      send \"$MYSQL_ROOT_PASSWORD\r\"
      exp_continue
    }
    \"Re-enter new password:\" {
      send \"$MYSQL_ROOT_PASSWORD\r\"
      exp_continue
    }
    \"Remove anonymous users? \

\[Y/n\\]

:\" {
      send \"Y\r\"
      exp_continue
    }
    \"Disallow root login remotely? \

\[Y/n\\]

:\" {
      send \"Y\r\"
      exp_continue
    }
    \"Remove test database and access to it? \

\[Y/n\\]

:\" {
      send \"Y\r\"
      exp_continue
    }
    \"Reload privilege tables now? \

\[Y/n\\]

:\" {
      send \"Y\r\"
      exp_continue
    }
  }
  expect eof
  ")

  echo "$SECURE_MYSQL"
fi

# Wait for MariaDB to start
until mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
  echo "Waiting for MariaDB to start..."
  sleep 2
done

# Ensure root password is set
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"

# Create the masaf database if it doesn't exist
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS masaf;"

# Grant all privileges to root on all databases
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;"

# Flush the privileges to ensure they are applied
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Export DATABASE_URL environment variable
export DATABASE_URL="mysql://root:jhddf23&!Hdw@localhost:3306/masaf"

# Debugging information
echo "DATABASE_URL: $DATABASE_URL"
echo "MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"

# Listing files in /app/prisma
echo "Listing files in /app/prisma:"
ls -l /app/prisma

# Display contents of schema.prisma
echo "Contents of schema.prisma:"
cat /app/prisma/schema.prisma

# Applying Prisma migrations
cd /app
echo "Running Prisma migrations..."
expect -c "
set timeout 20
spawn prisma migrate dev
expect \"Enter a name for the new migration\"
send \"\r\"
expect eof
"

# Check for migration files
echo "Listing migration files in prisma/migrations:"
ls -l /app/prisma/migrations

# Apply Prisma generate
prisma generate

# Debugging information
echo "Listing tables in masaf database after migrations:"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW TABLES;" masaf

# Keep the container running
tail -f /dev/null
