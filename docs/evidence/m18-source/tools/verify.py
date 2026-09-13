#!/usr/bin/env python3
"""Run actual native gameplay suites, validate reports, then export Web."""
import argparse, json, os, pathlib, re, subprocess
ROOT = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--suites', default='traversal,combat,bike,flight,cart,logistics,worker,world,save,ui,integration,feedback,ai,economy,highland,region,recovery')
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
minimum = dict(traversal=21, combat=34, bike=26, flight=22, cart=25, logistics=23, worker=25, world=15, distance=6, save=22, ui=14, integration=16, feedback=9, ai=10, economy=21, highland=8, region=18, recovery=8)
for suite in suites:
    if suite not in minimum: raise SystemExit(f'Unknown suite: {suite}')
    flag = '--verify' if suite == 'traversal' else '--verify-' + suite
    report = evidence / ('native-report.json' if suite == 'traversal' else suite + '-native-report.json')
    old_time = report.stat().st_mtime_ns if report.exists() else None
    run(suite + '-native-verifier', ['--headless','--path','.','--',flag], 850 if suite=='distance' else 300)
    if not report.exists() or report.stat().st_mtime_ns == old_time: raise SystemExit(f'{suite}: no fresh report')
    data = json.loads(report.read_text())
    assert data['passed'] == data['total'] and data['total'] >= minimum[suite], data
    print(f"{suite}: {data['passed']}/{data['total']} in {data['elapsed_seconds']:.1f}s", flush=True)
if not args.no_export:
    (ROOT / 'builds/web').mkdir(parents=True,exist_ok=True)
    run('web-export', ['--headless','--path','.','--export-debug','Web','builds/web/index.html'])
    print('Web export built. Serve with tools/serve.sh and verify in a browser.', flush=True)
