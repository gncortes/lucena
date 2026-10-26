# Lesson content

This public repository contains the application, parsers and synthetic contract
fixtures. Real lesson scripts, translations, exercises and course previews are
maintained privately and are not Flutter assets. Adding them to `.gitignore`
does not remove previously committed history.

The public build and its CI do not need access to the private repository.
Without a selected published release, lessons are unavailable; games, positions
and the other public assets remain local. Saved learning progress is retained.

For authorized authors, the private `conteudo/dev.py` tool links local drafts and
serves them on loopback. Run a **debug** app with:

```sh
flutter run --dart-define=CONTENT_URL=http://10.0.2.2:8791
```

No draft is uploaded by this operation. Release builds reject `CONTENT_URL`.
Private corpus tests are separate from the public synthetic contract tests;
the private tooling can prepare them under ignored paths for an explicit run.

A production release can explicitly select `CONTENT_RELEASE=<immutable-id>`.
The reader uses authenticated Storage SDK downloads, validates a published
manifest and each file's hash, and caches data in device secure storage scoped
to the signed-in account. This code does **not** deploy a bucket, grant course
access or verify purchases. Backend purchase validation, Storage rules, App
Check enforcement, version discovery and the update/download UI must be
configured and reviewed before a paid course is launched. There is no upload
operation or automatic draft publication in the application.

CI checks the tracked tree, asset declarations and final APK with
`.github/scripts/check_content_boundary.py` to prevent accidental bundling.
