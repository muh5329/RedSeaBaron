#!/usr/bin/env python3
"""Run actual native gameplay suites, validate reports, then export Web."""
import argparse, json, os, pathlib, re, subprocess
ROOT = pathlib.Path(__file__).resolve().parents[1]
catalog = json.loads((ROOT / 'tests/suites.json').read_text())
parser = argparse.ArgumentParser()
parser.add_argument('--suites', default=','.join(k for k,v in catalog.items() if v['default']))
parser.add_argument('--long', action='store_true')
parser.add_argument('--no-export', action='store_true')
args = parser.parse_args()
godot = os.environ.get('GODOT_BIN', '/Applications/Godot.app/Contents/MacOS/Godot')
evidence = ROOT / 'docs/evidence'
evidence.mkdir(exist_ok=True)

def run(name, command, timeout=240):
    with (evidence / (name + '.log')).open('w') as log:
        result = subprocess.run([godot, *command], cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
    output = (evidence / (name + '.log')).read_text()
    if result.returncode or re.search(r'SCRIPT ERROR|^ERROR:|\| FAIL \|', output, re.M):
        raise SystemExit(f'{name} FAILED: see docs/evidence/{name}.log\n{output[-5000:]}')

run('import', ['--headless','--editor','--path','.','--import','--quit'])
suites = args.suites.split(',') + (['distance'] if args.long else [])
for suite in suites:
    if suite not in catalog or catalog[suite].get('web_only'): raise SystemExit(f'Unknown or Web-only suite: {suite}')
    flag = '--verify' if suite == 'traversal' else '--verify-' + suite
    report = evidence / ('native-report.json' if suite == 'traversal' else suite + '-native-report.json')
    old_time = report.stat().st_mtime_ns if report.exists() else None
    run(suite + '-native-verifier', ['--headless','--path','.','--',flag], catalog[suite]['timeout'])
    if not report.exists() or report.stat().st_mtime_ns == old_time: raise SystemExit(f'{suite}: no fresh report')
    data = json.loads(report.read_text())
    assert data['passed'] == data['total'] and data['total'] >= catalog[suite]['minimum'], data
    print(f"{suite}: {data['passed']}/{data['total']} in {data['elapsed_seconds']:.1f}s", flush=True)
if not args.no_export:
    (ROOT / 'builds/web').mkdir(parents=True,exist_ok=True)
    run('web-export', ['--headless','--path','.','--export-debug','Web','builds/web/index.html'])
    print('Web export built. Serve with tools/serve.sh and verify in a browser.', flush=True)
