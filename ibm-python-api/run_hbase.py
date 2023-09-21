import subprocess
import os

class RunHbase:
    def __init__(self, hbase_home, worker_file, hbase_site_file, hbase_master, hbase_workers):
        self.hbase_home = hbase_home
        self.worker_file = worker_file
        self.hbase_site_file = hbase_site_file
        self.hbase_master = hbase_master
        self.hbase_workers = hbase_workers

    def _write_worker_hostnames(self) -> None:
        """ Writes hostnames to worker file
        """
        with open(self.worker_file, "w") as f:
            for node in self.hbase_workers:
                ip = node.strip()
                print("Worker node hostname", ip)
                f.write(ip + "\n")

    def _replace_config_values(self) -> None:
        """ Replaces values in hbase-site.xml
        """
        with open(self.hbase_site_file, "r") as f:
            lines = f.readlines()
        replacements = {
            "<name>hbase.rootdir</name>":  "<value>file://" + self.hbase_home + "/data</value>",
            "<name>hbase.zookeeper.property.dataDir</name>": "<value>" + self.hbase_home + "/zookeeper-data</value>",
            "<name>hbase.zookeeper.quorum</name>": "<value>" + self.hbase_master + "</value>",
            "<name>hbase.master.hostname</name>": "<value>" + self.hbase_master + "</value>"
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

    def start_hbase(self, start_hbase_file) -> None:
        """ Starts hbase
        """
        print("Starting hbase", start_hbase_file)
        subprocess.run([start_hbase_file], shell=True)

    def run_setup(self) -> None:
        """ Runs Hbase setup
        """
        self._write_worker_hostnames()
        self._replace_config_values()

    @staticmethod
    def stop_hbase(stop_hbase_file) -> None:
        """ Stops hbase
        """
        print("Stopping hbase", stop_hbase_file)
        subprocess.run([stop_hbase_file], shell=True)