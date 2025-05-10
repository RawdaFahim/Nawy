# Stage 1: Build the app
FROM node:18-alpine AS build

# Set working dir for the build stage
WORKDIR /app

# Copy the whole `node-hello` folder into the working directory
COPY node-hello /app/node-hello

# Go into the node-hello directory where package.json should exist
WORKDIR /app/node-hello

# Install dependencies
RUN npm install

# Stage 2: Final image
FROM node:18-alpine

# Set working dir for the final image
WORKDIR /app

# Copy the entire built app from the build stage
COPY --from=build /app/node-hello /app/node-hello

# Expose the port
EXPOSE 3000

# Run the application
CMD ["npm", "start", "--prefix", "/app/node-hello"]
