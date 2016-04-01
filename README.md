# Lets-Encrypt

As the certificates are only valid for 90 days it is of added value to automate the renewal process. I created a bash script that will request or renew certificates and additionally create the certificate file in Pound's format. The script will check the number of days the certificate is still valid for and renew if equal or less than 30 days.
