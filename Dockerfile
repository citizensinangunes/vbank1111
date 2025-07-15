FROM nginx:alpine

RUN apk add --no-cache bash

COPY . /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"] 