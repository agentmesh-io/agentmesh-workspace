#!/usr/bin/env python3
"""Analyse k6 JSON summary files. Usage: python3 _analyze.py"""
import json, glob, os

for f in sorted(glob.glob(os.path.join(os.path.dirname(__file__), 'summary-*.json')))[-4:]:
    d = json.load(open(f))
    m = d.get('metrics', {})
    dur = m.get('http_req_duration', {}).get('values', {})
    errs = m.get('errors', {}).get('values', {})
    failed = m.get('http_req_failed', {}).get('values', {})
    iters = m.get('iterations', {}).get('values', {})
    ths = m.get('http_req_duration', {}).get('thresholds', {})
    err_ths = m.get('errors', {}).get('thresholds', {})
    print(f'=== {os.path.basename(f)} ===')
    print(f'  http_req_duration: avg={dur.get("avg",0):.2f}ms p95={dur.get("p(95)",0):.2f}ms max={dur.get("max",0):.2f}ms')
    print(f'  p95 threshold: {ths}')
    print(f'  errors: rate={errs.get("rate",0)*100:.3f}% passes={errs.get("passes",0)} fails={errs.get("fails",0)} th={err_ths}')
    print(f'  http_req_failed: rate={failed.get("rate",0)*100:.3f}%')
    print(f'  iterations: count={iters.get("count",0)} rate={iters.get("rate",0):.2f}/s')
    print()

