# JalanCerdas AI - Nginx Reverse Proxy
FROM nginx:alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom configuration
COPY nginx.conf /etc/nginx/conf.d/jalancerdas.conf

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
