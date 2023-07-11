import subprocess
import os

class RunHadoop:
    def __init__(self, input_file, worker_file, yarn_site_file):
        self.input_file = input_file
        self.worker_file = worker_file
        self.yarn_site_file = yarn_site_file
        self.master_ip = None

    def get_master_ip(self) -> None:
        """ Fetches master node hostname from input file (PBS_NODEFILE)
        """
        with open(self.input_file, "r") as f:
            self.master_ip = f.readline().strip()
        print("Master node hostname:", self.master_ip)

    def write_worker_ips(self) -> None:
        """ Writes hostnames to worker file
        """
        with open(self.input_file, "r") as f:
            content = f.readlines()
            if len(content) > 1:
                worker_nodes = content[1:]
            else:
                worker_nodes = [content.strip()]
        with open(self.worker_file, "w") as f:
            for node in worker_nodes:
                ip = node.strip()
                print("Worker node hostname:", ip)
                f.write(ip + "\n")

    def replace_config_values(self) -> None:
        """ Replaces values in yarn-site.xml
        """
        with open(self.yarn_site_file, "r") as f:
            lines = f.readlines()
        replacements = {
            "<name>yarn.resourcemanager.hostname</name>": "<value>"+self.master_ip+"</value>"
        }
        for i, line in enumerate(lines):
            for config_name, new_value in replacements.items():
                if config_name in line:
                    next_line_number = i + 1
                    current_value = lines[next_line_number].strip()
                    print(f"{config_name} current: {current_value}")
                    lines[next_line_number] = lines[next_line_number].replace(current_value, new_value)
                    print(f"{config_name} new: {new_value}")
                    break
        with open(self.yarn_site_file, "w") as f:
            f.writelines(lines)

    def start_hadoop(self) -> None:
        """ Starts hbase
        """
        print("Starting hadoop/yarn", os.environ["HADOOP_HOME"] + "/sbin/start-hbase.sh")
        subprocess.run([os.environ["HADOOP_HOME"] + "/sbin/start-yarn.sh"], shell=True)
    
    def stop_hadoop(self) -> None:
        """ Stops hbase
        """
        print("Stopping hbase", os.environ["HADOOP_HOME"] + "/sbin/stop-yarn.sh")
        subprocess.run([os.environ["HADOOP_HOME"] + "/sbin/stop-yarn.sh"], shell=True)

    def run_setup(self) -> None:
        """ Runs Hbase
        """
        self.get_master_ip()
        self.write_worker_ips()
        self.replace_config_values()

# Usage
input_file = os.environ["PBS_NODEFILE"]
worker_file = os.environ["HADOOP_HOME"] + "/etc/hadoop/slaves"
yarn_site_file = os.environ["HADOOP_HOME"] + "/etc/hadoop/yarn-site.xml"

hadoop = RunHadoop(input_file, worker_file, yarn_site_file)
#hadoop.run_setup()
#hadoop.start_hadoop()
hadoop.stop_hadoop()