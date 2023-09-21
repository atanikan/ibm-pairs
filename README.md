# IBM PAIRS PORTAL

This repostory outlines steps to run IBM Pairs on Polaris supercomputer at ALCF.

## Requirements to run on Polaris

* Install JDK 1.8
* Install Hbase 2.4.16
* Install Hadoop 2.7.2
* [Load singularity and run Postgres container](run_postgres/README.md) 
* Load singularity and run Rabbitmq
* Clone this repository


## Run Pairs core in interactive mode

* Run a job submission script or fetch atleast 2 nodes in interactive mode

```bash
qsub -I -A IBM-GSS -q debug-scaling -l select=4 -l walltime=01:00:00 -l filesystems=home:grand -l singularity_fakeroot=true
```

* Add the following to your bashrc profile and source it `source ~/.bashrc`

```bash
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
#alias pairs_sql='psql -h x3005c0s31b0n0.hsn.cm.polaris.alcf.anl.gov -d pairs -U pairs_db_master' ##useful to query postgres

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
```

* Load singularity module 
```bash
module load singularity
```

* Run [start_pairs.py](ibm-python-api/start_pairs.py) to start all services
```bash
cd ibm-pairs/ibm-python-api
python3 start_pairs.py
```

* Upload data
```bash
$ cat dataset.post
{
 "name": "new modis upload test",
 "description_short" : "modis uploads tiles from jan 1, 2022",
 "description_long" : "uploading some tiles from jan 1, 2022",
 "category": {
   "id": "5"
 },
 "level": "18",
 "crs" : "EPSG:4326"
}
$ curl -vv -H "Content-Type:application/json" -n -d @dataset.post http://localhost:8080/v2/datasets
```

* Query the uploaded data
```bash
curl -u "admin:r/chVszxwX1gXB4o" 'http://localhost:8080/v2/datasets'
```

* Run `stop_pairs.py` to stop all services
```bash
cd ibm-pairs/ibm-python-api
python3 stop_pairs.py
```

## Run Pairs core in batch mode

* To run pairs core in batch mode. Simply run [`qsub job_subission.sh`](ibm-python-api/job_submission.sh)


