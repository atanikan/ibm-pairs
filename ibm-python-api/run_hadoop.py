import subprocess
import os

class RunHadoop:
    def __init__(self, hadoop_home, worker_file, yarn_site_file, hadoop_master, hadoop_workers):
        self.hadoop_home = hadoop_home
        self.worker_file = worker_file
        self.yarn_site_file = yarn_site_file
        self.hadoop_master = hadoop_master
        self.hadoop_workers = hadoop_workers

    def _write_worker_hostnames(self) -> None:
        """ Writes hostnames to worker file
        """
        with open(self.worker_file, "w") as f:
            for node in self.hadoop_workers:
                ip = node.strip()
                print("Worker node hostname:", ip)
                f.write(ip + "\n")

    def _replace_config_values(self) -> None:
        """ Replaces values in yarn-site.xml
        """
        with open(self.yarn_site_file, "r") as f:
            lines = f.readlines()
        replacements = {
            "<name>yarn.resourcemanager.hostname</name>": "<value>"+self.hadoop_master+"</value>"
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
        """ Starts hadoop
        """
        print("Starting hadoop/yarn", start_hadoop_file)
        subprocess.run([start_hadoop_file], shell=True)
    
    def run_setup(self) -> None:
        """ Runs hadoop
        """
        self._write_worker_hostnames()
        self._replace_config_values()

    @staticmethod
    def stop_hadoop(stop_hadoop_file) -> None:
        """ Stops hadoop
        """
        print("Stopping hadoop/yarn", stop_hadoop_file)
        subprocess.run([stop_hadoop_file], shell=True)



