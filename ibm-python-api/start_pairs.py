from create_environment import CreateEnvironment
from run_hbase import RunHbase
from run_hadoop import RunHadoop
from run_postgres import RunPostgres
import os

if __name__ == "__main__":
    
    # Create Pairs environment
    create_env = CreateEnvironment()
    create_env.run_setup()
    create_env.execute()

    input_file = os.environ["PBS_NODEFILE"]

    # Run Hbase
    hbase_home = os.environ["HBASE_HOME"]
    worker_file = hbase_home + "/conf/regionservers"
    hbase_site_file = hbase_home + "/conf/hbase-site.xml"
    hbase = RunHbase(hbase_home, input_file, worker_file, hbase_site_file)
    hbase.run_setup()
    start_hbase_file = hbase_home + "/bin/start-hbase.sh"
    hbase.start_hbase(start_hbase_file)

    # Run Hadoop
    hadoop_home = os.environ["HADOOP_HOME"] 
    slave_file = hadoop_home + "/etc/hadoop/slaves"
    yarn_site_file = hadoop_home + "/etc/hadoop/yarn-site.xml"
    hadoop = RunHadoop(hadoop_home, input_file, slave_file, yarn_site_file)
    hadoop.run_setup()
    start_hadoop_file = hadoop_home + "/sbin/start-yarn.sh"
    hadoop.start_hadoop(start_hadoop_file)

    # Run Postgres
    postgres_home = os.environ["RUN_POSTGRES"]
    postgres_image_file = postgres_home + "/postgres_latest.sif"
    pgdata_file = postgres_home + "/pgdata"
    pgrun_file = postgres_home + "/pgrun"
    postgres = RunPostgres()
    postgres.start_postgres_instance(postgres_image_file, pgdata_file, pgrun_file)
    env_file = postgres_home + "/pg.env"
    postgres.run_postgres(env_file)
