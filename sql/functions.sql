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
    --addresses
    array_to_json(ARRAY (
        SELECT
          row_to_json(addresses)
        FROM addresses
      WHERE
        user_id = users.id)),
    -- emails
    array_to_json(ARRAY (
        SELECT
          row_to_json(emails)
        FROM emails
      WHERE
        user_id = users.id)),
    -- tokens
    array_to_json(ARRAY (
        SELECT
          row_to_json(tokens)
        FROM tokens
      WHERE
        user_id = users.id))
  FROM
    users
  LEFT JOIN addresses ON addresses.user_id = users.id
  LEFT JOIN emails ON emails.user_id = users.id
  LEFT JOIN tokens ON tokens.user_id = users.id
WHERE (users.id = user_id_in
  OR user_id_in IS NULL)
GROUP BY
  users.id
ORDER BY
  id
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
-- 1.c
-- Get products with variants & avg_ratings

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
          row_to_json(ROW)
        FROM (
          SELECT
            u.username AS username, review FROM reviews AS review
          INNER JOIN users AS u ON review.user_id = u.id
            AND review.product_id = prod.id)
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
-- 1.f
-- Get product reviews (with username)

CREATE OR REPLACE FUNCTION product_reviews (product_id_in int)
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
-- 1.k
-- Get countries with states

CREATE OR REPLACE FUNCTION countries_states ()
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

CREATE OR REPLACE FUNCTION orders (user_id_in int)
  RETURNS TABLE (
    id int,
    address_bill json,
    address_ship json,
    shipping_method text,
    shipping_price real,
    status text,
    tracking_num text,
    paypal_id text,
    items json,
    created int
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
    ord.paypal_id,
    array_to_json(ARRAY (
        SELECT
          row_to_json(ROW)
        FROM (
          SELECT
            variant, product, item.quantity, item.price FROM order_items item
            INNER JOIN variants variant ON variant.id = variant_id
            INNER JOIN products product ON variant.product_id = product.id
              AND order_id = ord.id)
          ROW)),
    ord.created
  FROM
    orders ord
WHERE
  ord.user_id = user_id_in
$$
LANGUAGE SQL;

--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- #2   Public DATA
--++++++++++++++++++++++++++++
--
--
-- 2.a
-- Get all nutrients by food_id

CREATE OR REPLACE FUNCTION analyze_food_ids (food_id_in int[])
  RETURNS TABLE (
    food_id int,
    fdgrp_id int,
    long_desc text,
    manufacturer text,
    nutrients json
  )
  AS $$
  SELECT
    des.id,
    des.fdgrp_id,
    long_desc,
    manufacturer,
    array_to_json(ARRAY (
        SELECT
          row_to_json(ROW)
        FROM (
          SELECT
            def.nutr_desc, def.tagname, def.units, nutr_id, nutr_val FROM nut_data
            INNER JOIN nutr_def def ON def.id = nutr_id
              AND food_id = des.id)
          ROW))
  FROM
    food_des des
WHERE
  des.id = ANY (food_id_in)
$$
LANGUAGE SQL;

--
--
-- 2.b
-- Return 100 foods highest in a given nutr_id

CREATE OR REPLACE FUNCTION sort_foods_by_nutr_id (nutr_id_in int, fdgrp_id_in int[] DEFAULT NULL)
  RETURNS TABLE (
    food_id int,
    nutr_desc text,
    fdgrp int,
    fdgrp_desc text,
    value real,
    unit text,
    kcal real,
    long_desc text
  )
  AS $$
  SELECT
    nut_data.food_id,
    nutr_desc,
    fdgrp_id,
    fdgrp_desc,
    nut_data.nutr_val,
    units,
    kcal.nutr_val,
    long_desc
  FROM
    nut_data
    INNER JOIN food_des food ON id = food_id
    INNER JOIN nutr_def ndef ON ndef.id = nutr_id
    INNER JOIN fdgrp ON fdgrp.id = fdgrp_id
    LEFT JOIN nut_data kcal ON food.id = kcal.food_id
      AND kcal.nutr_id = 208
  WHERE
    nut_data.nutr_id = nutr_id_in
    -- filter by food id, if supplied
    AND (fdgrp_id = ANY (fdgrp_id_in)
      OR fdgrp_id_in IS NULL)
  ORDER BY
    nut_data.nutr_val DESC FETCH FIRST 100 ROWS ONLY
$$
LANGUAGE SQL;

--
--
-- 2.b II
-- Return 100 foods highest in a given nutr_id (per 200 kcal)

CREATE OR REPLACE FUNCTION sort_foods_by_kcal_nutr_id (nutr_id_in int, fdgrp_id_in int[] DEFAULT NULL)
  RETURNS TABLE (
    food_id int,
    nutr_desc text,
    fdgrp_id int,
    fdgrp_desc text,
    nutr_val real,
    units text,
    kcal_per_100g real,
    long_desc text
  )
  AS $$
  SELECT
    nut_data.food_id,
    nutr_desc,
    fdgrp_id,
    fdgrp_desc,
    ROUND((nut_data.nutr_val * 200 / kcal.nutr_val)::decimal, 2)::real,
    units,
    kcal.nutr_val,
    long_desc
  FROM
    nut_data
    INNER JOIN food_des food ON id = food_id
    INNER JOIN nutr_def ndef ON ndef.id = nutr_id
    INNER JOIN fdgrp ON fdgrp.id = fdgrp_id
    -- filter out NULL kcal
    INNER JOIN nut_data kcal ON food.id = kcal.food_id
      AND kcal.nutr_id = 208
  WHERE
    nut_data.nutr_id = nutr_id_in
    -- filter by food id, if supplied
    AND (fdgrp_id = ANY (fdgrp_id_in)
      OR fdgrp_id_in IS NULL)
  ORDER BY
    (nut_data.nutr_val / kcal.nutr_val) DESC FETCH FIRST 100 ROWS ONLY -- ON food.id = kcal.food_id AND kcal.nutr_id = 208
$$
LANGUAGE SQL;

--
--
-- 2.c
-- Get servings for food

CREATE OR REPLACE FUNCTION servings (food_ids_in int[] DEFAULT NULL)
  RETURNS TABLE (
    food_id int,
    msre_id int,
    msre_desc text,
    grams real
  )
  AS $$
  SELECT
    serv.food_id,
    serv.msre_id,
    serv_id.msre_desc,
    serv.grams
  FROM
    servings serv
  LEFT JOIN serving_id serv_id ON serv.msre_id = serv_id.id
WHERE
  serv.food_id = ANY (food_ids_in)
  OR food_ids_in IS NULL
$$
LANGUAGE SQL;

--
--
-- 2.d
-- Get nutrient overiew

CREATE OR REPLACE FUNCTION nutrients ()
-- TODO: decide milligram vs IU FOR vitamin A, E, D.. this function/script will help decid which are most common
  RETURNS TABLE (
    id int,
    nutr_desc text,
    rda real,
    units text,
    tagname text,
    food_count bigint,
    avg_val real,
    avg_rda real
  )
  AS $$
  SELECT
    id,
    nutr_desc,
    rda,
    units,
    tagname,
    COUNT(nut_data.nutr_id),
    ROUND(avg(nut_data.nutr_val)::decimal, 3)::real,
    ROUND(100 * (avg(nut_data.nutr_val) / rda)::decimal, 1)::real
  FROM
    nutr_def
    INNER JOIN nut_data ON nut_data.nutr_id = id
  GROUP BY
    id
  ORDER BY
    id
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

CREATE OR REPLACE FUNCTION find_user_id (identifier text)
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

