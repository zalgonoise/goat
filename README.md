# goat

### Google OAuth2 Test tools for Gmail

A Google OAuth2 Test environment with Gmail and Mutt, using Google's OAuth2, in a simple, lightweight Docker image.

Using the Developer's API, Google allows you to generate access for your apps in a secure way using 2-Legged OAuth.

Without ever using your private credentials, you're able to safely access your Google account even on a non-interactive environment.

For this method, we test the use of OAuth2 Client ID/Secret combinations to generate a Refresh Token, and to use the same refresh token to access the account after getting a new, valid Access Token.

It is achieved using Google's Gmail OAuth2 Tools, where the provided open-source Python script generates a valid Refresh Token after authentication:

[You can see the repo here.](https://github.com/google/gmail-oauth2-tools "Google's Gmail OAuth2 Tools")

### Generating Credentials

Begin by activating your Gmail API for the desired account from [Google Cloud Platform's Gmail API](https://console.cloud.google.com/apis/library/gmail.googleapis.com "GCP Gmail API").

When it is active, you can head over to __API__ > [Credentials](https://console.cloud.google.com/apis/credentials GCP API Credentials) and __+ Create Credentials__. Choose __OAuth2 client ID__.

You may then choose the type of application, for a headless instance we pick _Other_.

You can now retrieve the Client ID and Client Secret values, and store them somewhere safe. Alternatively you can use the __.json__ file to retrieve or store these values temporarily.

### Environment Definition

You can either:
1. Define the environment variables upon container runtime (ergo, during `docker run -e OAUTH2_CLIENTID=<client_id>`).
1. Export the variables to your environment and call them on container runtime (ergo, during `docker run -e OAUTH2_CLIENTID=$OAUTH2_CLIENTID`).
1. Populate a `creds` file and use it as a source of the environment for the container (ergo, during `docker run --env-file /path/to/creds`)

The used variables are the following:
- `OAUTH2_USER`: __[MANDATORY]__ Defines the email address being accessed. Gmail API must be enabled for this account (ergo, `OAUTH2_USER=root@example.com`). 
- `OAUTH2_CLIENTID`: __[MANDATORY]__ This is the client ID provisioned by Google to access the API for your account.
- `OAUTH2_CLIENTSECRET`: __[MANDATORY]__ This is the client secret provisioned by Google to access the API for your account.
- `OAUTH2_REFRESHTOKEN`: If you have generated one already, the container will use the provided token instead of generating one, skipping the Python script's Refresh Token generation sequence.

### Container Deployment

#### Without Refresh Token

You can run the container to access your inbox with interactive mode, by providing the correct environment variables:

```bash
docker run --rm -ti \
    --name goat \
    -e OAUTH2_USER=${OAUTH2_USER} \
    -e OAUTH2_CLIENTID=${OAUTH2_CLIENTID} \
    -e OAUTH2_CLIENTSECRET=${OAUTH2_CLIENTSECRET} \
    zalgonoise/goat:latest
```

A `tmux` window should appear to prompt you to authorize access to your account using this API:

```bash
To authorize token, visit this url and follow the directions:
https://accounts.google.com/o/oauth2/auth?client_id=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Enter verification code: 

```

You can copy this link and paste it to a browser (even on a different machine/device), authorize access and retrieve the code, which you should paste it back to the terminal and hit __Enter__.

The window should close and `mutt` will launch with a custom-generated `muttrc` config file, and authenticate you using `oauthbearer`.

__[Note]__
_If you wish to use your own `muttrc` file, you can push it to the container as a volume, in the following manner:_

```bash
docker run --rm -ti \
    --name goat \
    -v /path/to/muttrc:/data/muttrc:ro \
    -e OAUTH2_USER=${OAUTH2_USER} \
    -e OAUTH2_CLIENTID=${OAUTH2_CLIENTID} \
    -e OAUTH2_CLIENTSECRET=${OAUTH2_CLIENTSECRET} \
    zalgonoise/goat:latest
```
#### With Refresh Token

If you have already generated a refresh token (or if you need to check its integrity), you can define it as an environment variable as well, overriding the Python script's generation of one. Simply run the container with the environment variable:


```bash
docker run --rm -ti \
    --name goat \
    -e OAUTH2_USER=${OAUTH2_USER} \
    -e OAUTH2_CLIENTID=${OAUTH2_CLIENTID} \
    -e OAUTH2_CLIENTSECRET=${OAUTH2_CLIENTSECRET} \
    -e OAUTH2_REFRESHTOKEN=${OAUTH2_REFRESHTOKEN} \
    zalgonoise/goat:latest
```


#### Testing SMTP

You're also able to test _sending_ an email with these credentials. To simplify the method, you can append text as a parameter during container runtime, and when logging into your account using `mutt`, an email is sent to yourself as opposed of opening your inbox.

The email contain the following:
- __To__: This will be your defined email for logging in, ergo `OAUTH2_USER`
- __Subject__: This will contain today's date appended by the test your define as a paramenter, ergo `[$(date +%y-%m-%d)] ${MAIL_SUBJECT}`
- __Body__: The email body is hardcoded with _Hi from OAuth2 with Mutt tester!_, appended with the output of `uname -a`; `date`; and `echo ${USER}@${HOSTNAME}`.

To test SMTP, the `docker run` command is very simple:


```bash
docker run --rm -ti \
    --name goat \
    -e OAUTH2_USER=${OAUTH2_USER} \
    -e OAUTH2_CLIENTID=${OAUTH2_CLIENTID} \
    -e OAUTH2_CLIENTSECRET=${OAUTH2_CLIENTSECRET} \
    -e OAUTH2_REFRESHTOKEN=${OAUTH2_REFRESHTOKEN} \
    zalgonoise/goat:latest "OAuth2 Gmail Creds Test"
```

Results in the following email:

```bash
From: root@example.com
To: root@example.com

Subject: [20-03-09] OAuth2 Gmail Creds Test
Body:

Hi from OAuth2 with Mutt tester!

Linux 9533d6275024 5.6.0-2-MANJARO #1 SMP Mon Mar 04 11:13:32 UTC 2020 x86_64 Linux

Mon 09 Mar 2020 11:13:32 AM CET

@9533d6275024
```
