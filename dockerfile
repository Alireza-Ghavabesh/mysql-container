# Use the official Ubuntu 22.04 image from the Docker Hub
FROM ubuntu:22.04

# Set environment variable to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install necessary packages
RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client expect curl

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@10.9.0

# Set environment variables
ENV MYSQL_ROOT_PASSWORD=jhddf23&!Hdw
ENV DATABASE_URL="mysql://root:jhddf23&!Hdw@localhost:3306/masaf"

# Create the directory for automation scripts
RUN mkdir -p /secure_mariadb_automation /app

# Copy the entrypoint script to the directory
COPY entrypoint.sh /secure_mariadb_automation/entrypoint.sh
RUN chmod +x /secure_mariadb_automation/entrypoint.sh

# Copy Prisma schema to the app directory
COPY prisma /app/prisma

# Set the working directory to /app
WORKDIR /app

# Install Prisma CLI
RUN npm install -g prisma

# Expose the default MariaDB port
EXPOSE 3306

# Use the entrypoint script
ENTRYPOINT ["/secure_mariadb_automation/entrypoint.sh"]
