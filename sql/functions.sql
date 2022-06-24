-- nutra-db, a database for nutratracker clients
-- Copyright (C) 2019-2020  Shane Jaroch <nutratracker@gmail.com>
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
-- Get table names, with row counts

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
-- Get functions, with arguments

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
-- TODO: Condition 'users.id = user_id_in OR user_id_in IS NULL' is always 'true'

CREATE OR REPLACE FUNCTION users (user_id_in int DEFAULT NULL)
  RETURNS TABLE (
    id int,
    username text,
    addresses json,
    emails json,
    tokens json
  )
  AS $$
  SELECT
    users.id,
    username,
    row_to_json(addresses),
    row_to_json(emails),
    row_to_json(tokens)
  FROM
    users
  LEFT JOIN addresses ON addresses.user_id = users.id
  LEFT JOIN emails ON emails.user_id = users.id
  LEFT JOIN tokens ON tokens.user_id = users.id
WHERE (users.id = user_id_in
  OR user_id_in IS NULL)
GROUP BY
  users.id,
  addresses.id,
  emails.id,
  tokens.id
ORDER BY
  id
$$
LANGUAGE SQL;

--
--
-- 0.n
--
-- TODO: resolve warnings
--  Condition '(nutr_def.id = ANY (nutr_ids_in) OR nutr_ids_in IS NULL) AND rec_nut.searchable' is always 'false'
--  Expression 'nutr_def.id = ANY (nutr_ids_in)' is always null

CREATE OR REPLACE FUNCTION recs (nutr_ids_in int[] DEFAULT NULL)
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
    recs.rec_id,
    rec_nut.id,
    nutr_def.id,
    rec_nut.notes,
    recs.id,
    food_name,
    serving_size,
    recs.notes,
    rec_dat.nutr_val,
    nutr_def.units
  FROM
    recs
  LEFT JOIN rec_nut ON rec_nut.rec_id = recs.rec_id
  INNER JOIN rec_dat ON entry_id = recs.id
    AND rec_dat.rec_nut_id = rec_nut.id
  LEFT JOIN nutr_def ON nutr_def.id = rec_nut.nutr_id
WHERE (nutr_def.id = ANY (nutr_ids_in)
  OR nutr_ids_in IS NULL)
AND rec_nut.searchable
-- recs.rec_id = ANY (rec_ids_in)
-- OR rec_ids_in IS NULL
$$
LANGUAGE SQL;

--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- #1   SHOP
--++++++++++++++++++++++++++++
--
--
-- 1.k
-- Get countries, with states

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
        FROM states
      WHERE
        country_id = cn.id))
  FROM
    countries cn
  LEFT JOIN states st ON cn.id = st.country_id
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

CREATE OR REPLACE FUNCTION find_user (identifier text)
  RETURNS TABLE (
    id int,
    username text,
    email text,
    activated boolean
  )
  AS $$
  SELECT DISTINCT
    users.id,
    username,
    email,
    activated
  FROM
    users,
    emails
  WHERE
    username = identifier
    OR emails.user_id = users.id
    AND emails.email = identifier
$$
LANGUAGE SQL;
