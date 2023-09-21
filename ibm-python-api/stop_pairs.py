from create_environment import CreateEnvironment
from run_hbase import RunHbase
from run_hadoop import RunHadoop
from run_postgres import RunPostgres
from run_rabbitmq import Runrabbitmq
from run_pairs_core import Runpairscore
import subprocess
import os

if __name__ == "__main__":

    input_file = os.environ["PBS_NODEFILE"]
    with open(input_file, "r") as f:
        hostnames = [line.strip() for line in f]
    if len(hostnames) == 1: #If only one node adding same node to the list
        hostnames.append(hostnames[0])
    
    # Stop Hbase
    hbase_home = os.environ["HBASE_HOME"]
    stop_hbase_file = hbase_home + "/bin/stop-hbase.sh"
    RunHbase.stop_hbase(stop_hbase_file)

    # Stop Hadoop
    hadoop_home = os.environ["HADOOP_HOME"] 
    stop_hadoop_file = hadoop_home + "/sbin/stop-yarn.sh"
    RunHadoop.stop_hadoop(stop_hadoop_file)

    # Stop postgres
    RunPostgres.stop_postgres_instance()

    # Stop rabbitmq
    rabbitmq_host = hostnames[1]
    Runrabbitmq.stop_rabbitmq_instance(rabbitmq_host)    

    # Stop Pairs Core
    pairs_core_home = os.environ["PAIRS_CORE_HOME"]
    stop_pairs_var = f'{pairs_core_home}/shutdown.sh'
    pairs_core = Runpairscore.stop_pairs(stop_pairs_var)