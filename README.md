# Lets-Encrypt

This branch is a modified version of [secwiseblog/Lets-Encrypt](https://github.com/secwiseblog/Lets-Encrypt).  Check out [SecWiseBlog's excellent article](https://secwise.nl/lets-encrypt-certifcates-and-pound-load-balancer/) on implementing this handy tool.

This script handles certificate requests and renewals for the Pound reverse proxy.
The script is basically a wrapper for "certbot-auto", to enable automatic fetching and installation of new or updated certificates in the format which Pound requires.

---

This (PuceBaboon's) version adds quite a few updates to SecWiseBlog's original.

- By default, use the Let's Encrypt staging servers (comment-out a single line to use the live servers instead).
- Added functionality to allow for combined, alternate/alias, multi-name certificates (ie:- example.com, www.example.com and mail.example.com all in the same certificate).
- Added a "fatal()" exit routine to abort the script when things don't quite go according to plan.
- Updated the "--standalone-supported-challenges" argument to certbot-auto to use "--preferred-challenges", to fix the "deprecated" warning messages.


## Requirements
Certbot actually provides the method for authenticating with the Let's Encrypt servers (which is important, as Pound is *NOT* a web server).  This means that there are some requirements for Certbot (not for this script, per se) which need to be met before certbot-auto can do its own magic and build a temporary, mini web server for that authentication process.  Specifically, for a run-of-the-mill Linux machine, you *must* install these packages:-

- python-dev
- libiff-dev

Because Pound must talk to the Let's Encrypt servers, it must be set up with a basic configuration (again, [see SecWiseBlog's original article](https://secwise.nl/lets-encrypt-certifcates-and-pound-load-balancer/) on how to do this) before you start.  If you have a firewall, you must also open the relevant ports and put in NAT rules between it and your internal Pound server.
You obviously need to have the external DNS records all set up correctly for the A, AAAA and CNAME entries that you want to use for your external facing servers (hint:- whatever you might think of Google, their DNS servers get updates really quickly, so you can use a command-line tool such as "dig" or "nslookup" to check your DNS records from inside your local network by simply specifying one of the Google servers as an external source for your query, ie:- nslookup www.example.com 8.8.4.4).

## Warnings
#### The Staging Environment
If you use this script (and most especially if you use it for multiple individual certificates) without completing the Pound/Firewall configurations first, you will most likely fall foul of Let's Encrypt's rate limiting rules (usually the allowed number of failures in an hour) and be temporarily locked-out.  Depending on which rate you've exceeded, you could be locked out for up to a week, so it is very highly recommended that you stick with using the [Let's Encrypt staging servers](https://letsencrypt.org/docs/staging-environment/) (the current default) until you've worked the kinks out of your process.

Once you've successfully managed to obtain certificates from the staging environment, you can move on to requesting a real, valid certificate, but before you do, you need to do some housekeeping.  First of all, make backups of your complete Pound and Let's Encrypt directories (usually /etc/pound and /etc/letsencrypt), as well as the directory structure which CertBot created on the first run through (usually /opt/eff.org).  You should save your backups on a different machine.  Because you've probably added packages to get this far, I'd recommend doing a complete backup of your whole machine (and again, save it to somewhere remote from the machine itself).

When you have everything safely backed up, you should revoke your staging certificates and remove the support files specific to them (*blindingly obvious warning* - **this is dangerous**, which is why you really, really must make a *good backup* before starting on these steps).  Use CertBot to "revoke --staging" and then "delete --staging" [following the instructions in the CertBot documentation](https://certbot.eff.org/docs/using.html?highlight=revoke#revoking-certificates).  Because this is for the Pound server, you also need to move the staging server certificate from the /etc/pound/certs directory.  I would recommend that you create an archive directory in /etc/pound (not in the certs directory itself) and keep all of your old certificates there.

***Important Note*** If you fail to revoke and remove the staging certificates, your request for a genuine certificate with the same name from Let's Encrypt will work (CertBot can work around most obvious problems), but the new certificate will be stored under a different, unique name, which will cause the Pound-specific part of the process to fail, as the script has no easy way of knowing what CertBot has named the new certificate.

