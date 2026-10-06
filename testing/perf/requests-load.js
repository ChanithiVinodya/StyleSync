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
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
  },
};

export function setup() {
  const loginUrl = `${BASE_URL}/api/auth/login`;
  const payload = JSON.stringify({
    email: TEST_EMAIL,
    password: TEST_PASSWORD,
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  };

  const res = http.post(loginUrl, payload, params);

  const loginCheck = check(res, {
    'setup login status is 200': (r) => r.status === 200,
    'setup received token': (r) => {
      try {
        const json = JSON.parse(r.body);
        return Boolean(json.token);
      } catch (e) {
        return false;
      }
    },
  });

  if (!loginCheck) {
    throw new Error(`Setup failed: Unable to authenticate test user (${res.status} ${res.body})`);
  }

  const token = JSON.parse(res.body).token;
  return { token };
}

export default function (data) {
  const url = `${BASE_URL}/api/requests?page=1&pageSize=10`;
  const params = {
    headers: {
      'Authorization': `Bearer ${data.token}`,
      'Accept': 'application/json',
    },
    tags: { name: 'GetRequestsAuthenticated' },
  };

  const response = http.get(url, params);

  check(response, {
    'status is 200': (r) => r.status === 200,
    'has valid response': (r) => {
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
