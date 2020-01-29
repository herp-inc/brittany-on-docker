ARG STACK_IMAGE
FROM ${STACK_IMAGE}

# setup build environment
SHELL ["/bin/bash", "-c"]

ADD https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 /usr/bin/yq
RUN chmod +x /usr/bin/yq

# prepare source
ARG TARBALL
WORKDIR /usr/src/brittany
ADD ${TARBALL} source.tgz
RUN tar --strip-components=1 -xf source.tgz

# prepare stack
RUN mkdir -p /etc/stack
RUN [ -f /etc/stack/config.yaml ] || echo "{}" > /etc/stack/config.yaml
RUN yq merge -i -a /etc/stack/config.yaml - <<< "{ recommend-stack-upgrade: false, system-ghc: true }"
RUN stack update > /dev/null 2>&1

# patch source
ARG PATCH_FILE
COPY $PATCH_FILE /tmp/fix.patch
RUN patch -u < /tmp/fix.patch
RUN yq merge -i -a stack.yaml - <<< "drop-packages: [ Cabal ]"

# build
ARG INSTALL_DIR=/usr/bin
RUN stack install --local-bin-path "${INSTALL_DIR}" --ghc-options="-optc-Os -j"

# prepare for compression
WORKDIR /tmp
ADD https://github.com/upx/upx/releases/download/v3.95/upx-3.95-amd64_linux.tar.xz upx.tar.xz
RUN tar --strip-components=1 -xf upx.tar.xz && mv upx /usr/bin/

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
# locale files
      echo '/usr/lib/locale/C.UTF-8'; \
# workaround for 'createDirectory: does not exist' error in 0.9.0.0
      mkdir -p /.config/brittany && echo "/.config/brittany"; \
    } | xargs -I{} bash -c "echo {}; readlink -f {};" \
      | xargs -I{} cp -r --parents {} .

# copy
FROM scratch
COPY --from=0 /closure/ /.

# workaround for 'invalid byte sequence' error caused by reading multibyte characters
ENV LANG=C.UTF-8

WORKDIR /work
CMD ["${INSTALL_DIR}/brittany"]
