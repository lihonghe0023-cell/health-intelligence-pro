#!/usr/bin/env python3
"""Local structural smoke checks; does not replace macOS xcodebuild."""
from pathlib import Path
import plistlib

root = Path(__file__).resolve().parent.parent
for relative in [
    'Core/Package.swift', 'project.yml', 'iOS/HealthIntelligenceApp.swift',
    'Watch/HealthWatchApp.swift', 'Docs/MUSE_PRO_FINAL_EXECUTION_PROMPT.md',
    'Docs/ALL_HEALTH_CAPABILITIES.md', 'Docs/DESIGN_SYSTEM_V2.md',
    'Configuration/iOS.entitlements', 'Configuration/Watch.entitlements'
]:
    assert (root / relative).exists(), f'Missing {relative}'
metric_count = (root/'iOS/Models/HealthCatalog.swift').read_text().count('        .init(')
assert metric_count == 35, f"Metric catalog changed: {metric_count}"
import csv
with (root/'Docs/ALL_HEALTH_CAPABILITIES.csv').open(encoding='utf-8-sig', newline='') as stream:
    features = list(csv.DictReader(stream))
assert len(features) == 168, f"Feature coverage changed: {len(features)}"
for name in ['iOS.entitlements', 'Watch.entitlements']:
    plist = plistlib.loads((root/'Configuration'/name).read_bytes())
    assert plist['com.apple.developer.healthkit'] is True
secret_suffixes = {'.p12', '.mobileprovision', '.p8', '.pem', '.key', '.cer'}
for file in root.rglob('*'):
    if '.build' in file.parts or not file.is_file():
        continue
    assert file.suffix.lower() not in secret_suffixes, f'Sensitive file: {file}'
print(f'Source structural checks passed: two targets, {metric_count} metrics, {len(features)} roadmap items, HealthKit entitlements, no signing secrets')
