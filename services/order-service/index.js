const http = require("http");

// URL of the Inventory Service (Kubernetes DNS resolves this)
const INVENTORY_SERVICE_URL =
  process.env.INVENTORY_SERVICE_URL || "http://inventory-service:8080";

// Fetch inventory data from the Inventory Service
function fetchInventory() {
  return new Promise((resolve, reject) => {
    http
      .get(`${INVENTORY_SERVICE_URL}/inventory`, (res) => {
        let data = "";
        res.on("data", (chunk) => {
          data += chunk;
        });
        res.on("end", () => {
          resolve(JSON.parse(data));
        });
      })
      .on("error", (err) => {
        reject(err);
      });
  });
}

// HTTP server with health check and orders endpoint
const server = http.createServer(async (req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "healthy" }));
    return;
  }

  if (req.url === "/orders") {
    try {
      const inventory = await fetchInventory();
      const orders = {
        orders: [
          {
            id: "ORD-001",
            status: "processing",
            items: inventory.items.slice(0, 2),
          },
          {
            id: "ORD-002",
            status: "shipped",
            items: inventory.items.slice(2, 4),
          },
        ],
      };
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify(orders));
    } catch (err) {
      res.writeHead(502, { "Content-Type": "application/json" });
      res.end(
        JSON.stringify({ error: "Failed to reach Inventory Service", details: err.message })
      );
    }
    return;
  }

  res.writeHead(404, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "Not found" }));
});

server.listen(8080, () => {
  console.log("Order Service running on port 8080");
});