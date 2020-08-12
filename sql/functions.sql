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
-- 1.a
-- Get product categories with associated products and variants

CREATE OR REPLACE FUNCTION categories ()
  RETURNS TABLE (
    id int,
    name text,
    slug text,
    products json,
    created int
  )
  AS $$
  SELECT
    category.id,
    category.name,
    category.slug,
    array_to_json(ARRAY (
        SELECT
          row_to_json(products)
        FROM products
      WHERE
        category_id = category.id)),
    category.created
  FROM
    categories category
$$
LANGUAGE SQL;

--
--
-- 1.c (pre1)
-- Get products with variants & avg_ratings

CREATE OR REPLACE FUNCTION ingredient_nutrients (ingredient_id_in int)
  RETURNS TABLE (
    nutrients json
  )
  AS $$
  SELECT
    row_to_json(ROW)
  FROM (
    SELECT
      nutr_id,
      nutr_desc,
      rda,
      units,
      ratio
    FROM
      ingredient_nutrients
      INNER JOIN nutr_def ON nutr_def.id = nutr_id
    WHERE
      ingredient_id = ingredient_id_in)
  ROW
$$
LANGUAGE SQL;

--
--
-- 1.c (pre I)
-- Gets orders (for review page info, "verified purchase" etc)

CREATE OR REPLACE FUNCTION reviews (product_id_in int DEFAULT NULL)
  RETURNS TABLE (
    username text,
    order_id int,
    order_date int,
    product_id int,
    variant_id int,
    review_id int,
    rating smallint,
    review_date int,
    title text,
    body text
  )
  AS $$
  SELECT DISTINCT
    username,
    orders.id,
    orders.created,
    variants.product_id,
    variant_id,
    reviews.id,
    rating,
    reviews.created,
    title,
    review_text
  FROM
    reviews
    INNER JOIN users ON users.id = user_id
    INNER JOIN products ON products.id = product_id
    INNER JOIN variants ON variants.product_id = products.id
    LEFT JOIN order_items ON variants.id = variant_id
    LEFT JOIN orders ON orders.id = order_id
      AND orders.user_id = users.id
  WHERE (products.id = product_id_in
    OR product_id_in IS NULL)
  AND ((orders.id IS NULL
      AND variant_id IS NULL)
    OR (orders.id IS NOT NULL
      AND variant_id IS NOT NULL))
$$
LANGUAGE SQL;

--
--
-- 1.c
-- Get products with variants & avg_ratings
-- TODO: find out why `SELECT id FROM products();` doesn't yield product 8 (no variants, yet)

CREATE OR REPLACE FUNCTION products ()
  RETURNS TABLE (
    id int,
    name text,
    shippable boolean,
    category_id int,
    avg_rating real,
    variants json,
    created int,
    typical_dose text,
    usage text,
    details text[],
    citations text[],
    ingredients json,
    reviews json
  )
  AS $$
  SELECT
    prod.id,
    name,
    shippable,
    category_id,
    avg(rv.rating)::real,
    -- Variants
    array_to_json(ARRAY (
        SELECT
          row_to_json(variants)
        FROM variants
      WHERE
        product_id = prod.id)),
    prod.created,
    typical_dose,
    usage,
    details,
    citations,
    -- Ingredients
    array_to_json(ARRAY (
        SELECT
          row_to_json(ROW)
        FROM (
          SELECT
            id, name, specification, mg AS amount_mg, tasting_descriptors, transparency_note,
            -- Nutrients
            array_to_json(ARRAY (
                SELECT
                  nutrients FROM ingredient_nutrients (ingred.id))) AS nutrients
          -- From product ingredients table
          FROM product_ingredients AS pi
          INNER JOIN ingredients AS ingred ON pi.ingredient_id = ingred.id
            AND pi.product_id = prod.id)
          ROW)),
    -- Reviews
    array_to_json(ARRAY (
        SELECT
          row_to_json(reviews (prod.id))))
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

--
--
-- 1.o
-- Get orders with items

CREATE OR REPLACE FUNCTION orders (user_id_in int DEFAULT NULL)
  RETURNS TABLE (
    id int,
    user_id int,
    email text,
    created int,
    updated int,
    shipping_method text,
    shipping_price real,
    status text,
    tracking_num text,
    paypal_id text,
    address_bill json,
    address_ship json,
    items json
  )
  AS $$
  SELECT
    ord.id,
    ord.user_id,
    ord.email,
    ord.created,
    ord.updated,
    ord.shipping_method,
    ord.shipping_price,
    ord.status,
    ord.tracking_num,
    ord.paypal_id,
    ord.address_bill,
    ord.address_ship,
    -- items JSON
    array_to_json(ARRAY (
        SELECT
          row_to_json(ROW)
        FROM (
          SELECT
            variant, product, item.quantity, item.price FROM order_items item
            INNER JOIN variants variant ON variant.id = variant_id
            INNER JOIN products product ON variant.product_id = product.id
              AND order_id = ord.id)
          ROW))
  FROM
    orders ord
WHERE
  ord.user_id = user_id_in
  OR user_id_in IS NULL
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
    username text
  )
  AS $$
  SELECT DISTINCT
    users.id,
    username
  FROM
    users,
    emails
  WHERE
    username = identifier
    OR emails.user_id = users.id
    AND emails.email = identifier
$$
LANGUAGE SQL;

