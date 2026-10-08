#!/bin/bash
# Lists the commits between the installed hx_current and the commit packaged
# by the latest `make build` (newest ./out package). With no new commits it
# lists the last month of history up to that commit instead.
# Env: REPO, REF (same meaning as in the Makefile), OUT (package directory).
# The build checkout is shallow (--depth 1), so history comes from a blobless
# bare clone cached on the host: commits and trees only, no file contents.

set -o errexit -o nounset -o pipefail

REPO=${REPO:-git@github.com:helix-editor/helix.git}
REF=${REF:-master}
OUT=${OUT:-$(cd "$(dirname "$0")" && pwd)/out}
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/helix-current/$(echo "$REPO" | tr --complement '[:alnum:]' _).git
FORMAT='%h %ad %<(20,trunc)%an %s'

# "helix 25.07.1 (ba40e547)" -> ba40e547
INSTALLED=$(hx_current --version | sed --quiet 's/.*(\([0-9a-f]\+\)).*/\1/p')
[ -n "$INSTALLED" ] || { echo "Cannot read the commit from hx_current --version" >&2; exit 1; }

# helix-current-20261008.ba40e54-x86_64-1_cc.txz -> ba40e54
PACKAGE=$(ls --sort=time "$OUT"/helix-current-*.txz 2>/dev/null | head --lines=1)
[ -n "$PACKAGE" ] || { echo "No package in $OUT: run make build first" >&2; exit 1; }
BUILT=$(basename "$PACKAGE" | sed --quiet 's/^helix-current-[0-9]\{8\}\.\([0-9a-f]\+\)-.*/\1/p')

# Public GitHub repos need no keys: fetch git@github.com: URLs over anonymous https.
git_() { git -c url."https://github.com/".insteadOf=git@github.com: "$@"; }
if [ -d "$CACHE" ]; then
  git_ -C "$CACHE" fetch --quiet origin "$REF"
else
  git_ clone --quiet --bare --filter=blob:none --single-branch --branch "$REF" "$REPO" "$CACHE"
fi

commit() {
  git -C "$CACHE" rev-parse --quiet --verify "$1^{commit}" \
    || { echo "Commit $1 not found on $REPO $REF" >&2; exit 1; }
}
INSTALLED=$(commit "$INSTALLED")
BUILT=$(commit "$BUILT")

echo "Installed: $(git -C "$CACHE" log -1 --format='%h %ad' --date=short "$INSTALLED")"
echo "Built:     $(git -C "$CACHE" log -1 --format='%h %ad' --date=short "$BUILT") ($(basename "$PACKAGE"))"
echo

if [ -n "$(git -C "$CACHE" rev-list "$INSTALLED..$BUILT")" ]; then
  echo "Changes $INSTALLED..$BUILT:"
  git -C "$CACHE" log --date=short --format="$FORMAT" "$INSTALLED..$BUILT"
else
  echo "No changes between installed and built. Last month up to $(git -C "$CACHE" rev-parse --short "$BUILT"):"
  git -C "$CACHE" log --date=short --format="$FORMAT" --since='1 month ago' "$BUILT"
fi
