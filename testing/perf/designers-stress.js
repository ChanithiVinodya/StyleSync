import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:5000';

export const options = {
  stages: [
    { duration: '30s', target: 50 },  // Ramp-up to 50 users
    { duration: '1m', target: 50 },   // Sustain 50 users
    { duration: '30s', target: 100 }, // Ramp-up to 100 users
    { duration: '1m', target: 100 },  // Sustain 100 users
    { duration: '30s', target: 200 }, // Ramp-up to 200 users
    { duration: '1m', target: 200 },  // Sustain 200 users
    { duration: '30s', target: 0 },   // Ramp-down to 0 users
  ],
  // No thresholds specified for stress testing to observe breaking point
};

const STYLES = ['Modern', 'Minimalist', 'Tropical Modernism', 'Contemporary', 'Scandinavian', 'Industrial'];

export default function () {
  const selectedStyle = STYLES[Math.floor(Math.random() * STYLES.length)];
  const page = Math.floor(Math.random() * 5) + 1;
  const pageSize = 10;

  const url = `${BASE_URL}/api/designers?style=${encodeURIComponent(selectedStyle)}&page=${page}&pageSize=${pageSize}`;

  const params = {
    headers: {
      'Accept': 'application/json',
    },
    tags: { name: 'StressGetDesigners' },
  };

  const response = http.get(url, params);

  check(response, {
    'status is 200': (r) => r.status === 200,
    'has items array': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body && Array.isArray(body.items);
      } catch (e) {
        return false;
      }
    },
  });

  sleep(1);
}
