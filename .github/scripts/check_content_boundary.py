"""Fail if private lesson content is tracked or bundled in a public build."""
from pathlib import Path
import argparse, json, re, subprocess, zipfile

PRIVATE = ('assets/lessons', 'assets/courses', 'conteudo-local', 'test/private_content')

def private(path, roots=PRIVATE, retired=()):
    return path in retired or any(path == root or path.startswith(root + '/') for root in roots)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    paths = subprocess.check_output(['git', '-C', str(root), 'ls-files', '-z']).decode().split('\0')
    retired = set(json.loads((root / 'CONTENT_PRIVATE_PATHS.json').read_text()))
    roots = (*PRIVATE, *(str(Path(p).parent) for p in retired if p.endswith('.json')))
    errors = ['Tracked private content: ' + p for p in paths if private(p, roots, retired)]
    for line in (root / 'pubspec.yaml').read_text().splitlines():
        found = re.match(r'\s*-\s*[\"\']?([^\s\"\'#]+)', line)
        if found:
            asset = found[1].rstrip('/')
            if private(asset, roots, retired) or asset == '.' or any(p.startswith(asset + '/') for p in (*roots, *retired)):
                errors.append('Private content declared as an asset: ' + found[1])
    if args.apk:
        with zipfile.ZipFile(args.apk) as apk:
            for name in apk.namelist():
                prefix = 'assets/flutter_assets/'
                if name.startswith(prefix) and private(name[len(prefix):], roots, retired):
                    errors.append('Private content in APK: ' + name)
    if errors:
        print('\n'.join(errors[:8]))
        raise SystemExit(f'{len(errors)} content boundary violation(s).')
    print('Content boundary OK: no tracked/bundled private lesson files.')

if __name__ == '__main__': main()
