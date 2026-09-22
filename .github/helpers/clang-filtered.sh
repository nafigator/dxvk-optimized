#!/bin/bash

args=()

for arg in "$@"; do
	case "$arg" in
		-Wl,--allow-shlib-undefined|--allow-shlib-undefined) ;;
		*) args+=("$arg") ;;
	esac
done

exec clang "${args[@]}"
