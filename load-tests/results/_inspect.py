#!/usr/bin/env python3
"""Print key metrics + thresholds from k6 summary JSON files."""
import json, os, sys

def v(node):
    return node.get('values', node) if isinstance(node, dict) else {}

def report(path):
    d = json.load(open(path))
    m = d['metrics']
    dur = v(m.get('http_req_duration', {}))
    errs = v(m.get('errors', {}))
    failed = v(m.get('http_req_failed', {}))
    checks = v(m.get('checks', {}))
    iters = v(m.get('iterations', {}))
    reqs = v(m.get('http_reqs', {}))
    pid = v(m.get('project_init_duration', {}))
    print('===', os.path.basename(path), '===')
    print(f"  http_req_duration: p95={dur.get('p(95)',0):.2f}ms avg={dur.get('avg',0):.2f}ms max={dur.get('max',0):.2f}ms")
    print(f"  errors rate:           {errs.get('rate',0)*100:.3f}%")
    print(f"  http_req_failed rate:  {failed.get('rate',0)*100:.3f}%  passes={failed.get('passes',0)} fails={failed.get('fails',0)}")
    print(f"  checks rate:           {checks.get('rate',0)*100:.3f}%  passes={checks.get('passes',0)} fails={checks.get('fails',0)}")
    print(f"  iterations:            {iters.get('count',0)} @ {iters.get('rate',0):.2f}/s")
    print(f"  http_reqs:             {reqs.get('count',0)} @ {reqs.get('rate',0):.2f}/s")
    if pid:
        print(f"  project_init_duration: p95={pid.get('p(95)',0):.2f}ms avg={pid.get('avg',0):.2f}ms")
    def th(k):
        node = m.get(k, {})
        return node.get('thresholds', {}) or {}
    print(f"  thresholds.http_req_duration: {th('http_req_duration')}")
    print(f"  thresholds.errors:            {th('errors')}")
    print(f"  thresholds.http_req_failed:   {th('http_req_failed')}")
    print()

if __name__ == '__main__':
    targets = sys.argv[1:] or sorted([os.path.join(os.path.dirname(__file__), f)
                                       for f in os.listdir(os.path.dirname(__file__))
                                       if f.endswith('-final-20260422-225256.json')])
    for p in targets:
        report(p)


