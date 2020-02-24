SMTP CONF

Written by BTNZ 2020

1.0.2020.02.24

        Usage:
            -h, -?                  Display this help message
            -D <domain.com>         Sets the domain to be configured.
            -e                      Modifies the postfix main.cf file to ENABLE DKIM.
            -d                      Modifies the postfix main.cf file to DISABLE DKIM.
            -i                      Installs OpenDKIM and sets basic configurations.

        Example:
        ./smtp_config.sh -D phish.com -e
                This will configure DKIM with the domain phish.com( -D phish.com ), and will ensure the configuration settings
                are correctly configured in the postfix and dkim configuration files.

        ./smtp_config.sh -i
                This will install OpenDKIM and set base configuration.

        ./smtp_config.sh -d
                This will comment out any DKIM configuration in the postfix main.cf file.

Todo:

* validate user input for domain
* validate postfix/opendkim configurations
* extend to provide dmarc TXT record
* enhance enable/disable functions to ensure all 4 configuration lines are present
* verify at least one myhostname is present and uncommented in postfix/main.cf
* check for postfix installation as a pre-flight check
