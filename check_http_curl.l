.TH CHECK_HTTP_CURL 1 "November 2025" "v3.0" "Nagios Plugins Manual"
.SH NAME
check_http_curl \- Safe and robust Nagios plugin to test HTTP/HTTPS connections
.SH SYNOPSIS
.B check_http_curl
.B \-H
.I host
[\fB\-u\fR \fIuri\fR]
[\fB\-p\fR \fIport\fR]
[\fB\-s\fR \fIstring\fR]
[\fB\-S\fR]
[\fB\-k\fR]
[\fB\-w\fR \fIseconds\fR]
[\fB\-c\fR \fIseconds\fR]
[\fB\-t\fR \fItimeout\fR]
[\fB\-a\fR \fIauth\fR]
[\fB\-v\fR]
.SH DESCRIPTION
.B check_http_curl
is a Bash-based Nagios plugin designed to check the status of an HTTP or HTTPS service.
It uses 'curl' backend to perform the connection.
.PP
This version (v3) has been hardened against Command Injection vulnerabilities.
It validates inputs, uses Bash Arrays for argument handling, and performs literal string searching.
.SH OPTIONS
.TP
.BR \-H " " \fIhost\fR
The hostname or IP address to check. \fBMANDATORY\fR.
Input is validated (alphanumeric, dots, hyphens, underscores only).
.TP
.BR \-u " " \fIuri\fR
The URI to request. Defaults to "/".
.TP
.BR \-p " " \fIport\fR
The port number. Defaults to 80 (HTTP) or 443 (HTTPS).
.TP
.BR \-s " " \fIstring\fR
String to search for (LITERAL search, grep -F). Returns CRITICAL if not found.
.TP
.B \-S
Enable SSL/HTTPS.
.TP
.B \-k
(Insecure) Skip SSL certificate verification.
.TP
.BR \-w " " \fIseconds\fR
Response time for WARNING threshold.
.TP
.BR \-c " " \fIseconds\fR
Response time for CRITICAL threshold.
.TP
.BR \-t " " \fItimeout\fR
Connection timeout in seconds (Default: 10).
.TP
.BR \-a " " \fIuser:pass\fR
Basic Auth credentials.
.SH AUTHOR
Nitatemic, Gemini & Claude AI.
