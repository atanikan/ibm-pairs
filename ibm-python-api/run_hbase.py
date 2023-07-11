import subprocess
import os

class RunHbase:
    def __init__(self, input_file, worker_file, hbase_site_file):
        self.input_file = input_file
        self.worker_file = worker_file
        self.hbase_site_file = hbase_site_file
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
                region_server_nodes = content[1:]
            else:
                region_server_nodes = [content.strip()]

        with open(self.worker_file, "w") as f:
            for node in region_server_nodes:
                ip = node.strip()
                print("Worker node hostname", ip)
                f.write(ip + "\n")

    def replace_config_values(self) -> None:
        """ Replaces values in hbase-site.xml
        """
        with open(self.hbase_site_file, "r") as f:
            lines = f.readlines()
        replacements = {
            "<name>hbase.rootdir</name>":  "<value>file://" + os.environ["HBASE_HOME"] + "/data</value>",
            "<name>hbase.zookeeper.property.dataDir</name>": "<value>" + os.environ["HBASE_HOME"] + "/zookeeper-data</value>",
            "<name>hbase.zookeeper.quorum</name>": "<value>" + self.master_ip + "</value>",
            "<name>hbase.master.hostname</name>": "<value>" + self.master_ip + "</value>"
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
        with open(self.hbase_site_file, "w") as f:
            f.writelines(lines)

    def start_hbase(self) -> None:
        """ Starts hbase
        """
        print("Starting hbase", os.environ["HBASE_HOME"] + "/bin/start-hbase.sh")
        subprocess.run([os.environ["HBASE_HOME"] + "/bin/start-hbase.sh"], shell=True)
    
    def stop_hbase(self) -> None:
        """ Stops hbase
        """
        print("Stopping hbase", os.environ["HBASE_HOME"] + "/bin/stop-hbase.sh")
        subprocess.run([os.environ["HBASE_HOME"] + "/bin/stop-hbase.sh"], shell=True)

    def run_setup(self) -> None:
        """ Runs Hbase
        """
        self.get_master_ip()
        self.write_worker_ips()
        self.replace_config_values()

# Usage
input_file = os.environ["PBS_NODEFILE"]
worker_file = os.environ["HBASE_HOME"] + "/conf/regionservers"
hbase_site_file = os.environ["HBASE_HOME"] + "/conf/hbase-site.xml"

hbase = RunHbase(input_file, worker_file, hbase_site_file)
#hbase.run_setup()
#hbase.start_hbase()
hbase.stop_hbase()