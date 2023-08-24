-- all the grants after all the tables have been created
REVOKE ALL ON SCHEMA pairs FROM PUBLIC;

-- Write user
GRANT ALL ON SCHEMA pairs TO metadata_writer;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pairs TO metadata_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA pairs TO metadata_writer;

-- Read user
GRANT USAGE ON SCHEMA pairs TO metadata_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA pairs TO metadata_reader;

