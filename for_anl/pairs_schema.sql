--
-- PostgreSQL database dump
--

-- Dumped from database version 11.6 (Ubuntu 11.6-1.pgdg18.04+1)
-- Dumped by pg_dump version 11.8 (Ubuntu 11.8-1.pgdg18.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pairs; Type: SCHEMA; Schema: -; Owner: pairs_db_master
--

CREATE SCHEMA pairs;
-- 
-- 
-- CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
-- COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
-- CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;
-- COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
-- COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';
-- CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
-- COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';
-- 
-- 
CREATE EXTENSION postgis WITH SCHEMA ibm_extension;
CREATE EXTENSION pg_stat_statements WITH SCHEMA ibm_extension;
CREATE EXTENSION fuzzystrmatch WITH SCHEMA ibm_extension;
ALTER SCHEMA pairs OWNER TO pairs_db_master;

GRANT USAGE ON SCHEMA pairs TO metadata_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA pairs TO metadata_writer;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA pairs TO metadata_writer;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pairs TO metadata_writer;
GRANT ALL ON ALL TABLES IN SCHEMA pairs TO metadata_writer;
GRANT ALL ON ALL SEQUENCES IN SCHEMA pairs TO metadata_writer;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA pairs TO metadata_writer;

GRANT USAGE ON SCHEMA pairs TO metadata_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA pairs TO metadata_reader;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA pairs TO metadata_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pairs TO metadata_reader;
GRANT ALL ON ALL TABLES IN SCHEMA pairs TO metadata_reader;
GRANT ALL ON ALL SEQUENCES IN SCHEMA pairs TO metadata_reader;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA pairs TO metadata_reader;

GRANT USAGE ON SCHEMA pairs TO pairs_db_master;
GRANT SELECT ON ALL TABLES IN SCHEMA pairs TO pairs_db_master;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA pairs TO pairs_db_master;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pairs TO pairs_db_master;
GRANT ALL ON ALL TABLES IN SCHEMA pairs TO pairs_db_master;
GRANT ALL ON ALL SEQUENCES IN SCHEMA pairs TO pairs_db_master;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA pairs TO pairs_db_master;
--
-- Name: add_property_string2(text, text); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.add_property_string2(_tablename text, _tmp_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE fields text;
DECLARE table_id_out integer;
BEGIN
        BEGIN
        execute 'ALTER TABLE pairs.' || _tablename || ' ADD property_string text';
        EXCEPTION
        WHEN duplicate_column THEN RAISE NOTICE 'column property_string already exists in .';
        END;
        BEGIN
        execute 'ALTER TABLE pairs.' || _tmp_name || ' ADD property_string text';
        EXCEPTION
        WHEN duplicate_column THEN RAISE NOTICE 'column property_string already exists in .';
        END;
with table_info as (select ci.*, ti.db_table_name FROM pairs.pairs_pointdata_table_info ti, pairs.pairs_pointdata_column_info ci where ti.db_table_name = _tablename AND ti.id=ci.table_id AND ( ci.attrib = 'Other_Property' OR ci.attrib='Region') )
-- select 'CONCAT('|| array_to_string(array_agg('''' || col_name || ':'',cte.' || col_name), ','';'', ')|| ')' into fields  FROM table_info;
select array_to_string(array_agg('''' || col_name || ':''||COALESCE(cte.' || col_name||'::text,'''')'), '||'';''||') into fields  FROM table_info;
--      BEGIN
        execute 'WITH cte AS (SELECT * FROM pairs.'|| _tmp_name || ' where property_string is null limit 5000000 ) UPDATE pairs.'|| _tmp_name || ' t set property_string = (SELECT '|| fields || ' ) FROM cte where  t.id = cte.id';
--      EXCEPTION
--      WHEN query string argument THEN RAISE NOTICE 'wrong ';
--      END;
        -- execute 'WITH cte AS (SELECT * FROM pairs.'|| _tablename || ' where property_string is null) UPDATE pairs.'|| _tablename || ' t set property_string = (SELECT '|| fields || ' ) FROM cte where  t.id = cte.id';
END;
$$;


ALTER FUNCTION pairs.add_property_string2(_tablename text, _tmp_name text) OWNER TO pairs_db_master;

--
-- Name: add_property_string3(text, text); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.add_property_string3(_tablename text, _tmp_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
        DECLARE fields          TEXT;
        DECLARE table_id_out    INTEGER;
        BEGIN
            -- make sure that the property_string column exists for both tables
            BEGIN
                EXECUTE
                    'ALTER TABLE ' || _tablename || ' ADD property_string TEXT';
                EXCEPTION
                    WHEN duplicate_column
                    THEN RAISE NOTICE 'column property_string already exists in .';
            END;
            BEGIN
                EXECUTE 'ALTER TABLE ' || _tmp_name || ' ADD property_string TEXT';
                EXCEPTION
                    WHEN duplicate_column
                    THEN RAISE NOTICE 'column property_string already exists in .';
            END;
            -- get metadata from PAIRS Postgres (assumed that the relevant tables are remotely linked in)
            WITH table_info AS (
                SELECT
                        ci.*,
                        ti.db_table_name
                    FROM
                        pairs.pairs_pointdata_table_info ti,
                        pairs.pairs_pointdata_column_info ci
                    WHERE
                            ti.db_table_name = _tablename
                        AND
                            ti.id = ci.table_id
                        AND (
                                ci.attrib = 'Other_Property'
                            OR
                                ci.attrib = 'Region'
                        )
            )
            -- create property string concatenation
            SELECT array_to_string(
                array_agg(
                    '''' || col_name || ':'' || COALESCE(' || col_name || '::text, '''') '
                ), ' || '';'' || '
            ) INTO fields FROM table_info;
            -- generate property string in temporary table
            EXECUTE
                ' UPDATE ' || _tmp_name || ' SET property_string = ' || fields;
        END;
    $$;


ALTER FUNCTION pairs.add_property_string3(_tablename text, _tmp_name text) OWNER TO pairs_db_master;

--
-- Name: get_aoi_fqn(bigint); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.get_aoi_fqn(aoi_id bigint) RETURNS character varying
    LANGUAGE plpgsql
    AS $$  
DECLARE  
    fqn VARCHAR;
	level NUMERIC;
	aoi_row pairs.pairs_aoi%rowtype;   
BEGIN
	
	select *
	  into aoi_row
	  from pairs.pairs_aoi
	 where polygon_id = aoi_id;
	 	 
	 IF aoi_row IS NOT NULL THEN
	 
	 --fqn := aoi_row.shortname;
	 level := aoi_row.hierarchy_id;
	 
	 LOOP
	 	level := level -1;
		
		IF aoi_row.parent_id IS NOT NULL THEN
			
		select *
		  into aoi_row
	      from pairs.pairs_aoi
	     where polygon_id = aoi_row.parent_id;
	
			--fqn := aoi_row.shortname || ',' ||aoi_row.parent_id || '.' || fqn;
		
	    ELSE
		  	level := 0;
		END IF;
		
		EXIT WHEN level = 0;  
	END LOOP;
	
   --SELECT 'default body' into fqn;
   
	ELSE
		Select name
	  into fqn
	  from pairs.pairs_query_aoi
	 where id = aoi_id;
	END IF;
	  
   return fqn;
   
END;
$$;


ALTER FUNCTION pairs.get_aoi_fqn(aoi_id bigint) OWNER TO pairs_db_master;

--
-- Name: get_local_query_folder(text); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.get_local_query_folder(_query_id text) RETURNS text
    LANGUAGE sql
    AS $$
    SELECT (
        SELECT value
            FROM pairs.pairs_config
            WHERE key = 'pairs.config.fs.local'
            LIMIT 1
        )                           ||
        '/jobs/'                    ||
        (
            SELECT value
                FROM pairs.pairs_config
                WHERE key = 'pairs.config.query.folder.server_prefix'
                LIMIT 1
        )                           ||
        trim(to_char(s.id,'00'))    ||
        '/' || u.login              ||
        '/' || j.folder
    FROM pairs.pairs_query_job j
        INNER JOIN pairs.pairs_config_server s
        ON s.id = j.server_id
        INNER JOIN pairs.pairs_auth_user u
        ON u.id = j.usr
    WHERE j.id = _query_id;
$$;


ALTER FUNCTION pairs.get_local_query_folder(_query_id text) OWNER TO pairs_db_master;

--
-- Name: get_number_avail_cache_pixels(integer, real, real, real, real); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.get_number_avail_cache_pixels(_layerid integer, _xmin real DEFAULT (0)::numeric, _xmax real DEFAULT ('10000000000'::bigint)::numeric, _ymin real DEFAULT (0)::numeric, _ymax real DEFAULT ('10000000000'::bigint)::numeric) RETURNS real
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _Nrows          REAL        DEFAULT 0.;
BEGIN
    SELECT count(1)
        FROM pairs.pairs_layer_avail_level11 AS o
        WHERE
                layer_id = _layerID
            AND (o.xi BETWEEN _xmin AND _xmax)
            AND (o.yi BETWEEN _ymin AND _ymax)
    INTO _Nrows;
    RETURN _Nrows;
END;
$$;


ALTER FUNCTION pairs.get_number_avail_cache_pixels(_layerid integer, _xmin real, _xmax real, _ymin real, _ymax real) OWNER TO pairs_db_master;

--
-- Name: get_random_avail_cache_pixels(integer, integer, real, real, real, real, real); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.get_random_avail_cache_pixels(_layerid integer, _msample integer DEFAULT 1000, _xmin real DEFAULT (0)::numeric, _xmax real DEFAULT ('10000000000'::bigint)::numeric, _ymin real DEFAULT (0)::numeric, _ymax real DEFAULT ('10000000000'::bigint)::numeric, _nrows real DEFAULT 0) RETURNS TABLE(pairs_key bigint, xi integer, yi integer)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    _rmin           REAL;
    _rmax           REAL;
BEGIN
    -- explicitly get number of rows (if not specified)
    IF _Nrows = 0. THEN
        SELECT pairs.get_number_avail_cache_pixels(_layerID, _xmin, _xmax, _ymin, _ymax)
            INTO _Nrows;
    END IF;
    -- compute random interval for selecting random rows
    IF _Nrows = 0 THEN
        RETURN QUERY
            SELECT o.pairs_key, o.xi, o.yi
                FROM pairs.pairs_layer_avail_level11 AS o
                LIMIT 0;
    ELSE
        _rmin := greatest(0,random() - _Msample/_Nrows);
        _rmax := _rmin + _Msample / _Nrows;
        -- get random samples
        RETURN QUERY
            SELECT o.pairs_key, o.xi, o.yi
                FROM pairs.pairs_layer_avail_level11 AS o
                WHERE
                        layer_id = _layerID
                    AND (o.xi BETWEEN _xmin AND _xmax)
                    AND (o.yi BETWEEN _ymin AND _ymax)
                    AND (random BETWEEN _rmin AND _rmax)
                    LIMIT _Msample;
    END IF;
END;
$$;


ALTER FUNCTION pairs.get_random_avail_cache_pixels(_layerid integer, _msample integer, _xmin real, _xmax real, _ymin real, _ymax real, _nrows real) OWNER TO pairs_db_master;

--
-- Name: get_rel_query_folder(text); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.get_rel_query_folder(_query_id text) RETURNS text
    LANGUAGE sql
    AS $$
    SELECT
        u.login     ||
        '/'         ||
        q.folder
        FROM pairs.pairs_query_job q
        JOIN pairs.pairs_auth_user u
            ON u.id = q.usr
            WHERE q.id = _query_id;
$$;


ALTER FUNCTION pairs.get_rel_query_folder(_query_id text) OWNER TO pairs_db_master;

--
-- Name: has_dimensions(character varying); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.has_dimensions(t_layerid character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
  v_curr record;

declare
  build_text text;
declare
  _temp text;
declare
  col_name text;
declare
  table_name text;
declare
  separator text;
begin
  separator := '';
  build_text := 'N';
    EXECUTE 'select dimension from pairs.pairs_datalayer_mapping m join pairs.pairs_pointdata_column_info c on m.pointlayerid=c.table_id  where datalayerid='''|| t_layerid || ''' AND c.dimension=''Y'' limit 1;' INTO build_text;
  RETURN build_text;
end;
$$;


ALTER FUNCTION pairs.has_dimensions(t_layerid character varying) OWNER TO pairs_db_master;

--
-- Name: pairs_get_dimension_column(numeric); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.pairs_get_dimension_column(in_layer_id numeric) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

DECLARE
   layer_row   pairs.pairs_data_layer%ROWTYPE;
   dimension_row   pairs.pairs_dimensions%ROWTYPE;
   dim_value_row   pairs.pairs_dim_values%ROWTYPE;
   column_name     varchar;
BEGIN
   column_name = '';
   
   SELECT *
        INTO layer_row
        FROM pairs.pairs_data_layer
       WHERE id = in_layer_id;
   
   column_name = layer_row.col_q;
   
   FOR dimension_row IN SELECT *
                          FROM pairs.pairs_dimensions
                         WHERE layer_id = in_layer_id
 order by dim_order
   LOOP
   
  IF dimension_row.default_value is not null THEN
     SELECT *
        INTO dim_value_row
        FROM pairs.pairs_dim_values
       WHERE id = dimension_row.default_value;

     column_name = column_name || '@' || dimension_row.identifier || dim_value_row.value_string;
  END IF;

   END LOOP;
   RETURN column_name;
END;
$$;


ALTER FUNCTION pairs.pairs_get_dimension_column(in_layer_id numeric) OWNER TO pairs_db_master;

--
-- Name: pairs_query_job_status_timestamp(); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.pairs_query_job_status_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$                                                                                                           
 DECLARE
   r_status numeric(2,0);
   v_status numeric(2,0);                                                                                                                 
 BEGIN
   if NEW.status <> OLD.status then
    insert into pairs.pairs_query_job_status
      (queryjob, r_status, v_status, timestamp)
    values
      (NEW.id, NEW.status, null, (extract(EPOCH FROM now())::numeric(30,0))*1000);
   end if;
   
   if NEW.pd_status <> OLD.pd_status then
    insert into pairs.pairs_query_job_status
      (queryjob, r_status, v_status, timestamp)
    values
      (NEW.id, null, NEW.pd_status, (extract(EPOCH FROM now())::numeric(30,0))*1000);
   end if;
 
 RETURN NEW;
      
  END;                                                                                                                   
                                                                                                                         
$$;


ALTER FUNCTION pairs.pairs_query_job_status_timestamp() OWNER TO pairs_db_master;

--
-- Name: pointdata_clean_csv(character varying); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.pointdata_clean_csv(in_job_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
   DELETE FROM pairs.pairs_pointdata_table_query_join
         WHERE data_id IN (SELECT id
                             FROM pairs.pairs_pointdata_table_query_data
                            WHERE job_id = in_job_id);

   DELETE FROM pairs.pairs_pointdata_table_query_attr
         WHERE job_id = in_job_id;

   DELETE FROM pairs.pairs_pointdata_table_query_data
         WHERE job_id = in_job_id;

   DELETE FROM pairs.pairs_pointdata_table_query_column
         WHERE job_id = in_job_id;
END;
$$;


ALTER FUNCTION pairs.pointdata_clean_csv(in_job_id character varying) OWNER TO pairs_db_master;

--
-- Name: pointdata_parse_csv(character varying); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.pointdata_parse_csv(in_job_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$

DECLARE
   p_first        NUMERIC;
   p_count        NUMERIC;
   p_header_id    NUMERIC;
   p_column_id    INTEGER;
   p_data_id      NUMERIC;
   p_attr_id      NUMERIC;
   p_region       VARCHAR;
   p_lat          NUMERIC;
   p_lon          NUMERIC;
   p_timestamp    NUMERIC;
   p_index        NUMERIC;
   p_isnum        VARCHAR;
   p_attr_map     NUMERIC [];
   csv_row        pairs.pairs_pointdata_table_query_csv%ROWTYPE;
   data_token     TEXT [];
   region_token   TEXT [];
   prop_token     TEXT [];
   curr_token     TEXT;
   keyvl_token    TEXT [];
   properties     TEXT;
BEGIN
   p_first = 1;

   RAISE NOTICE 'Start';

   DELETE FROM pairs.pairs_pointdata_table_query_csv
         WHERE job_id = in_job_id AND data LIKE 'DataSet,Name,Time%';

   FOR csv_row IN SELECT *
                    FROM pairs.pairs_pointdata_table_query_csv
                   WHERE job_id = in_job_id
   LOOP
      p_index = 1;
      data_token =
         string_to_array (
            substr (csv_row.data, 0, position ('''' IN csv_row.data)),
            ',');
      properties = substr (csv_row.data, position ('''' IN csv_row.data) + 1);

      RAISE NOTICE 'Current row %', csv_row.data;

      IF p_count = 100
      THEN
         RAISE NOTICE 'Current row %', csv_row.data;
         p_count = 0;
      END IF;

      p_count = p_count + 1;

      -- CREATES A COLUMN, IF IT DOESN'T EXIST

      SELECT id
        INTO p_column_id
        FROM pairs.pairs_pointdata_table_query_column jc
       WHERE jc.job_id = in_job_id AND jc.key = data_token[2];

      IF p_column_id IS NULL
      THEN
         p_isnum = 'n';

         IF textregexeq (trim (BOTH FROM data_token[8]),
                         '^[[:digit:]]+(\.[[:digit:]]+)?$')
         THEN
            p_isnum = 'y';
         END IF;

         RAISE NOTICE 'Iserting column %', data_token[2];

         INSERT INTO pairs.pairs_pointdata_table_query_column (id,
                                                               job_id,
                                                               key,
                                                               is_num,
                                                               dataset)
                 VALUES (
                           nextval (
                              'pairs.pairs_pointdata_table_query_column_seq'),
                           in_job_id,
                           data_token[2],
                           p_isnum,
                           data_token[1]);

         SELECT currval ('pairs.pairs_pointdata_table_query_column_seq')
           INTO p_column_id;
      END IF;



      -- CREATES A DATA ROW
      IF length (trim (BOTH FROM data_token[4])) = 0
      THEN
         p_lat = NULL;
      ELSE
         p_lat = to_number (data_token[4], '9999.999');
      END IF;

      IF length (trim (BOTH FROM data_token[5])) = 0
      THEN
         p_lon = NULL;
      ELSE
         p_lon = to_number (data_token[5], '9999.999');
      END IF;

      IF length (trim (BOTH FROM data_token[6])) = 0
      THEN
         p_region = NULL;
      ELSE
         region_token = string_to_array (data_token[6], ':');
         p_region = region_token[1];
      END IF;

      p_timestamp =
         EXTRACT (
            EPOCH FROM to_timestamp (replace (data_token[3], 'T', ''),
                                     'MM/DD/YYHH24:MI:SS')::TIMESTAMP);


      RAISE NOTICE 'Before inser data %', now ();

      INSERT INTO pairs.pairs_pointdata_table_query_data (id,
                                                          job_id,
                                                          "timestamp",
                                                          lat,
                                                          lon,
                                                          region,
                                                          col_id,
                                                          value,
                                                          unit)
           VALUES (nextval ('pairs.pairs_pointdata_table_query_data_seq'),
                   in_job_id,
                   p_timestamp * 1000,
                   p_lat,
                   p_lon,
                   p_region,
                   p_column_id,
                   data_token[8],
                   data_token[7]);

      --PARSE PROPERTIES
      SELECT currval ('pairs.pairs_pointdata_table_query_data_seq')
        INTO p_data_id;

      prop_token =
         string_to_array (substr (properties, 0, length (properties) - 1),
                          ';');


  FOREACH curr_token IN ARRAY prop_token
     LOOP

        keyvl_token = string_to_array(curr_token, ':');

     IF keyvl_token[1] IS NOT NULL THEN

  IF p_first = 1 THEN

   INSERT INTO pairs.pairs_pointdata_table_query_attr
      (id,
      job_id,
      col_id,
      description)
     VALUES
      (nextval('pairs.pairs_pointdata_table_query_attr_seq'),
      in_job_id,
      p_column_id,
      keyvl_token[1]);

   SELECT currval('pairs.pairs_pointdata_table_query_attr_seq') INTO p_attr_id;

   p_attr_map[p_index] =  p_attr_id;

  END IF;

      INSERT INTO pairs.pairs_pointdata_table_query_join
     (data_id,
     attr_type_id,
     attr_value)
      VALUES(
    p_data_id,
     p_attr_map[p_index],
     keyvl_token[2]);

  END IF;

     p_index = p_index + 1;
     END LOOP;
      p_first = 0;
   END LOOP;
   
      DELETE FROM pairs.pairs_pointdata_table_query_csv WHERE job_id = in_job_id;
   
END;
$_$;


ALTER FUNCTION pairs.pointdata_parse_csv(in_job_id character varying) OWNER TO pairs_db_master;

--
-- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: pairs; Owner: pairs_db_master
--

CREATE FUNCTION pairs.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
      NEW.updated_at = NOW(); 
      RETURN NEW;
END;
$$;


ALTER FUNCTION pairs.trigger_set_timestamp() OWNER TO pairs_db_master;

-- SET default_tablespace = default_pairs_tablespace;

SET default_with_oids = false;

--
-- Name: containment; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.containment (
    id bigint,
    containt bigint,
    name character varying(256),
    containt_name character varying(256)
);


ALTER TABLE pairs.containment OWNER TO pairs_db_master;

--
-- Name: pairs_aoi; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_aoi (
    polygon_id bigint NOT NULL,
    hierarchy_id bigint,
    name text,
    shortname text,
    description text,
    center_lat real,
    center_lon real,
    continent_id bigint,
    country_id bigint,
    state_id bigint,
    county_id bigint,
    city_id bigint,
    zip_id bigint,
    body_of_water_id bigint,
    parent_id bigint,
    agricultural_district_id bigint,
    watershed_id bigint,
    ers_region_poly_id integer
);


ALTER TABLE pairs.pairs_aoi OWNER TO pairs_db_master;

--
-- Name: pairs_query_aoi; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_query_aoi (
    id bigint NOT NULL,
    key character varying(256),
    name character varying(256),
    grp numeric(8,0),
    usr numeric(8,0),
    poly geometry(Geometry,4326),
    area_deg_square numeric(10,7),
    created_by numeric(5,0),
    updated_by numeric(5,0),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE pairs.pairs_query_aoi OWNER TO pairs_db_master;

--
-- Name: pairs_aoi_geojson; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_aoi_geojson AS
 SELECT pairs_query_aoi.id,
    st_asgeojson(pairs_query_aoi.poly) AS geojson
   FROM pairs.pairs_query_aoi;


ALTER TABLE pairs.pairs_aoi_geojson OWNER TO pairs_db_master;

--
-- Name: pairs_aoi_hierarchy; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_aoi_hierarchy (
    id bigint NOT NULL,
    parent_id bigint,
    name text
);


ALTER TABLE pairs.pairs_aoi_hierarchy OWNER TO pairs_db_master;

--
-- Name: pairs_aoi_hierarchy_id_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_aoi_hierarchy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_aoi_hierarchy_id_seq OWNER TO pairs_db_master;

--
-- Name: pairs_aoi_hierarchy_id_seq; Type: SEQUENCE OWNED BY; Schema: pairs; Owner: pairs_db_master
--

ALTER SEQUENCE pairs.pairs_aoi_hierarchy_id_seq OWNED BY pairs.pairs_aoi_hierarchy.id;


--
-- Name: pairs_auth_disclaimer; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_auth_disclaimer (
    id numeric(5,0) NOT NULL,
    version numeric(5,0) DEFAULT 1 NOT NULL,
    name character varying(64) NOT NULL,
    start date NOT NULL,
    url character varying(256),
    active character varying(1),
    document bytea
);


ALTER TABLE pairs.pairs_auth_disclaimer OWNER TO pairs_db_master;

--
-- Name: pairs_auth_disclaimer_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_auth_disclaimer_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_auth_disclaimer_seq OWNER TO pairs_db_master;

--
-- Name: pairs_auth_group; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_auth_group (
    id numeric(8,0) NOT NULL,
    name character varying(64),
    query_limit_gb numeric(5,0),
    query_limit_run numeric(5,0) DEFAULT 10,
    query_limit_tot numeric(5,0) DEFAULT 0,
    query_limit_write numeric(5,0) DEFAULT 2,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by numeric(8,0),
    updated_by numeric(8,0),
    external_id character varying
);


ALTER TABLE pairs.pairs_auth_group OWNER TO pairs_db_master;

--
-- Name: pairs_auth_group_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_auth_group_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_auth_group_seq OWNER TO pairs_db_master;

--
-- Name: pairs_auth_group_user; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_auth_group_user (
    grp numeric(8,0),
    usr numeric(8,0)
);


ALTER TABLE pairs.pairs_auth_group_user OWNER TO pairs_db_master;

--
-- Name: pairs_auth_user; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_auth_user (
    id numeric(8,0) NOT NULL,
    login character varying(64),
    name character varying(64),
    password character varying(64),
    admin character varying(1),
    email character varying(64),
    country character varying(2),
    phone character varying(30),
    company character varying(256),
    active character varying(1),
    m_since numeric(30,0),
    status numeric(2,0),
    grp_admin character varying(1) DEFAULT 'N'::character varying,
    grp numeric(8,0) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by numeric(8,0),
    updated_by numeric(8,0),
    external_id character varying
);


ALTER TABLE pairs.pairs_auth_user OWNER TO pairs_db_master;

--
-- Name: pairs_data_access; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_data_access (
    id numeric(8,0) NOT NULL,
    dset numeric(8,0),
    layer numeric(8,0),
    usr numeric(8,0),
    level numeric(2,0) NOT NULL,
    grp numeric(8,0),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by numeric(8,0),
    updated_by numeric(8,0)
);


ALTER TABLE pairs.pairs_data_access OWNER TO pairs_db_master;

--
-- Name: pairs_auth_realm_role; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_auth_realm_role AS
 SELECT usr.login,
        CASE
            WHEN (max(acs.level) = (0)::numeric) THEN 'NONE'::text
            ELSE 'READ'::text
        END AS role
   FROM (((pairs.pairs_auth_user usr
     JOIN pairs.pairs_auth_group_user grp_usr ON ((grp_usr.usr = usr.id)))
     JOIN pairs.pairs_auth_group grp ON ((grp.id = grp_usr.grp)))
     JOIN pairs.pairs_data_access acs ON ((acs.grp = grp.id)))
  WHERE ((usr.admin)::text = 'N'::text)
  GROUP BY usr.login
UNION ALL
 SELECT pairs_auth_user.login,
    'READ'::text AS role
   FROM pairs.pairs_auth_user
  WHERE ((pairs_auth_user.admin)::text = 'Y'::text);


ALTER TABLE pairs.pairs_auth_realm_role OWNER TO pairs_db_master;

--
-- Name: pairs_auth_realm_user; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_auth_realm_user AS
 SELECT pairs_auth_user.login,
    pairs_auth_user.password
   FROM pairs.pairs_auth_user
  WHERE ((pairs_auth_user.active)::text = 'Y'::text);


ALTER TABLE pairs.pairs_auth_realm_user OWNER TO pairs_db_master;

--
-- Name: pairs_auth_signature; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_auth_signature (
    disc numeric(5,0) NOT NULL,
    version numeric(5,0) NOT NULL,
    usr numeric(5,0) NOT NULL,
    date date NOT NULL
);


ALTER TABLE pairs.pairs_auth_signature OWNER TO pairs_db_master;

--
-- Name: pairs_auth_user_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_auth_user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_auth_user_seq OWNER TO pairs_db_master;

--
-- Name: pairs_layer_avail_level11; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_layer_avail_level11 (
    pairs_key bigint,
    layer_id integer,
    xi integer,
    yi integer,
    random double precision DEFAULT random()
);


ALTER TABLE pairs.pairs_layer_avail_level11 OWNER TO pairs_db_master;

--
-- Name: vector_layer_availability; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.vector_layer_availability (
    layer_id character varying(32) NOT NULL,
    pairs_key bigint NOT NULL,
    resolution_level integer NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    latitude_index integer,
    longitude_index integer
);


ALTER TABLE pairs.vector_layer_availability OWNER TO pairs_db_master;

--
-- Name: pairs_availability_level11_view; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_availability_level11_view AS
 SELECT pairs_layer_avail_level11.pairs_key,
    (pairs_layer_avail_level11.layer_id)::text AS layer_id,
    pairs_layer_avail_level11.xi,
    pairs_layer_avail_level11.yi
   FROM pairs.pairs_layer_avail_level11
UNION ALL
 SELECT vector_layer_availability.pairs_key,
    (vector_layer_availability.layer_id)::text AS layer_id,
    vector_layer_availability.latitude_index AS xi,
    vector_layer_availability.longitude_index AS yi
   FROM pairs.vector_layer_availability
  WHERE (vector_layer_availability.resolution_level = 11);


ALTER TABLE pairs.pairs_availability_level11_view OWNER TO pairs_db_master;

--
-- Name: pairs_categorical; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_categorical (
    layer_id integer,
    value integer,
    string text
);


ALTER TABLE pairs.pairs_categorical OWNER TO pairs_db_master;

--
-- Name: pairs_config; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_config (
    key character varying(50) NOT NULL,
    value character varying(100)
);


ALTER TABLE pairs.pairs_config OWNER TO pairs_db_master;

--
-- Name: pairs_config_server; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_config_server (
    id numeric(4,0) NOT NULL,
    description character varying(50),
    url character varying(100),
    geoserver_url character varying(100),
    geoserver_local character varying(1),
    geoserver_user character varying(20),
    geoserver_pwd character varying(20),
    active character varying(1),
    hash character varying(20),
    mac character varying(20),
    local_fs character varying(20),
    hadoop_fs character varying(50),
    geoserver_ext character varying(100),
    geoserver_ws character varying(30)
);


ALTER TABLE pairs.pairs_config_server OWNER TO pairs_db_master;

--
-- Name: pairs_config_server_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_config_server_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_config_server_seq OWNER TO pairs_db_master;

--
-- Name: pairs_ctable_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_ctable_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_ctable_seq OWNER TO pairs_db_master;

--
-- Name: pairs_data_access_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_data_access_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_data_access_seq OWNER TO pairs_db_master;

--
-- Name: pairs_data_categ; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_data_categ (
    id numeric(5,0) NOT NULL,
    name character varying(50)
);


ALTER TABLE pairs.pairs_data_categ OWNER TO pairs_db_master;

--
-- Name: pairs_data_categ_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_data_categ_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_data_categ_seq OWNER TO pairs_db_master;

--
-- Name: pairs_data_ctable; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_data_ctable (
    name character varying(20),
    colors character varying(999999),
    id numeric(8,0) NOT NULL,
    def character varying(1) DEFAULT 'N'::character varying,
    middle numeric,
    log character varying(1) DEFAULT 'N'::character varying,
    labels character varying(999999)
);


ALTER TABLE pairs.pairs_data_ctable OWNER TO pairs_db_master;

--
-- Name: pairs_data_info; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_data_info (
    id numeric(8,0) NOT NULL,
    dset character varying(30),
    name character varying(75),
    htable character varying(50),
    type numeric(2,0),
    level numeric(4,0),
    categ numeric(5,0),
    crs character varying(200),
    ftp_password character varying(50),
    max_layers numeric(4,0) DEFAULT 10,
    status numeric(2,0) DEFAULT 10 NOT NULL,
    upload_host_id integer DEFAULT 2,
    pipeline_id integer,
    ftp_password_age numeric(30,0) DEFAULT 0,
    cache_spatial_availability smallint DEFAULT 1,
    name_alternate text,
    rating real DEFAULT 1.0,
    description_short text,
    description_long text,
    description_links text[] DEFAULT ARRAY[]::text[],
    data_source_name text,
    data_source_attribution text,
    data_source_description text,
    data_source_links text[] DEFAULT ARRAY[]::text[],
    pairs_update_interval_description text,
    pairs_update_interval_max interval,
    lag_horizon_description text,
    lag_horizon interval,
    temporal_resolution_description text,
    temporal_resolution interval,
    spatial_resolution_of_raw_data text,
    pairs_interpolation text DEFAULT 'near'::text,
    pairs_level numeric(4,0),
    dimensions_description text,
    permanence_description text,
    permanence boolean DEFAULT true,
    known_issues text,
    responsible_organization text,
    contact_person text,
    description_internal text,
    data_storage_mid_term text,
    data_storage_long_term text,
    elt_scripts_links text[] DEFAULT ARRAY[]::text[],
    license_information text,
    properties json DEFAULT '{}'::json,
    latitude_min real DEFAULT '-90'::integer,
    longitude_min real DEFAULT '-180'::integer,
    latitude_max real DEFAULT 90,
    longitude_max real DEFAULT 180,
    temporal_min timestamp without time zone,
    temporal_max timestamp without time zone,
    offering_status text,
    category integer,
    description_internal_links text[] DEFAULT ARRAY[]::text[],
    spatial_coverage json DEFAULT '{}'::json,
    params character varying(200),
    mapper character varying(300),
    original character varying(1),
    dsource_hlink character varying(250),
    dsource_desc character varying(640),
    priority numeric(2,0),
    temp_cover_end date,
    area_cover character varying(50),
    data_origin character varying(32),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by numeric(8,0),
    updated_by numeric(8,0)
);


ALTER TABLE pairs.pairs_data_info OWNER TO pairs_db_master;

--
-- Name: pairs_data_info_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_data_info_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_data_info_seq OWNER TO pairs_db_master;

--
-- Name: pairs_data_layer; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_data_layer (
    id numeric(8,0) NOT NULL,
    dset numeric(8,0),
    name character varying(50),
    dtype character varying(50),
    col_f character varying(5),
    col_q character varying(20),
    unit_cat character varying(10),
    formula character varying(200),
    short character varying(50),
    level numeric(4,0),
    htable character varying(50),
    ctable numeric(8,0),
    crs character varying(200),
    unit_symbol character varying(64),
    priority numeric(2,0),
    interpolation character varying(20) DEFAULT 'near'::character varying,
    nodata_in numeric(15,5),
    nodata_out numeric(15,5),
    status numeric(2,0) DEFAULT 10,
    upload_active smallint DEFAULT 1,
    upload_priority smallint DEFAULT 0,
    delete_on timestamp without time zone,
    qa character varying(1) DEFAULT 'N'::character varying,
    upload_post_proc_json text,
    metadata text,
    name_alternate text,
    rating real DEFAULT 1.0,
    description_short text,
    description_long text,
    description_links text[] DEFAULT ARRAY[]::text[],
    data_source_name text,
    data_source_attribution text,
    data_source_description text,
    data_source_links text[] DEFAULT ARRAY[]::text[],
    data_type text,
    units text,
    pairs_update_interval_description text,
    pairs_update_interval_max interval,
    lag_horizon_description text,
    lag_horizon interval,
    temporal_resolution_description text,
    temporal_resolution interval,
    spatial_resolution_of_raw_data text,
    pairs_interpolation text DEFAULT 'near'::text,
    pairs_level numeric(4,0),
    dimensions_description text,
    permanence_description text,
    permanence boolean DEFAULT true,
    known_issues text,
    description_internal text,
    measurement_interval_description text,
    measurement_interval interval,
    meaning_of_timestamp text,
    meaning_of_spatial_descriptor text,
    properties json DEFAULT '{}'::json,
    latitude_min real DEFAULT '-90'::integer,
    longitude_min real DEFAULT '-180'::integer,
    latitude_max real DEFAULT 90,
    longitude_max real DEFAULT 180,
    temporal_min timestamp without time zone,
    temporal_max timestamp without time zone,
    description_internal_links text[] DEFAULT ARRAY[]::text[],
    spatial_coverage json DEFAULT '{}'::json,
    parent numeric(5,0),
    forecast character varying(5),
    threshold_up numeric(15,5),
    threshold_lo numeric(15,5),
    "interval" numeric(10,0),
    detail_info character varying(400),
    physical_prop character varying(15),
    description character varying(200),
    min_value real,
    max_value real,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by numeric(8,0),
    updated_by numeric(8,0)
);


ALTER TABLE pairs.pairs_data_layer OWNER TO pairs_db_master;

--
-- Name: pairs_data_layer_region_rel; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_data_layer_region_rel (
    layer numeric(8,0) NOT NULL,
    region numeric(8,0) NOT NULL
);


ALTER TABLE pairs.pairs_data_layer_region_rel OWNER TO pairs_db_master;

--
-- Name: pairs_data_layer_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_data_layer_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_data_layer_seq OWNER TO pairs_db_master;

--
-- Name: pairs_data_region; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_data_region (
    id numeric(8,0) NOT NULL,
    dset numeric(8,0),
    name character varying(50),
    c_lat numeric(10,7),
    l_lon numeric(10,7),
    lat_min numeric(10,7),
    lat_max numeric(10,7),
    lon_min numeric(10,7),
    lon_max numeric(10,7)
);


ALTER TABLE pairs.pairs_data_region OWNER TO pairs_db_master;

--
-- Name: pairs_data_region_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_data_region_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_data_region_seq OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_column_info; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_pointdata_column_info (
    id integer NOT NULL,
    table_id integer,
    col_order numeric(5,0),
    col_name character varying(64),
    attrib character varying(64),
    data_type character varying(64),
    units character varying(64),
    col_desc character varying(200),
    dimension character varying(1) DEFAULT 'Y'::character varying NOT NULL,
    col_name_alternate text,
    rating real DEFAULT 1.0,
    description_short text,
    description_long text,
    description_links text[] DEFAULT ARRAY[]::text[],
    data_source_name text,
    data_source_attribution text,
    data_source_description text,
    data_source_links text[] DEFAULT ARRAY[]::text[],
    pairs_update_interval_description text,
    pairs_update_interval_max interval,
    lag_horizon_description text,
    lag_horizon interval,
    temporal_resolution_description text,
    temporal_resolution interval,
    spatial_resolution_of_raw_data text,
    pairs_interpolation text DEFAULT 'near'::text,
    pairs_level numeric(4,0),
    dimensions_description text,
    permanence_description text,
    permanence boolean DEFAULT true,
    known_issues text,
    description_internal text,
    measurement_interval_description text,
    measurement_interval interval,
    meaning_of_timestamp text,
    meaning_of_spatial_descriptor text,
    properties json DEFAULT '{}'::json,
    latitude_min real DEFAULT '-90'::integer,
    longitude_min real DEFAULT '-180'::integer,
    latitude_max real DEFAULT 90,
    longitude_max real DEFAULT 180,
    temporal_min timestamp without time zone,
    temporal_max timestamp without time zone,
    description_internal_links text[] DEFAULT ARRAY[]::text[],
    spatial_coverage json DEFAULT '{}'::json,
    ctable numeric(8,0),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by numeric(8,0),
    updated_by numeric(8,0)
);


ALTER TABLE pairs.pairs_pointdata_column_info OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_info; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_pointdata_table_info (
    id integer NOT NULL,
    dset numeric(8,0),
    table_name character varying(64),
    table_key character varying(64),
    db_table_name character varying(64),
    server character varying(64),
    rdbms character varying(64),
    status numeric(2,0) DEFAULT 10,
    level numeric(4,0),
    time_resolution integer DEFAULT 259200,
    delete_on timestamp without time zone,
    qa character varying(1) DEFAULT 'N'::character varying,
    upload_post_proc_json text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by numeric(8,0),
    updated_by numeric(8,0)
);


ALTER TABLE pairs.pairs_pointdata_table_info OWNER TO pairs_db_master;

--
-- Name: COLUMN pairs_pointdata_table_info.time_resolution; Type: COMMENT; Schema: pairs; Owner: pairs_db_master
--

COMMENT ON COLUMN pairs.pairs_pointdata_table_info.time_resolution IS 'This will be used to restrict time searches. Set to meaningfull value which is greater than typical time between measurements.  This is impostant for snapshot queries, instead of search for all record with < snapshot we will use snapshot - time_resolution <= t <= snapshot';


--
-- Name: pairs_datadocs_data_column; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_datadocs_data_column AS
 SELECT di.id AS dset,
    di.name AS dset_name,
    mt.table_id,
    dd.table_name,
    mt.attrib,
    mt.id,
    mt.col_name,
    mt.col_name AS name,
    mt.col_name_alternate AS name_expert,
    false AS to_delete,
    mt.rating,
    ARRAY[]::text[] AS tags,
    mt.description_short,
    mt.description_long,
    mt.description_links,
    mt.data_source_name,
    mt.data_source_attribution,
    mt.data_source_description,
    mt.data_source_links,
    mt.data_type,
    mt.units,
    mt.pairs_update_interval_description,
    mt.pairs_update_interval_max,
    mt.lag_horizon_description,
    mt.lag_horizon,
    mt.temporal_resolution_description,
    mt.temporal_resolution,
    mt.spatial_resolution_of_raw_data,
    mt.pairs_interpolation,
    mt.pairs_level,
    mt.dimensions_description,
    mt.permanence_description,
    mt.permanence,
    mt.known_issues,
    mt.description_internal,
    mt.measurement_interval_description,
    mt.measurement_interval,
    mt.meaning_of_timestamp,
    mt.meaning_of_spatial_descriptor,
    mt.properties,
    mt.latitude_min,
    mt.longitude_min,
    mt.latitude_max,
    mt.longitude_max,
    mt.temporal_min,
    mt.temporal_max,
    mt.description_internal_links
   FROM ((pairs.pairs_pointdata_column_info mt
     JOIN pairs.pairs_pointdata_table_info dd ON ((dd.id = mt.table_id)))
     JOIN pairs.pairs_data_info di ON ((di.id = dd.dset)));


ALTER TABLE pairs.pairs_datadocs_data_column OWNER TO pairs_db_master;

--
-- Name: pairs_datadocs_data_layer; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_datadocs_data_layer AS
 SELECT di.id AS dset,
    di.name AS dset_name,
    md.id,
    md.name,
    md.name AS name_common,
    md.name_alternate AS name_expert,
    false AS to_delete,
    md.rating,
    ARRAY[]::text[] AS tags,
    md.description_short,
    md.description_long,
    md.description_links,
    md.data_source_name,
    md.data_source_attribution,
    md.data_source_description,
    md.data_source_links,
    md.data_type,
    md.units,
    md.pairs_update_interval_description,
    md.pairs_update_interval_max,
    md.lag_horizon_description,
    md.lag_horizon,
    md.temporal_resolution_description,
    md.temporal_resolution,
    md.spatial_resolution_of_raw_data,
    md.pairs_interpolation,
    md.pairs_level,
    md.dimensions_description,
    md.permanence_description,
    md.permanence,
    md.known_issues,
    md.description_internal,
    md.measurement_interval_description,
    md.measurement_interval,
    md.meaning_of_timestamp,
    md.meaning_of_spatial_descriptor,
    md.properties,
    md.latitude_min,
    md.longitude_min,
    md.latitude_max,
    md.longitude_max,
    md.temporal_min,
    md.temporal_max,
    md.description_internal_links,
    md.spatial_coverage
   FROM (pairs.pairs_data_layer md
     JOIN pairs.pairs_data_info di ON ((di.id = md.dset)));


ALTER TABLE pairs.pairs_datadocs_data_layer OWNER TO pairs_db_master;

--
-- Name: pairs_datadocs_data_set; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_datadocs_data_set AS
 SELECT mt.id,
    mt.dset AS key,
    mt.name,
    mt.name AS name_common,
    mt.name_alternate AS name_expert,
    mt.rating,
    ARRAY[]::text[] AS tags,
    mt.description_short,
    mt.description_long,
    mt.description_links,
    mt.data_source_name,
    mt.data_source_attribution,
    mt.data_source_description,
    mt.data_source_links,
    mt.pairs_update_interval_description,
    mt.pairs_update_interval_max,
    mt.lag_horizon_description,
    mt.lag_horizon,
    mt.temporal_resolution_description,
    mt.temporal_resolution,
    mt.spatial_resolution_of_raw_data,
    mt.pairs_interpolation,
    mt.pairs_level,
    mt.dimensions_description,
    mt.permanence_description,
    mt.permanence,
    mt.known_issues,
    mt.responsible_organization,
    mt.contact_person,
    mt.description_internal,
    mt.data_storage_mid_term,
    mt.data_storage_long_term,
    mt.elt_scripts_links,
    mt.license_information,
    mt.properties,
    mt.latitude_min,
    mt.longitude_min,
    mt.latitude_max,
    mt.longitude_max,
    mt.temporal_min,
    mt.temporal_max,
    mt.offering_status,
    mt.category,
    mt.description_internal_links,
    mt.spatial_coverage
   FROM pairs.pairs_data_info mt;


ALTER TABLE pairs.pairs_datadocs_data_set OWNER TO pairs_db_master;

--
-- Name: pairs_datadocs_tags_data_set; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_datadocs_tags_data_set (
    id integer NOT NULL,
    key text,
    value text
);


ALTER TABLE pairs.pairs_datadocs_tags_data_set OWNER TO pairs_db_master;

--
-- Name: pairs_datadocs_tags_data_set_id_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_datadocs_tags_data_set_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_datadocs_tags_data_set_id_seq OWNER TO pairs_db_master;

--
-- Name: pairs_datadocs_tags_data_set_id_seq; Type: SEQUENCE OWNED BY; Schema: pairs; Owner: pairs_db_master
--

ALTER SEQUENCE pairs.pairs_datadocs_tags_data_set_id_seq OWNED BY pairs.pairs_datadocs_tags_data_set.id;


--
-- Name: pairs_datalayer_mapping; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_datalayer_mapping AS
 SELECT (l.id)::text AS datalayerid,
    'R'::text AS datalayertype,
    l.id AS rasterlayerid,
    l.name AS datalayername,
    l.dset AS datasetid,
    '-9999'::integer AS pointlayerid,
    '-9999'::integer AS pointlayercolumnid,
    l.unit_symbol AS unit,
    l.description_short AS datalayerdesc,
    COALESCE(l.level, i.level) AS datalayerlevel,
    l.dtype AS datalayerdtype,
    l.status AS datalayerstatus,
    l.crs AS datalayercrs,
    l.ctable AS colortable,
    l.col_f AS col_f_default,
    pairs.pairs_get_dimension_column(l.id) AS col_q_default
   FROM pairs.pairs_data_info i,
    pairs.pairs_data_layer l
  WHERE ((i.id = l.dset) AND (l.status = (10)::numeric))
UNION ALL
 SELECT concat('P', (t.id)::text, 'C', (c.id)::text) AS datalayerid,
    'V'::text AS datalayertype,
    '-9999'::integer AS rasterlayerid,
    (((t.table_name)::text || '.'::text) || (c.col_name)::text) AS datalayername,
    t.dset AS datasetid,
    t.id AS pointlayerid,
    c.id AS pointlayercolumnid,
    c.units AS unit,
    c.col_desc AS datalayerdesc,
    t.level AS datalayerlevel,
        CASE
            WHEN ((c.data_type)::text = 'double'::text) THEN 'db'::text
            ELSE substr(btrim((c.data_type)::text), 1, 2)
        END AS datalayerdtype,
    t.status AS datalayerstatus,
    NULL::character varying AS datalayercrs,
    NULL::numeric AS colortable,
    NULL::character varying AS col_f_default,
    NULL::character varying AS col_q_default
   FROM pairs.pairs_pointdata_table_info t,
    pairs.pairs_pointdata_column_info c
  WHERE ((t.id = c.table_id) AND ((c.attrib)::text = 'Value'::text) AND (t.status = (10)::numeric));


ALTER TABLE pairs.pairs_datalayer_mapping OWNER TO pairs_db_master;

--
-- Name: pairs_datalayer_mapping_full; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_datalayer_mapping_full WITH (security_barrier='false') AS
 SELECT (l.id)::text AS datalayerid,
    'R'::text AS datalayertype,
    l.id AS rasterlayerid,
    l.name AS datalayername,
    l.dset AS datasetid,
    '-9999'::integer AS pointlayerid,
    '-9999'::integer AS pointlayercolumnid,
    l.unit_symbol AS unit,
    l.description_short AS datalayerdesc,
    COALESCE(l.level, i.level) AS datalayerlevel,
    l.dtype AS datalayerdtype,
    l.status AS datalayerstatus,
    l.crs AS datalayercrs,
    l.ctable AS colortable,
    l.col_f AS col_f_default,
    pairs.pairs_get_dimension_column(l.id) AS col_q_default,
    l.name_alternate AS name_expert,
    l.rating,
    l.description_short,
    l.description_long,
    l.description_links,
    l.data_source_name,
    l.data_source_attribution,
    l.data_source_description,
    l.data_source_links,
        CASE
            WHEN ((l.dtype)::text = 'bt'::text) THEN 'Byte (1 byte)'::text
            WHEN ((l.dtype)::text = 'db'::text) THEN 'Double (8 bytes)'::text
            WHEN ((l.dtype)::text = 'in'::text) THEN 'Integer (4 bytes)'::text
            WHEN ((l.dtype)::text = 'fl'::text) THEN 'Float (4 bytes)'::text
            WHEN ((l.dtype)::text = 'sh'::text) THEN 'Short (2 bytes)'::text
            ELSE (l.dtype)::text
        END AS data_type,
    l.units,
    l.pairs_update_interval_description,
    l.pairs_update_interval_max,
    l.lag_horizon_description,
    l.lag_horizon,
    l.temporal_resolution_description,
    l.temporal_resolution,
    l.spatial_resolution_of_raw_data,
    l.pairs_interpolation,
    l.pairs_level,
    l.dimensions_description,
    l.permanence_description,
    l.permanence,
    l.known_issues,
    l.description_internal,
    l.measurement_interval_description,
    l.measurement_interval,
    l.meaning_of_timestamp,
    l.meaning_of_spatial_descriptor,
    l.properties,
    l.latitude_min,
    l.longitude_min,
    l.latitude_max,
    l.longitude_max,
    l.temporal_min,
    l.temporal_max,
    l.description_internal_links,
    l.spatial_coverage,
    l.short AS key,
    l.htable AS table_default,
    l.interpolation,
    l.min_value,
    l.max_value,
    l.formula,
    l.created_at,
    l.updated_at,
    l.created_by,
    l.updated_by
   FROM pairs.pairs_data_info i,
    pairs.pairs_data_layer l
  WHERE ((i.id = l.dset) AND (l.status = (10)::numeric))
UNION ALL
 SELECT concat('P', (t.id)::text, 'C', (c.id)::text) AS datalayerid,
    'V'::text AS datalayertype,
    '-9999'::integer AS rasterlayerid,
    (((t.table_name)::text || '.'::text) || (c.col_name)::text) AS datalayername,
    t.dset AS datasetid,
    t.id AS pointlayerid,
    c.id AS pointlayercolumnid,
    c.units AS unit,
    c.col_desc AS datalayerdesc,
    COALESCE(t.level, i.level) AS datalayerlevel,
        CASE
            WHEN ((c.data_type)::text = 'double'::text) THEN 'db'::text
            ELSE substr(btrim((c.data_type)::text), 1, 2)
        END AS datalayerdtype,
    t.status AS datalayerstatus,
    NULL::character varying AS datalayercrs,
    c.ctable AS colortable,
    NULL::character varying AS col_f_default,
    NULL::character varying AS col_q_default,
    c.col_name_alternate AS name_expert,
    c.rating,
    c.description_short,
    c.description_long,
    c.description_links,
    c.data_source_name,
    c.data_source_attribution,
    c.data_source_description,
    c.data_source_links,
    c.data_type,
    c.units,
    c.pairs_update_interval_description,
    c.pairs_update_interval_max,
    c.lag_horizon_description,
    c.lag_horizon,
    c.temporal_resolution_description,
    c.temporal_resolution,
    c.spatial_resolution_of_raw_data,
    c.pairs_interpolation,
    c.pairs_level,
    c.dimensions_description,
    c.permanence_description,
    c.permanence,
    c.known_issues,
    c.description_internal,
    c.measurement_interval_description,
    c.measurement_interval,
    c.meaning_of_timestamp,
    c.meaning_of_spatial_descriptor,
    c.properties,
    c.latitude_min,
    c.longitude_min,
    c.latitude_max,
    c.longitude_max,
    c.temporal_min,
    c.temporal_max,
    c.description_internal_links,
    c.spatial_coverage,
    t.table_key AS key,
    t.db_table_name AS table_default,
    NULL::character varying AS interpolation,
    NULL::double precision AS min_value,
    NULL::double precision AS max_value,
    NULL::character varying AS formula,
    c.created_at,
    c.updated_at,
    c.created_by,
    c.updated_by
   FROM pairs.pairs_pointdata_table_info t,
    pairs.pairs_pointdata_column_info c,
    pairs.pairs_data_info i
  WHERE ((i.id = t.dset) AND (t.id = c.table_id) AND ((c.attrib)::text = 'Value'::text) AND (t.status = (10)::numeric));


ALTER TABLE pairs.pairs_datalayer_mapping_full OWNER TO pairs_db_master;

--
-- Name: pairs_dim_values; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_dim_values (
    id bigint NOT NULL,
    dim_id bigint,
    value_order integer,
    value_string text,
    value_integer integer,
    value_float real,
    value_timestamp bigint,
    value_delta_timestamp bigint,
    value character varying(50),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by numeric(8,0),
    updated_by numeric(8,0)
);


ALTER TABLE pairs.pairs_dim_values OWNER TO pairs_db_master;

--
-- Name: pairs_dimensions; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_dimensions (
    id bigint NOT NULL,
    layer_id bigint,
    dim_order integer,
    dimension_name text,
    dimension_type text,
    identifier character(1),
    unit text,
    grid_origin real,
    grid_step real,
    shortname text,
    value character varying(50),
    default_value bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by numeric(8,0),
    updated_by numeric(8,0)
);


ALTER TABLE pairs.pairs_dimensions OWNER TO pairs_db_master;

--
-- Name: pairs_datalayer_mapping_with_default; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_datalayer_mapping_with_default AS
 SELECT (l.id)::text AS datalayerid,
    'R'::text AS datalayertype,
    l.id AS rasterlayerid,
    l.name AS datalayername,
    l.dset AS datasetid,
    '-9999'::integer AS pointlayerid,
    '-9999'::integer AS pointlayercolumnid,
    l.unit_symbol AS unit,
    l.description_short AS datalayerdesc,
    COALESCE(l.level, i.level) AS datalayerlevel,
    l.dtype AS datalayerdtype,
    l.status AS datalayerstatus,
    l.crs AS datalayercrs,
    l.ctable AS colortable,
    l.col_f AS col_f_default,
    x.col_q_default
   FROM pairs.pairs_data_info i,
    pairs.pairs_data_layer l,
    ( SELECT dl.id,
            ((dl.col_q)::text || COALESCE(('@'::text || string_agg(((d.identifier)::text || v.value_string), '@'::text ORDER BY d.dim_order)), ''::text)) AS col_q_default
           FROM ((pairs.pairs_data_layer dl
             LEFT JOIN pairs.pairs_dimensions d ON ((dl.id = (d.layer_id)::numeric)))
             LEFT JOIN pairs.pairs_dim_values v ON ((v.id = d.default_value)))
          GROUP BY dl.id, dl.col_q) x
  WHERE ((i.id = l.dset) AND (l.status = (10)::numeric) AND (x.id = l.id))
UNION ALL
 SELECT concat('P', (t.id)::text, 'C', (c.id)::text) AS datalayerid,
    'V'::text AS datalayertype,
    '-9999'::integer AS rasterlayerid,
    (((t.table_name)::text || '.'::text) || (c.col_name)::text) AS datalayername,
    t.dset AS datasetid,
    t.id AS pointlayerid,
    c.id AS pointlayercolumnid,
    c.units AS unit,
    c.col_desc AS datalayerdesc,
    t.level AS datalayerlevel,
        CASE
            WHEN ((c.data_type)::text = 'double'::text) THEN 'db'::text
            ELSE substr(btrim((c.data_type)::text), 1, 2)
        END AS datalayerdtype,
    t.status AS datalayerstatus,
    NULL::character varying AS datalayercrs,
    NULL::numeric AS colortable,
    NULL::character varying AS col_f_default,
    NULL::character varying AS col_q_default
   FROM pairs.pairs_pointdata_table_info t,
    pairs.pairs_pointdata_column_info c
  WHERE ((t.id = c.table_id) AND ((c.attrib)::text = 'Value'::text) AND (t.status = (10)::numeric));


ALTER TABLE pairs.pairs_datalayer_mapping_with_default OWNER TO pairs_db_master;

--
-- Name: pairs_datalayer_preview_url; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_datalayer_preview_url (
    id numeric(30,0),
    datalayerid numeric(30,0),
    wms_url text,
    style_url text,
    legend_style_url text,
    "timestamp" numeric(30,0),
    dimension_str text
);


ALTER TABLE pairs.pairs_datalayer_preview_url OWNER TO pairs_db_master;

--
-- Name: pairs_datalayer_preview_url_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_datalayer_preview_url_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_datalayer_preview_url_seq OWNER TO pairs_db_master;

--
-- Name: pairs_datalayer_search; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_datalayer_search AS
 SELECT m.datalayerid,
    m.datasetid,
    s.categ AS categoryid,
    s.name AS datasetname,
    m.datalayername,
    c.name AS categoryname,
    (((((m.datalayername)::text || ' - '::text) || (s.name)::text) || ' - '::text) || (c.name)::text) AS combinedname
   FROM pairs.pairs_datalayer_mapping m,
    pairs.pairs_data_info s,
    pairs.pairs_data_categ c
  WHERE ((m.datasetid = s.id) AND (s.categ = c.id));


ALTER TABLE pairs.pairs_datalayer_search OWNER TO pairs_db_master;

--
-- Name: pairs_dim_values_id_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_dim_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_dim_values_id_seq OWNER TO pairs_db_master;

--
-- Name: pairs_dim_values_id_seq; Type: SEQUENCE OWNED BY; Schema: pairs; Owner: pairs_db_master
--

ALTER SEQUENCE pairs.pairs_dim_values_id_seq OWNED BY pairs.pairs_dim_values.id;


--
-- Name: pairs_dimensions_id_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_dimensions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_dimensions_id_seq OWNER TO pairs_db_master;

--
-- Name: pairs_dimensions_id_seq; Type: SEQUENCE OWNED BY; Schema: pairs; Owner: pairs_db_master
--

ALTER SEQUENCE pairs.pairs_dimensions_id_seq OWNED BY pairs.pairs_dimensions.id;


--
-- Name: pairs_dimensions_vector; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_dimensions_vector (
    id bigint DEFAULT nextval('pairs.pairs_dimensions_id_seq'::regclass) NOT NULL,
    layer_id text,
    dim_order integer,
    dimension_name text,
    dimension_type text,
    identifier character(1),
    unit text,
    grid_origin real,
    grid_step real,
    shortname text,
    value character varying(50),
    default_value bigint
);


ALTER TABLE pairs.pairs_dimensions_vector OWNER TO pairs_db_master;

SET default_tablespace = '';

--
-- Name: pairs_federation_policy; Type: TABLE; Schema: pairs; Owner: pairs_db_master
--

CREATE TABLE pairs.pairs_federation_policy (
    datalayer_id text NOT NULL,
    start_ts timestamp without time zone NOT NULL,
    end_ts timestamp without time zone NOT NULL,
    ranknum integer DEFAULT 1 NOT NULL,
    tabletype character varying(30) DEFAULT 'RASTER'::character varying NOT NULL,
    tablename character varying(256) NOT NULL,
    compression boolean,
    keydesign character varying(20) DEFAULT 'GEO_FIRST'::character varying,
    store_id character varying(128) NOT NULL,
    modified_ts timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_user character varying(128) DEFAULT CURRENT_USER NOT NULL,
    upload_action character varying
);


ALTER TABLE pairs.pairs_federation_policy OWNER TO pairs_db_master;

--
-- Name: pairs_federation_policy_inactive; Type: TABLE; Schema: pairs; Owner: pairs_db_master
--

CREATE TABLE pairs.pairs_federation_policy_inactive (
    datalayer_id text NOT NULL,
    start_ts timestamp without time zone,
    end_ts timestamp without time zone,
    ranknum integer DEFAULT 1 NOT NULL,
    tabletype character varying(30) DEFAULT 'RASTER'::character varying NOT NULL,
    tablename character varying(256) NOT NULL,
    compression boolean,
    keydesign character varying(20) DEFAULT 'GEO_FIRST'::character varying,
    store_id character varying(128) NOT NULL,
    modified_ts timestamp with time zone NOT NULL,
    modified_user character varying(128) NOT NULL,
    deleted_ts timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_user character varying(128) DEFAULT CURRENT_USER NOT NULL
);


ALTER TABLE pairs.pairs_federation_policy_inactive OWNER TO pairs_db_master;

--
-- Name: pairs_federation_store; Type: TABLE; Schema: pairs; Owner: pairs_db_master
--

CREATE TABLE pairs.pairs_federation_store (
    store_id character varying(128) NOT NULL,
    technology character varying(25) NOT NULL,
    connection json NOT NULL,
    activation_time timestamp with time zone,
    deactivation_time timestamp with time zone,
    modified_ts timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_user character varying(128) DEFAULT CURRENT_USER NOT NULL
);


ALTER TABLE pairs.pairs_federation_store OWNER TO pairs_db_master;

-- SET default_tablespace = default_pairs_tablespace;

--
-- Name: pairs_ftp; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_ftp (
    id integer NOT NULL,
    hostname_ext text,
    hostname_int text,
    ip_address_ext text NOT NULL,
    ip_address_int text,
    port_ext integer DEFAULT 22,
    port_int integer DEFAULT 22,
    root_directory text,
    pipeline_id integer
);


ALTER TABLE pairs.pairs_ftp OWNER TO pairs_db_master;

-- SET default_tablespace = default_pairs_tablespace;

--
-- Name: pairs_noti_event; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_noti_event (
    id numeric(10,0) NOT NULL,
    key character varying(30) NOT NULL,
    type character varying(10) NOT NULL,
    status numeric(5,0) NOT NULL,
    "time" numeric(20,0) NOT NULL,
    message character varying(100) NOT NULL
);


ALTER TABLE pairs.pairs_noti_event OWNER TO pairs_db_master;

--
-- Name: pairs_noti_event_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_noti_event_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_noti_event_seq OWNER TO pairs_db_master;

SET default_tablespace = '';

--
-- Name: pairs_organization; Type: TABLE; Schema: pairs; Owner: metadata_writer
--

CREATE TABLE pairs.pairs_organization (
    name character varying(128) NOT NULL,
    description character varying(256),
    contact character varying(256) NOT NULL,
    max_storage numeric(12,0),
    max_nb_datasets numeric(4,0),
    query_limit_gb numeric(5,0),
    query_limit_run numeric(5,0) DEFAULT 10,
    query_limit_tot numeric(5,0) DEFAULT 0,
    query_limit_write numeric(5,0) DEFAULT 2,
    created_by numeric(8,0),
    modified_by numeric(8,0),
    created_at timestamp with time zone DEFAULT now(),
    modified_at timestamp with time zone DEFAULT now()
);


-- ALTER TABLE pairs.pairs_organization OWNER TO metadata_writer;

--
-- Name: pairs_overview_info_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_overview_info_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_overview_info_seq OWNER TO pairs_db_master;

-- SET default_tablespace = default_pairs_tablespace;

--
-- Name: pairs_overview_info; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_overview_info (
    id integer DEFAULT nextval('pairs.pairs_overview_info_seq'::regclass) NOT NULL,
    layer_id numeric(8,0) NOT NULL,
    level integer NOT NULL,
    statistic text NOT NULL,
    metadata text
);


ALTER TABLE pairs.pairs_overview_info OWNER TO pairs_db_master;

--
-- Name: pairs_pipeline; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_pipeline (
    id integer NOT NULL,
    name text
);


ALTER TABLE pairs.pairs_pipeline OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_column_info_id_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_pointdata_column_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_pointdata_column_info_id_seq OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_column_info_id_seq; Type: SEQUENCE OWNED BY; Schema: pairs; Owner: pairs_db_master
--

ALTER SEQUENCE pairs.pairs_pointdata_column_info_id_seq OWNED BY pairs.pairs_pointdata_column_info.id;


--
-- Name: pairs_pointdata_connections; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_pointdata_connections (
    server character varying(64) NOT NULL,
    database character varying(64) DEFAULT 'pairs_data'::character varying NOT NULL,
    "user" character varying(64) DEFAULT 'paisr_db_master'::character varying NOT NULL,
    password character varying(64) NOT NULL,
    port integer DEFAULT 5432 NOT NULL,
    max_connections integer DEFAULT 10 NOT NULL,
    init_connections integer DEFAULT 2 NOT NULL
);


ALTER TABLE pairs.pairs_pointdata_connections OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_info_id_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_pointdata_table_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_pointdata_table_info_id_seq OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_info_id_seq; Type: SEQUENCE OWNED BY; Schema: pairs; Owner: pairs_db_master
--

ALTER SEQUENCE pairs.pairs_pointdata_table_info_id_seq OWNED BY pairs.pairs_pointdata_table_info.id;


--
-- Name: pairs_pointdata_table_query_attr; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_pointdata_table_query_attr (
    id numeric(10,0) NOT NULL,
    job_id character varying(30),
    description character varying(50),
    col_id numeric(10,0)
);


ALTER TABLE pairs.pairs_pointdata_table_query_attr OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_query_attr_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_pointdata_table_query_attr_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_pointdata_table_query_attr_seq OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_query_column; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_pointdata_table_query_column (
    id numeric(10,0) NOT NULL,
    job_id character varying(30),
    key character varying(100),
    dataset character varying(50),
    is_num character varying(1)
);


ALTER TABLE pairs.pairs_pointdata_table_query_column OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_query_column_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_pointdata_table_query_column_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_pointdata_table_query_column_seq OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_query_csv; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_pointdata_table_query_csv (
    job_id character varying(30),
    data text
);


ALTER TABLE pairs.pairs_pointdata_table_query_csv OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_query_data; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_pointdata_table_query_data (
    id numeric(10,0) NOT NULL,
    job_id character varying(30),
    "timestamp" numeric(15,0),
    lat numeric(5,2),
    lon numeric(5,2),
    value character varying(30),
    region character varying(10),
    col_id numeric(10,0),
    unit character varying(30)
);


ALTER TABLE pairs.pairs_pointdata_table_query_data OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_query_data_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_pointdata_table_query_data_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_pointdata_table_query_data_seq OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_query_join; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_pointdata_table_query_join (
    data_id numeric(10,0),
    attr_type_id numeric(10,0),
    attr_value character varying(50)
);


ALTER TABLE pairs.pairs_pointdata_table_query_join OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_query_prop; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_pointdata_table_query_prop AS
 SELECT j.data_id,
    a.id AS attr_id,
    a.description AS attr_name,
    j.attr_value
   FROM (pairs.pairs_pointdata_table_query_join j
     JOIN pairs.pairs_pointdata_table_query_attr a ON ((a.id = j.attr_type_id)));


ALTER TABLE pairs.pairs_pointdata_table_query_prop OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_query_summary; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_pointdata_table_query_summary (
    id numeric(5,0) NOT NULL,
    job_id text,
    point_data_table_id integer,
    output_name text,
    output_type numeric(5,0),
    column_number numeric(5,0),
    column_name character varying(64),
    attribute character varying(64),
    type character varying(64)
);


ALTER TABLE pairs.pairs_pointdata_table_query_summary OWNER TO pairs_db_master;

--
-- Name: pairs_pointdata_table_query_summary_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_pointdata_table_query_summary_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_pointdata_table_query_summary_seq OWNER TO pairs_db_master;

--
-- Name: pairs_qa_metrics; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_qa_metrics (
    dset_id numeric(5,0) NOT NULL,
    datalayer_id text NOT NULL,
    dset_key text,
    datalayer_shortname text,
    start_timestamp bigint,
    end_timestamp bigint,
    end_time_relative bigint,
    min_interval real,
    max_interval real,
    low_threshold real,
    high_threshold real,
    number_dim integer DEFAULT 0,
    data_normal_layer_id text,
    minoffset_vs_normal real,
    maxoffset_vs_normal real,
    with_vector_region boolean DEFAULT false,
    additional_attributes text,
    run_qa character(1) DEFAULT 'f'::bpchar,
    with_tiles boolean DEFAULT false,
    contact_person text,
    vector_col_order integer
);


ALTER TABLE pairs.pairs_qa_metrics OWNER TO pairs_db_master;

--
-- Name: pairs_query_aoi_alias; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_query_aoi_alias (
    aoi_alias character varying(64) NOT NULL,
    aoi_id integer
);


ALTER TABLE pairs.pairs_query_aoi_alias OWNER TO pairs_db_master;

--
-- Name: pairs_query_aoi_hierarchy; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_query_aoi_hierarchy AS
 SELECT a.polygon_id AS id,
    h.name AS hierarchy
   FROM (pairs.pairs_aoi a
     JOIN pairs.pairs_aoi_hierarchy h ON ((a.hierarchy_id = h.id)));


ALTER TABLE pairs.pairs_query_aoi_hierarchy OWNER TO pairs_db_master;

--
-- Name: pairs_query_aoi_repository; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_query_aoi_repository AS
 SELECT que.id,
    que.key,
    que.name,
    aoi.description,
    que.grp,
    que.usr,
    que.poly,
    que.area_deg_square,
    hie.name AS hierarchy,
    que.created_at,
    que.updated_at,
    que.created_by,
    que.updated_by
   FROM ((pairs.pairs_query_aoi que
     LEFT JOIN pairs.pairs_aoi aoi ON (((aoi.polygon_id)::numeric = (que.id)::numeric)))
     LEFT JOIN pairs.pairs_aoi_hierarchy hie ON ((aoi.hierarchy_id = hie.id)));


ALTER TABLE pairs.pairs_query_aoi_repository OWNER TO pairs_db_master;

--
-- Name: pairs_query_aoi_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_query_aoi_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_query_aoi_seq OWNER TO pairs_db_master;

--
-- Name: pairs_query_hist; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_query_hist (
    id numeric(10,0) NOT NULL,
    usr numeric(8,0),
    type character varying(10) NOT NULL,
    apistring text,
    queryjob text,
    date timestamp(5) with time zone,
    apijson text,
    size_total bigint,
    size_raw bigint,
    size_zip bigint,
    count_total integer
);


ALTER TABLE pairs.pairs_query_hist OWNER TO pairs_db_master;

--
-- Name: pairs_query_hist_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_query_hist_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_query_hist_seq OWNER TO pairs_db_master;

--
-- Name: pairs_query_job; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_query_job (
    id text NOT NULL,
    status numeric(2,0),
    usr numeric(5,0),
    folder character varying(30),
    pql character varying(300),
    start numeric(30,0),
    sw_lat real,
    sw_lon real,
    ne_lat real,
    ne_lon real,
    flag boolean DEFAULT false,
    nickname character varying(256),
    hadoop_id3 character varying(20),
    pd_status numeric(2,0),
    server_id numeric(4,0),
    hadoop_id text,
    count_maps integer,
    count_layers integer,
    count_downloads integer,
    count_visualizations integer,
    parent text
);


ALTER TABLE pairs.pairs_query_job OWNER TO pairs_db_master;

--
-- Name: pairs_query_job_status; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_query_job_status (
    queryjob text,
    r_status numeric(2,0),
    v_status numeric(2,0),
    "timestamp" numeric(30,0)
);


ALTER TABLE pairs.pairs_query_job_status OWNER TO pairs_db_master;

--
-- Name: pairs_query_upload; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_query_upload (
    id numeric(20,0) NOT NULL,
    size_total numeric(20,0),
    size_uploaded numeric(20,0),
    endpoint character varying(100),
    bucket character varying(50),
    status numeric(3,0),
    queryjob text
);


ALTER TABLE pairs.pairs_query_upload OWNER TO pairs_db_master;

--
-- Name: pairs_query_upload_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_query_upload_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_query_upload_seq OWNER TO pairs_db_master;

--
-- Name: pairs_system_info; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_system_info (
    id integer NOT NULL,
    nextjobid numeric(15,0),
    workspace character varying(75)
);


ALTER TABLE pairs.pairs_system_info OWNER TO pairs_db_master;

--
-- Name: pairs_tile_info; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_tile_info (
    dset_id integer NOT NULL,
    dset_key text,
    tile_id text NOT NULL,
    probe_lon double precision,
    probe_lat double precision,
    satellite text
);


ALTER TABLE pairs.pairs_tile_info OWNER TO pairs_db_master;

-- SET default_tablespace = upload_table_tablespace;

--
-- Name: pairs_upload_error; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: upload_table_tablespace
--

CREATE TABLE pairs.pairs_upload_error (
    timestamp_error bigint DEFAULT date_part('epoch'::text, now()),
    upload_id bigint,
    error_code integer,
    error_message text,
    error_details text
);


ALTER TABLE pairs.pairs_upload_error OWNER TO pairs_db_master;

--
-- Name: upload_history_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.upload_history_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.upload_history_seq OWNER TO pairs_db_master;

--
-- Name: pairs_upload_history; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: upload_table_tablespace
--

CREATE TABLE pairs.pairs_upload_history (
    upload_id bigint DEFAULT nextval('pairs.upload_history_seq'::regclass),
    dset_id integer,
    layer_id integer,
    upload_host_id integer,
    uploading_pipeline_type text,
    upload_priority smallint,
    status integer,
    process_id integer,
    layer_shortname text,
    col_f text,
    col_q text,
    plevel smallint,
    dtype text,
    interpolation text,
    unit_conversion text,
    lin_conv_slope double precision,
    lin_conv_offset double precision,
    nodata_in double precision,
    nodata_out double precision,
    crs text,
    large_tile_flag smallint,
    input_band_number integer,
    raw_filename text,
    raw_filesize bigint,
    preprocessed_filename text,
    preprocessed_filesize bigint,
    timestamp_data bigint,
    tile_x integer,
    tile_y integer,
    timestamp_received bigint,
    timestamp_start_processing bigint,
    timestamp_start_writing bigint,
    timestamp_finished bigint,
    processing_directory text,
    finished_directory text,
    error_directory text,
    hdftype text,
    hdfbandname text,
    received_directory text,
    db_table text,
    db_name text,
    db_server text,
    hashed_filename text,
    hashed_layer_filename text,
    tile_global integer,
    conv_params_dict text,
    deletedata boolean,
    post_proc_json text,
    pre_proc_json jsonb
);


ALTER TABLE pairs.pairs_upload_history OWNER TO pairs_db_master;

--
-- Name: pairs_upload_history_aged; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: upload_table_tablespace
--

CREATE TABLE pairs.pairs_upload_history_aged (
    upload_id bigint DEFAULT nextval('pairs.upload_history_seq'::regclass),
    dset_id integer,
    layer_id integer,
    upload_host_id integer,
    uploading_pipeline_type text,
    upload_priority smallint,
    status integer,
    process_id integer,
    layer_shortname text,
    col_f text,
    col_q text,
    plevel smallint,
    dtype text,
    interpolation text,
    unit_conversion text,
    lin_conv_slope double precision,
    lin_conv_offset double precision,
    nodata_in double precision,
    nodata_out double precision,
    crs text,
    large_tile_flag smallint,
    input_band_number integer,
    raw_filename text,
    raw_filesize bigint,
    preprocessed_filename text,
    preprocessed_filesize bigint,
    timestamp_data bigint,
    tile_x integer,
    tile_y integer,
    timestamp_received bigint,
    timestamp_start_processing bigint,
    timestamp_start_writing bigint,
    timestamp_finished bigint,
    processing_directory text,
    finished_directory text,
    error_directory text,
    hdftype text,
    hdfbandname text,
    received_directory text,
    db_table text,
    db_name text,
    db_server text,
    hashed_filename text,
    hashed_layer_filename text,
    tile_global integer,
    conv_params_dict text,
    deletedata boolean,
    post_proc_json text
);


ALTER TABLE pairs.pairs_upload_history_aged OWNER TO pairs_db_master;

--
-- Name: pairs_upload_history_archive; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: upload_table_tablespace
--

CREATE TABLE pairs.pairs_upload_history_archive (
    upload_id bigint,
    dset_id integer,
    layer_id integer,
    upload_host_id integer,
    uploading_pipeline_type text,
    upload_priority smallint,
    status integer,
    process_id integer,
    layer_shortname text,
    col_f text,
    col_q text,
    plevel smallint,
    dtype text,
    interpolation text,
    unit_conversion text,
    lin_conv_slope double precision,
    lin_conv_offset double precision,
    nodata_in double precision,
    nodata_out double precision,
    crs text,
    large_tile_flag smallint,
    input_band_number integer,
    raw_filename text,
    raw_filesize bigint,
    preprocessed_filename text,
    preprocessed_filesize bigint,
    timestamp_data bigint,
    tile_x integer,
    tile_y integer,
    timestamp_received bigint,
    timestamp_start_processing bigint,
    timestamp_start_writing bigint,
    timestamp_finished bigint,
    processing_directory text,
    finished_directory text,
    error_directory text,
    hdftype text,
    hdfbandname text,
    received_directory text,
    db_table text,
    db_name text,
    db_server text,
    hashed_filename text,
    hashed_layer_filename text,
    tile_global integer,
    conv_params_dict text,
    deletedata boolean,
    post_proc_json text,
    pre_proc_json jsonb
);


ALTER TABLE pairs.pairs_upload_history_archive OWNER TO pairs_db_master;

--
-- Name: pairs_upload_history_combined; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.pairs_upload_history_combined AS
 SELECT pairs_upload_history.upload_id,
    pairs_upload_history.dset_id,
    pairs_upload_history.layer_id,
    pairs_upload_history.upload_host_id,
    pairs_upload_history.uploading_pipeline_type,
    pairs_upload_history.upload_priority,
    pairs_upload_history.status,
    pairs_upload_history.process_id,
    pairs_upload_history.layer_shortname,
    pairs_upload_history.col_f,
    pairs_upload_history.col_q,
    pairs_upload_history.plevel,
    pairs_upload_history.dtype,
    pairs_upload_history.interpolation,
    pairs_upload_history.unit_conversion,
    pairs_upload_history.lin_conv_slope,
    pairs_upload_history.lin_conv_offset,
    pairs_upload_history.nodata_in,
    pairs_upload_history.nodata_out,
    pairs_upload_history.crs,
    pairs_upload_history.large_tile_flag,
    pairs_upload_history.input_band_number,
    pairs_upload_history.raw_filename,
    pairs_upload_history.raw_filesize,
    pairs_upload_history.preprocessed_filename,
    pairs_upload_history.preprocessed_filesize,
    pairs_upload_history.timestamp_data,
    pairs_upload_history.tile_x,
    pairs_upload_history.tile_y,
    pairs_upload_history.timestamp_received,
    pairs_upload_history.timestamp_start_processing,
    pairs_upload_history.timestamp_start_writing,
    pairs_upload_history.timestamp_finished,
    pairs_upload_history.processing_directory,
    pairs_upload_history.finished_directory,
    pairs_upload_history.error_directory,
    pairs_upload_history.hdftype,
    pairs_upload_history.hdfbandname,
    pairs_upload_history.received_directory,
    pairs_upload_history.db_table,
    pairs_upload_history.db_name,
    pairs_upload_history.db_server,
    pairs_upload_history.hashed_filename,
    pairs_upload_history.hashed_layer_filename,
    pairs_upload_history.tile_global,
    pairs_upload_history.conv_params_dict,
    pairs_upload_history.deletedata,
    pairs_upload_history.post_proc_json
   FROM pairs.pairs_upload_history
UNION ALL
 SELECT pairs_upload_history_archive.upload_id,
    pairs_upload_history_archive.dset_id,
    pairs_upload_history_archive.layer_id,
    pairs_upload_history_archive.upload_host_id,
    pairs_upload_history_archive.uploading_pipeline_type,
    pairs_upload_history_archive.upload_priority,
    pairs_upload_history_archive.status,
    pairs_upload_history_archive.process_id,
    pairs_upload_history_archive.layer_shortname,
    pairs_upload_history_archive.col_f,
    pairs_upload_history_archive.col_q,
    pairs_upload_history_archive.plevel,
    pairs_upload_history_archive.dtype,
    pairs_upload_history_archive.interpolation,
    pairs_upload_history_archive.unit_conversion,
    pairs_upload_history_archive.lin_conv_slope,
    pairs_upload_history_archive.lin_conv_offset,
    pairs_upload_history_archive.nodata_in,
    pairs_upload_history_archive.nodata_out,
    pairs_upload_history_archive.crs,
    pairs_upload_history_archive.large_tile_flag,
    pairs_upload_history_archive.input_band_number,
    pairs_upload_history_archive.raw_filename,
    pairs_upload_history_archive.raw_filesize,
    pairs_upload_history_archive.preprocessed_filename,
    pairs_upload_history_archive.preprocessed_filesize,
    pairs_upload_history_archive.timestamp_data,
    pairs_upload_history_archive.tile_x,
    pairs_upload_history_archive.tile_y,
    pairs_upload_history_archive.timestamp_received,
    pairs_upload_history_archive.timestamp_start_processing,
    pairs_upload_history_archive.timestamp_start_writing,
    pairs_upload_history_archive.timestamp_finished,
    pairs_upload_history_archive.processing_directory,
    pairs_upload_history_archive.finished_directory,
    pairs_upload_history_archive.error_directory,
    pairs_upload_history_archive.hdftype,
    pairs_upload_history_archive.hdfbandname,
    pairs_upload_history_archive.received_directory,
    pairs_upload_history_archive.db_table,
    pairs_upload_history_archive.db_name,
    pairs_upload_history_archive.db_server,
    pairs_upload_history_archive.hashed_filename,
    pairs_upload_history_archive.hashed_layer_filename,
    pairs_upload_history_archive.tile_global,
    pairs_upload_history_archive.conv_params_dict,
    pairs_upload_history_archive.deletedata,
    pairs_upload_history_archive.post_proc_json
   FROM pairs.pairs_upload_history_archive;


ALTER TABLE pairs.pairs_upload_history_combined OWNER TO pairs_db_master;

--
-- Name: pairs_upload_history_upload_id_seq; Type: SEQUENCE; Schema: pairs; Owner: pairs_db_master
--

CREATE SEQUENCE pairs.pairs_upload_history_upload_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pairs.pairs_upload_history_upload_id_seq OWNER TO pairs_db_master;

-- SET default_tablespace = default_pairs_tablespace;

--
-- Name: pairs_upload_hosts; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_upload_hosts (
    id integer,
    root_directory text,
    upload_pause integer,
    upload_shutdown integer,
    preprocessor_timeout integer,
    hbase_writer_timeout integer,
    max_running_total integer,
    max_processing_total integer,
    max_running_2d integer,
    max_running_1d integer,
    max_running_this_host integer,
    max_running_layer integer,
    name text,
    ip_address text
);


ALTER TABLE pairs.pairs_upload_hosts OWNER TO pairs_db_master;

--
-- Name: pairs_vector_region_info; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pairs_vector_region_info (
    dset_id integer NOT NULL,
    dset_key text,
    datalayer_id text NOT NULL,
    datalayer_shortname text,
    region_key text,
    aoi_id bigint NOT NULL
);


ALTER TABLE pairs.pairs_vector_region_info OWNER TO pairs_db_master;

--
-- Name: pointdata_geomesa; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE TABLE pairs.pointdata_geomesa (
    id integer NOT NULL,
    table_schema character varying,
    type_name character varying
);


ALTER TABLE pairs.pointdata_geomesa OWNER TO pairs_db_master;

--
-- Name: query_diagnostic; Type: VIEW; Schema: pairs; Owner: pairs_db_master
--

CREATE VIEW pairs.query_diagnostic AS
 SELECT j.id,
    to_timestamp(((j.start / (1000)::numeric))::double precision) AS query_submitted,
    j.nickname,
    j.status,
    j.pd_status,
        CASE
            WHEN ((j.status >= (0)::numeric) AND (j.status <= (19)::numeric)) THEN ((((date_part('epoch'::text, now()) * (1000)::double precision) - (j.start)::double precision) / (1000)::double precision))::integer
            ELSE NULL::integer
        END AS started_secs_ago,
        CASE
            WHEN ((j.status IS NULL) AND (j.hadoop_id IS NOT NULL) AND (j.pd_status IS NULL) AND (((date_part('epoch'::text, now()) * (1000)::double precision) - (j.start)::double precision) > (3600)::double precision)) THEN 'Query submitted to HBASE but never completed in 1 hour'::text
            WHEN ((j.status IS NULL) AND (j.hadoop_id IS NOT NULL) AND (j.pd_status IS NULL) AND (((date_part('epoch'::text, now()) * (1000)::double precision) - (j.start)::double precision) > (86400)::double precision)) THEN 'Query submitted but never completed in one day'::text
            WHEN ((j.status >= (20)::numeric) AND (j.status <= (32)::numeric) AND (j.hadoop_id IS NOT NULL)) THEN 'HBASE Query completed'::text
            WHEN ((j.status >= (20)::numeric) AND (j.status <= (32)::numeric) AND (j.hadoop_id IS NULL)) THEN 'success but missing HADOOP ID'::text
            WHEN ((j.pd_status >= (20)::numeric) AND (j.pd_status <= (32)::numeric) AND (j.hadoop_id IS NULL)) THEN 'POINT Query completed'::text
            WHEN ((j.status >= (0)::numeric) AND (j.status <= (19)::numeric) AND (j.hadoop_id IS NOT NULL)) THEN 'HBASE Query in process'::text
            WHEN ((j.status >= (10)::numeric) AND (j.status <= (19)::numeric) AND (j.hadoop_id IS NULL)) THEN 'HBASE Query hanging?'::text
            WHEN ((j.status = (1)::numeric) AND (j.hadoop_id IS NULL) AND (((date_part('epoch'::text, now()) * (1000)::double precision) - (j.start)::double precision) > (100)::double precision)) THEN 'Query hanging before HBASE submission?'::text
            WHEN ((j.pd_status >= (0)::numeric) AND (j.pd_status <= (19)::numeric) AND (j.hadoop_id IS NULL)) THEN 'POINT Query in process'::text
            WHEN ((j.status IS NULL) AND (j.pd_status IS NULL) AND (j.hadoop_id IS NULL) AND (((date_part('epoch'::text, now()) * (1000)::double precision) - (j.start)::double precision) > (100)::double precision)) THEN 'Point Query submitted but taking longe than 100 seconds'::text
            WHEN ((j.status >= (40)::numeric) AND (j.status <= (41)::numeric) AND (j.pd_status IS NULL)) THEN 'Failed'::text
            ELSE 'Unknown status'::text
        END AS diagnostic,
        CASE COALESCE(j.status, j.pd_status)
            WHEN 0 THEN 'Queued'::text
            WHEN 1 THEN 'Initializing'::text
            WHEN 10 THEN 'Running'::text
            WHEN 11 THEN 'Writing'::text
            WHEN 12 THEN 'Packaging'::text
            WHEN 13 THEN 'Publishing'::text
            WHEN 20 THEN 'Succeeded'::text
            WHEN 21 THEN 'NoDataFound'::text
            WHEN 30 THEN 'Killed'::text
            WHEN 31 THEN 'Deleted'::text
            WHEN 40 THEN 'Failed'::text
            WHEN 41 THEN 'FailedConversion'::text
            ELSE 'Unknown status'::text
        END AS status_in_clear,
    j.hadoop_id,
    j.usr,
    j.pql,
    j.sw_lat,
    j.sw_lon,
    j.ne_lat,
    j.ne_lon,
    j.flag,
    j.server_id,
    s.description,
    s.url,
    s.geoserver_url,
    s.geoserver_ext,
    j.start AS start_unix,
    j.folder
   FROM pairs.pairs_query_job j,
    pairs.pairs_config_server s
  WHERE (j.server_id = s.id);


ALTER TABLE pairs.query_diagnostic OWNER TO pairs_db_master;

SET default_tablespace = '';

--
-- Name: test01; Type: TABLE; Schema: pairs; Owner: metadata_writer
--

CREATE TABLE pairs.test01 (
    did integer NOT NULL,
    name character varying(40),
    newcol character varying
);


-- ALTER TABLE pairs.test01 OWNER TO metadata_writer;

--
-- Name: test1; Type: TABLE; Schema: pairs; Owner: metadata_writer
--

CREATE TABLE pairs.test1 (
    id bigint NOT NULL,
    poly geometry
);


-- ALTER TABLE pairs.test1 OWNER TO metadata_writer;

-- SET default_tablespace = upload_table_tablespace;

--
-- Name: upload_status_cache; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: upload_table_tablespace
--

CREATE TABLE pairs.upload_status_cache (
    tracking_id text NOT NULL,
    raw_filename text NOT NULL,
    status real NOT NULL,
    details text,
    last_updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE pairs.upload_status_cache OWNER TO pairs_db_master;

--
-- Name: upload_status_history; Type: TABLE; Schema: pairs; Owner: pairs_db_master; Tablespace: upload_table_tablespace
--

CREATE TABLE pairs.upload_status_history (
    tracking_id text NOT NULL,
    user_tag text,
    number_uploads integer,
    user_id text,
    status character varying(20) NOT NULL,
    summary jsonb DEFAULT '[]'::jsonb,
    last_updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE pairs.upload_status_history OWNER TO pairs_db_master;

--
-- Name: pairs_aoi_hierarchy id; Type: DEFAULT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_aoi_hierarchy ALTER COLUMN id SET DEFAULT nextval('pairs.pairs_aoi_hierarchy_id_seq'::regclass);


--
-- Name: pairs_datadocs_tags_data_set id; Type: DEFAULT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_datadocs_tags_data_set ALTER COLUMN id SET DEFAULT nextval('pairs.pairs_datadocs_tags_data_set_id_seq'::regclass);


--
-- Name: pairs_dim_values id; Type: DEFAULT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_dim_values ALTER COLUMN id SET DEFAULT nextval('pairs.pairs_dim_values_id_seq'::regclass);


--
-- Name: pairs_dimensions id; Type: DEFAULT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_dimensions ALTER COLUMN id SET DEFAULT nextval('pairs.pairs_dimensions_id_seq'::regclass);


--
-- Name: pairs_pointdata_column_info id; Type: DEFAULT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_column_info ALTER COLUMN id SET DEFAULT nextval('pairs.pairs_pointdata_column_info_id_seq'::regclass);


--
-- Name: pairs_pointdata_table_info id; Type: DEFAULT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_info ALTER COLUMN id SET DEFAULT nextval('pairs.pairs_pointdata_table_info_id_seq'::regclass);


-- SET default_tablespace = default_pairs_tablespace;

--
-- Name: pairs_data_access UC_ALL; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_data_access
    ADD CONSTRAINT "UC_ALL" UNIQUE (dset, layer, grp, usr, level);


--
-- Name: pairs_upload_hosts UC_ID; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_upload_hosts
    ADD CONSTRAINT "UC_ID" UNIQUE (id);


--
-- Name: pairs_auth_disclaimer add; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_auth_disclaimer
    ADD CONSTRAINT add PRIMARY KEY (id, version);


--
-- Name: pairs_aoi_hierarchy pairs_aoi_hierarchy_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_aoi_hierarchy
    ADD CONSTRAINT pairs_aoi_hierarchy_pkey PRIMARY KEY (id);


--
-- Name: pairs_aoi pairs_aoi_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_aoi
    ADD CONSTRAINT pairs_aoi_pkey PRIMARY KEY (polygon_id);


--
-- Name: pairs_auth_group pairs_auth_group_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_auth_group
    ADD CONSTRAINT pairs_auth_group_pkey PRIMARY KEY (id);


--
-- Name: pairs_auth_user pairs_auth_user_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_auth_user
    ADD CONSTRAINT pairs_auth_user_pkey PRIMARY KEY (id);


--
-- Name: pairs_config pairs_config_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_config
    ADD CONSTRAINT pairs_config_pkey PRIMARY KEY (key);


--
-- Name: pairs_config_server pairs_config_server_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_config_server
    ADD CONSTRAINT pairs_config_server_pkey PRIMARY KEY (id);


--
-- Name: pairs_data_access pairs_data_access_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_data_access
    ADD CONSTRAINT pairs_data_access_pkey PRIMARY KEY (id);


--
-- Name: pairs_data_categ pairs_data_categ_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_data_categ
    ADD CONSTRAINT pairs_data_categ_pkey PRIMARY KEY (id);


--
-- Name: pairs_data_ctable pairs_data_ctable_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_data_ctable
    ADD CONSTRAINT pairs_data_ctable_pkey PRIMARY KEY (id);


--
-- Name: pairs_data_info pairs_data_info_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_data_info
    ADD CONSTRAINT pairs_data_info_pkey PRIMARY KEY (id);


--
-- Name: pairs_data_layer pairs_data_layer_dset_short_key; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_data_layer
    ADD CONSTRAINT pairs_data_layer_dset_short_key UNIQUE (dset, short);


--
-- Name: pairs_data_layer pairs_data_layer_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_data_layer
    ADD CONSTRAINT pairs_data_layer_pkey PRIMARY KEY (id);


--
-- Name: pairs_data_layer_region_rel pairs_data_layer_region_rel_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_data_layer_region_rel
    ADD CONSTRAINT pairs_data_layer_region_rel_pkey PRIMARY KEY (layer, region);


--
-- Name: pairs_data_region pairs_data_region_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_data_region
    ADD CONSTRAINT pairs_data_region_pkey PRIMARY KEY (id);


--
-- Name: pairs_datadocs_tags_data_set pairs_datadocs_tags_data_set_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_datadocs_tags_data_set
    ADD CONSTRAINT pairs_datadocs_tags_data_set_pkey PRIMARY KEY (id);


--
-- Name: pairs_dim_values pairs_dim_values_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_dim_values
    ADD CONSTRAINT pairs_dim_values_pkey PRIMARY KEY (id);


--
-- Name: pairs_dimensions pairs_dimensions_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_dimensions
    ADD CONSTRAINT pairs_dimensions_pkey PRIMARY KEY (id);


--
-- Name: pairs_dimensions_vector pairs_dimensions_vector_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_dimensions_vector
    ADD CONSTRAINT pairs_dimensions_vector_pkey PRIMARY KEY (id);


SET default_tablespace = '';

--
-- Name: pairs_federation_policy pairs_federation_policy_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_federation_policy
    ADD CONSTRAINT pairs_federation_policy_pkey PRIMARY KEY (datalayer_id, start_ts, end_ts, ranknum);


--
-- Name: pairs_federation_store pairs_federation_store_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_federation_store
    ADD CONSTRAINT pairs_federation_store_pkey PRIMARY KEY (store_id);


-- SET default_tablespace = default_pairs_tablespace;

--
-- Name: pairs_ftp pairs_ftp_id_key; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_ftp
    ADD CONSTRAINT pairs_ftp_id_key UNIQUE (id);


--
-- Name: pairs_noti_event pairs_noti_event_key_type_key; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_noti_event
    ADD CONSTRAINT pairs_noti_event_key_type_key UNIQUE (key, type);


--
-- Name: pairs_noti_event pairs_noti_event_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_noti_event
    ADD CONSTRAINT pairs_noti_event_pkey PRIMARY KEY (id);


SET default_tablespace = '';

--
-- Name: pairs_organization pairs_organization_pkey; Type: CONSTRAINT; Schema: pairs; Owner: metadata_writer
--

ALTER TABLE ONLY pairs.pairs_organization
    ADD CONSTRAINT pairs_organization_pkey PRIMARY KEY (name);


-- SET default_tablespace = default_pairs_tablespace;

--
-- Name: pairs_overview_info pairs_overview_info_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_overview_info
    ADD CONSTRAINT pairs_overview_info_pkey PRIMARY KEY (id);


--
-- Name: pairs_pipeline pairs_pipeline_id_key; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_pipeline
    ADD CONSTRAINT pairs_pipeline_id_key UNIQUE (id);


--
-- Name: pairs_pointdata_column_info pairs_pointdata_column_info_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_pointdata_column_info
    ADD CONSTRAINT pairs_pointdata_column_info_pkey PRIMARY KEY (id);


--
-- Name: pairs_pointdata_table_query_attr pairs_pointdata_query_attr_pk; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_query_attr
    ADD CONSTRAINT pairs_pointdata_query_attr_pk PRIMARY KEY (id);


--
-- Name: pairs_pointdata_table_query_column pairs_pointdata_query_column_pk; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_query_column
    ADD CONSTRAINT pairs_pointdata_query_column_pk PRIMARY KEY (id);


--
-- Name: pairs_pointdata_table_query_data pairs_pointdata_query_data_pk; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_query_data
    ADD CONSTRAINT pairs_pointdata_query_data_pk PRIMARY KEY (id);


--
-- Name: pairs_pointdata_table_info pairs_pointdata_table_info_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_info
    ADD CONSTRAINT pairs_pointdata_table_info_pkey PRIMARY KEY (id);


--
-- Name: pairs_pointdata_table_query_summary pairs_pointdata_table_query_summary_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_query_summary
    ADD CONSTRAINT pairs_pointdata_table_query_summary_pkey PRIMARY KEY (id);


--
-- Name: pairs_qa_metrics pairs_qa_metrics_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_qa_metrics
    ADD CONSTRAINT pairs_qa_metrics_pkey PRIMARY KEY (datalayer_id);


--
-- Name: pairs_query_aoi_alias pairs_query_aoi_alias_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_query_aoi_alias
    ADD CONSTRAINT pairs_query_aoi_alias_pkey PRIMARY KEY (aoi_alias);


--
-- Name: pairs_query_aoi pairs_query_aoi_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_query_aoi
    ADD CONSTRAINT pairs_query_aoi_pkey PRIMARY KEY (id);


--
-- Name: pairs_query_hist pairs_query_hist_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_query_hist
    ADD CONSTRAINT pairs_query_hist_pkey PRIMARY KEY (id);


--
-- Name: pairs_query_job pairs_query_job_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_query_job
    ADD CONSTRAINT pairs_query_job_pkey PRIMARY KEY (id);


--
-- Name: pairs_query_upload pairs_query_upload_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_query_upload
    ADD CONSTRAINT pairs_query_upload_pkey PRIMARY KEY (id);


--
-- Name: pairs_system_info pairs_system_info_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_system_info
    ADD CONSTRAINT pairs_system_info_pkey PRIMARY KEY (id);


--
-- Name: pairs_tile_info pairs_tile_info_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_tile_info
    ADD CONSTRAINT pairs_tile_info_pkey PRIMARY KEY (dset_id, tile_id);


--
-- Name: pairs_vector_region_info pairs_vector_region_info_pkey; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.pairs_vector_region_info
    ADD CONSTRAINT pairs_vector_region_info_pkey PRIMARY KEY (datalayer_id, aoi_id);


SET default_tablespace = '';

--
-- Name: test01 test01_pkey; Type: CONSTRAINT; Schema: pairs; Owner: metadata_writer
--

ALTER TABLE ONLY pairs.test01
    ADD CONSTRAINT test01_pkey PRIMARY KEY (did);


--
-- Name: pairs_auth_group unique_group_external_id; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_group
    ADD CONSTRAINT unique_group_external_id UNIQUE (external_id);


--
-- Name: pairs_auth_user unique_user_external_id; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_user
    ADD CONSTRAINT unique_user_external_id UNIQUE (external_id);


--
-- Name: pairs_auth_user unique_user_login; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_user
    ADD CONSTRAINT unique_user_login UNIQUE (login);


-- SET default_tablespace = default_pairs_tablespace;

--
-- Name: upload_status_cache upload_status_cache_tracking_id_raw_filename_key; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.upload_status_cache
    ADD CONSTRAINT upload_status_cache_tracking_id_raw_filename_key UNIQUE (tracking_id, raw_filename);


--
-- Name: upload_status_history upload_status_history_tracking_id_key; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.upload_status_history
    ADD CONSTRAINT upload_status_history_tracking_id_key UNIQUE (tracking_id);


--
-- Name: vector_layer_availability vector_layer_availability_pk; Type: CONSTRAINT; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

ALTER TABLE ONLY pairs.vector_layer_availability
    ADD CONSTRAINT vector_layer_availability_pk PRIMARY KEY (layer_id, pairs_key, resolution_level, latitude, longitude);


--
-- Name: datalayer_id_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX datalayer_id_idx ON pairs.pairs_qa_metrics USING btree (datalayer_id);


--
-- Name: datalayer_shortname_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX datalayer_shortname_idx ON pairs.pairs_qa_metrics USING btree (datalayer_shortname);


--
-- Name: dset_id_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX dset_id_idx ON pairs.pairs_qa_metrics USING btree (dset_id);


--
-- Name: dset_key_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX dset_key_idx ON pairs.pairs_qa_metrics USING btree (dset_key);


--
-- Name: load_rawfiles_adate_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

--
-- Name: load_rawfiles_file_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

--
-- Name: load_rawfiles_loc_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--


--
-- Name: pairs_data_layer_dset; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_data_layer_dset ON pairs.pairs_data_layer USING btree (dset);


--
-- Name: pairs_data_layer_id_status; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_data_layer_id_status ON pairs.pairs_data_layer USING btree (id, status);


--
-- Name: pairs_dim_values_dim_id_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_dim_values_dim_id_idx ON pairs.pairs_dim_values USING btree (dim_id);


--
-- Name: pairs_dimensions_def_value; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_dimensions_def_value ON pairs.pairs_dimensions USING btree (default_value);


--
-- Name: pairs_dimensions_layer_id; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_dimensions_layer_id ON pairs.pairs_dimensions USING btree (layer_id, default_value);


--
-- Name: pairs_dimensions_vector_default_value_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_dimensions_vector_default_value_idx ON pairs.pairs_dimensions_vector USING btree (default_value);


--
-- Name: pairs_dimensions_vector_layer_id_default_value_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_dimensions_vector_layer_id_default_value_idx ON pairs.pairs_dimensions_vector USING btree (layer_id, default_value);


--
-- Name: pairs_key_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_key_idx ON pairs.pairs_layer_avail_level11 USING btree (pairs_key);


--
-- Name: pairs_layer_avail_level11_full; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_layer_avail_level11_full ON pairs.pairs_layer_avail_level11 USING btree (layer_id, xi, yi, random);


--
-- Name: pairs_layer_avail_level11_layer_id_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_layer_avail_level11_layer_id_idx ON pairs.pairs_layer_avail_level11 USING btree (layer_id);


--
-- Name: pairs_pointdata_column_info_tableid; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_pointdata_column_info_tableid ON pairs.pairs_pointdata_column_info USING btree (table_id, attrib);


--
-- Name: pairs_pointdata_table_info_tidsttatus; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_pointdata_table_info_tidsttatus ON pairs.pairs_pointdata_table_info USING btree (id, status);


--
-- Name: pairs_query_aoi_gix; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_query_aoi_gix ON pairs.pairs_query_aoi USING gist (poly);


--
-- Name: pairs_query_aoi_name_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX pairs_query_aoi_name_idx ON pairs.pairs_query_aoi USING btree (name);


--
-- Name: pk_pairs_auth_group_user; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE UNIQUE INDEX pk_pairs_auth_group_user ON pairs.pairs_auth_group_user USING btree (grp, usr);


--
-- Name: query_hist_date_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX query_hist_date_idx ON pairs.pairs_query_hist USING btree (date);


--
-- Name: query_hist_job_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX query_hist_job_idx ON pairs.pairs_query_hist USING btree (queryjob);


--
-- Name: query_job_page_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX query_job_page_idx ON pairs.pairs_query_job USING btree (usr, flag, status);


--
-- Name: query_job_status_id_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX query_job_status_id_idx ON pairs.pairs_query_job_status USING btree (queryjob);


--
-- Name: query_job_status_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX query_job_status_idx ON pairs.pairs_query_job USING btree (status);


--
-- Name: upload_status_cache_last_updated_idx; Type: INDEX; Schema: pairs; Owner: pairs_db_master; Tablespace: default_pairs_tablespace
--

CREATE INDEX upload_status_cache_last_updated_idx ON pairs.upload_status_history USING brin (last_updated);


--
-- Name: pairs_query_aoi set_timestamp_aoi; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER set_timestamp_aoi BEFORE UPDATE ON pairs.pairs_query_aoi FOR EACH ROW EXECUTE PROCEDURE pairs.trigger_set_timestamp();


--
-- Name: pairs_data_access set_timestamp_dataaccess; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER set_timestamp_dataaccess BEFORE UPDATE ON pairs.pairs_data_access FOR EACH ROW EXECUTE PROCEDURE pairs.trigger_set_timestamp();


--
-- Name: pairs_pointdata_column_info set_timestamp_datacolumn; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER set_timestamp_datacolumn BEFORE UPDATE ON pairs.pairs_pointdata_column_info FOR EACH ROW EXECUTE PROCEDURE pairs.trigger_set_timestamp();


--
-- Name: pairs_data_layer set_timestamp_datalayer; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER set_timestamp_datalayer BEFORE UPDATE ON pairs.pairs_data_layer FOR EACH ROW EXECUTE PROCEDURE pairs.trigger_set_timestamp();


--
-- Name: pairs_data_info set_timestamp_dataset; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER set_timestamp_dataset BEFORE UPDATE ON pairs.pairs_data_info FOR EACH ROW EXECUTE PROCEDURE pairs.trigger_set_timestamp();


--
-- Name: pairs_pointdata_table_info set_timestamp_datatable; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER set_timestamp_datatable BEFORE UPDATE ON pairs.pairs_pointdata_table_info FOR EACH ROW EXECUTE PROCEDURE pairs.trigger_set_timestamp();


--
-- Name: pairs_dim_values set_timestamp_dim_values; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER set_timestamp_dim_values BEFORE UPDATE ON pairs.pairs_dim_values FOR EACH ROW EXECUTE PROCEDURE pairs.trigger_set_timestamp();


--
-- Name: pairs_dimensions set_timestamp_dimension; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER set_timestamp_dimension BEFORE UPDATE ON pairs.pairs_dimensions FOR EACH ROW EXECUTE PROCEDURE pairs.trigger_set_timestamp();


--
-- Name: pairs_auth_group set_timestamp_group; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER set_timestamp_group BEFORE UPDATE ON pairs.pairs_auth_group FOR EACH ROW EXECUTE PROCEDURE pairs.trigger_set_timestamp();


--
-- Name: pairs_auth_user set_timestamp_user; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER set_timestamp_user BEFORE UPDATE ON pairs.pairs_auth_user FOR EACH ROW EXECUTE PROCEDURE pairs.trigger_set_timestamp();


--
-- Name: pairs_query_job status_trigger; Type: TRIGGER; Schema: pairs; Owner: pairs_db_master
--

CREATE TRIGGER status_trigger AFTER UPDATE ON pairs.pairs_query_job FOR EACH ROW EXECUTE PROCEDURE pairs.pairs_query_job_status_timestamp();


--
-- Name: pairs_overview_info FK_overview_layer; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_overview_info
    ADD CONSTRAINT "FK_overview_layer" FOREIGN KEY (layer_id) REFERENCES pairs.pairs_data_layer(id);


--
-- Name: pairs_query_upload FK_pairs_queryjob_upload_1; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_upload
    ADD CONSTRAINT "FK_pairs_queryjob_upload_1" FOREIGN KEY (queryjob) REFERENCES pairs.pairs_query_job(id);


--
-- Name: pairs_aoi fk_aoi_parent; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_aoi
    ADD CONSTRAINT fk_aoi_parent FOREIGN KEY (parent_id) REFERENCES pairs.pairs_query_aoi(id);


--
-- Name: pairs_aoi fk_aoi_polygon; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_aoi
    ADD CONSTRAINT fk_aoi_polygon FOREIGN KEY (polygon_id) REFERENCES pairs.pairs_query_aoi(id);


--
-- Name: pairs_auth_group_user fk_auth_group_user_grp; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_group_user
    ADD CONSTRAINT fk_auth_group_user_grp FOREIGN KEY (grp) REFERENCES pairs.pairs_auth_group(id);


--
-- Name: pairs_auth_group_user fk_auth_group_user_usr; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_group_user
    ADD CONSTRAINT fk_auth_group_user_usr FOREIGN KEY (usr) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_pointdata_column_info fk_column_ctable; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_column_info
    ADD CONSTRAINT fk_column_ctable FOREIGN KEY (ctable) REFERENCES pairs.pairs_data_ctable(id);


--
-- Name: pairs_data_access fk_data_access_data_info; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_access
    ADD CONSTRAINT fk_data_access_data_info FOREIGN KEY (dset) REFERENCES pairs.pairs_data_info(id);


--
-- Name: pairs_data_access fk_data_access_grp; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_access
    ADD CONSTRAINT fk_data_access_grp FOREIGN KEY (grp) REFERENCES pairs.pairs_auth_group(id);


--
-- Name: pairs_data_info fk_data_info_categ; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_info
    ADD CONSTRAINT fk_data_info_categ FOREIGN KEY (categ) REFERENCES pairs.pairs_data_categ(id);


--
-- Name: pairs_data_layer fk_data_info_layer; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_layer
    ADD CONSTRAINT fk_data_info_layer FOREIGN KEY (dset) REFERENCES pairs.pairs_data_info(id);


--
-- Name: pairs_data_region fk_data_info_region; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_region
    ADD CONSTRAINT fk_data_info_region FOREIGN KEY (dset) REFERENCES pairs.pairs_data_info(id);


--
-- Name: pairs_data_layer fk_data_layer_ctable; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_layer
    ADD CONSTRAINT fk_data_layer_ctable FOREIGN KEY (ctable) REFERENCES pairs.pairs_data_ctable(id);


--
-- Name: pairs_data_layer_region_rel fk_data_layer_rel; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_layer_region_rel
    ADD CONSTRAINT fk_data_layer_rel FOREIGN KEY (layer) REFERENCES pairs.pairs_data_layer(id);


--
-- Name: pairs_data_layer_region_rel fk_data_region_rel; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_layer_region_rel
    ADD CONSTRAINT fk_data_region_rel FOREIGN KEY (region) REFERENCES pairs.pairs_data_region(id);


--
-- Name: pairs_auth_group fk_group_created_by; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_group
    ADD CONSTRAINT fk_group_created_by FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_auth_group fk_group_updated_by; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_group
    ADD CONSTRAINT fk_group_updated_by FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_aoi fk_pairs_aoi_pairs_aoi_hierarchy; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_aoi
    ADD CONSTRAINT fk_pairs_aoi_pairs_aoi_hierarchy FOREIGN KEY (hierarchy_id) REFERENCES pairs.pairs_aoi_hierarchy(id);


--
-- Name: pairs_pointdata_table_query_summary fk_pointdata_table_query_summary_job_id; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_query_summary
    ADD CONSTRAINT fk_pointdata_table_query_summary_job_id FOREIGN KEY (job_id) REFERENCES pairs.pairs_query_job(id);


--
-- Name: pairs_pointdata_table_query_summary fk_pointdata_table_query_summary_pointdata_table_id; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_query_summary
    ADD CONSTRAINT fk_pointdata_table_query_summary_pointdata_table_id FOREIGN KEY (point_data_table_id) REFERENCES pairs.pairs_pointdata_table_info(id);


--
-- Name: pairs_query_aoi fk_query_aoi_group; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_aoi
    ADD CONSTRAINT fk_query_aoi_group FOREIGN KEY (grp) REFERENCES pairs.pairs_auth_group(id);


--
-- Name: pairs_query_aoi fk_query_aoi_user; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_aoi
    ADD CONSTRAINT fk_query_aoi_user FOREIGN KEY (usr) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_query_hist fk_query_hist_queryjob; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_hist
    ADD CONSTRAINT fk_query_hist_queryjob FOREIGN KEY (queryjob) REFERENCES pairs.pairs_query_job(id);


--
-- Name: pairs_query_hist fk_query_hist_user; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_hist
    ADD CONSTRAINT fk_query_hist_user FOREIGN KEY (usr) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_auth_user fk_user_group; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_user
    ADD CONSTRAINT fk_user_group FOREIGN KEY (grp) REFERENCES pairs.pairs_auth_group(id);


--
-- Name: pairs_auth_group pairs_auth_group_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_group
    ADD CONSTRAINT pairs_auth_group_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_auth_group pairs_auth_group_updated_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_group
    ADD CONSTRAINT pairs_auth_group_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_auth_group pairs_auth_group_updated_by_fkey1; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_group
    ADD CONSTRAINT pairs_auth_group_updated_by_fkey1 FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_auth_user pairs_auth_user_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_user
    ADD CONSTRAINT pairs_auth_user_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_auth_user pairs_auth_user_updated_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_auth_user
    ADD CONSTRAINT pairs_auth_user_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_data_access pairs_data_access_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_access
    ADD CONSTRAINT pairs_data_access_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_data_access pairs_data_access_updated_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_access
    ADD CONSTRAINT pairs_data_access_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_data_info pairs_data_info_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_info
    ADD CONSTRAINT pairs_data_info_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_data_info pairs_data_info_updated_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_info
    ADD CONSTRAINT pairs_data_info_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_data_layer pairs_data_layer_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_layer
    ADD CONSTRAINT pairs_data_layer_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_data_layer pairs_data_layer_updated_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_data_layer
    ADD CONSTRAINT pairs_data_layer_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_datalayer_preview_url pairs_datalayer_preview_url_datalyer_fk; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_datalayer_preview_url
    ADD CONSTRAINT pairs_datalayer_preview_url_datalyer_fk FOREIGN KEY (datalayerid) REFERENCES pairs.pairs_data_layer(id);


--
-- Name: pairs_dim_values pairs_dim_values_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_dim_values
    ADD CONSTRAINT pairs_dim_values_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_dim_values pairs_dim_values_updated_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_dim_values
    ADD CONSTRAINT pairs_dim_values_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_dimensions pairs_dimensions_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_dimensions
    ADD CONSTRAINT pairs_dimensions_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_dimensions pairs_dimensions_updated_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_dimensions
    ADD CONSTRAINT pairs_dimensions_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_organization pairs_organization_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: metadata_writer
--

ALTER TABLE ONLY pairs.pairs_organization
    ADD CONSTRAINT pairs_organization_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_organization pairs_organization_modified_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: metadata_writer
--

ALTER TABLE ONLY pairs.pairs_organization
    ADD CONSTRAINT pairs_organization_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_pointdata_column_info pairs_pointdata_column_info_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_column_info
    ADD CONSTRAINT pairs_pointdata_column_info_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_pointdata_column_info pairs_pointdata_column_info_table_id_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_column_info
    ADD CONSTRAINT pairs_pointdata_column_info_table_id_fkey FOREIGN KEY (table_id) REFERENCES pairs.pairs_pointdata_table_info(id);


--
-- Name: pairs_pointdata_column_info pairs_pointdata_column_info_updated_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_column_info
    ADD CONSTRAINT pairs_pointdata_column_info_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_pointdata_table_query_attr pairs_pointdata_query_attr_fk_1; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_query_attr
    ADD CONSTRAINT pairs_pointdata_query_attr_fk_1 FOREIGN KEY (col_id) REFERENCES pairs.pairs_pointdata_table_query_column(id);


--
-- Name: pairs_pointdata_table_query_data pairs_pointdata_query_data_fk_1; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_query_data
    ADD CONSTRAINT pairs_pointdata_query_data_fk_1 FOREIGN KEY (col_id) REFERENCES pairs.pairs_pointdata_table_query_column(id);


--
-- Name: pairs_pointdata_table_query_join pairs_pointdata_query_join_fk_1; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_query_join
    ADD CONSTRAINT pairs_pointdata_query_join_fk_1 FOREIGN KEY (data_id) REFERENCES pairs.pairs_pointdata_table_query_data(id);


--
-- Name: pairs_pointdata_table_info pairs_pointdata_table_info_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_info
    ADD CONSTRAINT pairs_pointdata_table_info_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_pointdata_table_info pairs_pointdata_table_info_dset_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_info
    ADD CONSTRAINT pairs_pointdata_table_info_dset_fkey FOREIGN KEY (dset) REFERENCES pairs.pairs_data_info(id);


--
-- Name: pairs_pointdata_table_info pairs_pointdata_table_info_updated_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_pointdata_table_info
    ADD CONSTRAINT pairs_pointdata_table_info_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_query_aoi_alias pairs_query_aoi_alias_aoi_id_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_aoi_alias
    ADD CONSTRAINT pairs_query_aoi_alias_aoi_id_fkey FOREIGN KEY (aoi_id) REFERENCES pairs.pairs_query_aoi(id) ON DELETE RESTRICT;


--
-- Name: pairs_query_aoi pairs_query_aoi_created_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_aoi
    ADD CONSTRAINT pairs_query_aoi_created_by_fkey FOREIGN KEY (created_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_query_aoi pairs_query_aoi_updated_by_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_aoi
    ADD CONSTRAINT pairs_query_aoi_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pairs.pairs_auth_user(id);


--
-- Name: pairs_query_job pairs_query_job_parent_fk; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_job
    ADD CONSTRAINT pairs_query_job_parent_fk FOREIGN KEY (parent) REFERENCES pairs.pairs_query_job(id);


--
-- Name: pairs_query_job pairs_query_job_server_id_fkey; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_job
    ADD CONSTRAINT pairs_query_job_server_id_fkey FOREIGN KEY (server_id) REFERENCES pairs.pairs_config_server(id);


--
-- Name: pairs_query_job_status query_job_status_fk; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_query_job_status
    ADD CONSTRAINT query_job_status_fk FOREIGN KEY (queryjob) REFERENCES pairs.pairs_query_job(id);


--
-- Name: pairs_federation_policy store_id_fk; Type: FK CONSTRAINT; Schema: pairs; Owner: pairs_db_master
--

ALTER TABLE ONLY pairs.pairs_federation_policy
    ADD CONSTRAINT store_id_fk FOREIGN KEY (store_id) REFERENCES pairs.pairs_federation_store(store_id);


--
-- Name: SCHEMA pairs; Type: ACL; Schema: -; Owner: pairs_db_master
--

GRANT ALL ON SCHEMA pairs TO metadata_writer;
GRANT USAGE ON SCHEMA pairs TO metadata_reader;


--
-- Name: TABLE containment; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.containment TO metadata_writer;
GRANT SELECT ON TABLE pairs.containment TO metadata_reader;


--
-- Name: TABLE pairs_aoi; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_aoi TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_aoi TO metadata_reader;


--
-- Name: TABLE pairs_query_aoi; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_query_aoi TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_query_aoi TO metadata_reader;


--
-- Name: TABLE pairs_aoi_geojson; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_aoi_geojson TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_aoi_geojson TO metadata_reader;


--
-- Name: TABLE pairs_aoi_hierarchy; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_aoi_hierarchy TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_aoi_hierarchy TO metadata_reader;


--
-- Name: SEQUENCE pairs_aoi_hierarchy_id_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_aoi_hierarchy_id_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_aoi_hierarchy_id_seq TO metadata_reader;


--
-- Name: TABLE pairs_auth_disclaimer; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_auth_disclaimer TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_auth_disclaimer TO metadata_reader;


--
-- Name: SEQUENCE pairs_auth_disclaimer_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_auth_disclaimer_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_auth_disclaimer_seq TO metadata_reader;


--
-- Name: TABLE pairs_auth_group; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_auth_group TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_auth_group TO metadata_reader;


--
-- Name: SEQUENCE pairs_auth_group_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_auth_group_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_auth_group_seq TO metadata_reader;


--
-- Name: TABLE pairs_auth_group_user; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_auth_group_user TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_auth_group_user TO metadata_reader;


--
-- Name: TABLE pairs_auth_user; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_auth_user TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_auth_user TO metadata_reader;


--
-- Name: TABLE pairs_data_access; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_data_access TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_data_access TO metadata_reader;


--
-- Name: TABLE pairs_auth_realm_role; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_auth_realm_role TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_auth_realm_role TO metadata_reader;


--
-- Name: TABLE pairs_auth_realm_user; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_auth_realm_user TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_auth_realm_user TO metadata_reader;


--
-- Name: TABLE pairs_auth_signature; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_auth_signature TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_auth_signature TO metadata_reader;


--
-- Name: SEQUENCE pairs_auth_user_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_auth_user_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_auth_user_seq TO metadata_reader;


--
-- Name: TABLE pairs_layer_avail_level11; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_layer_avail_level11 TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_layer_avail_level11 TO metadata_reader;


--
-- Name: TABLE vector_layer_availability; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.vector_layer_availability TO metadata_writer;
GRANT SELECT ON TABLE pairs.vector_layer_availability TO metadata_reader;


--
-- Name: TABLE pairs_availability_level11_view; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_availability_level11_view TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_availability_level11_view TO metadata_reader;


--
-- Name: TABLE pairs_categorical; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_categorical TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_categorical TO metadata_reader;


--
-- Name: TABLE pairs_config; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_config TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_config TO metadata_reader;


--
-- Name: TABLE pairs_config_server; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_config_server TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_config_server TO metadata_reader;


--
-- Name: SEQUENCE pairs_config_server_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_config_server_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_config_server_seq TO metadata_reader;


--
-- Name: SEQUENCE pairs_ctable_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_ctable_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_ctable_seq TO metadata_reader;


--
-- Name: SEQUENCE pairs_data_access_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_data_access_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_data_access_seq TO metadata_reader;


--
-- Name: TABLE pairs_data_categ; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_data_categ TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_data_categ TO metadata_reader;


--
-- Name: SEQUENCE pairs_data_categ_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_data_categ_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_data_categ_seq TO metadata_reader;


--
-- Name: TABLE pairs_data_ctable; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_data_ctable TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_data_ctable TO metadata_reader;


--
-- Name: TABLE pairs_data_info; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_data_info TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_data_info TO metadata_reader;


--
-- Name: SEQUENCE pairs_data_info_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_data_info_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_data_info_seq TO metadata_reader;


--
-- Name: TABLE pairs_data_layer; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_data_layer TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_data_layer TO metadata_reader;


--
-- Name: TABLE pairs_data_layer_region_rel; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_data_layer_region_rel TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_data_layer_region_rel TO metadata_reader;


--
-- Name: SEQUENCE pairs_data_layer_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_data_layer_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_data_layer_seq TO metadata_reader;


--
-- Name: TABLE pairs_data_region; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_data_region TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_data_region TO metadata_reader;


--
-- Name: SEQUENCE pairs_data_region_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_data_region_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_data_region_seq TO metadata_reader;


--
-- Name: TABLE pairs_pointdata_column_info; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pointdata_column_info TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pointdata_column_info TO metadata_reader;


--
-- Name: TABLE pairs_pointdata_table_info; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pointdata_table_info TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pointdata_table_info TO metadata_reader;


--
-- Name: TABLE pairs_datadocs_data_column; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_datadocs_data_column TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_datadocs_data_column TO metadata_reader;


--
-- Name: TABLE pairs_datadocs_data_layer; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_datadocs_data_layer TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_datadocs_data_layer TO metadata_reader;


--
-- Name: TABLE pairs_datadocs_data_set; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_datadocs_data_set TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_datadocs_data_set TO metadata_reader;


--
-- Name: TABLE pairs_datadocs_tags_data_set; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_datadocs_tags_data_set TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_datadocs_tags_data_set TO metadata_reader;


--
-- Name: SEQUENCE pairs_datadocs_tags_data_set_id_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_datadocs_tags_data_set_id_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_datadocs_tags_data_set_id_seq TO metadata_reader;


--
-- Name: TABLE pairs_datalayer_mapping; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_datalayer_mapping TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_datalayer_mapping TO metadata_reader;


--
-- Name: TABLE pairs_datalayer_mapping_full; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_datalayer_mapping_full TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_datalayer_mapping_full TO metadata_reader;


--
-- Name: TABLE pairs_dim_values; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_dim_values TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_dim_values TO metadata_reader;


--
-- Name: TABLE pairs_dimensions; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_dimensions TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_dimensions TO metadata_reader;


--
-- Name: TABLE pairs_datalayer_mapping_with_default; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_datalayer_mapping_with_default TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_datalayer_mapping_with_default TO metadata_reader;


--
-- Name: TABLE pairs_datalayer_preview_url; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_datalayer_preview_url TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_datalayer_preview_url TO metadata_reader;


--
-- Name: SEQUENCE pairs_datalayer_preview_url_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_datalayer_preview_url_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_datalayer_preview_url_seq TO metadata_reader;


--
-- Name: TABLE pairs_datalayer_search; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_datalayer_search TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_datalayer_search TO metadata_reader;


--
-- Name: SEQUENCE pairs_dim_values_id_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_dim_values_id_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_dim_values_id_seq TO metadata_reader;


--
-- Name: SEQUENCE pairs_dimensions_id_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_dimensions_id_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_dimensions_id_seq TO metadata_reader;


--
-- Name: TABLE pairs_dimensions_vector; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_dimensions_vector TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_dimensions_vector TO metadata_reader;


--
-- Name: TABLE pairs_federation_policy; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_federation_policy TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_federation_policy TO metadata_reader;


--
-- Name: TABLE pairs_federation_policy_inactive; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_federation_policy_inactive TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_federation_policy_inactive TO metadata_reader;


--
-- Name: TABLE pairs_federation_store; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_federation_store TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_federation_store TO metadata_reader;


--
-- Name: TABLE pairs_ftp; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_ftp TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_ftp TO metadata_reader;

--
--

GRANT ALL ON TABLE pairs.pairs_noti_event TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_noti_event TO metadata_reader;


--
-- Name: SEQUENCE pairs_noti_event_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_noti_event_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_noti_event_seq TO metadata_reader;


--
-- Name: SEQUENCE pairs_overview_info_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_overview_info_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_overview_info_seq TO metadata_reader;


--
-- Name: TABLE pairs_overview_info; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_overview_info TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_overview_info TO metadata_reader;


--
-- Name: TABLE pairs_pipeline; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pipeline TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pipeline TO metadata_reader;


--
-- Name: SEQUENCE pairs_pointdata_column_info_id_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_column_info_id_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_column_info_id_seq TO metadata_reader;


--
-- Name: TABLE pairs_pointdata_connections; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pointdata_connections TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pointdata_connections TO metadata_reader;


--
-- Name: SEQUENCE pairs_pointdata_table_info_id_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_table_info_id_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_table_info_id_seq TO metadata_reader;


--
-- Name: TABLE pairs_pointdata_table_query_attr; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pointdata_table_query_attr TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pointdata_table_query_attr TO metadata_reader;


--
-- Name: SEQUENCE pairs_pointdata_table_query_attr_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_table_query_attr_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_table_query_attr_seq TO metadata_reader;


--
-- Name: TABLE pairs_pointdata_table_query_column; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pointdata_table_query_column TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pointdata_table_query_column TO metadata_reader;


--
-- Name: SEQUENCE pairs_pointdata_table_query_column_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_table_query_column_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_table_query_column_seq TO metadata_reader;


--
-- Name: TABLE pairs_pointdata_table_query_csv; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pointdata_table_query_csv TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pointdata_table_query_csv TO metadata_reader;


--
-- Name: TABLE pairs_pointdata_table_query_data; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pointdata_table_query_data TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pointdata_table_query_data TO metadata_reader;


--
-- Name: SEQUENCE pairs_pointdata_table_query_data_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_table_query_data_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_table_query_data_seq TO metadata_reader;


--
-- Name: TABLE pairs_pointdata_table_query_join; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pointdata_table_query_join TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pointdata_table_query_join TO metadata_reader;


--
-- Name: TABLE pairs_pointdata_table_query_prop; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pointdata_table_query_prop TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pointdata_table_query_prop TO metadata_reader;


--
-- Name: TABLE pairs_pointdata_table_query_summary; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_pointdata_table_query_summary TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_pointdata_table_query_summary TO metadata_reader;


--
-- Name: SEQUENCE pairs_pointdata_table_query_summary_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_table_query_summary_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_pointdata_table_query_summary_seq TO metadata_reader;


--
-- Name: TABLE pairs_qa_metrics; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_qa_metrics TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_qa_metrics TO metadata_reader;


--
-- Name: TABLE pairs_query_aoi_alias; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_query_aoi_alias TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_query_aoi_alias TO metadata_reader;


--
-- Name: TABLE pairs_query_aoi_hierarchy; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_query_aoi_hierarchy TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_query_aoi_hierarchy TO metadata_reader;


--
-- Name: TABLE pairs_query_aoi_repository; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_query_aoi_repository TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_query_aoi_repository TO metadata_reader;


--
-- Name: SEQUENCE pairs_query_aoi_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_query_aoi_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_query_aoi_seq TO metadata_reader;


--
-- Name: TABLE pairs_query_hist; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_query_hist TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_query_hist TO metadata_reader;


--
-- Name: SEQUENCE pairs_query_hist_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_query_hist_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_query_hist_seq TO metadata_reader;


--
-- Name: TABLE pairs_query_job; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_query_job TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_query_job TO metadata_reader;


--
-- Name: TABLE pairs_query_job_status; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_query_job_status TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_query_job_status TO metadata_reader;


--
-- Name: TABLE pairs_query_upload; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_query_upload TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_query_upload TO metadata_reader;


--
-- Name: SEQUENCE pairs_query_upload_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_query_upload_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_query_upload_seq TO metadata_reader;


--
-- Name: TABLE pairs_system_info; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_system_info TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_system_info TO metadata_reader;


--
-- Name: TABLE pairs_tile_info; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_tile_info TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_tile_info TO metadata_reader;


--
-- Name: TABLE pairs_upload_error; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_upload_error TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_upload_error TO metadata_reader;


--
-- Name: SEQUENCE upload_history_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.upload_history_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.upload_history_seq TO metadata_reader;


--
-- Name: TABLE pairs_upload_history; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_upload_history TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_upload_history TO metadata_reader;


--
-- Name: TABLE pairs_upload_history_aged; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_upload_history_aged TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_upload_history_aged TO metadata_reader;


--
-- Name: TABLE pairs_upload_history_archive; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_upload_history_archive TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_upload_history_archive TO metadata_reader;


--
-- Name: TABLE pairs_upload_history_combined; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_upload_history_combined TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_upload_history_combined TO metadata_reader;


--
-- Name: SEQUENCE pairs_upload_history_upload_id_seq; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_upload_history_upload_id_seq TO metadata_writer;
GRANT SELECT,USAGE ON SEQUENCE pairs.pairs_upload_history_upload_id_seq TO metadata_reader;


--
-- Name: TABLE pairs_upload_hosts; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_upload_hosts TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_upload_hosts TO metadata_reader;


--
-- Name: TABLE pairs_vector_region_info; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pairs_vector_region_info TO metadata_writer;
GRANT SELECT ON TABLE pairs.pairs_vector_region_info TO metadata_reader;


--
-- Name: TABLE pointdata_geomesa; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.pointdata_geomesa TO metadata_writer;
GRANT SELECT ON TABLE pairs.pointdata_geomesa TO metadata_reader;


--
-- Name: TABLE query_diagnostic; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.query_diagnostic TO metadata_writer;
GRANT SELECT ON TABLE pairs.query_diagnostic TO metadata_reader;


--
-- Name: TABLE test01; Type: ACL; Schema: pairs; Owner: metadata_writer
--

GRANT SELECT ON TABLE pairs.test01 TO metadata_reader;


--
-- Name: TABLE test1; Type: ACL; Schema: pairs; Owner: metadata_writer
--

GRANT SELECT ON TABLE pairs.test1 TO metadata_reader;


--
-- Name: TABLE upload_status_cache; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.upload_status_cache TO metadata_writer;
GRANT SELECT ON TABLE pairs.upload_status_cache TO metadata_reader;


--
-- Name: TABLE upload_status_history; Type: ACL; Schema: pairs; Owner: pairs_db_master
--

GRANT ALL ON TABLE pairs.upload_status_history TO metadata_writer;
GRANT SELECT ON TABLE pairs.upload_status_history TO metadata_reader;


--
-- PostgreSQL database dump complete
--

