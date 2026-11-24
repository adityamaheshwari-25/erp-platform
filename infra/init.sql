-- Create the inventory table
CREATE TABLE IF NOT EXISTS inventory (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  warehouse VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed with sample ERP data
INSERT INTO inventory (name, quantity, warehouse) VALUES
  ('Widget A', 150, 'WH-01'),
  ('Widget B', 75, 'WH-02'),
  ('Gadget C', 200, 'WH-01'),
  ('Component D', 320, 'WH-03'),
  ('Assembly E', 50, 'WH-02');