#!/usr/bin/env bash

version_file="$ROOT_DIR/VERSION"

current_app_version() {
    if [[ -f "$version_file" ]]; then
        tr -d '[:space:]' < "$version_file"
    else
        printf "1.0"
    fi
}

next_app_version() {
    local version="${1:-$(current_app_version)}"
    awk -F. '
        {
            major = $1 + 0
            minor = $2 + 1
            if (minor >= 10) {
                major += int(minor / 10)
                minor = minor % 10
            }
            printf "%d.%d", major, minor
        }
    ' <<< "$version"
}

app_build_number() {
    local version="${1:-$(current_app_version)}"
    awk -F. '{ printf "%d", (($1 + 0) * 10) + ($2 + 0) }' <<< "$version"
}

set_app_version() {
    printf "%s\n" "$1" > "$version_file"
}
