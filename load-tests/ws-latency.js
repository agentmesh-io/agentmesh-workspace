/**
 * Sprint 13.1 — Live UI · WebSocket latency probe
 *
 * Measures the wall-clock delay between a workflow phase change on the backend
 * and the corresponding `workflow.update` WebSocket frame being delivered to
 * a subscribed browser-equivalent client.
 *
 * North-star acceptance (ROADMAP_M13 §13.1): p95 < 500 ms.
 *
 * Run:
 *   k6 run -e BASE_URL=http://api.agentmesh.localhost \
 *          -e WS_URL=ws://api.agentmesh.localhost/ws   \
 *          load-tests/ws-latency.js
 */

import ws from 'k6/ws'
import http from 'k6/http'
import { check, sleep } from 'k6'
import { Trend, Counter } from 'k6/metrics'

const BASE_URL = __ENV.BASE_URL || 'http://api.agentmesh.localhost'
const WS_URL = __ENV.WS_URL || 'ws://api.agentmesh.localhost/ws'

const wsLatency = new Trend('ws_workflow_update_latency_ms', true)
const wsFramesReceived = new Counter('ws_frames_received')
const wsFramesDropped = new Counter('ws_frames_dropped')

export const options = {
  scenarios: {
    live_ui_probe: {
      executor: 'per-vu-iterations',
      vus: Number(__ENV.WORKFLOW_LOAD || 1),
      iterations: 1,
      maxDuration: '5m',
    },
  },
  thresholds: {
    // Per ROADMAP_M13.md §13.1 acceptance: <500 ms p95
    ws_workflow_update_latency_ms: ['p(95)<500', 'p(99)<1000'],
    ws_frames_dropped: ['count==0'],
  },
}

export default function () {
  // 1. Trigger a workflow via REST so the backend will start emitting frames
  const initBody = JSON.stringify({
    projectName: `m13-ws-probe-${__VU}-${Date.now()}`,
    srsContent: '# SRS\nReturn HTTP 200 from /health',
  })
  const initRes = http.post(`${BASE_URL}/api/projects/initialize`, initBody, {
    headers: { 'Content-Type': 'application/json' },
    timeout: '15s',
  })
  check(initRes, { 'project initialized': (r) => r.status === 200 || r.status === 201 })
  let workflowId = null
  try {
    workflowId = initRes.json('workflowId') || initRes.json('id')
  } catch (_) {
    /* fall through */
  }
  if (!workflowId) {
    console.error('No workflowId returned, aborting probe')
    return
  }

  // 2. Open the WebSocket and subscribe to that workflow
  const params = { tags: { name: 'ws-live-stream' } }
  const res = ws.connect(WS_URL, params, function (socket) {
    socket.on('open', () => {
      socket.send(JSON.stringify({ type: 'subscribe.workflow', workflowId }))
    })

    socket.on('message', (data) => {
      const receivedAt = Date.now()
      let msg
      try {
        msg = JSON.parse(data)
      } catch {
        wsFramesDropped.add(1)
        return
      }
      if (msg.type !== 'workflow.update') return
      wsFramesReceived.add(1)

      // Latency = wall clock now - frame timestamp from server
      // (server stamps Instant.now() inside broadcastWorkflowUpdate)
      if (msg.timestamp) {
        const sentAt = Date.parse(msg.timestamp)
        if (!Number.isNaN(sentAt)) {
          wsLatency.add(receivedAt - sentAt)
        }
      }

      // Done when the workflow reaches a terminal state
      const terminal = ['COMPLETED', 'FAILED', 'CANCELLED']
      if (msg.data && terminal.includes(String(msg.data.status))) {
        socket.close()
      }
    })

    socket.on('error', (e) => {
      console.error('ws error:', e.error())
    })

    socket.setTimeout(() => {
      // Hard cap so the run doesn't hang on a stuck workflow
      socket.close()
    }, 4 * 60 * 1000)
  })

  check(res, { 'ws handshake 101': (r) => r && r.status === 101 })
  sleep(1)
}

