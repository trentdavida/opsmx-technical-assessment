FROM nginx:alpine

RUN { \
        echo 'server {'; \
        echo '    listen       80;'; \
        echo '    server_name  localhost;'; \
        echo; \
        echo '    location / {'; \
        echo '        default_type text/plain;'; \
        echo '        return 200 "Your IP Address is $remote_addr\n";'; \
        echo '    }'; \
        echo '}'; \
    } > /etc/nginx/conf.d/default.conf
