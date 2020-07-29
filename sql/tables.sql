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
  terms_agreement timestamp DEFAULT CURRENT_TIMESTAMP,
  gender text,
  name varchar(60),
  job text,
  dob date,
  -- cm & kg
  height smallint,
  weight smallint,
  blood_group text,
  -- TODO: mappings, 0 - 5, or 1 - 5 ??
  activity_level smallint,
  weight_goal smallint,
  bmr_equation smallint,
  bodyfat_method smallint,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (username)
);

CREATE TABLE emails (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  email varchar(140) NOT NULL,
  -- TODO: limit to 5 emails, purge old ones
  main boolean NOT NULL,
  activated boolean DEFAULT FALSE,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (user_id, main),
  UNIQUE (email),
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
  id int PRIMARY KEY,
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
  address text,
  company_name varchar(70),
  street_address varchar(90), -- NOT NULL
  apartment_unit varchar(20),
  country_id int, -- NOT NULL
  state_id int,
  zip varchar(20),
  name_first varchar(90), -- NOT NULL
  name_last varchar(90), -- NOT NULL
  phone varchar(20),
  email varchar(80),
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (country_id) REFERENCES countries (id),
  FOREIGN KEY (state_id) REFERENCES states (id)
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
  units varchar(10),
  tagname varchar(10) NOT NULL,
  nutr_desc text NOT NULL,
  -- weighting?
  UNIQUE (tagname)
);

CREATE TABLE data_src (
  id int PRIMARY KEY NOT NULL,
  name text NOT NULL,
  is_searchable boolean NOT NULL,
  UNIQUE (name)
);

---------------------------
-- Food groups
---------------------------

CREATE TABLE fdgrp (
  id int PRIMARY KEY,
  fdgrp_desc text,
  UNIQUE (fdgrp_desc)
);

---------------------------
-- Food names
---------------------------

CREATE TABLE food_des (
  id serial PRIMARY KEY,
  fdgrp_id int NOT NULL,
  data_src_id int NOT NULL,
  long_desc text NOT NULL,
  shrt_desc varchar(200),
  -- TODO: same as sci_name.
  comm_name text,
  manufacturer text,
  -- gtin_UPC DECIMAL,
  -- ingredients TEXT,

  ref_desc text,
  refuse int,
  sci_name text,
  -- UNIQUE(gtin_UPC),
  FOREIGN KEY (fdgrp_id) REFERENCES fdgrp (id) ON UPDATE CASCADE,
  FOREIGN KEY (data_src_id) REFERENCES data_src (id)
);

---------------------------
-- Food-Nutrient data
---------------------------

CREATE TABLE nut_data (
  food_id int NOT NULL,
  nutr_id int NOT NULL,
  nutr_val real,
  -- TODO: data_src_id as composite key?
  PRIMARY KEY (food_id, nutr_id),
  FOREIGN KEY (food_id) REFERENCES food_des (id) ON UPDATE CASCADE,
  FOREIGN KEY (nutr_id) REFERENCES nutr_def (id) ON UPDATE CASCADE
);

---------------------------
-- Food recommendations
---------------------------

CREATE TABLE recommendation_id (
  id serial PRIMARY KEY,
  name text,
  nutr1_id int,
  nutr2_id int,
  nutr3_id int,
  unit1 text,
  unit2 text,
  unit3 text,
  per_denomination text NOT NULL,
  nutr1_desc text NOT NULL,
  nutr2_desc text,
  nutr3_desc text,
  serving_size text, -- Overrides recommendations.serving_size
  source_urls text[] NOT NULL,
  UNIQUE (name),
  FOREIGN KEY (nutr_id) REFERENCES nutr_def (id) ON UPDATE CASCADE
);

CREATE TABLE recommendations (
  id int PRIMARY KEY,
  rec_id int NOT NULL,
  serving_size text,
  food_name text NOT NULL,
  nutr_val float NOT NULL,
  FOREIGN KEY (rec_id) REFERENCES recommendation_id (id) ON UPDATE CASCADE
);

-- TODO:  recommendation_foods (many-to-one: [food_ids...] --> rec_id)
--     .. based on user upvotes/reporting?
------------------------------
-- Servings
------------------------------

CREATE TABLE serving_id (
  id serial PRIMARY KEY,
  msre_desc text NOT NULL,
  UNIQUE (msre_desc)
);

CREATE TABLE servings (
  food_id int NOT NULL,
  msre_id int NOT NULL,
  grams real NOT NULL,
  PRIMARY KEY (food_id, msre_id),
  FOREIGN KEY (food_id) REFERENCES food_des (id) ON UPDATE CASCADE,
  FOREIGN KEY (msre_id) REFERENCES serving_id (id) ON UPDATE CASCADE
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
  supplier_url text NOT NULL,
  tasting_descriptors text[],
  transparency_note text
);

CREATE TABLE ingredient_nutrients (
  ingredient_id int,
  nutr_id int,
  ratio real NOT NULL,
  PRIMARY KEY (ingredient_id, nutr_id),
  FOREIGN KEY (ingredient_id) REFERENCES ingredients (id),
  FOREIGN KEY (nutr_id) REFERENCES nutr_def (id)
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

