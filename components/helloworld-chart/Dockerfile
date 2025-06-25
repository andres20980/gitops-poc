# components/helloworld-chart/Dockerfile v1.0.0

# Stage 1: Build Stage (not strictly necessary for this simple app, but good practice)
# We could add build steps here if we had a real application.

# Stage 2: Final Stage
# Use an official, lightweight NGINX image as a base
FROM nginx:1.27.0-alpine-slim

# The author of the image
LABEL maintainer="asanchez"

# Remove the default NGINX welcome page
RUN rm /usr/share/nginx/html/index.html

# Copy a new simple HTML file into the container
COPY --chown=nginx:nginx index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# The command to run when the container starts
CMD ["nginx", "-g", "daemon off;"]