import subprocess
import os
import re
import time

# POSTGRES_RUN_VAR = f'''module load singularity
# singularity instance start -B {os.environ["RUN_POSTGRES"]}/pgdata:/var/lib/postgresql/data -B {os.environ["RUN_POSTGRES"]}/pgrun:/var/run/postgresql {os.environ["RUN_POSTGRES"]}/postgres_latest.sif postgres
# singularity run --env-file pg.env instance://postgres &
# '''

class RunPostgres:
    def __init__(self, env_file, postgres_host):
        self.env_file = env_file
        self.postgres_host = postgres_host

    def start_postgres_instance(self, postgres_image_file, pgdata_file, pgrun_file):
        """ Start postgres using singularity
        """
        start_postgres_instance_var = f'singularity instance start -B {pgdata_file}:/var/lib/postgresql/data -B {pgrun_file}:/var/run/postgresql {postgres_image_file} postgres'
        print("Starting", start_postgres_instance_var)
        subprocess.run([start_postgres_instance_var], shell=True)

    def run_postgres(self):
        """ Run postgres """
        run_postgres_instance_var = f'singularity run --env-file {self.env_file} instance://postgres &'
        print("Running", run_postgres_instance_var)
        subprocess.run([run_postgres_instance_var], shell=True)

    @staticmethod
    def stop_postgres_instance():
        """ Stop postgres """
        subprocess.run(["singularity instance stop postgres"], shell=True)
    
    def add_pg_pass(self):
        """ Add pgpass file """
        variables = {}
        with open(self.env_file, 'r') as f:
            for line in f:
                name, var = line.partition("=")[::2]
                name = re.sub('export ', '', name)  # remove 'export ' from the name
                variables[name] = var.strip()  # remove any leading/trailing whitespaces
        # format the string
        postgres_port = variables.get('POSTGRES_PORT')
        postgres_db = variables.get('POSTGRES_DB')
        postgres_user = variables.get('POSTGRES_USER')
        postgres_password = variables.get('POSTGRES_PASSWORD')
        pgpass_str = '{}:{}:{}:{}:{}'.format(self.postgres_host, postgres_port,postgres_db, postgres_user, postgres_password)
        # write to .pgpass
        with open(os.path.expanduser('~/.pgpass'), 'w') as f:
            f.write(pgpass_str)

#Run Postgres
# input_file = os.environ["PBS_NODEFILE"]
# with open(input_file, "r") as f:
#     hostnames = [line.strip() for line in f]
# if len(hostnames) == 1: #If only one node adding same node to the list
#     hostnames.append(hostnames[0])
# postgres_home = os.environ["RUN_POSTGRES"]
# postgres_image_file = postgres_home + "/postgres_latest.sif"
# pgdata_file = postgres_home + "/pgdata"
# pgrun_file = postgres_home + "/pgrun"
# env_file = postgres_home + "/pg.env"
# postgres_host = hostnames[0]
# postgres = RunPostgres(env_file, postgres_host)
# postgres.start_postgres_instance(postgres_image_file, pgdata_file, pgrun_file)
# postgres.run_postgres()
# print(f"Started postgres on {postgres_host}")
# postgres.add_pg_pass()
# os.environ['POSTGRESHOST'] = postgres_host
# RunPostgres.stop_postgres_instance()
