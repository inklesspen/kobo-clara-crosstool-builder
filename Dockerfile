# docker buildx build --platform=linux/arm64 . --output type=local,dest=.
FROM --platform=$TARGETPLATFORM debian:bookworm as build-stage

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -qqy gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
    python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
    patch libstdc++6 rsync git meson ninja-build && rm -rf /var/lib/apt/lists

RUN mkdir -p /tc/tc-src /tc/tc-cache

ENV HOME=/tc

ADD http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.26.0.tar.xz /tc/

RUN cd /tc && tar xf crosstool-ng-1.26.0.tar.xz && rm crosstool-ng-1.26.0.tar.xz && cd crosstool-ng-1.26.0 && \
    ./configure --prefix=/tc/ct-ng && make && make install

COPY ct-ng-config.txt /tc/tc-src/.config
RUN /tc/ct-ng/bin/ct-ng -C /tc/tc-src updatetools && /tc/ct-ng/bin/ct-ng -C /tc/tc-src build CT_ONLY_DOWNLOAD=y

RUN /tc/ct-ng/bin/ct-ng -C /tc/tc-src build CT_FORBID_DOWNLOAD=y && rm -rf /tc/tc-src

# fix permissions
RUN chmod -R u=rwX,go=rX /tc/x-tools/arm-kobo-linux-gnueabihf

# remove libtool la files, which are useless after the initial tc compilation
# and are impossible to relocate properly
RUN find /tc/x-tools/arm-kobo-linux-gnueabihf -name '*.la' -delete

# fix ldscripts search dir prefixes (also messed up by the fact that DESTDIR was
# included in the prefix)
# note: the '=' is replaced by the sysroot, which is
#       tc_path/arm-kobo-linux-gnueabihf/sysroot (see the tests below)
RUN find /tc/x-tools/arm-kobo-linux-gnueabihf/lib/ldscripts -name '*.x*' -exec sed -i 's:=/tc/x-tools/arm-kobo-linux-gnueabihf/arm-kobo-linux-gnueabihf/lib:=/../lib:g' {} + && \
    find /tc/x-tools/arm-kobo-linux-gnueabihf/lib/ldscripts -name '*.x*' -exec sed -i 's:=/tc/x-tools/arm-kobo-linux-gnueabihf/arm-kobo-linux-gnueabihf/sysroot:=:g' {} +

RUN mkdir /export && cd /export && cp -a /tc/x-tools/arm-kobo-linux-gnueabihf . && tar cf arm-kobo-linux-gnueabihf.tar arm-kobo-linux-gnueabihf

FROM scratch AS export-stage
COPY --from=build-stage /export/arm-kobo-linux-gnueabihf.tar /
