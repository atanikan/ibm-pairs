Oysysys -- RECREATE PAIRS database from scratch 
-- Run as a postgres root user (on ibmcloud as admin via connecting to ibmclouddb ) 
DROP DATABASE pairs WITH (FORCE);
CREATE DATABASE pairs;
DROP USER IF EXISTS pairs_db_master;
CREATE USER pairs_db_master WITH PASSWORD 'PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE pairs TO pairs_db_master;
DROP USER IF EXISTS metadata_writer;
CREATE USER metadata_writer WITH PASSWORD 'PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE pairs TO metadata_writer;
DROP USER IF EXISTS metadata_reader;
CREATE USER metadata_reader WITH PASSWORD 'PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE pairs TO metadata_reader;
GRANT metadata_writer TO pairs_db_master;

-- CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA ibm_extension;
-- COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
-- CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA ibm_extension;
-- COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA ibm_extension;
-- COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';
-- CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA ibm_extension;
-- COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';
-- 
-- ALTER SCHEMA pairs OWNER TO pairs_db_master;
