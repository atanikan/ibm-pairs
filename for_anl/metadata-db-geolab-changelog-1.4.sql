-- add record for new PAIRS V2 uploaders

INSERT INTO pairs.pairs_upload_hosts (
        id, root_directory, upload_pause, upload_shutdown, preprocessor_timeout,
        hbase_writer_timeout, max_running_total, max_processing_total, max_running_2d,
        max_running_1d, max_running_this_host, max_running_layer, name, ip_address
    ) VALUES (
        17, '/data/pairs-uploader/datasets/', 0, 0, 1200,
        43200, 60, 30, 40,
        40, 40, 160, 'pairs_uploader-17', '9.47.220.19'
    );

INSERT INTO pairs.pairs_upload_hosts (
        id, root_directory, upload_pause, upload_shutdown, preprocessor_timeout,
        hbase_writer_timeout, max_running_total, max_processing_total, max_running_2d,
        max_running_1d, max_running_this_host, max_running_layer, name, ip_address
    ) VALUES (
        18, '/data/pairs-uploader/datasets/', 0, 0, 1200,
        43200, 60, 30, 40,
        40, 40, 160, 'pairs_uploader-18', '9.47.220.21'
    );
