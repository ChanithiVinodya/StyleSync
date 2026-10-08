import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:5000';
const TEST_EMAIL = __ENV.LOGIN_EMAIL || 'admin@stylesync.com';
const TEST_PASSWORD = __ENV.LOGIN_PASSWORD || 'Admin@StyleSync2026!';

export const options = {
  stages: [
    { duration: '30s', target: 50 }, // Ramp-up to 50 users
    { duration: '1m', target: 50 },  // Sustain 50 users
    { duration: '30s', target: 0 },  // Ramp-down to 0 users
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],    // Error rate < 1%
    http_req_duration: ['p(95)<500'],  // 95% of login requests under 500ms
  },
};

export default function () {
  const url = `${BASE_URL}/api/auth/login`;
  const payload = JSON.stringify({
    email: TEST_EMAIL,
    password: TEST_PASSWORD,
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    tags: { name: 'PostAuthLogin' },
  };

  const response = http.post(url, payload, params);

  check(response, {
    'status is 200': (r) => r.status === 200,
    'contains token': (r) => {
      try {
        const json = JSON.parse(r.body);
        return typeof json.token === 'string' && json.token.length > 0;
      } catch (e) {
        return false;
      }
    },
  });

  sleep(1);
}
