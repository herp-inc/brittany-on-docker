FROM fpco/stack-build

# setup build environment
RUN echo "build: { split-objs: true }" >> /etc/stack/config.yaml
RUN stack update
ENV DEBIAN_FRONTENV=noninteractive
RUN apt-get update
RUN apt-get install -y patchelf

# prepare source
ARG TARBALL
WORKDIR /usr/src/brittany
ADD ${TARBALL} source.tgz
RUN tar --strip-components=1 -xf source.tgz

# patch source
ARG PATCH=""
RUN echo -n "${PATCH}" | patch -u

# build
RUN stack install --local-bin-path /usr/bin --ghc-options="-optc-Os"

# bundle runtime dependencies
RUN ldd "$(which brittany)" \
      | awk -F'=>' '{print $2}' \
      | sed 's/(.*)//' \
      | awk '{$1=$1};1' \
      | { cat; patchelf --print-interpreter "$(which brittany)"; } \
      | xargs -L1 -I{} bash -c "echo {}; readlink -f {};" \
      | xargs tar cf /bundle.tar.gz \
          "$(which brittany)" \
          /opt/ghc/*/lib/ghc-*/settings \
          /opt/ghc/*/lib/ghc-*/platformConstants \
          /opt/ghc/*/lib/ghc-*/llvm-passes \
          /opt/ghc/*/lib/ghc-*/llvm-targets \
          /opt/ghc/*/lib/ghc-*/package.conf.d

# copy
FROM scratch
COPY --from=0 /bundle.tar.gz /tmp/bundle.tar.gz
COPY ./busybox /busybox
RUN ["/busybox", "sh", "-c", "/busybox tar xf /tmp/bundle.tar.gz -C / && /busybox rm /tmp/bundle.tar.gz /busybox"]

WORKDIR /work
CMD ["/usr/bin/brittany"]
