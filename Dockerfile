FROM phusion/baseimage:latest-amd64

RUN install_clean \
 build-essential rsync file curl time wget git git-lfs tmux zsh sudo neovim unzip httpie iputils-ping \
 software-properties-common cmake make gcc g++ 

# user setup
ARG luser=shae
ENV LUSER=${luser}
ENV TERM=xterm-256color

RUN groupadd -r ${LUSER} -g 777
RUN useradd -m -u 777 -r -g 777 -s /usr/bin/zsh ${LUSER}
RUN adduser ${LUSER} sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
COPY ./shell /home/${LUSER}/shell


RUN apt-get update && \
    apt-get install -y -q --allow-unauthenticated \
    git \
    sudo
RUN useradd -m -s /bin/zsh linuxbrew && \
    usermod -aG sudo linuxbrew &&  \
    mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R linuxbrew: /home/linuxbrew/.linuxbrew

USER ${LUSER}
WORKDIR /home/${LUSER}
ENV HOME=/home/${LUSER}
RUN export HOME=${HOME}

RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
RUN chown -R $CONTAINER_USER: /home/linuxbrew/.linuxbrew
RUN chown -R $CONTAINER_USER: /home/linuxbrew/.linuxbrew/Cellar
ENV BREW_ROOT=/home/linuxbrew/.linuxbrew
RUN ${BREW_ROOT}/bin/brew install starship zoxide fzf fd micro nvm

ENV NVM_DIR=${BREW_ROOT}/opt/nvm/

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    -p brew -p git -p sudo \
    -p colored-man-pages -p command-not-found \
    -p copyfile -p copypath \
    -p https://github.com/ptavares/zsh-exa \
    -p fzf -p history -p https://github.com/aubreypwd/zsh-plugin-fd -p https://github.com/zsh-users/zsh-completions \
    -p https://github.com/zsh-users/zsh-syntax-highlighting -p https://github.com/zsh-users/zsh-autosuggestions -p https://github.com/zsh-users/zsh-history-substring-search \
    -p poetry -p pip -p node -p nvm -p zoxide -p zsh-interactive-cd -p zsh-navigation-tools \
    -p https://github.com/jirutka/zsh-shift-select \
    -a 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'\
    -a 'eval "$(starship init zsh)"'\
    -a 'eval "$(zoxide init zsh --cmd fz)"'\
    -a "zle -N history-substring-search-up"\
    -a "zle -N history-substring-search-down"\
    -a 'bindkey "^R" history-incremental-pattern-search-backward' \
    -a 'bindkey "^S" history-incremental-pattern-search-forward' \
    -a "bindkey '^[[Z' reverse-menu-complete" \
    -a "bindkey '^[[A' history-substring-search-up" \
    -a "bindkey '^[[B' history-substring-search-down" \
    -a "bindkey '^[[1;5D' vi-backward-blank-word" \
    -a "bindkey '^[[1;5C' vi-forward-blank-word" \
    -a "bindkey '^X' kill-region" \
    -a 'bindkey "\$terminfo[kcuu1]" history-substring-search-up' \
    -a 'bindkey "\$terminfo[kcud1]" history-substring-search-down'\
    -a 'ZSH_THEME=""' \
    -a '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh' \
    -a "export NVM_DIR=\"${NVM_DIR}\"" \
    -a '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' \
    -a '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' 

RUN mkdir -p /home/${LUSER}/.config/
RUN git clone https://github.com/arnos-stuff/starship-themes starship
RUN cp starship/g-g-go.toml /home/${LUSER}/.config/starship.toml
COPY shell/zsh/shae-ubuntu-zshenv /home/${LUSER}/.zshenv
COPY shell/apps/micro/ /home/${LUSER}/.config/micro/

# minio DL

RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio
RUN chmod +x minio
RUN sudo mv minio /usr/local/bin/
RUN mkdir ~/minio
EXPOSE 9000
EXPOSE 9090

RUN minio server ~/minio \
    --address "0.0.0.0:9000"\
    --console-address "0.0.0.0:9090"\
    --ftp="adress=:8080"
# CMD ["minio", "server", "~/minio", ]

