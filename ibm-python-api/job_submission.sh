#!/bin/sh
#PBS -l select=4:system=polaris
#PBS -q debug-scaling
#PBS -l place=scatter
#PBS -l walltime=00:60:00
#PBS -l filesystems=home:grand
#PBS -A IBM-GSS

cd ${PBS_O_WORKDIR}

# IBM_PAIRS_HOME
export SQL_PAIRS_HOME=/grand/IBM-GSS/atanikanti/ibm-pairs
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
#alias pairs_sql='psql -h x3005c0s31b0n0.hsn.cm.polaris.alcf.anl.gov -d pairs -U pairs_db_master'

# RABBITMQ
export RUN_RABBITMQ=$IBM_PAIRS_HOME/run_rabbitmq

# PAIRS CORE
export RUN_PAIRS_CORE=/grand/IBM-GSS/pairs_data/www
export PAIRS_CORE_HOME=$RUN_PAIRS_CORE/apache-tomcat-pairs-9.0.73/bin


# PROXY
export HTTP_PROXY="http://proxy-01.pub.alcf.anl.gov:3128"
export HTTPS_PROXY="http://proxy-01.pub.alcf.anl.gov:3128"
export http_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export https_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export ftp_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export no_proxy="admin,polaris-adminvm-01,localhost,*.cm.polaris.alcf.anl.gov,polaris-*,*.polaris.alcf.anl.gov,*.alcf.anl.gov"

# MODULE LOADS 
module load singularity
python3 start_pairs.py
curl -u "admin:r/chVszxwX1gXB4o" 'http://localhost:8080/v2/datasets'




