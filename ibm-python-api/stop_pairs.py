from create_environment import CreateEnvironment
from run_hbase import RunHbase
from run_hadoop import RunHadoop
from run_postgres import RunPostgres
import os

if __name__ == "__main__":

    input_file = os.environ["PBS_NODEFILE"]
    
    # Stop Hbase
    hbase_home = os.environ["HBASE_HOME"]
    worker_file = hbase_home + "/conf/regionservers"
    hbase_site_file = hbase_home + "/conf/hbase-site.xml"
    hbase = RunHbase(hbase_home, input_file, worker_file, hbase_site_file)
    stop_hbase_file = hbase_home + "/bin/stop-hbase.sh"
    hbase.stop_hbase(stop_hbase_file)

    # Stop Hadoop
    hadoop_home = os.environ["HADOOP_HOME"] 
    slave_file = hadoop_home + "/etc/hadoop/slaves"
    yarn_site_file = hadoop_home + "/etc/hadoop/yarn-site.xml"
    hadoop = RunHadoop(hadoop_home, input_file, slave_file, yarn_site_file)
    stop_hadoop_file = hadoop_home + "/sbin/stop-yarn.sh"
    hadoop.stop_hadoop(stop_hadoop_file)

    # Stop postgres
    postgres = RunPostgres()
    postgres.stop_postgres_instance()

