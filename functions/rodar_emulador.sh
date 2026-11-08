#!/usr/bin/env bash
# Testes das Functions no emulador (Auth, Firestore e Storage). O emulador pede Java 21
# ou mais novo: se o java do PATH for antigo, usa o do Android Studio.
set -euo pipefail
pasta="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versao="$(java -version 2>&1 | sed -n 's/.*version "\([0-9]*\).*/\1/p' | head -1)"
if [ "${versao:-0}" -lt 21 ]; then
  for jbr in "${JAVA_HOME:-}" /opt/android-studio/jbr "$HOME/android-studio/jbr" /snap/android-studio/current/jbr; do
    if [ -n "$jbr" ] && [ -x "$jbr/bin/java" ]; then
      export JAVA_HOME="$jbr"
      export PATH="$jbr/bin:$PATH"
      break
    fi
  done
fi
cd "$pasta"
npm run build
exec firebase emulators:exec --project demo-lucena --only auth,firestore,storage \
  --config ../firebase.json "node --test --test-concurrency=1 lib/test/emulador/*.emu.js"
