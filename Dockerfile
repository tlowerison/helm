FROM nginx:1.21.0

  WORKDIR /app

  COPY nginx /etc/nginx
  COPY releases/ /usr/share/nginx/html
  RUN ROOT=/usr/share/nginx/html envsubst < /etc/nginx/nginx.conf.template | sed -e 's/§/$/g' > /etc/nginx/nginx.conf

  EXPOSE 3000
  CMD ["nginx", "-g", "daemon off;"]
