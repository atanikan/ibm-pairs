import subprocess
import os
import time

class Runrabbitmq:
    def __init__(self, env_file, rabbitmq_host):
        self.env_file = env_file
        self.rabbitmq_host = rabbitmq_host

    def start_rabbitmq_instance(self, rabbit_image_file, rabbit_dir):
        """ Start rabbitmq using singularity
        """
        # start_and_run_rabbit_instance = f'module load singularity &&\
        #     singularity instance start -B {rabbit_dir}:/var/lib/rabbitmq {rabbit_image_file} rabbitmq &&\
        #     singularity run --env-file {self.env_file} instance://rabbitmq & &&\
        #         exit'
        start_instance = f'module load singularity && singularity instance start -B {rabbit_dir}:/var/lib/rabbitmq {rabbit_image_file} rabbitmq'
        start_rabbit_instance_var = ['ssh', self.rabbitmq_host,
                                             start_instance]
        print("Starting Instance", start_rabbit_instance_var)
        try:
            output = subprocess.Popen(start_rabbit_instance_var)
            print(output)
        except subprocess.CalledProcessError as e:
            print(f"Command failed with error: {e.output}")
        # print("Running Instance", run_var)
        # subprocess.Popen(run_var)

    def run_rabbitmq_instance(self):
        """ Run rabbitmq using singularity
        """
        run_instance = f'module load singularity && singularity run --env-file {self.env_file} instance://rabbitmq &'
        # run_var = ['ssh',self.rabbitmq_host,]
        # start_and_run_rabbit_instance = f'module load singularity &&\
        #     singularity instance start -B {rabbit_dir}:/var/lib/rabbitmq {rabbit_image_file} rabbitmq &&\
        #     singularity run --env-file {self.env_file} instance://rabbitmq & &&\
        #         exit'
        # test_instance = f'module load singularity && singularity instance start -B {rabbit_dir}:/var/lib/rabbitmq {rabbit_image_file} rabbitmq'
        run_rabbit_instance_var = ['ssh', self.rabbitmq_host,
                                             run_instance]
        print("Running Instance", run_rabbit_instance_var)
        try:
            output = subprocess.Popen(run_rabbit_instance_var)
            # output = subprocess.check_output(start_and_run_rabbit_instance_var, stderr=subprocess.STDOUT)
            print(output)
        except subprocess.CalledProcessError as e:
            print(f"Command failed with error: {e.output}")

    @staticmethod
    def stop_rabbitmq_instance(rabbitmq_host):
        """ Stop rabbitmq """
        stop_var = ['ssh', rabbitmq_host,f'module load singularity && singularity instance stop rabbitmq']
        try:
            output = subprocess.check_output(stop_var, stderr=subprocess.STDOUT)
            print(output)
            return output
        except subprocess.CalledProcessError as e:
            print(f"Command failed with error: {e.output}")
        return None

#Run rabbitmq
 # # Create Pairs environment
# input_file = os.environ["PBS_NODEFILE"]
# with open(input_file, "r") as f:
#     hostnames = [line.strip() for line in f]
# if len(hostnames) == 1: #If only one node adding same node to the list
#     hostnames.append(hostnames[0])
# # Run rabbitmq
# rabbitmq_home = os.environ["RUN_RABBITMQ"]
# rabbitmq_image_file = rabbitmq_home + "/rabbitmq_latest.sif"
# rabbitmq_dir = rabbitmq_home + "/rabbitmq"
# env_file = rabbitmq_home + "/mq.env"
# rabbitmq_host = hostnames[1]
# rabbitmq = Runrabbitmq(env_file, rabbitmq_host)
# rabbitmq.start_rabbitmq_instance(rabbitmq_image_file,rabbitmq_dir)
# print(f"Started rabbitmq on {rabbitmq_host}")
# time.sleep(3)
# rabbitmq.run_rabbitmq_instance()
# print(f"Running rabbitmq on {rabbitmq_host}")
# os.environ['RABBITMQHOST'] = rabbitmq_host
# time.sleep(10)
# Runrabbitmq.stop_rabbitmq_instance(rabbitmq_host)



# input_file = os.environ["PBS_NODEFILE"]
# rabbitmq_home = os.environ["RUN_RABBITMQ"]
# rabbitmq_image_file = rabbitmq_home + "/rabbitmq_latest.sif"
# rabbitmq_dir = rabbitmq_home + "/rabbitmq"
# env_file = rabbitmq_home + "/mq.env"
# rabbitmq = Runrabbitmq(input_file, env_file)
# rabbitmq.start_and_run_rabbitmq_instance(rabbitmq_image_file,rabbitmq_dir)
# #rabbitmq.stop_rabbitmq_instance()