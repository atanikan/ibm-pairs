import subprocess
import os

POSTGRES_RUN_VAR = f'''module load singularity
singularity instance start -B {os.environ["RUN_POSTGRES"]}/pgdata:/var/lib/postgresql/data -B {os.environ["RUN_POSTGRES"]}/pgrun:/var/run/postgresql {os.environ["RUN_POSTGRES"]}/postgres_latest.sif postgres
singularity run --env-file pg.env instance://postgres &
'''


class RunPostgres:
    def __init__(self):
        pass

    def start_postgres_instance(self, postgres_image_file, pgdata_file, pgrun_file):
        """ Start postgres using singularity
        """
        start_postgres_instance_var = f'singularity instance start -B {pgdata_file}:/var/lib/postgresql/data -B {pgrun_file}:/var/run/postgresql {postgres_image_file} postgres'
        print("Starting", start_postgres_instance_var)
        subprocess.run([start_postgres_instance_var], shell=True)

    def run_postgres(self, env_file):
        """ Run postgres """
        run_postgres_instance_var = f'singularity run --env-file {env_file} instance://postgres &'
        print("Running", run_postgres_instance_var)
        subprocess.run([run_postgres_instance_var], shell=True)

    def stop_postgres_instance(self):
        """ Stop postgres """
        subprocess.run(["singularity instance stop postgres"], shell=True)