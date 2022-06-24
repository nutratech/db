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

DROP SCHEMA IF EXISTS nt CASCADE;

CREATE SCHEMA nt;

SET search_path TO nt;

SET client_min_messages TO WARNING;

CREATE TABLE "version"
(
  id      serial PRIMARY KEY,
  version text NOT NULL,
  created timestamp DEFAULT CURRENT_TIMESTAMP,
  notes   text
);

--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- Main users tables
--++++++++++++++++++++++++++++

CREATE TABLE users
(
  id       serial PRIMARY KEY,
  username text,
  passwd   text,
  created  int DEFAULT extract(epoch FROM NOW()),
  UNIQUE (username)
);

CREATE TABLE emails
(
  id        serial PRIMARY KEY,
  user_id   int     NOT NULL,
  email     text    NOT NULL,
  -- TODO: limit to 5 emails, purge old ones
  main      boolean NOT NULL,
  activated boolean DEFAULT FALSE,
  created   int     DEFAULT extract(epoch FROM NOW()),
  UNIQUE (user_id, main),
  UNIQUE (email),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

-- TODO: do we want to manage this? How. (e.g. analytics vs. customer_activity)
CREATE TABLE devices
(
  id          bigserial PRIMARY KEY,
  user_id     int  NOT NULL,
  token       text NOT NULL,
  last_active int DEFAULT extract(epoch FROM NOW()),
  device_id   text NOT NULL, -- e.g. linux nutra@homecpu python-requests/2.24.0
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

-- CREATE TABLE token_types (
--   id serial PRIMARY KEY,
--   family text NOT NULL,
--   -- email_token_activate
--   -- email_token_pw_reset
--   name text NOT NULL
-- );

CREATE TABLE tokens
(
  -- TODO: device fingerprinting, token revocation, client-side hashing?
  id      bigserial PRIMARY KEY,
  user_id int  NOT NULL,
  token   text NOT NULL,
  type    text NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  expires int,
  UNIQUE (token),
  UNIQUE (user_id, TYPE),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);

---------------------------
-- Location info
---------------------------

CREATE TABLE countries
(
  id             int PRIMARY KEY,
  code           text    NOT NULL,
  name           text    NOT NULL,
  has_zip        boolean NOT NULL,
  requires_state boolean NOT NULL,
  UNIQUE (code),
  UNIQUE (name)
);

CREATE TABLE states
(
  id         int PRIMARY KEY,
  country_id int  NOT NULL,
  code       text NOT NULL,
  name       text NOT NULL,
  UNIQUE (country_id, name),
  -- UNIQUE(country_id, code),
  FOREIGN KEY (country_id) REFERENCES countries (id)
);

--
--
--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- Biometrics, SYNC logs
--++++++++++++++++++++++++++++

CREATE TABLE bmr_eqs
(
  id   serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE bf_eqs
(
  id   serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE profiles
(
  id             serial PRIMARY KEY,
  guid           text NOT NULL UNIQUE,
  user_id        int  NOT NULL,
  created        int DEFAULT extract(epoch FROM NOW()),
  updated        int DEFAULT extract(epoch FROM NOW()),
  eula           int DEFAULT 0,
  gender         text,
  name_first     text,
  name_last      text,
  blood_group    text,
  dob            date,
  activity_level smallint, -- [1, 2, 3, 4, 5]
  goal_weight    real,
  goal_bf        real,
  bmr_eq_id      int,      -- ['HARRIS_BENEDICT', 'KATCH_MACARDLE', 'MIFFLIN_ST_JEOR', 'CUNNINGHAM']
  bf_eq_id       int,      -- ['NAVY', '3SITE', '7SITE']
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (bf_eq_id) REFERENCES bf_eqs (id),
  FOREIGN KEY (bmr_eq_id) REFERENCES bmr_eqs (id)
);

CREATE TABLE recipes
(
  id      serial PRIMARY KEY,
  guid    text NOT NULL UNIQUE,
  user_id int  NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  updated int DEFAULT extract(epoch FROM NOW()),
  name    text NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE recipe_dat
(
  recipe_id int  NOT NULL,
  -- TODO: enforce FK constraint across two DBs?
  food_id   int  NOT NULL,
  grams     real NOT NULL,
  notes     text,
  UNIQUE (recipe_id, food_id),
  FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON UPDATE CASCADE
);

CREATE TABLE meal_names
(
  id   serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE food_log
(
  id      serial PRIMARY KEY,
  guid    text NOT NULL UNIQUE,
  uid     int  NOT NULL,
  created int  DEFAULT extract(epoch FROM NOW()),
  updated int  DEFAULT extract(epoch FROM NOW()),
  date    date DEFAULT CURRENT_DATE,
  meal_id int,
  grams   real NOT NULL,
  -- TODO: enforce FK constraint across two DBs?
  food_id int,
  FOREIGN KEY (uid) REFERENCES profiles (id) ON UPDATE CASCADE,
  FOREIGN KEY (meal_id) REFERENCES meal_names (id) ON UPDATE CASCADE
);

CREATE TABLE recipe_log
(
  id        serial PRIMARY KEY,
  guid      text NOT NULL UNIQUE,
  uid       int  NOT NULL,
  created   int  DEFAULT extract(epoch FROM NOW()),
  updated   int  DEFAULT extract(epoch FROM NOW()),
  date      date DEFAULT CURRENT_DATE,
  meal_id   int,
  grams     real NOT NULL,
  recipe_id int,
  FOREIGN KEY (uid) REFERENCES profiles (id) ON UPDATE CASCADE,
  FOREIGN KEY (meal_id) REFERENCES meal_names (id) ON UPDATE CASCADE,
  FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON UPDATE CASCADE
);

CREATE TABLE biometrics
(
  id      serial PRIMARY KEY,
  name    text NOT NULL,
  unit    text,
  created int DEFAULT extract(epoch FROM NOW())
);

CREATE TABLE biometric_log
(
  id      serial PRIMARY KEY,
  guid    text NOT NULL UNIQUE,
  uid     int  NOT NULL,
  created int  DEFAULT extract(epoch FROM NOW()),
  updated int  DEFAULT extract(epoch FROM NOW()),
  date    date DEFAULT CURRENT_DATE,
  tags    text,
  notes   text,
  FOREIGN KEY (uid) REFERENCES profiles (id) ON UPDATE CASCADE
);

CREATE TABLE bio_log_entry
(
  log_id       int  NOT NULL,
  biometric_id int  NOT NULL,
  value        real NOT NULL,
  PRIMARY KEY (log_id, biometric_id),
  FOREIGN KEY (log_id) REFERENCES biometric_log (id) ON UPDATE CASCADE,
  FOREIGN KEY (biometric_id) REFERENCES biometrics (id) ON UPDATE CASCADE
);

CREATE TABLE rda
(
  uid     int  NOT NULL,
  created int DEFAULT extract(epoch FROM NOW()),
  updated int DEFAULT extract(epoch FROM NOW()),
  -- TODO: move below SR, enforce FK constraint across nutr_def
  nutr_id int  NOT NULL,
  rda     real NOT NULL,
  UNIQUE (uid, nutr_id),
  FOREIGN KEY (uid) REFERENCES profiles (id) ON UPDATE CASCADE
);

--
--
--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- USDA SR Database
--++++++++++++++++++++++++++++

CREATE TABLE nutr_def
(
  id            int PRIMARY KEY,
  rda           real,
  units         text,
  tagname       text NOT NULL,
  nutr_desc     text NOT NULL,
  anti_nutrient boolean,
  -- weighting?
  UNIQUE (tagname)
);

---------------------------
-- Food recommendations
---------------------------
-- TODO:  recommendation_foods (many-to-one: [food_ids...] --> rec_id)
--     .. based on user upvotes/reporting?--
CREATE TABLE rec_id
(
  id           serial PRIMARY KEY,
  name         text,
  serving_size text, -- NULL == "per recs.serving_size"
  source_urls  text[] NOT NULL,
  UNIQUE (name)
);

CREATE TABLE recs
(
  id           serial PRIMARY KEY,
  rec_id       int  NOT NULL,
  food_name    text NOT NULL,
  serving_size text,   -- Display purposes only
  notes        text,   -- e.g. visually segregate DAIRY vs. NON-DAIRY for calcium
  source_urls  text[], -- If different from rec_id.source_urls
  FOREIGN KEY (rec_id) REFERENCES rec_id (id) ON UPDATE CASCADE
);

CREATE TABLE rec_nut
(
  id         serial PRIMARY KEY,
  rec_id     int NOT NULL,
  nutr_id    int,
  nutr_desc  text,
  unit       text,
  searchable boolean,
  notes      text,
  FOREIGN KEY (rec_id) REFERENCES recs (id) ON UPDATE CASCADE,
  FOREIGN KEY (nutr_id) REFERENCES nutr_def (id) ON UPDATE CASCADE
);

CREATE TABLE rec_dat
(
  id         int PRIMARY KEY,
  entry_id   int  NOT NULL,
  rec_nut_id int  NOT NULL,
  nutr_val   text NOT NULL,
  -- nutr_val float NOT NULL,
  UNIQUE (entry_id, rec_nut_id),
  FOREIGN KEY (entry_id) REFERENCES recs (id) ON UPDATE CASCADE,
  FOREIGN KEY (rec_nut_id) REFERENCES rec_nut (id) ON UPDATE CASCADE
);

--------------------------------------------------
-- Bug reports & message queue
--------------------------------------------------
CREATE TABLE reports
(
  id             serial PRIMARY KEY,
  user_id        int  NOT NULL,
  -- TODO: FK with report_type TABLE ?
  -- TODO: base URL for all reports

  report_type    text NOT NULL,
  report_message text NOT NULL,
  created        int DEFAULT extract(epoch FROM NOW()),
  FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE
);
