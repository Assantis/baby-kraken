FROM ubuntu:26.04

RUN apt-get update && apt-get install -y tini && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install prerequisites
RUN apt-get update && apt-get install \
    sudo \
    git \
    jq \
    curl \
    zsh \
    -y

# In case you need a specific language support for example german:
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && locale-gen "de_DE.UTF-8"
ENV LANG=de_DE.UTF-8 \
    LANGUAGE=de_DE:de \
    LC_ALL=de_DE.UTF-8

# make zsh your default shell
RUN chsh root --shell /bin/zsh

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleep", "infinity"]