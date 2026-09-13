#!/usr/bin/env python3
"""Freeze source, run the native gauntlet there, and record hash-checked provenance."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('name', help='Unique evidence prefix, e.g. m40')
parser.add_argument('--long', action='store_true', help='Also run continuous world flight')
args = parser.parse_args()
if not re.fullmatch(r'[a-z0-9][a-z0-9_-]*', args.name):
    parser.error('Use a simple lowercase checkpoint name')
evidence = ROOT / 'docs/evidence'
clone = evidence / f'{args.name}-source'
manifest_path = evidence / f'{args.name}-source-manifest.json'
if clone.exists() or manifest_path.exists():
    parser.error('Checkpoint already exists; choose a new name to preserve it')
clone.mkdir(parents=True)
for name in ('scripts', 'scenes', 'assets', 'resources', 'tests', 'tools'):
    source = ROOT / name
    if source.exists():
        shutil.copytree(source, clone / name, ignore=shutil.ignore_patterns('__pycache__', '*.pyc', '.DS_Store'))
for name in ('README.md', 'project.godot', 'export_presets.cfg'):
    shutil.copy2(ROOT / name, clone / name)
(clone / 'docs/evidence').mkdir(parents=True)
(clone / 'docs/.gdignore').touch()
for name in ('PROJECT_BRIEF.txt', 'ARCHITECTURE.md'):
    if (ROOT / 'docs' / name).exists():
        shutil.copy2(ROOT / 'docs' / name, clone / 'docs' / name)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

manifest = {str(p.relative_to(clone)): digest(p) for p in sorted(clone.rglob('*')) if p.is_file()}
manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
catalog = json.loads((clone / 'tests/suites.json').read_text())
suites = [k for k, v in catalog.items() if v['default']]
if args.long:
    suites.append('distance')
print(f'Fixed source: {len(manifest)} files; {len(suites)} suites; {sum(catalog[k]["minimum"] for k in suites)} minimum assertions', flush=True)
command = [sys.executable, str(clone / 'tools/verify.py'), '--no-export']
if args.long:
    command.append('--long')
log_path = evidence / f'{args.name}-full-regression.log'
with log_path.open('w') as log:
    result = subprocess.run(command, cwd=clone, stdout=log, stderr=subprocess.STDOUT)
changed = [name for name, expected in manifest.items() if not (clone / name).is_file() or digest(clone / name) != expected]
results = []
for suite in suites:
    report = clone / 'docs/evidence' / ('native-report.json' if suite == 'traversal' else suite + '-native-report.json')
    if not report.exists():
        continue
    data = json.loads(report.read_text())
    results.append({'suite': suite, 'passed': data['passed'], 'total': data['total'], 'seconds': data['elapsed_seconds']})
accepted = result.returncode == 0 and not changed and len(results) == len(suites) and all(r['passed'] == r['total'] and r['total'] >= catalog[r['suite']]['minimum'] for r in results)
summary = {'accepted': accepted, 'returncode': result.returncode, 'files_verified': len(manifest) - len(changed), 'changed_files': changed, 'suites': len(results), 'expected_suites': len(suites), 'passed': sum(r['passed'] for r in results), 'total': sum(r['total'] for r in results), 'seconds': sum(r['seconds'] for r in results), 'results': results}
(evidence / f'{args.name}-regression-summary.json').write_text(json.dumps(summary, indent=2) + '\n')
shutil.copytree(clone / 'docs/evidence', evidence / f'{args.name}-validation')
print(json.dumps({k: v for k, v in summary.items() if k != 'results'}, indent=2), flush=True)
sys.exit(0 if accepted else 1)
