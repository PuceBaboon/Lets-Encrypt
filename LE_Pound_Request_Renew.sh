#!/bin/bash
#!/bin/sh
#
##
## Pick your shell - Generally "/bin/bash" on Linux systems.
##                   Just move the line to the very top of the
##                   file to have it take effect.
#
# -----------------------------------------------------------------
# v1.0 - SecWiseBlog
# This script will use Lets Encrypt (LE) to request and/or renew certificates automatically.
# The script will also concatenate the private key and cert chain (in the format required
# by Pound) and make it available to Pound Load Balancer.
#
# v1.1 - SecWiseBlog
# switch to certbot-auto
#
# v1.2 - PuceBaboon
# Added "fatal()" routine to exit the script when things dont go according to plan.
# Added "STAGING" option to point the script at the Lets Encrypt staging servers
# instead of the live ones.
# Added handling for alternative-name certificates (comma separated domain list).
# Updated "--standalone-supported-challenges" flag to "--preferred-challenges", to
# fix the "deprecated" warning messages.
# Made /bin/bash the default (watch out for apostrophes in comments if youre using
# /bin/sh instead).
# Fixed minor typos, ie:- doubled-up ")" character on "domains=" line.
#
# -----------------------------------------------------------------


# Parameters
# -----------------------------------------------------------------
#
#
#  Staging servers.   You can get yourself locked out of the main Lets Encrypt
#                     servers very easily when experimenting with this script (ask
#                     me how I know :-)  ), so Id recommend using the "STAGING"
#                     option until youre comfortable that everything is working as
#                     expected.
#
#                     Simply comment-out the "STAGING=--staging;" line to run on
#                     the live servers for a genuine certificate.
#
STAGING="--staging";

#
#  Domains.           Domains to request certs for, separated either by a
#                     space or by commas (with NO spaces).
#
#                     A comma separated list will create a single certificate
#                     with a "Certificate Subject Alternative Name" (aliases/CNAME)
#                     list.  That is, the single certificate is valid for several
#                     hostnames in the same DNS domain.  The certificate will be
#                     created and stored using the first name in the "domains"
#                     list (ie:- one.example.com).
#
#                     A space separated list will create multiple certificates,
#                     one for each entry in the list.  Each certificate will be
#                     stored under its own name.
#
#                     Usually you will want to use a comma separated list.
#
#                     Examples:-
#
## domains=( one.example.com,two.example.com );    ## Alt/alias single certificate.
## domains=( one.example.com two.example.com );    ## Two (or more) certificates.
#
domains=( one.example.com,two.example.com );

#
# Email address for the user registering certs.
email=postmaster@example.com;

#
# LE Binary directory (Lets Encrypt binaries).
le_bin=/etc/letsencrypt;

#
# LE Output directory (default /etc/letsencrypt).
le_output="${le_bin}";

#
# Port to bind CertBot "standalone" server to for authentication with LE.
le_port=8000;

#
# Pound directory.
pound_dir=/etc/pound;

#
# Pound Cert directory.
pound_cfol=${pound_dir}/certs;

#
# -----------------------------------------------------------------
# --------------- Do not edit beyond this point -------------------

# Functions
# -----------------------------------------------------------------
# Original work by Acetylator (https://community.letsencrypt.org/t/how-to-completely-automating-certificate-renewals-on-debian/5615)
#
fatal() {
    printf "\n\tERROR: ${*}\n\n"
    exit 255
}

# Function to extract the number of days for which the cert in question is still valid.
get_days_exp() {
    ## Getting the number of days for which the current cert is still valid.
    local d1=$(date -d "`openssl x509 -in $1 -text -noout|grep "Not After"|cut -c 25-`" +%s)
    local d2=$(date -d "now" +%s)

    ## Return result in global variable.
    days_exp=$(echo \( $d1 - $d2 \) / 86400 |bc)
}

# Function to create certificate in the format required by pound.
create_pound_cert() {
    echo "Create a PEM file in Pound's format / Combine the private key with fullchain"
    for I in ${1} ${2}; do
        if [ ! -s ${I} ]; then
            fatal "Missing or empty certificate file: ${I}";
    fi
    done
    cat ${1} ${2} > ${3} || fatal "Failed to overwrite ${3} with ${1} + ${2}";

    echo "Fix owner and permissions for ${3}"
    chown www-data:www-data ${3}
    chmod 644 ${3}
}


#-----------------------------------------------------------------

# Execution
# -----------------------------------------------------------------
# Create Pound certs folder if it does not exists yet
# Make sure that the cert paths point to the correct folder in the Pound config file
if [ ! -d ${pound_cfol} ]; then
    echo "creating ${pound_cfol}"
    mkdir ${pound_cfol} || fatal "Could not create ${pound_cfol}";

    echo "fix owner and permissions for ${pound_cfol}"
    chown www-data:www-data ${pound_cfol} || fatal "Could not chown ${pound_cfol}";
fi

echo "For each domain in '$domains' array check certs"
for domain_name in "${domains[@]}"
    do
        # Variables for this for loop (Required as it used the domain_name from the domains array)
	#
	# NOTE that if the certificate request is for multiple, comma-separated names, the output
	# file names will be based on the -first- name in that list.  If the request is for
	# multiple, space-separated names, a separate certificate will be generated for each
	# individual name in the list and multiple output files will be produced.
	#
        # ---------------------------

	#
	# Check for the presence of a comma in ${domain_name} and set
	# the output filenames accordingly.
	#
        echo "${domain_name}" | grep -s "," >/dev/null 2>&1;
        retv=${?};
        if [ ${retv} -eq 0 ]; then	## Comma, so set to first name in list.
            opdomfile=`echo "${domain_name}" | cut - --delimiter=',' --fields=1`;
        elif [ ${retv} -eq 1 ]; then	## No comma. filename is ${domain_name}.
            opdomfile="${domain_name}";
        else				## Error occurred during check.
            fatal "Domain name check error for: ${domain_name}";
        fi

        # LE Live folder
        le_live=${le_output}/live/${opdomfile}

        # LE live certs
        le_cert=${le_live}/cert.pem

        # Pound cert folder for every domain
        pound_cert=${pound_cfol}/${opdomfile}

        # ---------------------------

        # if a Pound cert file does not exist
        echo "Checking if ${pound_cert} exists"
        if [ ! -e ${pound_cert}  ]; then
            echo "${pound_cert} does not exist"

            # if a LE cert does not exist request it
            echo "Checking if ${le_cert} exists"
            if [ ! -e ${le_cert} ]; then
                echo "${le_cert} does not exist"
                echo "Requesting cert for ${domain_name}"
                ${le_bin}/certbot-auto -v ${STAGING} --no-bootstrap certonly --standalone --agree-tos --domains ${domain_name} --email ${email} --preferred-challenges http-01 --http-01-port 8000 --renew-by-default --rsa-key-size 4096 || fatal "Failed to create certificate for ${domain_name}";
            fi

            echo "Creating pound cert for ${domain_name}"
            create_pound_cert ${le_live}/privkey.pem ${le_live}/fullchain.pem ${pound_cert}

            echo "set parameter used to determine if pound needs to be restarted"
            restart=1
        fi

        echo "Checking the number of days for which this cert is still valid."
        get_days_exp "${le_cert}"
        echo "${domain_name}'s cert is valid for another ${days_exp} days."

        # If the certificate is valid for 30 or less days
        if [ ${days_exp} -le "30" ]; then
            # The renew command is the same as the initial request command - it will use the config file in ${le_output}/renewal
            # if you used LE for this domain before (for example using the test parameter) you may need to alter the renew config file
            echo "Renewing cert for ${domain_name}"
            ${le_bin}/certbot-auto -v ${STAGING} --no-bootstrap certonly --standalone --agree-tos --domains ${domain_name} --email ${email} --preferred-challenges http-01 --http-01-port 8000 --renew-by-default --rsa-key-size 4096 || fatal "Failed to create certificate for ${domain_name}";

            echo "Creating pound cert for ${domain_name}"
            create_pound_cert ${le_live}/privkey.pem ${le_live}/fullchain.pem ${pound_cert}

            echo "set parameter used to determine if pound needs to be restarted"
            restart=1
        fi
    done

if [ "${restart}" == "1" ]; then
    echo "Restart Pound to load new certs"
    /etc/init.d/pound restart
else
    echo "No new or renewed certs - no restart required"
fi
# -----------------------------------------------------------------
