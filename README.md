MiniPKI is a set of small shell scripts to tame OpenSSL and hide its niggling
behaviour in order to create a state of the art certificate authority.

It imposes the following hierarchy:
Root CA:    C=Country, O=Organisation
Sub CA:     C=Country, O=Organisation, OU=Organization Unit
Sub-sub CA: C=Country, O=Organisation, OU=Organization Unit, OU=Type
    where Type = <Server|Client|UserAuth|UserMail>
Leaf cert:  C=Country, O=Organisation, OU=Organization Unit, OU=Type, CN=Subject

For leaf certificates, an alternate subject is required as well (FQDN for
Server/Client certificates, mail address for user auth or user mail
certificates).



Usage is simple, create the root certificate first, then the sub CA, then
the sub-sub CA and finally leaf certificates.

Example:
./mk_root_CA.sh -f $((365*10)) FR Example
./mk_subCA.sh $((365*10)) FR Example Mail
./mk_subsubCA.sh $((365*5)) FR Example Mail Server
./mk_leaf_cert.sh $((365*2)) FR Example Mail Server MX1
./mk_leaf_cert.sh $((365*2)) FR Example Mail Server MX2
./mk_subsubCA.sh $((365*5)) FR Example Mail UserMail
./mk_leaf_cert.sh $((365*2)) FR Example Mail UserMail jeremie jeremie@example.com
