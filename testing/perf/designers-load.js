import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:5000';

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m', target: 50 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'], // http_req_failed < 1%
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
  },
};

const STYLES = ['Modern', 'Minimalist', 'Tropical Modernism', 'Contemporary', 'Scandinavian', 'Industrial'];

export default function () {
  const selectedStyle = STYLES[Math.floor(Math.random() * STYLES.length)];
  const page = Math.floor(Math.random() * 5) + 1;
  const pageSize = 10;

  const url = `${BASE_URL}/api/designers?style=${encodeURIComponent(selectedStyle)}&page=${page}&pageSize=${pageSize}&sort=rating_desc`;

  const params = {
    headers: {
      'Accept': 'application/json',
    },
    tags: { name: 'GetDesignersFiltered' },
  };

  const response = http.get(url, params);

  check(response, {
    'status is 200': (r) => r.status === 200,
    'has valid JSON body': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body && Array.isArray(body.items);
      } catch (e) {
        return false;
      }
    },
  });

  if (response.status !== 200) console.log(`status=${response.status} error=${response.error}`);

  sleep(1);
}
