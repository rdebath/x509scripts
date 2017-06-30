The mk-cert program
===================

The `mk-cert` program is used to make private keys, certificates and
certificate requests. To "make a certificate" all you have to do is run
the script, it will allow openssl to prompt you for the name to put on
the certificate and create a small but secure key and certificate on
the standard output ready to copy & paste to where you need them.

If instead you give the script a non-option (without a hyphen) argument
this will be used as the "commonName". Addition arguments will be used
as SAN entries if they look kinda like DNS names or IP addresses and
"organizationalUnitName" field values otherwise.

The default period for the certificate is 20 years, if this is not right
for you the `-days=365` option allows you to choose any period you wish,
or the `-alldays` option increases the period to the maximum possible.

Some applications don't understand the default "Elliptic curve" keys
that this generates so the `-rsa` option switches to the traditional
"RSA" style keys. Adding an argument to the option `-rsa:4096` allows
you to choose a specific size for this key.

RSA keys are somewhat larger than their "EC" equivalents so you will
probably want to write the output to a file with `-out=Filename`. If you
want the key in a separate file the `-keyout=KeyFilename` will do that.

Some applications may require a few of the many other possible items to
be added to the "subject" of the certificate. The more usual ones are:
`-subj-cn=String`, `-subj-ou=String`, `-subj-dc=String`, `-subj-o=String`,
`-subj-l=String`, `-subj-st=String`, `-subj-c=String`. Others can be
added by options like `-subj=favouriteDrink=Whisky` or even by using an
"OID" number directly... `-subj:2.16.840.1.113883.19.5.1091='malty brew
with a slight caramel sweetness'`.

Without additional prompting a "Version 1" certificate is created, this
is a simple and secure type of certificate, but some applications insist
that extensions be added (which converts the certificate to "Version 3").

The most useful extension is probably the "Subject Alternative Name"
or SAN which web browsers use to specify multiple common names (instead
of, you know, specifing multiple common names).  Just adding `-san` adds
an entry for the common name. If you specify an argument to the option
like `-san=testhost.xy` this will be added and another name to the san
list. Inserting a tag identifier `-san=DNS:example.com` specifies the
type of this SAN entry. You can add as many as you need.

BEWARE: Chrome requires the SAN or it will give a "Common name invalid"
error even if the common name is perfectly correct and legal on it's own.

Any extension can be added by using the `-v3=something` and the
`-v3xt=something` options, but those are really difficult to use.

Much easier are the options `-server`, `-client` and `-email`. Any
combination of these options can be added and the certificate will be
constructed to allow those usages and deny others.

The problem with this is that an application that insists on this
sort of configuration is likely to also be unhappy with a self-signed
certificate. The simplest and most secure solution to this problem is
the "Single use CA" (option `-singleuseca` or `-suca`).

This option instructs the script to create two certificates with different
keys, the first is a "CA certificate". It's key used to sign the second
certificate and then discarded. It's certificate is output normally (and
can be saved in it's own file using the `-caout=filename` option). The
second certificate is limited to non-CA usage and it and it's key are
output. The CA certificate should be put into the trusted store at one
end of the link and the non-CA certificate and it's key are used at the
other end. This it usually sufficient for any application.

Except; occasionally an application will insist that a CRL be
available... the `-crlout=filename` option will create an empty, signed
"certificate revocation list" just before discarding the CA key to placate
these applications. The application may also need a "CRL Distribution
Point" extension with the URL it can download the CRL from, the option
`-crlurl=http://example.com/path/file.crl` does this.

Many of these options can be used when creating a CSR (or "Certificate
signing request") just choose the options as normal and add `-csr` to
the end. Note when making a CSR I would strongly suggest you always put
the key in a separate file; you don't want to be sending it to the CA
by accident after all.

If you want to use a long term CA certificate then `-v3ca` option
will give it the extensions expected for a certificate and the
`-sign=ca-file.pem` will use it to sign a certificate. The `-csrin=file`
can also be added in this case if you need to make a certificate based
on a CSR rather than creating the key and certificate together. Beware,
however, that this script can only create an empty CRL, if you ever need
to create an actually useful CRL you'll have to do it separately.

If you're creating files for Windows you'll need the `-pfx=file.pfx`
option to create a file that Windows can load the private key from. It's
default password is empty (leave the fields on the import wizard blank)
but `-pass=123456` or `-pass=[openssl_passphrase_option]` can be used
to change this.

There are other options; use the `-help` option for details.

