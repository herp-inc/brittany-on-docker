FROM fpco/stack-build

# setup build environment
RUN echo "build: { split-objs: true }" >> /etc/stack/config.yaml
RUN stack update

WORKDIR /tmp
ADD https://github.com/upx/upx/releases/download/v3.95/upx-3.95-amd64_linux.tar.xz upx.tar.xz
RUN tar --strip-components=1 -xf upx.tar.xz && mv upx /usr/bin/

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
ARG INSTALL_DIR=/usr/bin
RUN stack install --local-bin-path "${INSTALL_DIR}" --ghc-options="-optc-Os"

# compress executable
RUN cp "${INSTALL_DIR}/brittany" /tmp/brittany_copy
RUN upx -q -9 --brute "${INSTALL_DIR}/brittany"

# collect runtime dependencies
WORKDIR /closure
RUN { \
# brittany itself
      echo "${INSTALL_DIR}/brittany"; \
# interpreter
      readelf -l /tmp/brittany_copy \
        | grep "program interpreter" \
        | sed -e 's/^.*: \(.*\)\]$/\1/'; \
# dynamically linked libraries
      ldd /tmp/brittany_copy \
        | awk -F'=>' '{print $2}' \
        | sed -e 's/(.*)//' -e '/^\s*$/d' \
        | awk '{$1=$1};1'; \
# ghc-related files
      find / \
        \( -path '/opt/ghc/*/lib/ghc-*/*' \
        -o -path '/root/.stack/programs/x86_64-linux/ghc-*/lib/ghc-*/*' \) \
        -a \
        \( -name settings \
        -o -name platformConstants \
        -o -name llvm-passes \
        -o -name llvm-targets \
        -o -name package.conf.d \); \
# workaround for 'createDirectory: does not exist' error in 0.9.0.0
      mkdir -p /.config/brittany && echo "/.config/brittany"; \
    } | xargs -I{} bash -c "echo {}; readlink -f {};" \
      | xargs -I{} cp -r --parents {} .

# copy
FROM scratch
COPY --from=0 /bundle.tar.gz /tmp/bundle.tar.gz
ARG BUSYBOX_PATH
COPY ${BUSYBOX_PATH} /busybox
RUN ["/busybox", "sh", "-c", "/busybox tar xf /tmp/bundle.tar.gz -C / && /busybox rm /tmp/bundle.tar.gz /busybox"]

WORKDIR /work
CMD ["/usr/bin/brittany"]
