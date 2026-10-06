"""Compare an installed bundle with source modules without writing either."""
import argparse
import hashlib
import json
import re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
MARKER = re.compile(r'^HUD\.([a-zA-Z0-9_]+)=\(function\(\)\r?\n', re.M)

def audit(path):
    text = path.read_text(encoding='utf-8')
    matches = list(MARKER.finditer(text))
    report = {'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
              'matching': [], 'different': [], 'missing_source': []}
    for i, match in enumerate(matches):
        tail = text[match.end():matches[i+1].start() if i+1 < len(matches) else len(text)]
        source = ROOT / 'src' / (match[1] + '.lua')
        if not source.exists():
            report['missing_source'].append(match[1])
        else:
            expected = source.read_text(encoding='utf-8').strip()
            # Match the entire source body followed by its bundle terminator.
            # A source module may contain its own nested end)() closures.
            body = tail.lstrip()
            if body.startswith(expected) and body[len(expected):].lstrip().startswith('end)()'):
                report['matching'].append(match[1])
            else:
                report['different'].append(match[1])
    report['module_count'] = len(matches)
    return report

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=Path)
    args = parser.parse_args()
    print(json.dumps(audit(args.bundle), indent=2))
