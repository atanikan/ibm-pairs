import subprocess
import os
import re
from create_environment import CreateEnvironment

# POSTGRES_RUN_VAR = f'''module load singularity
# singularity instance start -B {os.environ["RUN_POSTGRES"]}/pgdata:/var/lib/postgresql/data -B {os.environ["RUN_POSTGRES"]}/pgrun:/var/run/postgresql {os.environ["RUN_POSTGRES"]}/postgres_latest.sif postgres
# singularity run --env-file pg.env instance://postgres &
# '''

class RunPostgres:
    def __init__(self, input_file, env_file):
        self.input_file = input_file
        self.env_file = env_file

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

    def stop_postgres_instance(self):
        """ Stop postgres """
        subprocess.run(["singularity instance stop postgres"], shell=True)
    
    def replace_psql_password(self):
        """ Replace Psql password """
        variables = {}
        with open(self.env_file, 'r') as f:
            for line in f:
                name, var = line.partition("=")[::2]
                name = re.sub('export ', '', name)  # remove 'export ' from the name
                variables[name] = var.strip()  # remove any leading/trailing whitespaces
        # format the string
        with open(self.input_file, "r") as f:
            hostname = f.readline().strip()
        postgres_port = variables.get('POSTGRES_PORT')
        postgres_db = variables.get('POSTGRES_DB')
        postgres_user = variables.get('POSTGRES_USER')
        postgres_password = variables.get('POSTGRES_PASSWORD')
        pgpass_str = '{}:{}:{}:{}:{}'.format(hostname, postgres_port,postgres_db, postgres_user, postgres_password)
        # write to .pgpass
        with open(os.path.expanduser('~/.pgpass'), 'w') as f:
            f.write(pgpass_str)
        create_env = CreateEnvironment(self.input_file)
        user_profile_file = create_env.fetchUserProfileFile()
        with open(user_profile_file, 'r') as f:
            content = f.read()
        # Check if the POSTGRESHOST line exists
        if re.search(r'export POSTGRESHOST=([^\s]+)', content):
            content = re.sub(r'export POSTGRESHOST=([^\s]+)', f'export POSTGRESHOST={hostname}', content)
        # Check if the pairs_sql alias line exists
        if re.search(r"alias pairs_sql='psql -h ([^\s]+) -d pairs -U pairs_db_master'", content):
            content = re.sub(r"alias pairs_sql='psql -h ([^\s]+) -d pairs -U pairs_db_master'", f"alias pairs_sql='psql -h {hostname} -d pairs -U pairs_db_master'", content)
        print(content)
        #Write the modified content back to the bashrc file
        with open(user_profile_file, 'w') as f:
             f.write(content)
        print("SOURCE YOUR BASHRC/PROFILE")


#Run Postgres
input_file = os.environ["PBS_NODEFILE"]
postgres_home = os.environ["RUN_POSTGRES"]
postgres_image_file = postgres_home + "/postgres_latest.sif"
pgdata_file = postgres_home + "/pgdata"
pgrun_file = postgres_home + "/pgrun"
env_file = postgres_home + "/pg.env"
postgres = RunPostgres(input_file, env_file)
# postgres.start_postgres_instance(postgres_image_file, pgdata_file, pgrun_file)
# postgres.run_postgres()
postgres.replace_psql_password()