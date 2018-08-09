FROM openresty/openresty:alpine
COPY nginx.conf usr/local/openresty/nginx/conf/
COPY index.html /usr/local/openresty/nginx/html/
EXPOSE 80
