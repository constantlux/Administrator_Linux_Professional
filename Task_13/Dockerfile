FROM alpine:latest
EXPOSE 80
RUN apk update && apk upgrade && apk add nginx
COPY index.html /var/www/otus/index.html
COPY nginx_instance.conf /etc/nginx/http.d/nginx_instance.conf 
CMD ["nginx", "-g", "daemon off;"]