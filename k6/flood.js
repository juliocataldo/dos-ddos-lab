// HTTP flood — muitas VUs batendo sem parar em /heavy (custa CPU pra comprimir).
// Uso: docker exec k6 k6 run /scripts/flood.js
// Ou:  docker exec k6 k6 run --vus 100 --duration 20s /scripts/flood.js
import http from "k6/http";

export const options = {
  vus: 100,
  duration: "20s",
};

export default function () {
  http.get("http://target/heavy.txt", {
    headers: { "Accept-Encoding": "gzip" },
  });
}
