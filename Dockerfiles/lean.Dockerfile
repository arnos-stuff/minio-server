FROM phusion/baseimage:latest-amd64

RUN install_clean \
 build-essential rsync file curl time wget git git-lfs tmux zsh sudo neovim unzip httpie iputils-ping \
 software-properties-common cmake make gcc g++ 
# minio DL

RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio
RUN chmod +x minio
RUN sudo mv minio /usr/local/bin/
RUN mkdir ~/minio
EXPOSE 9000
EXPOSE 9090
CMD [ "minio", "server", "~/minio", "--address", "0.0.0.0:9000", "--console-address", "0.0.0.0:9090", "--ftp='adress=:8080'"]

# CMD ["minio", "server", "~/minio", "--console-address", ":9090"]

