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

DROP SCHEMA nt CASCADE;

CREATE SCHEMA nt;

SET search_path TO nt;

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
  id int NOT NULL PRIMARY KEY,
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
  is_anti boolean NOT NULL,
  user_id bigint,
  is_shared boolean NOT NULL,
  -- weighting?
  UNIQUE (tagname),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
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
  user_id int,
  is_shared boolean NOT NULL,
  -- UNIQUE(gtin_UPC),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE,
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
--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- Users Database
--++++++++++++++++++++++++++++

CREATE TABLE rda (
  nutr_id int NOT NULL,
  user_id int NOT NULL,
  rda real NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  PRIMARY KEY (user_id, nutr_id),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE,
  FOREIGN KEY (nutr_id) REFERENCES nutr_def (id) ON UPDATE CASCADE
);

------------------------------
-- Custom recipes
------------------------------

CREATE TABLE recipe_des (
  id serial PRIMARY KEY,
  recipe_name varchar(255) NOT NULL,
  user_id int NOT NULL,
  -- publicly shared ?
  shared boolean NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

CREATE TABLE recipe_dat (
  recipe_id int NOT NULL,
  food_id int NOT NULL,
  -- msre_id == (NULL || 0) ==> grams
  msre_id int,
  amount real NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  PRIMARY KEY (recipe_id, food_id),
  FOREIGN KEY (recipe_id) REFERENCES recipe_des (id) ON UPDATE CASCADE,
  FOREIGN KEY (food_id) REFERENCES food_des (id) ON UPDATE CASCADE
);

-- Recipe Portions
CREATE TABLE portion_id (
  id serial PRIMARY KEY,
  portion_desc varchar(255) NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (portion_desc)
);

CREATE TABLE portions (
  recipe_id int NOT NULL,
  portion_id int NOT NULL,
  percentage real NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  PRIMARY KEY (recipe_id, portion_id),
  FOREIGN KEY (recipe_id) REFERENCES recipe_des (id) ON UPDATE CASCADE,
  FOREIGN KEY (portion_id) REFERENCES portion_id (id) ON UPDATE CASCADE
);

------------------------------
-- Favorite foods
------------------------------

CREATE TABLE favorite_foods (
  user_id int NOT NULL,
  food_id int NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  PRIMARY KEY (user_id, food_id),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE,
  FOREIGN KEY (food_id) REFERENCES food_des (id) ON UPDATE CASCADE
);

------------------------------
-- Food logs
------------------------------

CREATE TABLE food_logs (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  eat_on_date date NOT NULL,
  -- TODO: FK and meal TABLE ?
  meal_name text NOT NULL,
  amount real NOT NULL,
  msre_id int,
  recipe_id int,
  food_id int,
  created int DEFAULT extract(epoch FROM NOW()),
  updated int,
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE,
  FOREIGN KEY (msre_id) REFERENCES serving_id (id) ON UPDATE CASCADE,
  FOREIGN KEY (recipe_id) REFERENCES recipe_des (id) ON UPDATE CASCADE,
  FOREIGN KEY (food_id) REFERENCES food_des (id) ON UPDATE CASCADE
);

------------------------------
-- Exercises
------------------------------

CREATE TABLE exercises (
  id serial PRIMARY KEY,
  name text NOT NULL,
  data_src_id int NOT NULL,
  cals_per_rep real,
  cals_per_min real,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (data_src_id) REFERENCES data_src (id)
);

CREATE TABLE exercise_logs (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  exercise_id int NOT NULL,
  date date NOT NULL,
  reps int,
  weight int,
  duration_min int,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE,
  FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON UPDATE CASCADE
);

------------------------------
-- Biometrics
------------------------------

CREATE TABLE biometrics (
  id serial PRIMARY KEY,
  name text NOT NULL,
  units text NOT NULL,
  created int DEFAULT extract(epoch FROM NOW())
);

CREATE TABLE biometric_logs (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  biometric_id int NOT NULL,
  timestamp timestamp NOT NULL,
  bio_val real NOT NULL,
  unit text NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE,
  FOREIGN KEY (biometric_id) REFERENCES biometrics (id) ON UPDATE CASCADE
);

------------------------------
-- Trainer Roles
------------------------------

CREATE TABLE trainer_users (
  trainer_id int NOT NULL,
  user_id int NOT NULL,
  approved boolean NOT NULL DEFAULT FALSE,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (trainer_id, user_id),
  FOREIGN KEY (trainer_id) REFERENCES users (id) ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

------------------------------
-- Reports
------------------------------

CREATE TABLE reports (
  user_id int NOT NULL,
  -- TODO: FK with report_type TABLE ?
  report_type text NOT NULL,
  report_message text NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  PRIMARY KEY (user_id, created),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

--
--
------------------------------
--++++++++++++++++++++++++++++
-- SHOP
--++++++++++++++++++++++++++++

CREATE TABLE products (
  id serial PRIMARY KEY,
  name text NOT NULL,
  tag text NOT NULL,
  shippable boolean NOT NULL,
  released boolean NOT NULL,
  created int DEFAULT extract(epoch FROM NOW())
);

CREATE TABLE variants (
  id serial PRIMARY KEY,
  product_id int NOT NULL,
  denomination text NOT NULL,
  price int NOT NULL,
  weight int,
  dimensions real[],
  stock int,
  interval int,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE CASCADE
);

-- Customer activity
CREATE TABLE customer_activity (
  -- Identifiers
  user_id int,
  email text,
  ip_address text NOT NULL,
  -- payload
  url_current text NOT NULL,
  url_target text,
  action text DEFAULT 'VIEW',
  product_id int,
  variant_id int,
  payload JSONB,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);
CREATE TABLE views (
  user_id int NOT NULL,
  product_id int NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  PRIMARY KEY (user_id, product_id),
  FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE CASCADE,
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
  method_id int NOT NULL,
  -- for readability
  shipping_type text NOT NULL,
  tag text NOT NULL,
  dimensions real[] NOT NULL,
  weight_max real
);

-- Orders
CREATE TABLE orders (
  id serial PRIMARY KEY,
  user_id int,
  email text,
  address_bill jsonb,
  address_ship jsonb,
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

CREATE TABLE tag_id (
  id serial PRIMARY KEY,
  tag_desc varchar(255) NOT NULL,
  shared boolean DEFAULT TRUE NOT NULL,
  approved boolean DEFAULT FALSE NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (tag_desc)
);

CREATE TABLE tags (
  food_id int NOT NULL,
  tag_id int NOT NULL,
  user_id int NOT NULL,
  -- votes, approved?
  created int DEFAULT extract(epoch FROM NOW()),
  PRIMARY KEY (food_id, tag_id),
  FOREIGN KEY (food_id) REFERENCES food_des (id) ON UPDATE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tag_id (id) ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

------------------------------
-- Scratchpad
------------------------------

CREATE TABLE scratchpad (
  user_id int NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

