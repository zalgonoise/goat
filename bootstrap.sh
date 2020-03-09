#!/bin/sh

# Make sure Workdir is /data and it exists

if ! [ -d /data ]
then
    mkdir /data
fi

cd /data

if [ -f /data/creds ]
then
    source /data/creds
fi

# Make sure Python Script is present

if ! [ -f /data/oauth2.py ]
then
    git clone https://github.com/google/gmail-oauth2-tools
    cp /data/gmail-oauth2-tools/python/oauth2.py /data/oauth2.py
    rm -rf /data/gmail-oauth2-tools
fi

# Get environment, stops process if undefined
# Collect email variable

if [ -z $OAUTH2_USER ]
then
    echo "No user defined! define with -e OAUTH2_USER=<email>!"
    exit 1
fi

# Collect Client ID variable

if [ -z $OAUTH2_CLIENTID ]
then
    echo "No user defined! define with -e OAUTH2_CLIENTID=<client_id>!"
    exit 1
fi

# Collect Client Secret variable

if [ -z $OAUTH2_CLIENTSECRET ]
then
    echo "No user defined! define with -e OAUTH2_CLIENTSECRET=<client_secret>!"
    exit 1
fi

# Collect Refresh Token variable
# Generate one from Google's script if undefined

if [ -z $OAUTH2_REFRESHTOKEN ]
then
    tmux new-session -A -s oauth2 \; detach
    tmux pipe-pane -t oauth2 -o 'cat > /data/result'
    tmux send-keys -t oauth2 "clear && python2 /data/oauth2.py --user=$OAUTH2_USER --client_id=$OAUTH2_CLIENTID --client_secret=$OAUTH2_CLIENTSECRET --generate_oauth2_token ; exit" 'C-m'
    tmux attach-session -t oauth2
    export OAUTH2_REFRESHTOKEN=$(grep -i "refresh" /data/result | awk '{print $3}')
fi

# Remove output from Python script

if [ -f /data/result ]
then
    rm /data/result
fi

# If file still doesn't exist, break

if ! [ -z ${OAUTH2_USER} ] \
    && ! [ -z ${OAUTH2_CLIENTID} ] \
    && ! [ -z ${OAUTH2_CLIENTSECRET} ] \
    && ! [ -z ${OAUTH2_REFRESHTOKEN} ]
then
    sh /data/entrypoint.sh $@
else
    echo "Needed variables aren't defined. Something went wrong."
    exit 1
fi
