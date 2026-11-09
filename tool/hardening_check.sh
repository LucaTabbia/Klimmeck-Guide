#!/usr/bin/env bash
# Phase 12 guard greps (HARDEN-01, HARDEN-07, D-03c). Usage: tool/hardening_check.sh [path/to/app-prod-release.apk]
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
failures=0
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# Production graph: the entry point plus every bootstrap file except the dev composition.
for f in lib/main.dart $(ls lib/bootstrap/*.dart | grep -v dev_auth_composition); do
  [ -f "$f" ] || { fail "$f missing"; continue; }
  grep -nE 'DEV_AUTH_|DevAuthTokenService|dev_auth_token_service|dev_auth_composition|flutter_dotenv' "$f" && fail "$f references the dev bypass"
done
grep -n "export 'dev_auth_token_service.dart'" lib/repository/services/auth/auth.dart && fail "the auth barrel re-exports the dev bypass"
grep -n 'flutter_dotenv' lib/config/env_config.dart && fail "env_config imports flutter_dotenv"

allowed='lib/repository/cache/cache_expiry.dart|lib/repository/storage/(storage_manager|active_user_store|device_identity_store|notification_preferences_store|library_bookmarks_store|session_store)\.dart'
grep -rlE '\.set(String|StringList|Bool|Int|Double)\(' lib --include='*.dart' | grep -vE "^($allowed)$" | while read -r f; do echo "FAIL: $f writes SharedPreferences outside the allow-list"; done | grep . && failures=$((failures + 1))
grep -rn -A3 -E '\.set(String|StringList)\(' lib --include='*.dart' | grep -iE 'token|jwt|bearer|secret' && fail "a SharedPreferences write mentions a token"

grep -rnE '(^|[^A-Za-z_])(debugPrint|print)\(|developer\.log\(' lib --include='*.dart' | grep -v '^lib/utils/app_log.dart:' && fail "log call outside lib/utils/app_log.dart"
grep -rn -A3 -E '(appLog|debugPrint)\(' lib --include='*.dart' | grep -E '\$\{?[A-Za-z_.]*([Tt]oken|[Bb]earer|[Jj]wt|[Aa]uthorization|[Pp]assword|[Ss]ecret)' && fail "a log call interpolates a credential"

if [ $# -ge 1 ]; then
  apk="$1"
  if ! { [ -f "$apk" ] && unzip -tq "$apk" >/dev/null 2>&1; }; then
    fail "$apk not found or not a readable archive"
  elif [ "$(unzip -l "$apk" | grep -c 'lib/.*libapp\.so')" = "0" ]; then
    fail "$apk has no libapp.so: not a Flutter release bundle"
  else
    [ "$(unzip -l "$apk" | grep -c 'flutter_assets/\.env$')" = "0" ] || fail ".env bundled in $apk"
    [ "$(unzip -p "$apk" | grep -a -c 'DEV_AUTH_')" = "0" ] || fail "DEV_AUTH_ found in $apk"
    [ "$(unzip -p "$apk" | grep -a -c 'DevAuthTokenService')" = "0" ] || fail "DevAuthTokenService found in $apk"
  fi
fi

[ "$failures" -eq 0 ] && { echo "hardening_check: OK"; exit 0; }
echo "hardening_check: $failures check(s) failed"; exit 1
