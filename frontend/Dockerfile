FROM node:18

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Add babel plugin to fix the warning
RUN npm install --save-dev @babel/plugin-transform-private-property-in-object

# Copy the rest of the code
COPY . .

# Create .cache directory and set permissions
RUN mkdir -p node_modules/.cache && chmod -R 777 node_modules/.cache

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Set proper ownership
RUN chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

EXPOSE 3000

CMD ["npm", "start"] 