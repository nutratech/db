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
    variants jsonb
  )
  AS $$
  SELECT
    prod.id,
    prod.name,
    shippable,
    jsonb_agg(vars)
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
--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- #2   Public DATA
--++++++++++++++++++++++++++++
--
--
--
-- 2.a
-- Get all nutrients by food_id

CREATE OR REPLACE FUNCTION get_nutrients_by_food_ids (food_id_in int[])
  RETURNS TABLE (
    food_id int,
    fdgrp_id int,
    long_desc varchar,
    manufacturer varchar,
    nutrients json
  )
  AS $$
  SELECT
    des.id,
    des.fdgrp_id,
    long_desc,
    manufacturer,
    json_agg(json_build_object('nutr_id', val.nutr_id, 'nutr_desc', nutr_desc, 'tagname', tagname, 'nutr_val', nutr_val, 'units', units)) AS nutrients
  FROM
    food_des des
  LEFT JOIN nut_data val ON val.food_id = des.id
  LEFT JOIN nutr_def def ON def.id = val.nutr_id
WHERE
  des.id = ANY (food_id_in)
GROUP BY
  des.id,
  long_desc
$$
LANGUAGE SQL;

--
--
-- 2.b
-- Return 100 foods highest in a given nutr_id

CREATE OR REPLACE FUNCTION sort_foods_by_nutrient_id (nutr_id_in int)
  RETURNS TABLE (
    nutr_id int,
    units varchar,
    tagname varchar,
    nutr_desc varchar,
    foods json
  )
  AS $$
  SELECT
    def.id,
    def.units,
    def.tagname,
    def.nutr_desc,
    json_agg(json_build_object('food_id', des.id, 'long_desc', des.long_desc, 'nutr_val', val.nutr_val, 'data_src', src.name, 'fdgrp_desc', grp.fdgrp_desc)
    ORDER BY
      val.nutr_val DESC) AS foods
  FROM (
    SELECT
      food_id,
      nutr_val,
      nutr_id
    FROM
      nut_data val
    WHERE
      val.nutr_id = nutr_id_in
    ORDER BY
      val.nutr_val DESC FETCH FIRST 100 ROWS ONLY) val
  LEFT JOIN nutr_def def ON def.id = val.nutr_id
  LEFT JOIN food_des des ON val.food_id = des.id
  LEFT JOIN data_src src ON src.id = des.data_src_id
  LEFT JOIN fdgrp grp ON grp.id = des.fdgrp_id
GROUP BY
  def.id,
  def.units,
  def.tagname,
  def.nutr_desc
$$
LANGUAGE SQL;

--
--
-- 2.c
-- Get servings for food

CREATE OR REPLACE FUNCTION get_food_servings (food_id_in int)
  RETURNS TABLE (
    msre_id int,
    msre_desc varchar,
    grams real
  )
  AS $$
  SELECT
    serv.msre_id,
    serv_id.msre_desc,
    serv.grams
  FROM
    servings serv
  LEFT JOIN serving_id serv_id ON serv.msre_id = serv_id.id
WHERE
  serv.food_id = food_id_in
$$
LANGUAGE SQL;

--
--
--++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++
-- #3   Private DATA
--++++++++++++++++++++++++++++
--
--
--
-- 3.a
-- Get user RDAs

CREATE OR REPLACE FUNCTION get_user_rdas (user_id_in int)
  RETURNS TABLE (
    nutr_id int,
    rda real,
    units varchar,
    tagname varchar,
    nutr_desc varchar
  )
  AS $$
  SELECT
    rda.id,
    COALESCE(urda.rda, rda.rda) AS rda,
    rda.units,
    rda.tagname,
    rda.nutr_desc
  FROM
    nutr_def rda
  LEFT JOIN rda urda ON rda.id = urda.nutr_id
    AND urda.user_id = user_id_in
$$
LANGUAGE SQL;

--
--
-- 3.b
-- Get user favorite foods

CREATE OR REPLACE FUNCTION get_user_favorite_foods (user_id_in int)
  RETURNS TABLE (
    food_id int,
    long_desc varchar
  )
  AS $$
  SELECT
    food_id,
    fdes.long_desc
  FROM
    favorite_foods ff
    INNER JOIN food_des fdes ON fdes.id = ff.food_id
  WHERE
    ff.user_id = user_id_in
$$
LANGUAGE SQL;

--
--
-- 3.c
-- Get user's trainers

CREATE OR REPLACE FUNCTION get_user_trainers (user_id_in int)
  RETURNS TABLE (
    trainer_id int,
    username varchar
  )
  AS $$
  SELECT
    tusr.trainer_id,
    usr.username
  FROM
    trainer_users tusr
  LEFT JOIN users usr ON usr.id = tusr.trainer_id
WHERE
  tusr.user_id = user_id_in
$$
LANGUAGE SQL;

--
--
-- 3.d
-- Get trainer's users

CREATE OR REPLACE FUNCTION get_trainer_users (trainer_id_in int)
  RETURNS TABLE (
    user_id int,
    username varchar
  )
  AS $$
  SELECT
    usr.id,
    usr.username
  FROM
    users usr
  LEFT JOIN trainer_users tusr ON tusr.user_id = usr.id
WHERE
  tusr.trainer_id = trainer_id_in
$$
LANGUAGE SQL;

--
--
-- 3.d
-- Get user details

CREATE OR REPLACE FUNCTION get_user_details (user_id_in int)
  RETURNS TABLE (
    user_id int,
    username varchar,
    email varchar,
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

