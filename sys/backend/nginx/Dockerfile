FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create directories for static files and web app
RUN mkdir -p /usr/share/nginx/html/static
RUN mkdir -p /usr/share/nginx/html/web

# Copy web build output
COPY web/ /usr/share/nginx/html/web/

# Expose ports
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
