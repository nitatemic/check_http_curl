CHECK_HTTP_CURL(1)           Nagios Plugins Manual          CHECK_HTTP_CURL(1)

NAME
       check_http_curl - Safe and robust Nagios plugin to test HTTP/HTTPS connections

SYNOPSIS
       check_http_curl -H host [-u uri] [-p port] [-s string] [-S] [-k]
                       [-w seconds] [-c seconds] [-t timeout] [-a auth] [-v]

DESCRIPTION
       check_http_curl is a Bash-based Nagios plugin designed to check the status
       of an HTTP or HTTPS service. It uses 'curl' backend to perform the connection.

       This version (v3) has been hardened against Command Injection vulnerabilities.
       It validates inputs, uses Bash Arrays for argument handling, and performs
       literal string searching (no regex) to prevent ReDoS attacks.

OPTIONS
       -H host
           The hostname or IP address to check.
           MANDATORY.
           Security Note: Input is validated. Only alphanumeric characters, dots (.),
           hyphens (-), and underscores (_) are allowed.

       -u uri
           The URI to request. Defaults to "/".

       -p port
           The port number to connect to. Defaults to 80 (HTTP) or 443 (HTTPS).

       -s string
           A string to search for in the response body.
           Note: This performs a LITERAL search (grep -F), not a Regular Expression.
           The check returns CRITICAL if the string is not found.

       -S
           Enable SSL/HTTPS. Automatically switches default port to 443 if not specified.

       -k
           (Insecure) Skip SSL certificate verification.
           Use this only for internal self-signed certificates.
           Default behavior is to verify certificates.

       -w seconds
           Response time to result in WARNING status. Can be a float (e.g., 0.5).

       -c seconds
           Response time to result in CRITICAL status. Can be a float (e.g., 1.0).

       -t timeout
           Connection timeout in seconds. Defaults to 10.

       -a user:password
           Authentication credentials for Basic Auth.
           Warning: Credentials may be visible in the process list.

       -v
           Verbose mode. Prints debug information to stdout.

EXIT STATUS
       The exit status is compatible with Nagios standards:
       0 (OK)       Service is up, string found, response time within limits.
       1 (WARNING)  Service is up, but response time exceeded warning threshold.
       2 (CRITICAL) Service down, string not found, or critical threshold exceeded.
       3 (UNKNOWN)  Invalid arguments or internal error.

EXAMPLES
       Check a standard website (Google):
           check_http_curl -H google.com -S

       Check an internal API with a warning threshold of 500ms:
           check_http_curl -H api.internal.lan -u /health -w 0.5

       Check a protected site looking for specific text, ignoring SSL errors:
           check_http_curl -H staging.local -S -k -a admin:secret -s "Welcome"

SECURITY
       This plugin implements several security measures:
       1. Input Sanitization: The Hostname is strictly validated.
       2. Argument Injection Prevention: Uses Bash Arrays to pass arguments to curl.
       3. ReDoS Prevention: Search strings are treated as fixed strings, not regex.

AUTHOR
       Written by Nitatemic, Gemini & Claude AI.

v3.0                             November 2025              CHECK_HTTP_CURL(1)
