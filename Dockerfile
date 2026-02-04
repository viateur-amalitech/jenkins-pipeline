FROM node:18-slim

WORKDIR /usr/src/app

COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy app source
COPY . .

# Use the ENV variable for EXPOSE (documentation only, but good practice)
EXPOSE ${PORT}

# Start command
CMD ["node", "index.js"]
