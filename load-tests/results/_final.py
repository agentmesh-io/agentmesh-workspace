#!/usr/bin/env python3
import json, glob, os
for f in sorted(glob.glob(os.path.join(os.path.dirname(__file__), '*-final-*.json'))):
    d = json.load(open(f))
    m = d['metrics']
    dur = m['http_req_duration']['values']
    errs = m['errors']['values']
    failed = m['http_req_failed']['values']
    checks = m['checks']['values']
    iters = m['iterations']['values']
    th_dur = m['http_req_duration']['thresholds']
    th_err = m['errors']['thresholds']
    print('===', os.path.basename(f), '===')
    print(f'  p95={dur["p(95)"]:.2f}ms  avg={dur["avg"]:.2f}ms  max={dur["max"]:.2f}ms  med={dur["med"]:.2f}ms')
    print(f'  thresholds: {th_dur}')
    print(f'  errors (custom):  rate={errs["rate"]*100:.3f}%  thresholds={th_err}')
    print(f'  http_req_failed:  rate={failed["rate"]*100:.3f}%  passes={failed["passes"]}  fails={failed["fails"]}')
    print(f'  checks:           rate={checks["rate"]*100:.3f}%  passes={checks["passes"]}  fails={checks["fails"]}')
    print(f'  iterations:       count={iters["count"]}  rate={iters["rate"]:.2f}/s')
    print(f'  http_reqs:        count={m["http_reqs"]["values"]["count"]}  rate={m["http_reqs"]["values"]["rate"]:.2f}/s')
    print()

