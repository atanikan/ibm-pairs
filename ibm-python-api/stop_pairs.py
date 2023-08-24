from create_environment import CreateEnvironment
from run_hbase import RunHbase
from run_hadoop import RunHadoop
from run_postgres import RunPostgres
from run_rabbitmq import Runrabbitmq
import subprocess
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
    postgres_home = os.environ["RUN_POSTGRES"]
    env_file = postgres_home + "/pg.env"
    postgres = RunPostgres(input_file, env_file)    
    postgres.stop_postgres_instance()

    # Stop rabbitmq
    rabbitmq_home = os.environ["RUN_RABBITMQ"]
    env_file = rabbitmq_home + "/mq.env"
    rabbitmq = Runrabbitmq(input_file, env_file)    
    rabbitmq.stop_rabbitmq_instance()    

    # Stop Pairs Core
    pairs_core = os.environ["PARIS_CORE_HOME"]
    stop_pairs_var = f'bash {pairs_core}/shutdown.sh'
    try:
        output = subprocess.check_output(stop_pairs_var, stderr=subprocess.STDOUT)
        print(output)
    except subprocess.CalledProcessError as e:
        print(f"Command failed with error: {e.output}")