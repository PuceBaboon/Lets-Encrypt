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

## Warnings
If you use this script (and most especially if you use it for multiple individual certificates) without completing the Pound/Firewall configurations first, you will most likely fall foul of Let's Encrypt's rate limiting rules (usually the allowed number of failures in an hour) and be temporarily locked-out.  Depending on which rate you've exceeded, you could be locked out for up to a week, so it is very highly recommended that you stick with using the staging servers (the current default) until you've worked the kinks out of your process.

