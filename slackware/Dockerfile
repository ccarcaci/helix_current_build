ARG BASE_IMAGE=aclemons/slackware:15.0
# The stage name ends up in every build cache record description
# ("[helix-current-builder n/m] ..."): `make uninstall` prunes by it.
FROM ${BASE_IMAGE} AS helix-current-builder

# ponytail: list guessed from Slackware 15.0 package names; extend if the build reports a missing tool/lib.
# upgrade-all applies Slackware 15.0 /patches (current ca-certificates and openssl among them).
RUN slackpkg -batch=on -default_answer=y update \
 && slackpkg -batch=on -default_answer=y upgrade-all \
 && slackpkg -batch=on -default_answer=y install \
      git curl ca-certificates perl openssl nghttp2 brotli libssh2 libpsl libidn2 libunistring \
      cyrus-sasl openldap krb5 \
      gcc gcc-g++ binutils glibc kernel-headers make gmp mpfr libmpc isl zstd

ARG RUST_TOOLCHAIN=1.90.0
ENV PATH=/root/.cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 --silent --show-error --fail https://sh.rustup.rs \
  | sh -s -- -y --profile minimal --default-toolchain "$RUST_TOOLCHAIN"

COPY helix-current.SlackBuild slack-desc /build/
CMD ["bash", "/build/helix-current.SlackBuild"]
