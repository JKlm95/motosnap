#!/usr/bin/env bash
# Blocks committing production Firebase client config and other secrets.
# Default: scans git STAGED files only (pre-commit). CI sets CHECK_NO_SECRETS_FULL=1.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAIL=0
FULL="${CHECK_NO_SECRETS_FULL:-0}"

echo "check_no_secrets: scanning (full=$FULL)..."

GUARDED=(
  "android/app/google-services.json"
  "lib/firebase_options.dart"
  "ios/Runner/GoogleService-Info.plist"
  "firebase.json"
)

FORBIDDEN_MARKERS=(
  "motosnap-18101"
  "1008260666997"
  "5ded85270abdb2aa184a3c"
  "firebasestorage.app"
)

ALLOWED_KEY_FRAGMENTS=(
  "AIzaSyDummyReplaceWithFlutterFireConfigure"
  "REPLACE_ME"
)

should_skip_path() {
  local path="$1"
  case "$path" in
    *.md | scripts/check_no_secrets.*) return 0 ;;
  esac
  return 1
}

scan_file_for_api_keys() {
  local file="$1"
  should_skip_path "$file" && return 0
  [[ -f "$file" ]] || return 0
  while IFS= read -r line; do
    if echo "$line" | grep -qE 'AIzaSy[A-Za-z0-9_-]{20,}'; then
      local allowed=0
      for frag in "${ALLOWED_KEY_FRAGMENTS[@]}"; do
        if echo "$line" | grep -qF "$frag"; then allowed=1; break; fi
      done
      if [[ "$allowed" -eq 0 ]]; then
        echo "ERROR: possible real Google API key in $file:"
        echo "  $line"
        FAIL=1
      fi
    fi
  done < <(grep -nE 'AIzaSy[A-Za-z0-9_-]{20,}' "$file" 2>/dev/null || true)
}

scan_guarded_file() {
  local path="$1"
  [[ -f "$path" ]] || return 0
  for marker in "${FORBIDDEN_MARKERS[@]}"; do
    if grep -qF "$marker" "$path"; then
      echo "ERROR: guarded file '$path' contains production marker: $marker"
      FAIL=1
    fi
  done
  if [[ "$path" == "firebase.json" ]] && grep -q '"flutter"' "$path"; then
    echo "ERROR: firebase.json must not contain a committed 'flutter' block."
    FAIL=1
  fi
  scan_file_for_api_keys "$path"
}

if [[ "$FULL" != "1" ]]; then
  mapfile -t CHANGED < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -v '^$' || true)
fi

if [[ "$FULL" != "1" ]] && [[ ${#CHANGED[@]} -eq 0 ]]; then
  echo "check_no_secrets: nothing staged — OK"
  exit 0
fi

if [[ "$FULL" == "1" ]]; then
  for path in "${GUARDED[@]}"; do scan_guarded_file "$path"; done
  while IFS= read -r -d '' file; do
    case "$file" in
      */node_modules/* | */.git/* | */build/* | */.dart_tool/* | */functions/lib/*) continue ;;
    esac
    scan_file_for_api_keys "${file#./}"
  done < <(find . -type f \( -name '*.dart' -o -name '*.json' -o -name '*.plist' \
    -o -name '*.yaml' -o -name '*.yml' -o -name '*.env' -o -name '*.kts' \) -print0 2>/dev/null)
else
  echo "check_no_secrets: reviewing staged paths:"
  printf '  %s\n' "${CHANGED[@]}"
  for path in "${CHANGED[@]}"; do
    for guarded in "${GUARDED[@]}"; do
      [[ "$path" == "$guarded" ]] && scan_guarded_file "$path"
    done
    case "$path" in
      *.dart | *.json | *.plist | *.yaml | *.yml | *.env | *.kts) scan_file_for_api_keys "$path" ;;
    esac
    if should_skip_path "$path"; then continue; fi
    for pat in 'BEGIN (RSA )?PRIVATE KEY' '"private_key"' 'GEMINI_API_KEY=' 'sk-[A-Za-z0-9]{20,}'; do
      if grep -qE "$pat" "$path" 2>/dev/null; then
        echo "ERROR: pattern ($pat) in staged file $path"
        FAIL=1
      fi
    done
  done
fi

if git ls-files --error-unmatch .env .env.local .env.production 2>/dev/null | grep -q .; then
  echo "ERROR: .env file is tracked by git."
  FAIL=1
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo ""
  echo "check_no_secrets FAILED — do not commit."
  echo "Unstage production config or restore placeholders before push."
  exit 1
fi

echo "check_no_secrets: OK"
exit 0
