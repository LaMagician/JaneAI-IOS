#!/bin/sh
# Model boundary. A configured runtime may replace the offline deterministic backend.
backend_runtime_available() {
    [ -n "${JANE_MODEL_RUNTIME:-}" ] || return 1
    [ -x "$JANE_MODEL_RUNTIME" ] || command -v "$JANE_MODEL_RUNTIME" >/dev/null 2>&1
}

backend_name() {
    if [ -n "${JANE_MODEL_COMMAND:-}" ]; then
        echo external-command
    elif backend_runtime_available && [ -s "${JANE_MODEL_FILE:-}" ]; then
        echo "local-quantized-${JANE_MODEL_PROFILE:-LOW}"
    else
        echo deterministic
    fi
}

backend_respond() {
    if [ -n "${JANE_MODEL_COMMAND:-}" ]; then
        printf '%s\n' "$1" | sh -c "$JANE_MODEL_COMMAND"
        return
    fi
    if backend_runtime_available && [ -s "${JANE_MODEL_FILE:-}" ]; then
        "$JANE_MODEL_RUNTIME" -m "$JANE_MODEL_FILE" -t "${JANE_MODEL_THREADS:-1}" \
            -c "${JANE_CONTEXT_TOKENS:-2048}" -n "${JANE_MODEL_MAX_TOKENS:-256}" \
            -p "$1"
        return
    fi
    return 1
}