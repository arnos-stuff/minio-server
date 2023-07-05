FROM nginx

RUN apt-get update
RUN apt-get install -y wget sudo

RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio
RUN chmod +x minio
RUN sudo mv minio /usr/local/bin/
RUN mkdir ~/storage
EXPOSE 9000
EXPOSE 9090
EXPOSE 8021
COPY nginx/minio.nginx.conf /etc/nginx/nginx.conf

RUN echo '#!/bin/bash\n' >> entrypoint.sh

RUN echo 'minio server ~/storage\
    --address "0.0.0.0:9000"\
    --console-address 0.0.0.0:9090\
    --ftp="adress=:8080"\
    &\n' >> entrypoint.sh

RUN echo "nginx-debug -g 'daemon off'" >> entrypoint.sh

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]