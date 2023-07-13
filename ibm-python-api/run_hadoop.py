import subprocess
import os

class RunHadoop:
    def __init__(self, hadoop_home, input_file, worker_file, yarn_site_file):
        self.hadoop_home = hadoop_home
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
                worker_nodes = content[1:2]
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

    def start_hadoop(self, start_hadoop_file) -> None:
        """ Starts hbase
        """
        print("Starting hadoop/yarn", start_hadoop_file)
        subprocess.run([start_hadoop_file], shell=True)
    
    def stop_hadoop(self, stop_hadoop_file) -> None:
        """ Stops hbase
        """
        print("Stopping hadoop/yarn", stop_hadoop_file)
        subprocess.run([stop_hadoop_file], shell=True)

    def run_setup(self) -> None:
        """ Runs Hbase
        """
        self.get_master_ip()
        self.write_worker_ips()
        self.replace_config_values()


