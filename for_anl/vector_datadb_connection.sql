-- accomodate tovery long server names per cloud services 
ALTER TABLE pairs.pairs_pointdata_table_info ALTER COLUMN server TYPE character varying(1032);
ALTER TABLE pairs.pairs_pointdata_table_info ALTER COLUMN server SET DEFAULT '0222c406-f116-4df0-bb4b-4db49aaff859.3c7f6c12a66c4324800651be37a77ceb.databases.appdomain.cloud';
-- allow non default connection port to pairs vector data database
ALTER TABLE pairs.pairs_pointdata_table_info ADD COLUMN IF NOT EXISTS db_server_port INTEGER;
ALTER TABLE pairs.pairs_pointdata_table_info ALTER COLUMN db_server_port SET DEFAULT 31038;
ALTER TABLE pairs.pairs_pointdata_table_info ALTER COLUMN rdbms SET DEFAULT 'pairs_data';
