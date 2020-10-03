-- nutra-db, a database for nutratracker clients
-- Copyright (C) 2019  Nutra, LLC. [Shane & Kyle] <nutratracker@gmail.com>
-- Copyright (C) 2020  Shane Jaroch <nutratracker@gmail.com>
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

CREATE TABLE version (
  id serial PRIMARY KEY,
  version text NOT NULL,
  created timestamp DEFAULT CURRENT_TIMESTAMP,
  notes text
);

--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- Main users tables
--++++++++++++++++++++++++++++
CREATE TABLE users (
  id serial PRIMARY KEY,
  username text,
  passwd text,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (username)
);

CREATE TABLE emails (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  email text NOT NULL,
  -- TODO: limit to 5 emails, purge old ones
  main boolean NOT NULL,
  activated boolean DEFAULT FALSE,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (user_id, main),
  UNIQUE (email),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

CREATE TABLE devices (
  id bigserial PRIMARY KEY,
  user_id int NOT NULL,
  token text NOT NULL,
  last_active int DEFAULT extract(epoch FROM NOW()),
  device_id text NOT NULL, -- e.g. linux nutra@homecpu python-requests/2.24.0
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
  -- TODO: device fingerprinting, token revocation, client-side hashing?
  id bigserial PRIMARY KEY,
  user_id int NOT NULL,
  token text NOT NULL,
  type text NOT NULL,
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
  name text,
  company text,
  street_address1 text NOT NULL,
  street_address2 text,
  country_id int NOT NULL,
  state_id int,
  zip text,
  name_first text NOT NULL,
  name_last text NOT NULL,
  phone text,
  email text,
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (country_id) REFERENCES countries (id),
  FOREIGN KEY (state_id) REFERENCES states (id)
);

--
--
--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- Biometrics, SYNC logs
--++++++++++++++++++++++++++++
CREATE TABLE bmr_eqs (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE bf_eqs (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE profiles (
  id serial PRIMARY KEY,
  guid text NOT NULL UNIQUE,
  user_id int NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  terms_agreement timestamp,
  gender text,
  name_first text,
  name_last text,
  blood_group text,
  dob date,
  activity_level smallint, -- [1, 2, 3, 4, 5]
  goal_weight real,
  goal_bf real,
  bf_eq_id int, -- ['NAVY', '3SITE', '7SITE']
  bmr_eq_id int, -- ['HARRIS_BENEDICT', 'KATCH_MACARDLE', 'MIFFLIN_ST_JEOR', 'CUNNINGHAM']
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (bf_eq_id) REFERENCES bf_eqs (id),
  FOREIGN KEY (bmr_eq_id) REFERENCES bmr_eqs (id)
);

CREATE TABLE recipes (
  id serial PRIMARY KEY,
  guid text NOT NULL UNIQUE,
  user_id int NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  name text NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE recipe_dat (
  recipe_id int NOT NULL,
  -- TODO: enforce FK constraint across two DBs?
  food_id int NOT NULL,
  grams real NOT NULL,
  notes text,
  UNIQUE (recipe_id, food_id),
  FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON UPDATE CASCADE
);

CREATE TABLE meal_names (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE food_log (
  id serial PRIMARY KEY,
  guid text NOT NULL UNIQUE,
  uid int NOT NULL,
  date date DEFAULT CURRENT_DATE,
  meal_id int,
  grams real NOT NULL,
  -- TODO: enforce FK constraint across two DBs?
  food_id int,
  FOREIGN KEY (uid) REFERENCES profiles (id) ON UPDATE CASCADE,
  FOREIGN KEY (meal_id) REFERENCES meal_names (id) ON UPDATE CASCADE
);

CREATE TABLE recipe_log (
  id serial PRIMARY KEY,
  guid text NOT NULL UNIQUE,
  uid int NOT NULL,
  date date DEFAULT CURRENT_DATE,
  meal_id int,
  grams real NOT NULL,
  recipe_id int,
  FOREIGN KEY (uid) REFERENCES profiles (id) ON UPDATE CASCADE,
  FOREIGN KEY (meal_id) REFERENCES meal_names (id) ON UPDATE CASCADE,
  FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON UPDATE CASCADE
);

CREATE TABLE biometrics (
  id serial PRIMARY KEY,
  name text NOT NULL,
  unit text,
  created int DEFAULT extract(epoch FROM NOW())
);

CREATE TABLE biometric_log (
  id serial PRIMARY KEY,
  guid text NOT NULL UNIQUE,
  uid int NOT NULL,
  date date DEFAULT CURRENT_DATE,
  tags text,
  notes text,
  FOREIGN KEY (uid) REFERENCES profiles (id) ON UPDATE CASCADE
);

CREATE TABLE bio_log_entry (
  log_id int NOT NULL,
  biometric_id int NOT NULL,
  value real NOT NULL,
  PRIMARY KEY (log_id, biometric_id),
  FOREIGN KEY (log_id) REFERENCES biometric_log (id) ON UPDATE CASCADE,
  FOREIGN KEY (biometric_id) REFERENCES biometrics (id) ON UPDATE CASCADE
);

CREATE TABLE sync_data (
  id serial PRIMARY KEY,
  tablename text NOT NULL,
  uid int NOT NULL,
  guid text,
  "constraint" text, -- e.g. "(a, b)" in "UNIQUE (a, b)" or "ON CONFLICT (a, b) DO ..."
  action text NOT NULL, -- insert, delete, update
  UNIQUE (tablename, uid, guid),
  FOREIGN KEY (uid) REFERENCES profiles (id) ON UPDATE CASCADE
);

CREATE TABLE rda (
  uid int NOT NULL,
  -- TODO: move below SR, enforce FK constraint across nutr_def
  nutr_id int NOT NULL,
  rda real NOT NULL,
  synced int DEFAULT 0,
  UNIQUE (uid, nutr_id),
  FOREIGN KEY (uid) REFERENCES profiles (id) ON UPDATE CASCADE
);

--
--
--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- USDA SR Database
--++++++++++++++++++++++++++++
CREATE TABLE nutr_def (
  id int PRIMARY KEY,
  rda real,
  units text,
  tagname text NOT NULL,
  nutr_desc text NOT NULL,
  anti_nutrient boolean,
  -- weighting?
  UNIQUE (tagname)
);

---------------------------
-- Food recommendations
---------------------------
CREATE TABLE rec_id (
  id serial PRIMARY KEY,
  name text,
  serving_size text, -- NULL == "per recs.serving_size"
  source_urls text[] NOT NULL,
  UNIQUE (name)
);

CREATE TABLE recs (
  id serial PRIMARY KEY,
  rec_id int NOT NULL,
  food_name text NOT NULL,
  serving_size text, -- Display purposes only
  notes text, -- e.g. visually segregate DAIRY vs. NON-DAIRY for calcium
  source_urls text[], -- If different from rec_id.source_urls
  FOREIGN KEY (rec_id) REFERENCES rec_id (id) ON UPDATE CASCADE
);

CREATE TABLE rec_nut (
  id serial PRIMARY KEY,
  rec_id int NOT NULL,
  nutr_id int,
  nutr_desc text,
  unit text,
  searchable boolean,
  notes text,
  FOREIGN KEY (rec_id) REFERENCES recs (id) ON UPDATE CASCADE,
  FOREIGN KEY (nutr_id) REFERENCES nutr_def (id) ON UPDATE CASCADE
);

CREATE TABLE rec_dat (
  id int PRIMARY KEY,
  entry_id int NOT NULL,
  rec_nut_id int NOT NULL,
  nutr_val text NOT NULL,
  -- nutr_val float NOT NULL,
  UNIQUE (entry_id, rec_nut_id),
  FOREIGN KEY (entry_id) REFERENCES recs (id) ON UPDATE CASCADE,
  FOREIGN KEY (rec_nut_id) REFERENCES rec_nut (id) ON UPDATE CASCADE
);

-- TODO:  recommendation_foods (many-to-one: [food_ids...] --> rec_id)
--     .. based on user upvotes/reporting?--
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
  supplier_url text NOT NULL,
  tasting_descriptors text[],
  transparency_note text
);

CREATE TABLE ingredient_nutrients (
  ingredient_id int,
  nutr_id int,
  ratio real NOT NULL,
  PRIMARY KEY (ingredient_id, nutr_id),
  FOREIGN KEY (ingredient_id) REFERENCES ingredients (id) ON UPDATE CASCADE,
  FOREIGN KEY (nutr_id) REFERENCES nutr_def (id) ON UPDATE CASCADE
);

CREATE TABLE products (
  id serial PRIMARY KEY,
  name text NOT NULL,
  slug text NOT NULL,
  -- TODO: support multiple categories
  category_id int NOT NULL,
  shippable boolean NOT NULL,
  released boolean NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  typical_dose text,
  usage text,
  details text[],
  citations text[],
  -- TODO: Reference by `tag`? Eliminate `id` for unchanging data?
  FOREIGN KEY (category_id) REFERENCES categories (id) ON UPDATE CASCADE
);

CREATE TABLE product_ingredients (
  product_id int NOT NULL,
  ingredient_id int NOT NULL,
  mg real NOT NULL,
  PRIMARY KEY (product_id, ingredient_id),
  FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE CASCADE,
  FOREIGN KEY (ingredient_id) REFERENCES ingredients (id) ON UPDATE CASCADE
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
  serving text,
  serving_mg int,
  dimensions real[],
  stock int,
  interval int,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE CASCADE
);

-- Reviews
CREATE TABLE reviews (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  product_id int NOT NULL,
  rating smallint NOT NULL,
  title text NOT NULL,
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
  -- TODO: base URL for all reports
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
  email text, -- require either email OR user_id
  created int DEFAULT extract(epoch FROM NOW()),
  updated int,
  shipping_method text,
  shipping_price real,
  status text DEFAULT 'INITIALIZED',
  tracking_num text,
  paypal_id text,
  address_bill json,
  address_ship json,
  UNIQUE (paypal_id),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

CREATE TABLE order_items (
  order_id int NOT NULL,
  variant_id int NOT NULL,
  quantity smallint DEFAULT 1,
  price real NOT NULL,
  UNIQUE (order_id, variant_id),
  FOREIGN KEY (order_id) REFERENCES orders (id) ON UPDATE CASCADE,
  FOREIGN KEY (variant_id) REFERENCES variants (id) ON UPDATE CASCADE
);

CREATE TABLE order_shipments (
  order_id int NOT NULL,
  container_id int NOT NULL,
  quantity smallint DEFAULT 1,
  FOREIGN KEY (order_id) REFERENCES orders (id) ON UPDATE CASCADE,
  FOREIGN KEY (container_id) REFERENCES shipping_containers (id) ON UPDATE CASCADE
);

--
--
------------------------------
--++++++++++++++++++++++++++++
-- IN PROGRESS
--++++++++++++++++++++++++++++
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

