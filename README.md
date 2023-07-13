# IBM PAIRS PORTAL

## Requirements to run on Polaris

* Install JDK 1.8
* Install Hbase 2.4.16
* Install Hadoop 2.7.2
* [Load singularity and run Postgres container](run_postgres/README.md) 
* Load python3


## Steps to run on Polaris

* Clone this repository
* Modify the [ibm-python-api/create_environment.py](ibm-python-api/create_environment.py) file and ensure the `ENVIRONMENT_VAR` is set correctly to the installation locations of java, hbase, hadoop and postgres.

```bash
ENVIRONMENT_VAR = '''
#IBM_PAIRS_HOME
export IBM_PAIRS_HOME=/grand/IBM-GSS/atanikanti/ibm-pairs

# JAVA
export JAVA_HOME=$IBM_PAIRS_HOME/jdk1.8.0_371
export PATH=$PATH:$JAVA_HOME/bin
export _JAVA_OPTIONS="-Djava.io.tmpdir=$IBM_PAIRS_HOME/java/tmp\
    -XX:-UsePerfData"

# HBASE
export RUN_HBASE=$IBM_PAIRS_HOME/run_hbase
export HBASE_HOME=$RUN_HBASE/hbase
export PATH=$PATH:$HBASE_HOME/bin

# HADOOP
export RUN_HADOOP=$IBM_PAIRS_HOME/run_hadoop
export HADOOP_HOME=$RUN_HADOOP/hadoop
export PATH=$PATH:$HADOOP_HOME/bin

# POSTGRES
export RUN_POSTGRES=$IBM_PAIRS_HOME/run_postgres

# PROXY
export HTTP_PROXY="http://proxy-01.pub.alcf.anl.gov:3128"
export HTTPS_PROXY="http://proxy-01.pub.alcf.anl.gov:3128"
export http_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export https_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export ftp_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export no_proxy="admin,polaris-adminvm-01,localhost,*.cm.polaris.alcf.anl.gov,polaris-*,*.polaris.alcf.anl.gov,*.alcf.anl.gov"'''
```

* Run a job submission script or fetch atleast 4 nodes in interactive mode

```bash
qsub -I -A datascience -q preemptable -l select=4 -l walltime=02:00:00 -l filesystems=home:grand -l singularity_fakeroot=true
```

* Run `start_pairs.py` to start all services
```bash
python3 ibm-python-api/start_pairs.py
```

* Run `stop_pairs.py` to stop all services
```bash
python3 ibm-python-api/stop_pairs.py
```