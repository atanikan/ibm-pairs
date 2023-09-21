from run_hbase import RunHbase
from run_hadoop import RunHadoop
from run_postgres import RunPostgres
from run_rabbitmq import Runrabbitmq
from run_pairs_core import Runpairscore
import os
import time

PROMPT=''' First follow 3 steps:
1. Run 'module load singularity'
2. Ensure the following in your bashrc and 
****
# IBM_PAIRS_HOME
export IBM_PAIRS_HOME=/grand/IBM-GSS/lustredata

# JAVA
export JAVA_HOME=$IBM_PAIRS_HOME/jdk1.8.0_371
export PATH=$PATH:$JAVA_HOME/bin
export _JAVA_OPTIONS="-Djava.io.tmpdir=$IBM_PAIRS_HOME/java/tmp    -XX:-UsePerfData"

# HBASE
export RUN_HBASE=$IBM_PAIRS_HOME
export HBASE_HOME=$RUN_HBASE/hbase
export PATH=$PATH:$HBASE_HOME/bin

# HADOOP
export RUN_HADOOP=$IBM_PAIRS_HOME
export HADOOP_HOME=$RUN_HADOOP/hadoop
export PATH=$PATH:$HADOOP_HOME/bin

# POSTGRES
export RUN_POSTGRES=$IBM_PAIRS_HOME/run_postgres
export POSTGRES_HOME=$RUN_POSTGRES/PostgreSQL
export PATH=$PATH:$POSTGRES_HOME/bin
export POSTGRESHOST=x3206c0s37b0n0.hsn.cm.polaris.alcf.anl.gov #CHANGE IN PYTHON SCRIPT
alias pairs_sql='psql -h x3206c0s37b0n0.hsn.cm.polaris.alcf.anl.gov -d pairs -U pairs_db_master'

# RABBITMQ
export RUN_RABBITMQ=$IBM_PAIRS_HOME/run_rabbitmq

# PROXY
export HTTP_PROXY="http://proxy-01.pub.alcf.anl.gov:3128"
export HTTPS_PROXY="http://proxy-01.pub.alcf.anl.gov:3128"
export http_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export https_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export ftp_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export no_proxy="admin,polaris-adminvm-01,localhost,*.cm.polaris.alcf.anl.gov,polaris-*,*.polaris.alcf.anl.gov,*.alcf.anl.gov"
***
3. source ~/.bashrc
Type y(yes) if you have executed the above or n(no)?:
'''

if __name__ == "__main__":
    
    # # Create Pairs environment
    input_file = os.environ["PBS_NODEFILE"]
    with open(input_file, "r") as f:
        hostnames = [line.strip() for line in f]
    if len(hostnames) == 1: #If only one node adding same node to the list
        hostnames.append(hostnames[0])
    # response = input(PROMPT).strip().lower()
    # if "n" in response:
    #     print("Exiting as response has n: ",response)
    #     exit()
    # Run Hbase
    hbase_home = os.environ["HBASE_HOME"]
    worker_file = hbase_home + "/conf/regionservers"
    hbase_site_file = hbase_home + "/conf/hbase-site.xml"
    hbase_master = hostnames[0]
    hbase_workers = hostnames[1:]
    hbase = RunHbase(hbase_home, worker_file, hbase_site_file,hbase_master, hbase_workers)
    hbase.run_setup()
    start_hbase_file = hbase_home + "/bin/start-hbase.sh"
    hbase.start_hbase(start_hbase_file)
    time.sleep(3)
    print(f"Started hbase master on {hbase_master} and workers on {','.join(hbase_workers)}")

    # Run Hadoop
    hadoop_home = os.environ["HADOOP_HOME"] 
    slave_file = hadoop_home + "/etc/hadoop/slaves"
    yarn_site_file = hadoop_home + "/etc/hadoop/yarn-site.xml"
    hadoop_master = hostnames[0]
    hadoop_workers = hostnames[1:]
    hadoop = RunHadoop(hadoop_home, slave_file, yarn_site_file, hadoop_master, hadoop_workers)
    hadoop.run_setup()
    start_hadoop_file = hadoop_home + "/sbin/start-yarn.sh"
    hadoop.start_hadoop(start_hadoop_file)
    time.sleep(3)
    print(f"Started hadoop master on {hadoop_master} and workers on {','.join(hadoop_workers)}")


    # Run Postgres
    postgres_home = os.environ["RUN_POSTGRES"]
    postgres_image_file = postgres_home + "/postgres_latest.sif"
    pgdata_file = postgres_home + "/pgdata"
    pgrun_file = postgres_home + "/pgrun"
    env_file = postgres_home + "/pg.env"
    postgres_host = hostnames[0]
    postgres = RunPostgres(env_file, postgres_host)
    postgres.start_postgres_instance(postgres_image_file, pgdata_file, pgrun_file)
    postgres.run_postgres()
    print(f"Started postgres on {postgres_host}")
    postgres.add_pg_pass()
    os.environ['POSTGRESHOST'] = postgres_host

    rabbitmq_home = os.environ["RUN_RABBITMQ"]
    rabbitmq_image_file = rabbitmq_home + "/rabbitmq_latest.sif"
    rabbitmq_dir = rabbitmq_home + "/rabbitmq"
    env_file = rabbitmq_home + "/mq.env"
    rabbitmq_host = hostnames[1]
    rabbitmq = Runrabbitmq(env_file, rabbitmq_host)
    rabbitmq.start_rabbitmq_instance(rabbitmq_image_file,rabbitmq_dir)
    print(f"Started rabbitmq on {rabbitmq_host}")
    time.sleep(3)
    rabbitmq.run_rabbitmq_instance()
    print(f"Running rabbitmq on {rabbitmq_host}")
    os.environ['RABBITMQHOST'] = rabbitmq_host
    time.sleep(10)

    # # Run Pairs Core
    pairs_core_root = os.environ["RUN_PAIRS_CORE"]
    pairs_core_home = os.environ["PAIRS_CORE_HOME"]
    pairs_core_host = hostnames[0]
    pairs_core = Runpairscore(postgres_host, rabbitmq_host, pairs_core_host)
    pairs_core.replace_postgres_host(pairs_core_home + "/setenv.sh")
    pairs_core.replace_rabbitmq_host(pairs_core_root + "/etc/pairs.config")
    pairs_core.replace_netrc()
    pairs_core.start_pairs(pairs_core_home + "/startup.sh")
    time.sleep(20) 