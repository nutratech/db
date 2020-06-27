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
-- 0.a
-- Get product categories with associated products and variants

CREATE OR REPLACE FUNCTION get_categories ()
  RETURNS TABLE (
    id int,
    name text,
    slug text,
    products json,
    created int
  )
  AS $$
  SELECT
    cats.id,
    cats.name,
    cats.slug,
    array_to_json(ARRAY (
        SELECT
          row_to_json(products)
        FROM products
      WHERE
        category_id = cats.id)),
    cats.created
  FROM
    categories cats
    -- LEFT JOIN reviews rv ON rv.product_id = prod.id
$$
LANGUAGE SQL;

--
--
-- 1.a
-- Get products with variants & avg_ratings

CREATE OR REPLACE FUNCTION get_products ()
  RETURNS TABLE (
    id int,
    name text,
    shippable boolean,
    avg_rating real,
    variants json,
    created int,
    usage text,
    details text[],
    sourcing_notes text[],
    citations text[],
    ingredients json
  )
  AS $$
  SELECT
    prod.id,
    prod.name,
    prod.shippable,
    avg(rv.rating)::real,
    array_to_json(ARRAY (
        SELECT
          row_to_json(variants)
        FROM variants
      WHERE
        product_id = prod.id)),
    prod.created,
    prod.usage,
    prod.details,
    prod.sourcing_notes,
    prod.citations,
    array_to_json(ARRAY (
        SELECT
          row_to_json(ROW)
        FROM (
          SELECT
            ingreds.name, ingreds.specification, mg FROM product_ingredients AS pi
            INNER JOIN ingredients AS ingreds ON pi.ingredient_id = ingreds.id
              AND pi.product_id = prod.id)
          ROW))
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
-- 1.b
-- Get product reviews (with username)

CREATE OR REPLACE FUNCTION get_product_reviews (product_id_in int)
  RETURNS TABLE (
    username text,
    rating smallint,
    title text,
    review_text text,
    created int
  )
  AS $$
  SELECT
    u.username AS username,
    rv.rating,
    rv.title,
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
-- 1.d
-- Get countries with states

CREATE OR REPLACE FUNCTION get_countries_states ()
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

--
--
-- 1.e
-- Get orders with items

CREATE OR REPLACE FUNCTION get_orders (user_id_in int)
  RETURNS TABLE (
    id int,
    address_bill json,
    address_ship json,
    shipping_method text,
    shipping_price real,
    status text,
    tracking_num text,
    items json
  )
  AS $$
  SELECT
    ord.id,
    ord.address_bill,
    ord.address_ship,
    ord.shipping_method,
    ord.shipping_price,
    ord.status,
    ord.tracking_num,
    array_to_json(ARRAY (
        SELECT
          row_to_json(order_items)
        FROM order_items
      WHERE
        order_id = ord.id))
  FROM
    orders ord
    INNER JOIN order_items orit ON ord.id = orit.order_id
  WHERE
    ord.user_id = user_id_in
$$
LANGUAGE SQL;

--
--
-- 1.f
-- Get formulations with associated costs and ingredients
-- CREATE OR REPLACE FUNCTION get_formulations ()
--   RETURNS TABLE ( )
--   AS $$
-- $$
-- LANGUAGE SQL;
--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- #3   USERS
--++++++++++++++++++++++++++++
--
--
-- 3.d
-- Get user details

CREATE OR REPLACE FUNCTION get_user_details (user_id_in int)
  RETURNS TABLE (
    user_id int,
    username text,
    email text,
    email_activated boolean,
    accept_eula boolean
  )
  AS $$
  SELECT
    usr.id,
    usr.username,
    eml.email,
    eml.activated,
    usr.accept_eula
  FROM
    users usr
    INNER JOIN emails eml ON eml.user_id = usr.id
  WHERE
    usr.id = user_id_in
$$
LANGUAGE SQL;

--
--
-- 3.e
-- Get user tokens

CREATE OR REPLACE FUNCTION get_user_tokens (user_id_in int)
  RETURNS TABLE (
    user_id int,
    username text,
    token text,
    token_type text,
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

CREATE OR REPLACE FUNCTION get_user_id_from_username_or_email (identifier text)
  RETURNS TABLE (
    id int,
    username text
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

