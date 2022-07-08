-- nutra-db, a database for nutratracker clients
-- Copyright (C) 2019-2022  Shane Jaroch <chown_tee@proton.me>
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
--
SET search_path TO nt;

SET client_min_messages TO WARNING;

--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- #0   META
--++++++++++++++++++++++++++++
--
--
-- 0.a
-- List tables, with row counts
--
CREATE OR REPLACE FUNCTION tables ()
  RETURNS TABLE (
    schemaname name,
    tablename name,
    row_count bigint
  )
  AS $$
  SELECT
    schemaname,
    relname,
    n_live_tup
  FROM
    pg_stat_user_tables
  ORDER BY
    n_live_tup DESC
$$
LANGUAGE SQL;

--
--
-- 0.b
-- List functions, with arguments
--
CREATE OR REPLACE FUNCTION functions ()
  RETURNS TABLE (
    proname name,
    oidvectortypes text,
    format text,
    args text
  )
  AS $$
  SELECT
    p.proname,
    oidvectortypes(p.proargtypes),
    format('%I(%s)', p.proname, oidvectortypes(p.proargtypes)),
    pg_get_function_arguments(p.oid)
  FROM
    pg_proc p
    INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
  WHERE
    ns.nspname = 'nt'
$$
LANGUAGE SQL;

--
--
-- 0.g
-- Get user overview, with info
--
CREATE OR REPLACE FUNCTION user (user_id_in int DEFAULT NULL)
  RETURNS TABLE (
    id int,
    username text,
    email json,
    token json
  )
  AS $$
  SELECT
    "user".id,
    username,
    row_to_json(email),
    row_to_json(token)
  FROM
    "user"
  LEFT JOIN email ON email.user_id = "user".id
  LEFT JOIN token ON token.user_id = "user".id
WHERE (user.id = user_id_in
  OR user_id_in IS NULL)
GROUP BY
  "user".id,
  email.id,
  token.id
ORDER BY
  id
$$
LANGUAGE SQL;

--
--
-- 0.n
-- Recommendations
--
CREATE OR REPLACE FUNCTION rec (nutr_ids_in int[] DEFAULT NULL)
  RETURNS TABLE (
    -- id int,
    rec_id int,
    rec_nut_id int,
    nutr_id int,
    nutr_notes text,
    entry_id int,
    food_name text,
    serving_size text,
    notes text,
    value text,
    unit text
  )
  AS $$
  SELECT
    rec.rec_id,
    rec_nut.id,
    nutr_def.id,
    rec_nut.notes,
    rec.id,
    food_name,
    serving_size,
    rec.notes,
    rec_dat.nutr_val,
    nutr_def.units
  FROM
    rec
  LEFT JOIN rec_nut ON rec_nut.rec_id = rec.rec_id
  INNER JOIN rec_dat ON entry_id = rec.id
    AND rec_dat.rec_nut_id = rec_nut.id
  LEFT JOIN nutr_def ON nutr_def.id = rec_nut.nutr_id
WHERE (nutr_def.id = ANY (nutr_ids_in)
  OR nutr_ids_in IS NULL)
AND rec_nut.searchable
-- rec.rec_id = ANY (rec_ids_in)
-- OR rec_ids_in IS NULL
$$
LANGUAGE SQL;

--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- #1   GENERAL
--++++++++++++++++++++++++++++
--
--
-- 1.k
-- Get countries, with states
--
CREATE OR REPLACE FUNCTION countries ()
  RETURNS TABLE (
    id int,
    code text,
    name text,
    has_zip boolean,
    requires_state boolean,
    states json
  )
  AS $$
  SELECT
    cn.id,
    cn.code,
    cn.name,
    cn.has_zip,
    cn.requires_state,
    array_to_json(ARRAY (
        SELECT
          row_to_json(states)
        FROM state
        WHERE
          country_id = cn.id))
  FROM
    country cn
  LEFT JOIN state st ON cn.id = st.country_id
GROUP BY
  cn.id
$$
LANGUAGE SQL;

--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- #3   USERS
--++++++++++++++++++++++++++++
--
--
-- 3.f
-- Get user by email OR username
--
CREATE OR REPLACE FUNCTION find_user (identifier text)
  RETURNS TABLE (
    id int,
    username text,
    email text,
    activated boolean
  )
  AS $$
  SELECT DISTINCT
    "user".id,
    username,
    email,
    activated
  FROM
    user,
    email
  WHERE
    username = identifier
    OR email.user_id = "user".id
    AND email.email = identifier
$$
LANGUAGE SQL;
