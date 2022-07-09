-- nutra-db, a database for our server
-- Copyright (C) 2019 - 2022  Shane Jaroch <chown_tee@proton.me>
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
-- TODO: handle this better, in the python script?
DROP SCHEMA IF EXISTS nt CASCADE;

CREATE SCHEMA nt;

SET search_path TO nt;

SET client_min_messages TO WARNING;

---------------------------
-- Versioning table
---------------------------
CREATE TABLE "version" (
  id serial PRIMARY KEY,
  "version" text NOT NULL,
  created date DEFAULT CURRENT_DATE,
  notes text
);

---------------------------
-- Location info
---------------------------
CREATE TABLE country (
  id int PRIMARY KEY,
  code text NOT NULL,
  "name" text NOT NULL,
  has_zip boolean NOT NULL,
  requires_state boolean NOT NULL,
  UNIQUE (code),
  UNIQUE (name)
);

CREATE TABLE state (
  id int PRIMARY KEY,
  country_id int NOT NULL,
  code text NOT NULL,
  "name" text NOT NULL,
  UNIQUE (country_id, name),
  -- UNIQUE(country_id, code),
  FOREIGN KEY (country_id) REFERENCES country (id)
);

--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- Main users tables
--++++++++++++++++++++++++++++
CREATE TABLE "user" (
  id serial PRIMARY KEY,
  username text,
  passwd text,
  created int DEFAULT extract(epoch FROM NOW()),
  country_id int,
  state_id int,
  UNIQUE (username),
  FOREIGN KEY (country_id) REFERENCES country (id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (state_id) REFERENCES state (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE email (
  id serial PRIMARY KEY,
  user_id int NOT NULL,
  email text NOT NULL,
  -- TODO: limit to 5 emails, purge old ones
  "main" boolean NOT NULL,
  activated boolean DEFAULT FALSE,
  created int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (user_id, "main"),
  UNIQUE (email),
  FOREIGN KEY (user_id) REFERENCES "user" (id) ON UPDATE CASCADE
);

-- TODO: do we want to manage this? How. (e.g. analytics vs. customer_activity)
CREATE TABLE device (
  id bigserial PRIMARY KEY,
  user_id int NOT NULL,
  token text NOT NULL,
  last_active int DEFAULT extract(epoch FROM NOW()),
  device_id text NOT NULL, -- e.g. linux nutra@homecpu python-requests/2.24.0
  FOREIGN KEY (user_id) REFERENCES "user" (id) ON UPDATE CASCADE
);

-- CREATE TABLE token_type (
--   id serial PRIMARY KEY,
--   family text NOT NULL,
--   -- email_token_activate
--   -- email_token_pw_reset
--   name text NOT NULL
-- );
CREATE TABLE token (
  -- TODO: device fingerprinting, token revocation, client-side hashing?
  id bigserial PRIMARY KEY,
  user_id int NOT NULL,
  token text NOT NULL,
  "type" text NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  expires int,
  UNIQUE (token),
  UNIQUE (user_id, "type"),
  FOREIGN KEY (user_id) REFERENCES "user" (id) ON UPDATE CASCADE
);

--
--
--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- Food recipes & custom RDAs
--++++++++++++++++++++++++++++
CREATE TABLE bmr_eq (
  id serial PRIMARY KEY,
  "name" text NOT NULL
);

CREATE TABLE bf_eq (
  id serial PRIMARY KEY,
  "name" text NOT NULL
);

CREATE TABLE profile (
  id serial PRIMARY KEY,
  guid text NOT NULL UNIQUE,
  user_id int NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  -- TODO: trigger for last updated
  updated int DEFAULT extract(epoch FROM NOW()),
  eula int DEFAULT 0,
  gender text,
  "name" text,
  dob date,
  activity_level smallint, -- [1, 2, 3, 4, 5]
  goal_weight real,
  goal_bf real,
  bmr_eq_id int, -- ['HARRIS_BENEDICT', 'KATCH_MACARDLE', 'MIFFLIN_ST_JEOR', 'CUNNINGHAM']
  bf_eq_id int, -- ['NAVY', '3SITE', '7SITE']
  FOREIGN KEY (user_id) REFERENCES "user" (id),
  FOREIGN KEY (bf_eq_id) REFERENCES bf_eq (id),
  FOREIGN KEY (bmr_eq_id) REFERENCES bmr_eq (id)
);

CREATE TABLE recipe (
  id serial PRIMARY KEY,
  guid text NOT NULL UNIQUE,
  user_id int NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  updated int DEFAULT extract(epoch FROM NOW()),
  "name" text NOT NULL,
  FOREIGN KEY (user_id) REFERENCES "user" (id)
);

CREATE TABLE recipe_dat (
  recipe_id int NOT NULL,
  -- TODO: enforce FK constraint across two DBs?
  food_id int NOT NULL,
  grams real NOT NULL,
  notes text,
  UNIQUE (recipe_id, food_id),
  FOREIGN KEY (recipe_id) REFERENCES recipe (id) ON UPDATE CASCADE
);

CREATE TABLE rda (
  profile_id int NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  updated int DEFAULT extract(epoch FROM NOW()),
  -- TODO: move below SR, enforce FK constraint across nutr_def
  nutr_id int NOT NULL,
  rda real NOT NULL,
  UNIQUE (profile_id, nutr_id),
  FOREIGN KEY (profile_id) REFERENCES profile (id) ON UPDATE CASCADE
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
-- TODO:  recommendation_foods (many-to-one: [food_ids...] --> rec_id)
--     .. based on user upvotes/reporting?--
CREATE TABLE rec_id (
  id serial PRIMARY KEY,
  "name" text,
  serving_size text, -- NULL == "per rec.serving_size"
  source_urls text[] NOT NULL,
  UNIQUE (name)
);

CREATE TABLE rec (
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
  FOREIGN KEY (rec_id) REFERENCES rec (id) ON UPDATE CASCADE,
  FOREIGN KEY (nutr_id) REFERENCES nutr_def (id) ON UPDATE CASCADE
);

CREATE TABLE rec_dat (
  id int PRIMARY KEY,
  entry_id int NOT NULL,
  rec_nut_id int NOT NULL,
  nutr_val text NOT NULL,
  -- nutr_val float NOT NULL,
  UNIQUE (entry_id, rec_nut_id),
  FOREIGN KEY (entry_id) REFERENCES rec (id) ON UPDATE CASCADE,
  FOREIGN KEY (rec_nut_id) REFERENCES rec_nut (id) ON UPDATE CASCADE
);

--------------------------------------------------
-- Bug reports & message queue
--------------------------------------------------
-- CREATE TABLE reports
-- (
--   id             serial PRIMARY KEY,
--   user_id        int  NOT NULL,
--   -- TODO: FK with report_type TABLE ?
--   -- TODO: base URL for all reports
--   report_type    text NOT NULL,
--   report_message text NOT NULL,
--   created        int DEFAULT extract(epoch FROM NOW()),
--   FOREIGN KEY (user_id) REFERENCES "user" (id) ON UPDATE CASCADE
-- );
-- NOTE: wip
CREATE TABLE client_app (
  id serial PRIMARY KEY,
  "name" text NOT NULL UNIQUE
);

INSERT INTO client_app
  VALUES (1, 'cli'), (2, 'android'), (3, 'web');

CREATE TABLE bug (
  id bigserial PRIMARY KEY,
  guid uuid UNIQUE NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  client_app_name text,
  "version" text,
  "release" text,
  client_info jsonb NOT NULL,
  stack text,
  FOREIGN KEY (client_app_name) REFERENCES client_app ("name") ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE msg (
  id serial PRIMARY KEY,
  guid uuid UNIQUE NOT NULL,
  created int,
  "header" text,
  body text
);
