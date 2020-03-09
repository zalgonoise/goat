FROM alpine:edge

LABEL maintainer="Zalgo Noise <zalgo.noise@gmail.com>"
LABEL version="1.0" 
LABEL description="OAuth2 Authentication Validator via Gmail and Mutt, in a Docker image."

RUN apk add --update --no-cache python2 git tmux mutt ; \
    mkdir /data ; \
    cd /data ; \
    git clone https://github.com/google/gmail-oauth2-tools/ ; \
    cp /data/gmail-oauth2-tools/python/oauth2.py /data/oauth2.py

COPY bootstrap.sh entrypoint.sh /data/

WORKDIR /data

ENTRYPOINT ["/data/bootstrap.sh"]
