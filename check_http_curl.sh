#!/bin/bash
#
# check_http_curl.sh
#
# Version: 3.0
# Author: Nitatemic
# Review: Gemini & Claude AI collaboration
#
# v3 Improvements:
# - Use of BASH ARRAYS to prevent argument injection
# - Strict hostname validation (sanitization)
# - Literal text search mode (grep -F)
# - Cleaner SSL options management

# --- Nagios Constants ---
readonly STATE_OK=0
readonly STATE_WARNING=1
readonly STATE_CRITICAL=2
readonly STATE_UNKNOWN=3

# --- Default Values ---
HOSTNAME=""
URI="/"
PORT="80"
SSL=false
VERIFY_SSL=true  # By default, we verify certificates (Best Practice)
SEARCH_STRING=""
TIMEOUT=10
WARN_TIME=0
CRIT_TIME=0
AUTH=""
USER_AGENT="check_http_curl/1.0"
VERBOSE=false

# --- Help Function ---
usage() {
    echo "Usage: $0 -H <host> [-u <uri>] [-p <port>] [-s <string>] [-S] [-k] [-w <warn>] [-c <crit>]"
    echo ""
    echo "Options:"
    echo "  -H  Hostname or IP (Required, no special characters except . - _)"
    echo "  -u  URI to check (Default: /)"
    echo "  -p  Port (Default: 80)"
    echo "  -s  Exact string to search for (Literal search)"
    echo "  -S  Enable SSL/HTTPS"
    echo "  -k  Ignore SSL certificate errors (Insecure)"
    echo "  -w  WARNING threshold (seconds)"
    echo "  -c  CRITICAL threshold (seconds)"
    echo "  -t  Timeout (Default: 10s)"
    echo "  -a  Authentication (user:pass)"
    exit $STATE_UNKNOWN
}

# --- Argument Parsing ---
while getopts "H:u:p:s:Skw:c:t:a:v" opt; do
    case $opt in
        H) HOSTNAME="$OPTARG" ;;
        u) URI="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        s) SEARCH_STRING="$OPTARG" ;;
        S) SSL=true ;;
        k) VERIFY_SSL=false ;; # The -k option disables SSL verification
        w) WARN_TIME="$OPTARG" ;;
        c) CRIT_TIME="$OPTARG" ;;
        t) TIMEOUT="$OPTARG" ;;
        a) AUTH="$OPTARG" ;;
        v) VERBOSE=true ;;
        *) usage ;;
    esac
done

# --- 1. Input Validation (Sanitization) ---

if [[ -z "$HOSTNAME" ]]; then
    echo "ERROR: -H is required."
    usage
fi

# Security: We forbid dangerous characters in the hostname (@, /, \, etc.)
# We only allow alphanumeric characters, dots, hyphens, underscores and colons (for IPv6)
if [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9.:_-]+$ ]]; then
    echo "CRITICAL ERROR: The hostname contains invalid characters."
    exit $STATE_UNKNOWN
fi

# Protocol and port management
PROTOCOL="http"
if $SSL; then
    PROTOCOL="https"
    if [[ "$PORT" == "80" ]]; then PORT="443"; fi
fi

# URL construction (Safe because hostname is validated)
FULL_URL="${PROTOCOL}://${HOSTNAME}:${PORT}${URI}"

if $VERBOSE; then echo "Debug: Target $FULL_URL"; fi

# --- 2. Secure Command Construction (Arrays) ---
# This is the major protection against argument injection.
# Each array element is treated as a distinct argument,
# regardless of whether it contains spaces or dashes.

CURL_ARGS=(
    "-s"                # Silent
    "-L"                # Follow redirects
    "--max-time" "$TIMEOUT"
    "-A" "$USER_AGENT"
    "-w" "||nagiosstats||%{http_code}:%{time_total}" # Output format
)

# SSL management
if [ "$VERIFY_SSL" = false ]; then
    CURL_ARGS+=("-k") # Insecure mode
fi

# Authentication management
if [[ -n "$AUTH" ]]; then
    CURL_ARGS+=("-u" "$AUTH")
fi

# --- 3. Execution ---

# "${CURL_ARGS[@]}" expands the array into separate secure arguments
RESULT=$(curl "${CURL_ARGS[@]}" "$FULL_URL")
CURL_EXIT=$?

# Extraction des données (Body vs Stats)
BODY=$(awk -F"\|\|nagiosstats\|\|" '{print $1}' <<< "$RESULT")
STATS=$(awk -F"\|\|nagiosstats\|\|" '{print $2}' <<< "$RESULT")

# On utilise 'tr -d' pour supprimer tous les espaces et retours à la ligne parasites
HTTP_CODE=$(cut -d: -f1 <<< "$STATS" | tr -d '[:space:]')
TIME_TOTAL=$(cut -d: -f2 <<< "$STATS" | tr -d '[:space:]')

# --- 4. Analysis ---

# Check for CURL errors
if [[ $CURL_EXIT -ne 0 ]]; then
    echo "CRITICAL - Connection failed to $HOSTNAME (Curl error: $CURL_EXIT)"
    exit $STATE_CRITICAL
fi

# Check HTTP Code
if [[ "$HTTP_CODE" -ge 400 ]]; then
    echo "CRITICAL - HTTP Error $HTTP_CODE on $HOSTNAME | time=${TIME_TOTAL}s;;;"
    exit $STATE_CRITICAL
fi

# String verification (Secure "Fixed String" mode)
if [[ -n "$SEARCH_STRING" ]]; then
    # grep -F forces pure textual search (no regex)
    # grep -q is silent
    if ! grep -F -q "$SEARCH_STRING" <<< "$BODY"; then
        echo "CRITICAL - String '$SEARCH_STRING' not found | time=${TIME_TOTAL}s;;;"
        exit $STATE_CRITICAL
    fi
    MSG_PART="string found"
else
    MSG_PART="Status $HTTP_CODE"
fi

# Time threshold verification (via awk)
PERF_DATA="time=${TIME_TOTAL}s;${WARN_TIME};${CRIT_TIME};0;${TIMEOUT}"

check_threshold() {
    local time=$1
    local threshold=$2
    awk -v t="$time" -v th="$threshold" 'BEGIN {exit (t > th) ? 0 : 1}'
}

if [[ "$CRIT_TIME" != "0" ]] && check_threshold "$TIME_TOTAL" "$CRIT_TIME"; then
    echo "CRITICAL - Response time ${TIME_TOTAL}s > ${CRIT_TIME}s | $PERF_DATA"
    exit $STATE_CRITICAL
fi

if [[ "$WARN_TIME" != "0" ]] && check_threshold "$TIME_TOTAL" "$WARN_TIME"; then
    echo "WARNING - Response time ${TIME_TOTAL}s > ${WARN_TIME}s | $PERF_DATA"
    exit $STATE_WARNING
fi

echo "OK - $MSG_PART, time ${TIME_TOTAL}s | $PERF_DATA"
exit $STATE_OK
