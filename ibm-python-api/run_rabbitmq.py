import subprocess
import os
import re
from create_environment import CreateEnvironment

class Runrabbitmq:
    def __init__(self, input_file, env_file):
        self.input_file = input_file
        self.env_file = env_file
        with open(self.input_file, "r") as f:
            content = f.readlines()
            if len(content) > 1:
                rabbit_node = content[-1].strip()
            else:
                rabbit_node = content.strip()
        self.rabbit_hostname = rabbit_node
        print("RABBIT MQ HOSTNAME",self.rabbit_hostname)


    def start_and_run_rabbitmq_instance(self, rabbit_image_file, rabbit_dir):
        """ Start rabbitmq using singularity
        """
        start_and_run_rabbit_instance = f'module load singularity &&\
            singularity instance start -B {rabbit_dir}:/var/lib/rabbitmq {rabbit_image_file} rabbitmq &&\
            singularity run --env-file {self.env_file} instance://rabbitmq & &&\
                exit'
        test_instance = f'module load singularity && singularity instance start -B {rabbit_dir}:/var/lib/rabbitmq {rabbit_image_file} rabbitmq'
        start_and_run_rabbit_instance_var = ['ssh', self.rabbit_hostname,
                                             test_instance]
        run_var = ['ssh',self.rabbit_hostname,f'module load singularity && singularity run --env-file {self.env_file} instance://rabbitmq &']
        print("Starting Instance", start_and_run_rabbit_instance_var)
        try:
            output = subprocess.check_output(start_and_run_rabbit_instance_var, stderr=subprocess.STDOUT)
            print(output)
        except subprocess.CalledProcessError as e:
            print(f"Command failed with error: {e.output}")
        print("Running Instance", run_var)
        subprocess.Popen(run_var)
        return None


    def stop_rabbitmq_instance(self):
        """ Stop rabbitmq """
        run_var = ['ssh',self.rabbit_hostname,f'module load singularity && singularity instance stop rabbitmq']
        try:
            output = subprocess.check_output(run_var, stderr=subprocess.STDOUT)
            print(output)
            return output
        except subprocess.CalledProcessError as e:
            print(f"Command failed with error: {e.output}")
        return None

    def replace_rabbitmq_host(self):
        """ Replace Psql password """
        variables = {}
        # format the string
        create_env = CreateEnvironment(self.input_file)
        user_profile_file = create_env.fetchUserProfileFile()
        with open(user_profile_file, 'r') as f:
            content = f.read()
        # Check if the POSTGRESHOST line exists
        if re.search(r'export RABBITMQHOST=([^\s]+)', content):
            content = re.sub(r'export RABBITMQHOST=([^\s]+)', f'export RABBITMQHOST={self.rabbit_hostname}', content)
        #Write the modified content back to the bashrc file
        with open(user_profile_file, 'w') as f:
             f.write(content)
        print("SOURCE YOUR BASHRC/PROFILE")

#Run rabbitmq
# input_file = os.environ["PBS_NODEFILE"]
# rabbitmq_home = os.environ["RUN_RABBITMQ"]
# rabbitmq_image_file = rabbitmq_home + "/rabbitmq_latest.sif"
# rabbitmq_dir = rabbitmq_home + "/rabbitmq"
# env_file = rabbitmq_home + "/mq.env"
# rabbitmq = Runrabbitmq(input_file, env_file)
# rabbitmq.start_and_run_rabbitmq_instance(rabbitmq_image_file,rabbitmq_dir)
#rabbitmq.stop_rabbitmq_instance()