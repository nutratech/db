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
--

SET search_path TO nt;

SET client_min_messages TO WARNING;

--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- #1   SHOP
--++++++++++++++++++++++++++++
--
--
--
-- 1.a
-- Get product reviews (with username)

CREATE OR REPLACE FUNCTION get_product_reviews (product_id_in int)
  RETURNS TABLE (
    username varchar,
    rating smallint,
    review_text varchar,
    created int
  )
  AS $$
  SELECT
    u.username AS username,
    rv.rating,
    rv.review_text,
    rv.created
  FROM
    reviews AS rv
    INNER JOIN users AS u ON rv.user_id = u.id
  WHERE
    rv.product_id = product_id_in
$$
LANGUAGE SQL;

--
--
-- 1.b
-- Get products with avg_ratings

CREATE OR REPLACE FUNCTION get_products_ratings ()
  RETURNS TABLE (
    id int,
    name varchar,
    shippable boolean,
    avg_rating real,
    created int
  )
  AS $$
  SELECT
    prod.id,
    prod.name,
    shippable,
    avg(rv.rating)::real,
    prod.created
  FROM
    products prod
  LEFT JOIN reviews rv ON rv.product_id = prod.id
WHERE
  released
GROUP BY
  prod.id
ORDER BY
  prod.id
$$
LANGUAGE SQL;

--
--
-- 1.c
-- Get products (with variants)

CREATE OR REPLACE FUNCTION get_products ()
  RETURNS TABLE (
    id int,
    name varchar,
    shippable boolean,
    variants json
  )
  AS $$
  SELECT
    prod.id,
    prod.name,
    shippable,
    (SELECT row_to_json(variants) FROM variants WHERE product_id=prod.id)::json
  FROM
    products prod
    INNER JOIN variants vars ON vars.product_id = prod.id
  WHERE
    released
  GROUP BY
    prod.id
$$
LANGUAGE SQL;

--
--
-- 1.d
-- Get countries with states

CREATE OR REPLACE FUNCTION get_countries_states ()
  RETURNS TABLE (
    id int,
    code varchar,
    name varchar,
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
    json_agg(st)
  FROM
    countries cn
  LEFT JOIN states st ON cn.id = st.country_id
GROUP BY
  cn.id
$$
LANGUAGE SQL;

--
--
-- 3.e
-- Get user tokens

CREATE OR REPLACE FUNCTION get_user_tokens (user_id_in int)
  RETURNS TABLE (
    user_id int,
    username varchar,
    token varchar,
    token_type varchar,
    created int
  )
  AS $$
  SELECT
    usr.id,
    usr.username,
    tkn.token,
    tkn.type,
    tkn.created
  FROM
    users usr
    INNER JOIN tokens tkn ON tkn.user_id = usr.id
  WHERE
    usr.id = user_id_in
$$
LANGUAGE SQL;

--
--
-- 3.f
-- Get user by email OR username

CREATE OR REPLACE FUNCTION get_user_id_from_username_or_email (identifier varchar)
  RETURNS TABLE (
    id int,
    username varchar
  )
  AS $$
  SELECT DISTINCT
    id,
    username
  FROM
    users,
    emails
  WHERE
    username = identifier
    OR emails.user_id = id
    AND emails.email = identifier
$$
LANGUAGE SQL;

