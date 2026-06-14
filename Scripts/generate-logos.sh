#!/bin/sh

set -eu

ROOT="${SRCROOT:-$(pwd)}"
INPUT="${ROOT}/Tweak/Tweak.x"
OUTPUT="${ROOT}/Tweak/Tweak.mm"
THEOS_ROOT="${MonkeyDevTheosPath:-${THEOS:-/opt/theos}}"
LOGOS="${THEOS_ROOT}/bin/logos.pl"
TEMP="${OUTPUT}.tmp"

if [ ! -x "${LOGOS}" ]; then
    echo "error: Logos compiler not found at ${LOGOS}" >&2
    exit 1
fi

cd "${ROOT}"
"${LOGOS}" "Tweak/Tweak.x" | sed -E 's/[[:space:]]+$//' > "${TEMP}"

if [ -f "${OUTPUT}" ] && cmp -s "${TEMP}" "${OUTPUT}"; then
    rm -f "${TEMP}"
else
    mv -f "${TEMP}" "${OUTPUT}"
fi
