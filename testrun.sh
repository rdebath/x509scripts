#!/bin/sh -
if [ -z "$BASH_VERSION" ];then exec bash "$0" "$@";else set +o posix;fi

if [ "$(dirname "$0")" = . ]
then export PATH="$(pwd):$PATH"
else export PATH="$(dirname "$0"):$PATH"
fi

make_certs() {
    mkdir -p certs

    mk-cert ss-host > certs/default-host.pem
    mk-cert -ca ss-ca > certs/default-ca.pem
    mk-cert -lastca ss-lastca > certs/default-lastca.pem
    mk-cert -suca suca-host suca-host.local localhost > certs/default-suca.pem
    mk-cert -dv dv-host dv-host.local localhost > certs/default-dv.pem

    mk-cert -san -suca -pubin=certs/default-host.pem \
	suca-san-duphost.local suca-san-duphost localhost > certs/default-host-dup.pem

    mk-cert -v3ca -lastca -out=certs/v3-lastca.pem 'Private CA'
    mk-cert server-host1.local -server -out=certs/v3-server-host1.pem -sign=certs/v3-lastca.pem
    mk-cert server-host2.local -server -out=certs/v3-server-host2.pem -sign=certs/v3-lastca.pem
    mk-cert server-host3.local -server -out=certs/v3-server-host3.pem -sign=certs/v3-lastca.pem
    mk-cert client-host1.local -client -out=certs/v3-client-host1.pem -sign=certs/v3-lastca.pem

    mk-cert -suca -ed25519 \
	suca-ed25519.local ed25519 localhost > certs/suca-curve25519-Edwards.pem

    mk-cert -suca -ec=x25519 \
	suca-x25519.local x25519 localhost > certs/suca-curve25519-Montgomery.pem

}

mktestsets() {

    # ft() { faketime -f '1999-01-01 12:00:00' "$@" ; }
    # DAYS=-days=$((24842 - $(ft date +%s)/86400))

    ft() { "$@" ; }
    DAYS=-days=3652

    CA1K=$(ft mk-cert -rsa:1024 -sha1 -v3basicca -dnq "$DAYS" \
	    "hostmaster@$DOM" -subj-o="Above reproach CA" )

    CA2K=$(ft mk-cert -rsa:2048 -sha256 -v3basicca -dnq "$DAYS" \
	    "hostmaster@$DOM" -subj-o="Above reproach CA" )

    run_cert "$CA1K" -ec > ca1k-${CN}.ec.1k.pem
    run_cert "$CA1K" -sha1 -rsa:1024 > ca1k-${CN}.rsa.1k.pem
    run_cert "$CA1K" -sha1 -dsa:1024 > ca1k-${CN}.dsa.1k.pem

    run_cert "$CA2K" -ec > ca2k-${CN}.ec.2k.pem
    run_cert "$CA2K" -sha256 -rsa:2048 > ca2k-${CN}.rsa.2k.pem
    run_cert "$CA2K" -sha256 -dsa:2048 > ca2k-${CN}.dsa.2k.pem

    [ -f dhparam-2k.pem ] ||
	openssl dhparam 2048 > dhparam-2k.pem

    [ -f dhparam-1k.pem ] ||
	openssl dhparam 1024 > dhparam-1k.pem

    # IE6 keys
    # DH parameter can be 2048 if TLS1.0 is DISabled,
    # BUT only 1024 if TLS1.0 is ENabled.
    cat ca1k-${CN}.dsa.1k.pem dhparam-1k.pem > ca1k-${CN}.dsa.tls1.1k.pem
    cat ca1k-${CN}.dsa.1k.pem dhparam-2k.pem > ca1k-${CN}.dsa.ssl3.1k+2k.pem

    # Later DHE-DSS
    cat ca2k-${CN}.dsa.2k.pem dhparam-2k.pem > ca2k-${CN}.dsa.dhe.2k.pem

    {
	ft mk-cert \
	    -suca -rsa:1024 -sha1 \
	    $DAYS \
	    -subj-cn=tvisiontech.co.uk \
	    -subj-ou='SSLv2 Certificate' \
	    -casubj='SSLv2 CA' \
	    -san="$CN" \
	    -san="$DOM" \
	    -san='*.'"$DOM"

	std_dhparam;
    }> suca-${CN}.dsa.ssl2.1k.pem

# Only for DHE-RSA
#   cat ca1k-${CN}.rsa.1k.pem dhparams-1k.pem > ca1k-${CN}.rsa.mixed.1k.pem
#   cat ca2k-${CN}.rsa.2k.pem dhparams-2k.pem > ca2k-${CN}.rsa.mixed.2k.pem

}

run_cert() {
    CA="$1"
    shift
    ft mk-cert \
        -v3user -nokeyid \
        "$DAYS" \
        -sign=<(echo "$CA") \
        -addcert=<(echo "$CA") \
        -cn="$CN" \
        -san="$SANHOSTS" \
        "$@"
}

std_dhparam() {
cat <<\!
-----BEGIN DH PARAMETERS-----
MIGHAoGBALu8LcrYRnSQfEP89YDpz9vZWKP1aLQtSwju1OsPs1BMbAMCducQgAxc
y7qokiYUxb7spWWl/fHSh6K8BJvmd4Bg6RqSp1fjBI9osHb302zI8pul34HcLKcl
7OZicMyaUDXYzs7vnqAnSmOrHlj6/UmI0PZdFGdX2gcd8EXP4WubAgEC
-----END DH PARAMETERS-----
!
}

example_dhparam() {

[ -f dhparam-1k.pem ] || cat > dhparam-1k.pem <<\!
-----BEGIN DH PARAMETERS-----
MIGHAoGBANivd72m35sC+gpcOhBl0ohkI29eQEpgwhUslAF1YJ68A7lzaJHtkRut
d7gGx48sRq9m2M/upexh8eMBf6T5U4LVmI5WCAwRcHFDkyws6COny1m+8h4mkdAR
zUaFF64r997JILnTZmdFKb2eydk86byw2DZ3iGpT1sBNivT8tDEjAgEC
-----END DH PARAMETERS-----
!

[ -f dhparam-2k.pem ] || cat > dhparam-2k.pem <<\!
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAqrIS6rUaTYkO6+0p9bRIduBvrK0Kmn3QpUIJjlWXu4SO/SJKKrdu
tWZ3A0enTI83R5YTC9TJc5a6iusT+ymzbDmyVLmNDPIEdCplhjb9/B6P99uI8SKV
Wj/Hjc3pgKySpy+l5vZ3Ad28i1KMuCPqq8AHPXnBHkaw7xDSNuLOc7RjtFTcyB9z
hRDuVbClYOrIFws6J7OB4sA23BeumlLkiWsW+OebWD83k5GlOgLIjxCpqveyfBxi
vuoWTT8Ptsh19uWA8m54agKiQK6qMlbLGao+kWUqN9T622wjyK73PH89e+yccuVP
P09VLZTn7AWSMipcbd5if/4YqExx+taIYwIBAg==
-----END DH PARAMETERS-----
!

}

main() {
    rm -rf certs

    echo Making certificates
    make_certs

    echo Making certificate set
    CN=localhost ; X1=tvision ; X2=tech ; X3=tvt ; X4=co.uk
    DOM=$X1$X2.$X4
    SANHOSTS="DNS:$X1$X2.$X4, DNS:*.$X1$X2.$X4, DNS:*.$X3.local, DNS:$X1.tk, DNS:$X1.$X2"

    ( cd certs ; example_dhparam ; mktestsets )

    echo Scanning certificates

    whatssl certs/*.pem > certs/res-new.txt

    echo Filtering hex codes

    sed < certs/res-new.txt \
	-e 's/Not Before: ... .*/Not Before: .../' \
	-e 's/Not After : ... .*/Not After : .../' \
	-e 's/dnQualifier=[0-9a-fA-F]*/dnQualifier=.../' \
	|
    awk '/:[0-9a-fA-F][0-9a-fA-F]/ {
	s = $0

	for(i=0;i<2;i++) {
	    if (i==0) {
		m = "[0-9a-fA-F][0-9a-fA-F]";
		m = m ":" m ":" m ":" m "(:" m ")*";
		d=3;c=1;
	    } else {
		m = "[0-9a-fA-F][0-9a-fA-F]";
		m = "DER:" m "(" m ")*";
		d=2;c=-4;
	    }
	    while (match(s, m)) {
		v = substr(s, RSTART, RLENGTH)
		if (v in keys) {
		    v = keys[v];
		} else {
		    keys[v] = "IDTXT/" (++idnum) "/" ((RLENGTH+c)/d*8);
		    v = keys[v];
		}

		s = substr(s, 1, RSTART-1) v substr(str, RSTART+1)
	    }
	}

	print s;
	next;
    }
    /^Contents/ { delete keys; idnum = 0; }
    {print;}
    '

    echo Done
}

main
