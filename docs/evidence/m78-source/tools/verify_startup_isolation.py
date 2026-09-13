#!/usr/bin/env python3
"""Fault-inject only a temporary project copy; never damage a playable checkout."""
import json, os, pathlib, shutil, subprocess, tempfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT_BIN', '/Applications/Godot.app/Contents/MacOS/Godot')
EVIDENCE = ROOT / 'docs/evidence'
results = []
with tempfile.TemporaryDirectory(prefix='rsb-startup-') as work:
    project = pathlib.Path(work)
    for name in ['project.godot', 'scripts', 'scenes', 'tests', 'assets']:
        source = ROOT / name
        if source.is_dir(): shutil.copytree(source, project / name)
        else: shutil.copy2(source, project / name)
    subprocess.run([GODOT, '--headless', '--editor', '--path', work, '--import', '--quit'],
                   stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT, check=True, timeout=90)
    # Imported test subsequently gets a syntax error: ordinary play must remain usable.
    (project / 'tests/chase_camera_verifier.gd').write_text('extends Node\nfunc broken( -> void:\n')
    for name, flags in [('ordinary', []), ('selected-broken', ['--verify-chase_camera']),
                        ('unknown', ['--verify-not_a_suite'])]:
        run = subprocess.run([GODOT, '--headless', '--path', work, '--quit-after', '90', '--', *flags],
                             capture_output=True, text=True, timeout=30)
        output = run.stdout + run.stderr
        (EVIDENCE / ('startup-' + name + '.log')).write_text(output)
        if name == 'ordinary':
            passed = run.returncode == 0 and 'RSB_READY' in output and 'SCRIPT ERROR' not in output
        else:
            passed = run.returncode == 2 and 'RSB_VERIFICATION_ERROR' in output and 'RSB_READY' in output
        results.append(dict(name=name, passed=passed, exit_code=run.returncode))
report = dict(passed=sum(r['passed'] for r in results), total=len(results), assertions=results)
(EVIDENCE / 'startup-isolation-report.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
raise SystemExit(0 if report['passed'] == report['total'] else 1)
