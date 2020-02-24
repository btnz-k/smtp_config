#!/bin/bash

# Script to automate DKIM configuration
#
# DKIM CONFIGURATION SCRIPT
# Wanna know how to use this? run -h!!
#
# Written by BTNZ
VERSION="1.0.2020.02.24"

# init vars
DOMAIN=""
ENABLE=0
DISABLE=0
INSTALL=0
VERBOSE=0

#file location vars
TRUSTEDHOSTS="/etc/opendkim/TrustedHosts"
KEYTABLE="/etc/opendkim/KeyTable"
SIGNINGTABLE="/etc/opendkim/SigningTable"
KEYSFOLDER="/etc/opendkim/keys"
POSTFIX_MAIN="/etc/postfix/main.cf"
OPENDKIM_CONF="/etc/opendkim.conf"
OPENDKIM_DEFAULT="/etc/default/opendkim"

# text colors
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

# Parse arguments
while getopts "D:hide?" option; do
        case "${option}"
                in
                D) DOMAIN=${OPTARG};;
                d) DISABLE=1;;
                e) ENABLE=1;;
                i) INSTALL=1;;
                h|\?) printf "%s\n" "   ______  ____________    _________  _  ______" "  / __/  |/  /_  __/ _ \  / ___/ __ \/ |/ / __/" " _\ \/ /|_/ / / / / ___/ / /__/ /_/ /    / _/" "/___/_/  /_/ /_/ /_/     \___/\____/_/|_/_/" "Written by BTNZ 2020" "$VERSION"
                    printf "\n"
                    printf "\t%s\n" "Usage:" "    -h, -?                  Display this help message" "    -D <domain.com>         Sets the domain to be configured." "    -e                      Modifies the postfix main.cf file to ENABLE DKIM." "    -d                      Modifies the postfix main.cf file to DISABLE DKIM."
                    printf "\t%s\n\n" "    -i                      Installs OpenDKIM and sets basic configurations."
                    printf "\t%s\n" "Example:" "$0 -D phish.com -e"
                    printf "\t\t%s\n" "This will configure DKIM with the domain phish.com( -D phish.com ), and will ensure the configuration settings"
                    printf "\t\t%s\n\n" "are correctly configured in the postfix and dkim configuration files."
                    printf "\t%s\n" "$0 -i"
                    printf "\t\t%s\n\n" "This will install OpenDKIM and set base configuration."
                    printf "\t%s\n" "$0 -d"
                    printf "\t\t%s\n\n" "This will comment out any DKIM configuration in the postfix main.cf file."
                    exit 0;;
        esac
done

# functions used
install_opendkim(){
    # checking for already installed
    printf "%s\n" " ${CYAN}[+]${NORMAL} Installation flag set. Checking to see if OpenDKIM is installed."
    if [ -z "$(command -v opendkim-genkey)" ]; then
        printf "%s\n" " ${CYAN}[+]${NORMAL} OpenDKIM missing, installing through apt-get."
        DEBIAN_FRONTEND=noninteractive apt-get install -yqq  opendkim opendkim-tools 2>&1 >> /dev/null
        # test to make sure install was successful, else quit
        if [ -z $(command -v opendkim-genkey) ]; then
            printf "%s\n" " ${RED}[!] ******************************** ERROR! ******************************** [!]${NORMAL}" " ${RED}[!]${NORMAL} Installation seems to have been unsuccessful. Please manually install" " ${RED}[!]${NORMAL} opendkim and opendkim-tools (sudo apt-get install opendkim openkdim-tools) and try again."
            printf "%s\n" " ${RED}[!] ******************************** ERROR! ******************************** [!]${NORMAL}"
            exit 1
        fi

        printf "%s\n" " ${CYAN}[+]${NORMAL} Pulling down base configurations for OpenDKIM."
        # copy default config to .old
        mv "$OPENDKIM_CONF" "$OPENDKIM_CONF.old" 2>/dev/null
        # Pull down configuration file gist for OpenDKIM
        wget -q -O "$OPENDKIM_CONF" https://gist.githubusercontent.com/btnz-k/6e9cd09312dd4a2c13014c3d1a616651/raw/2893186a7b29f00e5cbef4b6e34d53ed38bc7215/opendkim.conf

        # move default $OPENDKIM_DEFAULT to .old
        mv "$OPENDKIM_DEFAULT" "$OPENDKIM_DEFAULT.old"
        # Pull down configuration file gist for OpenDKIM
        wget -q -O "$OPENDKIM_DEFAULT" https://gist.githubusercontent.com/btnz-k/d419b863e9cc83bc717250920923c5b3/raw/5e6e1a8cb6aa390cfab6177a6e54123e80df97bc/etc_default_opendkim

        # make directory structure
        printf " ${CYAN}[+]${NORMAL} Creating OpenDKIM folders.\n"
        if [ ! -d "$KEYSFOLDER" ]; then
            mkdir -p "$KEYSFOLDER"
        fi

        # prepopulate TrustedHosts, KeyTable, and SigningTable with commented out defaults
        printf " ${CYAN}[+]${NORMAL} Importing base configurations for TrustedHosts, KeyTable, and SigningTable.\n"
        wget -q -O "$TRUSTEDHOSTS" https://gist.githubusercontent.com/btnz-k/f9cd276d06f6783c5d59bd2f29ed7fe8/raw/d5297a2631abeb5427a66cf4366290a0036024e3/opendkim_TrustedHosts
        wget -q -O "$KEYTABLE" https://gist.githubusercontent.com/btnz-k/5fe7ef9f458487b458a89bef613662b2/raw/4bb9ad9ac13fec2139ccaf86b97b8a4e9d1260b4/opendkim_KeyTable
        wget -q -O "$SIGNINGTABLE" https://gist.githubusercontent.com/btnz-k/3685cfe178812fcf60616b51c17306d9/raw/28927950f38bb0c49ba31cf5ee36b0780b837f47/opendkim_SigningTable
    else

        printf "%s\n" " ${RED}[!] ******************************** ERROR! ******************************** [!]${NORMAL}" " ${RED}[!]${NORMAL} OpenDKIM is already installed. If you wish to reinstall with baseline configs, please uninstall" " ${RED}[!]${NORMAL} opendkim manually and re-run this script with the -i option ( $0 -i )."
        printf "%s\n" " ${RED}[!] ******************************** ERROR! ******************************** [!]${NORMAL}"
        exit 1
    fi
    printf "%s\n" " ${CYAN}[+]${NORMAL} Installation Complete!"
}

enable_opendkim(){
    # add/uncomment the following lines to $POSTFIX_MAIN
    #milter_protocol = 2
    #milter_default_action = accept
    #smtpd_milters = inet:localhost:8892
    #non_smtpd_milters = inet:localhost:8892

    printf "%s\n" " ${CYAN}[+]${NORMAL} Enabling OpenDKIM configuration."
    # check to see if lines are present
    MILTERPRESENT=$(grep -F milter "$POSTFIX_MAIN")
    if [ ! -z "$MILTERPRESENT" ]; then
        # ensure lines are not commented out
        printf "%s\n" " ${CYAN}[+]${NORMAL} Configuration settings found, removing comment character."
        sed -i 's,^#milter_protocol = 2,milter_protocol = 2,g' "$POSTFIX_MAIN"
        sed -i 's,^#milter_default_action = accept,milter_default_action = accept,g' "$POSTFIX_MAIN"
        sed -i 's,^#smtpd_milters = inet:localhost:8892,smtpd_milters = inet:localhost:8892,g' "$POSTFIX_MAIN"
        sed -i 's,^#non_smtpd_milters = inet:localhost:8892,non_smtpd_milters = inet:localhost:8892,g' "$POSTFIX_MAIN"
    else
        # did not find lines w/ the word MILTER, append lines to end of config file
        printf "%s\n" " ${CYAN}[+]${NORMAL} No configuration settings found, adding settings to config file."
        echo "" >> "$POSTFIX_MAIN"
        echo "milter_protocol = 2" >> "$POSTFIX_MAIN"
        echo "milter_default_action = accept" >> "$POSTFIX_MAIN"
        echo "smtpd_milters = inet:localhost:8892" >> "$POSTFIX_MAIN"
        echo "non_smtpd_milters = inet:localhost:8892" >> "$POSTFIX_MAIN"
    fi

    printf "%s\n\n" " ${CYAN}[+]${NORMAL} OpenDKIM has been enabled!"
}

disable_opendkim(){
    # comment out these lines in $POSTFIX_MAIN
    #milter_protocol = 2
    #milter_default_action = accept
    #smtpd_milters = inet:localhost:8892
    #non_smtpd_milters = inet:localhost:8892

    # check to see if lines are present
    MILTERPRESENT=$(grep -F milter "$POSTFIX_MAIN")
    if [ ! -z "$MILTERPRESENT" ]; then
        printf "%s\n" " ${CYAN}[+]${NORMAL} Configuration settings found, adding comment character for applicable lines."
        # ensure lines are commented out
        sed -i 's,^milter_protocol = 2,#milter_protocol = 2,g' "$POSTFIX_MAIN"
        sed -i 's,^milter_default_action = accept,#milter_default_action = accept,g' "$POSTFIX_MAIN"
        sed -i 's,^smtpd_milters = inet:localhost:8892,#smtpd_milters = inet:localhost:8892,g' "$POSTFIX_MAIN"
        sed -i 's,^non_smtpd_milters = inet:localhost:8892,#non_smtpd_milters = inet:localhost:8892,g' "$POSTFIX_MAIN"
    fi
    printf "%s\n\n" " ${CYAN}[+]${NORMAL} OpenDKIM has been disabled."
}

domain_opendkim(){
    if [ ! -z "$DOMAIN" ]; then
        printf  "%s\n" " ${CYAN}[+]${NORMAL} Configuring OpenDKIM for domain $DOMAIN" " ${CYAN}[+]${NORMAL} Adding domain (mail.$DOMAIN) to postfix main.cf file for myhostname variable."

        # remove any commented out #myhostname lines
        sed -i '/^#myhostname/d' "$POSTFIX_MAIN"
        # change hostname line to match mail.domain.com
        sed -i "s/^myhostname =.*/myhostname = mail.$DOMAIN/" "$POSTFIX_MAIN"

        printf  "%s\n" " ${CYAN}[+]${NORMAL} Creating required folders at $KEYSFOLDER/$DOMAIN."
        # create folder for keys
        if [ ! -d "$KEYSFOLDER/$DOMAIN" ]; then
            mkdir -p "$KEYSFOLDER/$DOMAIN"
        fi
        printf  "%s\n" " ${CYAN}[+]${NORMAL} Adding $DOMAIN to TrustedHosts file."
        # ensure domain present in $TRUSTEDHOSTS
        if [ -z $(grep -i "^*.$DOMAIN" "$TRUSTEDHOSTS") ]; then
            echo "*.$DOMAIN" >> "$TRUSTEDHOSTS"
        fi
        printf  "%s\n" " ${CYAN}[+]${NORMAL} Adding $DOMAIN to KeyTable."
        # add keytable info to $KEYTABLE
        if [ -z $(grep -i "^mail._domainkey.$DOMAIN" "$KEYTABLE") ]; then
            # if key not found in table, add
            echo "mail._domainkey.$DOMAIN $DOMAIN:mail:$KEYSFOLDER/$DOMAIN/mail.private" >> "$KEYTABLE"
        fi
        printf  "%s\n" " ${CYAN}[+]${NORMAL} Adding $DOMAIN to SigningTable."
        # add signing table info to $SIGNINGTABLE
        if [ -z $(grep -i "^*@$DOMAIN " "$SIGNINGTABLE") ]; then
            echo "*@$DOMAIN mail._domainkey.$DOMAIN" >> "$SIGNINGTABLE"
        fi

        printf  "%s\n" " ${CYAN}[+]${NORMAL} Generating DKIM keys for $DOMAIN."
        # generate keys
        cd "$KEYSFOLDER/$DOMAIN"
        opendkim-genkey -s mail -d "$DOMAIN"
        chown opendkim:opendkim mail.private

        printf  "%s\n" " ${CYAN}[+]${NORMAL} Formatting DNS entry."
        # command to format mail.txt
        TEMPSTR=$(cat "$KEYSFOLDER/$DOMAIN/mail.txt" | tr -d '\n' | tr '()' ' '| tr -d '"' | tr '\t' ' ' | sed 's,  *, ,g' | cut -d';' -f1-4)
        HEAD=$(echo "$TEMPSTR" | cut -d";" -f1-3)
        TAIL=$(echo "$TEMPSTR" | cut -d";" -f4 | tr -d " ")
        DNSENTRYFULL=$(echo "$HEAD $TAIL")

        DNSENTRY_HOST=$(echo "$DNSENTRYFULL" | cut -d" " -f1)
        DNSENTRY_DATA=$(echo "$DNSENTRYFULL" | cut -d" " -f4-7)

        #display the DNS entry

        printf "%s\n" " ${GREEN}[*] ******************************** INFO ******************************** [*]${NORMAL}" " ${GREEN}[*]${NORMAL} Please add the following as a TXT record in DNS. " " ${GREEN}[*]${NORMAL}" " ${GREEN}[*]${NORMAL} Host:          $DNSENTRY_HOST" " ${GREEN}[*]${NORMAL} Domain:        $DOMAIN" " ${GREEN}[*]${NORMAL} Record Type:   TXT" " ${GREEN}[*]${NORMAL} Content:       $DNSENTRY_DATA"
        printf "%s\n" " ${GREEN}[*] ******************************** INFO ******************************** [*]${NORMAL}"

    else

        printf "%s\n" " ${RED}[!] ******************************** ERROR! ******************************** [!]${NORMAL}" " ${RED}[!]${NORMAL} DOMAIN has not been provided, and is required for this step. Please " " ${RED}[!]${NORMAL} re-run this script with the -D option include the domain ( $0 -D test.com)."
        printf "%s\n" " ${RED}[!] ******************************** ERROR! ******************************** [!]${NORMAL}"
        exit 1
    fi
}

#######################################
###### start main script process ######
#######################################

# Banner
printf "%s\n" "   ______  ____________    _________  _  ______" "  / __/  |/  /_  __/ _ \  / ___/ __ \/ |/ / __/" " _\ \/ /|_/ / / / / ___/ / /__/ /_/ /    / _/" "/___/_/  /_/ /_/ /_/     \___/\____/_/|_/_/" "Written by BTNZ 2020" "$VERSION" ""


# Check to see if user is root/sudo
if [ "$EUID" -ne 0 ]; then
    printf "%s\n" " ${RED}[!] ******************************** ERROR! ******************************** [!]${NORMAL}" " ${RED}[!]${NORMAL} This script changes system configuration files, and must be run as root or with sudo."
    printf "%s\n" " ${RED}[!] ******************************** ERROR! ******************************** [!]${NORMAL}"
    exit 1
fi


# checking for install flag
if [ "$INSTALL" -eq "1" ]; then
    # run install/enable commands
    install_opendkim
    # PostInstall Note
    printf "%s\n" " ${CYAN}[+]${NORMAL} Checking other flags."
    # check other flags for processing
    if [ "$ENABLE" -eq 1 ]; then enable_opendkim; fi
    if [ "$DISABLE" -eq 1 ]; then disable_opendkim; fi
    if [ ! -z "$DOMAIN" ]; then domain_opendkim; fi
    systemctl restart postfix
    systemctl restart opendkim
    # PostAllNote
    printf "%s\n\n" " ${CYAN}[+]${NORMAL} Tasks complete. Happy phishing!"
    exit 0
fi

# Check to see if opendkim is installed
if [ -z "$(command -v opendkim-genkey)" ]; then
    printf "%s\n" " ${RED}[!] ******************************** ERROR! ******************************** [!]${NORMAL}" " ${RED}[!]${NORMAL} OpenDKIM is required to run this script!"  " ${RED}[!]${NORMAL} Rerun this script ( $0 -i ) to install and configure OpenDKIM."
    printf "%s\n" " ${RED}[!] ******************************** ERROR! ******************************** [!]${NORMAL}"
    exit 1
fi

if [ ! -z "$DOMAIN" ]; then domain_opendkim; systemctl restart postfix; systemctl restart opendkim; fi
if [ "$ENABLE" -eq 1 ]; then enable_opendkim; systemctl restart postfix; systemctl restart opendkim; fi
if [ "$DISABLE" -eq 1 ]; then disable_opendkim; systemctl restart postfix; systemctl restart opendkim; fi
