import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 50,
  duration: '30s',
};

export default function () {
  const res = http.get('http://localhost:5000/api/Designers');

  check(res, {
    'status is 200': (r) => r.status === 200,
  });
}
