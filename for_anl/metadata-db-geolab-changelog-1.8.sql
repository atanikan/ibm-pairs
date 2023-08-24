-- Uploader - add uploader host data

DELETE FROM pairs.pairs_upload_hosts;


INSERT INTO pairs.pairs_upload_hosts( "id",
                                      "name",
                                      "ip_address",
                                      "root_directory",
                                      "upload_pause",
                                      "upload_shutdown",
                                      "preprocessor_timeout",
                                      "hbase_writer_timeout",
                                      "max_running_total",
                                      "max_processing_total",
                                      "max_running_2d",
                                      "max_running_1d",
                                      "max_running_this_host",
                                      "max_running_layer" )
     VALUES
  ( 1,
       'pairs_uploader-1',
       '10.191.93.131',
       '/data/pairs-uploader/datasets',
       0,
       0,
       1200,
       43200,
       60,
       30,
       40,
       40,
       40,
       4
    );

