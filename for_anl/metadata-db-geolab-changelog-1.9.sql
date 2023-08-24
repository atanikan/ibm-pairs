-- Uploader - add point data config 

delete from pairs.pairs_config where key = 'pairs.config.pointdata.dbname'; 
insert into pairs.pairs_config (key,value) values ('pairs.config.pointdata.dbname','pairs_data');
delete from pairs.pairs_config where key = 'pairs.config.pointdata.user';
insert into pairs.pairs_config (key,value) values ('pairs.config.pointdata.user','pairs_db_master');
delete from pairs.pairs_config where key = 'pairs.config.pointdata.psswd'; 
insert into pairs.pairs_config (key,value) values ('pairs.config.pointdata.psswd','nccnaiofniowniiw');
delete from pairs.pairs_config where key = 'pairs.config.pointdata.host'; 
insert into pairs.pairs_config (key,value) values ('pairs.config.pointdata.host','0222c406-f116-4df0-bb4b-4db49aaff859.3c7f6c12a66c4324800651be37a77ceb.databases.appdomain.cloud');
delete from pairs.pairs_config where key = 'pairs.config.pointdata.port';
insert into pairs.pairs_config VALUES ('pairs.config.pointdata.port','31038');
