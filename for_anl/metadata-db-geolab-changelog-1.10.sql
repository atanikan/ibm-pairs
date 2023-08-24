-- add PORT column to pairs.pairs_pointdata_table_info  

ALTER TABLE pairs.pairs_pointdata_table_info ADD COLUMNIF NOT EXISTS  db_server_port int;

