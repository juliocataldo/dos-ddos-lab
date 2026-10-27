// Tráfego legítimo contínuo contra o alvo — roda durante os ataques também,
// para o aluno ver o impacto real em usuário "de verdade".
// Uso: docker exec k6 k6 run /scripts/baseline.js
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 5,
  duration: "2m",
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed: ["rate<0.05"],
  },
};

export default function () {
  const res = http.get("http://target/");
  check(res, { "status 200": (r) => r.status === 200 });
  sleep(1);
}
