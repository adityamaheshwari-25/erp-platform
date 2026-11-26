const http = require("http");
const { Client } = require("pg");

// Database connection config from environment variables
const dbConfig = {
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || "5432"),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: { rejectUnauthorized: false },
};

// Query all inventory items from PostgreSQL
async function queryInventory() {
  const client = new Client(dbConfig);
  await client.connect();
  const result = await client.query(
    "SELECT id, name, quantity, warehouse FROM inventory"
  );
  await client.end();
  return result.rows;
}

// HTTP server with health check and inventory endpoint
const server = http.createServer(async (req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "healthy" }));
    return;
  }

  if (req.url === "/inventory") {
    try {
      const items = await queryInventory();
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ items }));
    } catch (err) {
      res.writeHead(500, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "Database error", details: err.message }));
    }
    return;
  }

    if (req.url === "/seed") {
    try {
      const client = new Client(dbConfig);
      await client.connect();
      // Randomized item data
      const names = ["Sensor F", "Module G", "Relay H", "Actuator I", "Connector J"];
      const warehouses = ["WH-01", "WH-02", "WH-03"];
      const name = names[Math.floor(Math.random() * names.length)];
      const quantity = Math.floor(Math.random() * 500) + 10;
      const warehouse = warehouses[Math.floor(Math.random() * warehouses.length)];
      await client.query(
        "INSERT INTO inventory (name, quantity, warehouse) VALUES ($1, $2, $3)",
        [name, quantity, warehouse]
      );
      await client.end();
      res.writeHead(201, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ message: "Seeded", name, quantity, warehouse }));
    } catch (err) {
      res.writeHead(500, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "Seed failed", details: err.message }));
    }
    return;
  }

  res.writeHead(404, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "Not found" }));
});

server.listen(8080, () => {
  console.log("Inventory Service running on port 8080");
});