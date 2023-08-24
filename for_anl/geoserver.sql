DELETE FROM pairs.pairs_config_server;

INSERT INTO pairs.pairs_config_server ("id", "description", "url", "geoserver_url", "geoserver_local", "geoserver_user", "geoserver_pwd", "active", "hash", "mac", "local_fs", "hadoop_fs", "geoserver_ext", "geoserver_ws")
     VALUES
  ( 1,
    '10.191.93.111',
    'http://10.191.93.111:8080',
    'http://localhost:9080/geoserver',
    'Y',
    'admin',
    'kfwk2l51qjkwpa',
    'Y',
    NULL,
    NULL,
    '/data/pairs_data',
    '/nfsdata',
    'https://10.191.93.4:8080/geoserver1/',
    'pairs' );


