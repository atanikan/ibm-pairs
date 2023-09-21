import subprocess
import os
import re

class Runpairscore:
    def __init__(self, postgres_host, rabbitmq_host, pairs_core_host):
        self.postgres_host = postgres_host
        self.rabbitmq_host = rabbitmq_host
        self.pairs_core_host = pairs_core_host
    
    def replace_postgres_host(self, pairs_core_env_file):
        """ Replace postgreshost in $PAIRS_CORE_HOME/setenv.sh"""
        with open(pairs_core_env_file, 'r') as f:
            content = f.read()
        print("Before changing setenv.sh", content)
        updated_content = re.sub(r'(?<=-Dpostgreshost=)[^\s"]*', self.postgres_host, content)
        print("After changing setenv.sh", updated_content)
        # Write the modified content back to the path
        with open(os.path.expanduser(pairs_core_env_file), 'w') as f:
            f.write(updated_content)

    def replace_rabbitmq_host(self, pairs_core_config_file):
        """ Replace rabbit mq host in pairs_data/etc/pairs.config """
        with open(pairs_core_config_file, 'r') as f:
            content = f.read()
        # Check if the server line exists
        print("Before changing pairs.config", content)
        # if re.search(r'pairs.config.vs.status.queue.server=([^\s]+)', content):
        #     content = re.sub(r'pairs.config.vs.status.queue.server=([^\s]+)', f'pairs.config.vs.status.queue.server={self.rabbitmq_host}', content)
        updated_content = re.sub(r'(?<=pairs\.config\.vs\.status\.queue\.server=).*', self.rabbitmq_host, content)
        print("After changing pairs.config", updated_content)
        # Write the modified content back to the path
        with open(os.path.expanduser(pairs_core_config_file), 'w') as f:
            f.write(updated_content)
    
    def replace_netrc(self):
        """ write to netrc"""
        # Create or open the .netrc file and write the content
        # Get the home directory path
        home_dir = os.path.expanduser("~")
        # Construct the .netrc file path
        netrc_path = os.path.join(home_dir, ".netrc")
        with open(netrc_path, 'w') as file:
            file.write(f"machine {self.pairs_core_host}\n")
            file.write("login admin\n")
            file.write("password r/chVszxwX1gXB4o\n")
        print(f"Written to {netrc_path}")

    
    def start_pairs(self, start_pairs_file) -> None:
        """ Starts pairs core
        """
        print("Starting pairs core", start_pairs_file)
        subprocess.run([start_pairs_file], shell=True)
    
    @staticmethod
    def stop_pairs(stop_pairs_file) -> None:
        """ Stops pairs core
        """
        print("Stopping pairs core", stop_pairs_file)
        subprocess.run([stop_pairs_file], shell=True) 

# # Run Pairs Core
# # Create Pairs environment
# input_file = os.environ["PBS_NODEFILE"]
# with open(input_file, "r") as f:
#     hostnames = [line.strip() for line in f]
# if len(hostnames) == 1: #If only one node adding same node to the list
#     hostnames.append(hostnames[0])
# postgres_host = hostnames[0]
# rabbitmq_host = hostnames[1]
# pairs_core_root = os.environ["RUN_PAIRS_CORE"]
# pairs_core_home = os.environ["PAIRS_CORE_HOME"]
# pairs_core_host = hostnames[0]
# pairs_core = Runpairscore(postgres_host, rabbitmq_host, pairs_core_host)
# pairs_core.replace_postgres_host(pairs_core_home + "/setenv.sh")
# pairs_core.replace_rabbitmq_host(pairs_core_root + "/etc/pairs.config")
# pairs_core.replace_netrc()
# #pairs_core.start_pairs(pairs_core_home + "/startup.sh")