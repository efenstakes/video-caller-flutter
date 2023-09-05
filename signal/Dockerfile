# Use an official Node.js runtime as the base image
FROM node:14

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./


# Install Node.js dependencies
RUN npm install

# Copy the rest of the application source code to the working directory
COPY . .

# Build Typescript code here
RUN npm run build


# Expose port 8080
EXPOSE 8080

# Define the command to start your Node.js application
CMD ["node", "/build/index.js"]
