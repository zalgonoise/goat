#!/bin/sh

# Make sure /data directory exists

if ! [ -d /data  ]
then
    echo "/data folder doesn't exist\! Exiting."
    exit 1
fi

# Source /data/creds if provided

if [ -f /data/creds ]
then
    source /data/creds
fi

# Break user variable (email) into username + domain
OAUTH2_USERNAME=$(echo ${OAUTH2_USER//@/ } | awk '{print $1}')
OAUTH2_DOMAINNAME=$(echo ${OAUTH2_USER//@/ } | awk '{print $2}')


# Generate config unless one is added

if ! [ -f /data/muttrc ]
then
    echo "Generating Mutt OAuth2 config."
    cat << EOF > /data/muttrc
# User config
set my_username="${OAUTH2_USERNAME}"
set my_domain="${OAUTH2_DOMAINNAME}"
set my_lang="en_US"
set my_clientid="${OAUTH2_CLIENTID}"
set my_clientsecret="${OAUTH2_CLIENTSECRET}"
set my_refreshtoken="${OAUTH2_REFRESHTOKEN}"

## Server config

# IMAP config
set imap_user="${OAUTH2_USER}"
set imap_authenticators="oauthbearer"
set imap_oauth_refresh_command="python2 /data/oauth2.py --quiet --user=${OAUTH2_USER} --client_id=${OAUTH2_CLIENTID} --client_secret=${OAUTH2_CLIENTSECRET} --refresh_token=${OAUTH2_REFRESHTOKEN}"
set folder="imaps://imap.gmail.com/"
set spoolfile= +INBOX


# SMTP config
set from = "${OAUTH2_USER}"
set hostname = "${OAUTH2_DOMAINNAME}"
set smtp_url = "smtp://${OAUTH2_USER}@smtp.gmail.com:587/"
set smtp_authenticators = "oauthbearer"
set smtp_oauth_refresh_command="python2 /data/oauth2.py --quiet --user=${OAUTH2_USER} --client_id=${OAUTH2_CLIENTID} --client_secret=${OAUTH2_CLIENTSECRET} --refresh_token=${OAUTH2_REFRESHTOKEN}"
EOF
fi

# Open Mutt if no parameters are provided (test imap)
# Send email with parameters as subject if added (test smtp)

if [ $# -eq 0 ]
then
    mutt -F /data/muttrc
else
    export MAIL_SUBJECT="$@"
    echo -e "Hi from OAuth2 with Mutt tester!\n\n$(uname -a)\n$(date)\n\n$USER@$HOSTNAME" > /tmp/mail
    echo "" | mutt -F /data/muttrc -s "[$(date +%y-%m-%d)] ${MAIL_SUBJECT}" -i /tmp/mail -- ${OAUTH2_USER}
    rm /tmp/mail
fi
