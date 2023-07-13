i## PostgreSQL
PostgreSQL also known as Postgres, is a free and open-source relational database management system (RDBMS) emphasizing extensibility and SQL compliance.

### How to use Postgres on Polaris
1. Pull container from docker
```bash
singularity pull --name postgres.simg docker://postgres
```

2. Now create an environment file
```bash
cat >> pg.env <<EOF
export POSTGRES_USER=pguser
export POSTGRES_PASSWORD=mypguser123
export POSTGRES_DB=mydb
export POSTGRES_INITDB_ARGS="--encoding=UTF-8"
EOF
```

3. Create a data and run directory to bind to the running container
```bash
mkdir pgdata
mkdir pgrun
```

4. Start an instance of the container
```bash
singularity instance start -B pgdata:/var/lib/postgresql/data -B pgrun:/var/run/postgresql postgres.simg postgres
```

5. Run the container
```bash
singularity run --env-file pg.env instance://postgres &
```

6. To run a sample code to connect to POSTGRES. You can refer to the [postgres_test.py](postgres/postgres_test.py) file
```bash
>module load conda
>conda activate base #do this once
>python3 -m venv ~/envs/postgres_env # do this once
>source ~/envs/postgres_env/bin/activate
>pip install -r $PWD/requirements.txt
>python3 $PWD/postgres_test.py
```

7. When done, stop the postgres container instance.

```bash
singularity instance stop postgres
```
