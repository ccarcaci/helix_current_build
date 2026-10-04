ARG BASE_IMAGE=aclemons/slackware:15.0
# The stage name ends up in every build cache record description
# ("[helix-current-builder n/m] ..."): `make uninstall` prunes by it.
FROM ${BASE_IMAGE} AS helix-current-builder

# Runtime libs of the toolchain: flex (libfl, ar/ranlib), elfutils (libdebuginfod, objdump), guile + gc (make).
# To find more: docker run --rm helix-current-builder sh -c 'ldd /usr/bin/* 2>/dev/null | grep "not found"'
# upgrade-all applies Slackware 15.0 /patches (current ca-certificates and openssl among them).
# slackpkg exit codes (man slackpkg): 20 = nothing to do (not an error),
# 50 = slackpkg upgraded itself and must be re-run, hence the self-upgrade first.
RUN set -e; \
    sp() { slackpkg -batch=on -default_answer=y "$@" || { rc=$?; [ $rc -eq 20 ] || return $rc; }; }; \
    sp update; \
    sp upgrade slackpkg || [ $? -eq 50 ]; \
    sp update; \
    sp upgrade-all; \
    sp install \
      git curl ca-certificates perl openssl nghttp2 brotli libssh2 libpsl libidn2 libunistring \
      cyrus-sasl openldap krb5 \
      gcc gcc-g++ binutils glibc kernel-headers make gmp mpfr libmpc isl zstd \
      flex elfutils guile gc; \
    # The package's doinst.sh leaves no bundle/hash links here, so TLS verification fails without this.
    update-ca-certificates --fresh

ARG RUST_TOOLCHAIN=1.90.0
ENV PATH=/root/.cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 --silent --show-error --fail https://sh.rustup.rs \
  | sh -s -- -y --profile minimal --default-toolchain "$RUST_TOOLCHAIN"

COPY helix-current.SlackBuild slack-desc /build/
CMD ["bash", "/build/helix-current.SlackBuild"]
