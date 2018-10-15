# Lets-Encrypt

This script handles certificate requests and renewals for the Pound reverse proxy.

The script is basically a wrapper for "certbot-auto", to enable automatic fetching and installation of new or updated certificates in the format which Pound requires.

Certbot actually provides the method for authenticating with the Let's Encrypt servers (which is important, as Pound is NOT a web server).  This means that there are some requirements for Certbot (not for this script, per se) which need to be met before certbot-auto can do its own magic and build a temporary, mini web server for that authentication process.  Specifically, for a run-of-the-mill Linux machine, you must install these packages:-

- python-dev
- libiff-dev

