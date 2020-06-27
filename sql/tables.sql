-- nutra-db, a database for nutratracker clients
-- Copyright (C) 2020  Nutra, LLC. [Shane & Kyle] <nutratracker@gmail.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

DROP SCHEMA IF EXISTS nt CASCADE;

CREATE SCHEMA nt;

SET search_path TO nt;

SET client_min_messages TO WARNING;

--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- Main users tables
--++++++++++++++++++++++++++++

CREATE TABLE users (
  id serial PRIMARY KEY,
  username varchar(18),
  passwd text,
  certified_beta_tester boolean DEFAULT FALSE,
  certified_beta_trainer_tester boolean DEFAULT FALSE,
  accept_eula boolean NOT NULL DEFAULT FALSE,
  passed_onboarding_tutorial boolean DEFAULT FALSE,
  gender text,
  name_first varchar(20),
  name_last varchar(30),
  dob date,
  height smallint,
  height_units varchar(2),
  weight smallint,
  weight_units varchar(2),
  activity_level smallint,
  weight_goal smallint,
  bmr_equation smallint,
  bodyfat_method smallint,
  ship_bill_same_address boolean DEFAULT TRUE,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (username)
);

CREATE TABLE emails (
  email varchar(140) PRIMARY KEY,
  user_id int NOT NULL,
  activated boolean DEFAULT FALSE,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (user_id, activated),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

-- CREATE TABLE token_types (
--   id serial PRIMARY KEY,
--   family text NOT NULL,
--   -- email_token_activate
--   -- email_token_pw_reset
--   name text NOT NULL
-- );

CREATE TABLE tokens (
  user_id int NOT NULL,
  token text NOT NULL,
  type TEXT NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  expires int,
  UNIQUE (token),
  UNIQUE (user_id, TYPE),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

---------------------------
-- Ship/bill addresses
---------------------------

CREATE TABLE countries (
  id int PRIMARY KEY,
  code text NOT NULL,
  name text NOT NULL,
  has_zip boolean NOT NULL,
  requires_state boolean NOT NULL,
  UNIQUE (code),
  UNIQUE (name)
);

CREATE TABLE states (
  id int PRIMARY KEY,
  country_id int NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  UNIQUE (country_id, name),
  -- UNIQUE(country_id, code),
  FOREIGN KEY (country_id) REFERENCES countries (id)
);

CREATE TABLE addresses (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  company_name varchar(70),
  street_address varchar(90) NOT NULL,
  apartment_unit varchar(20),
  country_id int NOT NULL,
  state_id int,
  zip varchar(20),
  name_first varchar(90) NOT NULL,
  name_last varchar(90) NOT NULL,
  phone varchar(20) NOT NULL,
  email varchar(80) NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (country_id) REFERENCES countries (id),
  FOREIGN KEY (state_id) REFERENCES states (id)
);

--
--
------------------------------
--++++++++++++++++++++++++++++
-- SHOP
--++++++++++++++++++++++++++++

CREATE TABLE categories (
  id serial PRIMARY KEY,
  name text NOT NULL,
  slug text NOT NULL,
  created int DEFAULT extract(epoch FROM NOW())
);

CREATE TABLE ingredients (
  id serial PRIMARY KEY,
  name text NOT NULL,
  specification text NOT NULL,
  effective_dose_mg int NOT NULL,
  cost_per_kg real NOT NULL,
  cost_per_test real NOT NULL,
  supplier_url text NOT NULL
);

CREATE TABLE products (
  id serial PRIMARY KEY,
  name text NOT NULL,
  slug text NOT NULL,
  category_id int NOT NULL,
  shippable boolean NOT NULL,
  released boolean NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  serving text,
  serving_grams real,
  usage text,
  details text[],
  sourcing_notes text[],
  citations text[],
  -- TODO: Reference by `tag`? Eliminate `id` for unchanging data?
  FOREIGN KEY (category_id) REFERENCES categories (id)
);

CREATE TABLE product_ingredients (
  product_id int NOT NULL,
  ingredient_id int NOT NULL,
  mg real NOT NULL,
  PRIMARY KEY (product_id, ingredient_id),
  FOREIGN KEY (product_id) REFERENCES products (id),
  FOREIGN KEY (ingredient_id) REFERENCES ingredients (id)
);

CREATE TABLE variants (
  id serial PRIMARY KEY,
  product_id int NOT NULL,
  quantity int,
  unit text,
  mg_per_ct int,
  exemplification text,
  price real NOT NULL,
  grams real,
  dimensions real[],
  stock int,
  interval int,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE CASCADE
);

-- Customer activity
CREATE TABLE customer_activity (
  -- Identifiers
  id serial PRIMARY KEY,
  user_id int,
  email text,
  ip_address text NOT NULL,
  -- payload
  url_current text NOT NULL,
  url_target text,
  action text DEFAULT 'VIEW',
  product_id int,
  variant_id int,
  payload json,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

-- Reviews
CREATE TABLE reviews (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  product_id int NOT NULL,
  rating smallint NOT NULL,
  review_text text NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (user_id, product_id),
  FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

------------------------------
-- Reports
------------------------------

CREATE TABLE reports (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  -- TODO: FK with report_type TABLE ?
  report_type text NOT NULL,
  report_message text NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

------------------------------
-- Cart & Shop
------------------------------

CREATE TABLE coupons (
  id serial PRIMARY KEY,
  code text NOT NULL,
  user_id int,
  expires int NOT NULL,
  created int NOT NULL,
  UNIQUE (code, user_id),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

-- Common box and envelope (sizes and weights)
CREATE TABLE shipping_containers (
  id int PRIMARY KEY,
  courier text NOT NULL,
  method text NOT NULL,
  container text NOT NULL,
  dimensions real[] NOT NULL,
  weight_max real,
  cost json,
  UNIQUE (courier, method, container)
);

-- Orders
CREATE TABLE orders (
  id serial PRIMARY KEY,
  user_id int,
  email text,
  address_bill json,
  address_ship json,
  shipping_method text,
  shipping_price real,
  status text DEFAULT 'INITIALIZED',
  paypal_id text,
  tracking_num text,
  created int DEFAULT extract(epoch FROM NOW()),
  updated int,
  UNIQUE (paypal_id),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

CREATE TABLE order_items (
  order_id int NOT NULL,
  variant_id int NOT NULL,
  quantity smallint NOT NULL,
  price real NOT NULL,
  UNIQUE (order_id, variant_id),
  FOREIGN KEY (order_id) REFERENCES orders (id) ON UPDATE CASCADE,
  FOREIGN KEY (variant_id) REFERENCES variants (id) ON UPDATE CASCADE
);

------------------------------------------
-- Threads & Messages (order related)
------------------------------------------

CREATE TABLE threads (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  subject text NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

CREATE TABLE messages (
  id serial PRIMARY KEY,
  thread_id int NOT NULL,
  body text NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  is_read boolean DEFAULT FALSE,
  FOREIGN KEY (thread_id) REFERENCES threads (id) ON UPDATE CASCADE
);

------------------------------
-- Cart
------------------------------

CREATE TABLE cart (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  product_id int NOT NULL,
  quanity smallint NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (user_id, product_id),
  FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

--
--
------------------------------
--++++++++++++++++++++++++++++
-- IN PROGRESS
--++++++++++++++++++++++++++++
