import os
import subprocess
import re

# Define the content to add
ENVIRONMENT_VAR = '''
# IBM_PAIRS_HOME
export SQL_PAIRS_HOME=/grand/IBM-GSS/atanikanti/ibm-pairs
export IBM_PAIRS_HOME=/grand/IBM-GSS/lustredata

# JAVA
export JAVA_HOME=$IBM_PAIRS_HOME/jdk1.8.0_371
export PATH=$PATH:$JAVA_HOME/bin
export _JAVA_OPTIONS="-Djava.io.tmpdir=$IBM_PAIRS_HOME/java/tmp    -XX:-UsePerfData"

# HBASE
export RUN_HBASE=$IBM_PAIRS_HOME
export HBASE_HOME=$RUN_HBASE/hbase
export PATH=$PATH:$HBASE_HOME/bin

# HADOOP
export RUN_HADOOP=$IBM_PAIRS_HOME
export HADOOP_HOME=$RUN_HADOOP/hadoop
export PATH=$PATH:$HADOOP_HOME/bin

# POSTGRES
export RUN_POSTGRES=$IBM_PAIRS_HOME/run_postgres
export POSTGRES_HOME=$RUN_POSTGRES/PostgreSQL
export PATH=$PATH:$POSTGRES_HOME/bin

# RABBITMQ
export RUN_RABBITMQ=$IBM_PAIRS_HOME/run_rabbitmq

# PROXY
export HTTP_PROXY="http://proxy-01.pub.alcf.anl.gov:3128"
export HTTPS_PROXY="http://proxy-01.pub.alcf.anl.gov:3128"
export http_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export https_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export ftp_proxy="http://proxy-01.pub.alcf.anl.gov:3128"
export no_proxy="admin,polaris-adminvm-01,localhost,*.cm.polaris.alcf.anl.gov,polaris-*,*.polaris.alcf.anl.gov,*.alcf.anl.gov"'''


class CreateEnvironment:
    def __init__(self,input_file) -> None:
        self.user_profile_path = None
        self.user_profile_content = None
        self.input_file = input_file
    
    def fetchUserProfileFile(self) -> None:
        # Determine the shell profile file based on the user's shell
        shell = os.environ.get("SHELL", "")
        if "bash" in shell:
            profile_file = ".bashrc"
        elif "zsh" in shell:
            profile_file = ".zshrc"
        elif "tcsh" in shell:
            profile_file = ".tcshrc" 
        else:
            print("Unsupported shell profile")
            exit(1)
        self.user_profile_path = os.path.join(os.path.expanduser("~"), profile_file) 
        return self.user_profile_path

    def readUserProfileFile(self) -> None:
        """
            Reads user profile file
        """
        with open(self.user_profile_path , "r") as file:
            self.user_profile_content = file.read()
    
    def writeToProfile(self) -> bool:
        # Check if the content already exists in profile
        if ENVIRONMENT_VAR in self.user_profile_content:
            print(f"Environment variables already exists in {self.user_profile_path}")
            return False
        else:
            # Append the content to profile
            with open(self.user_profile_path, "a") as file:
                file.write("\n" + ENVIRONMENT_VAR)
            print(f"Environment variables added to {self.user_profile_path}")
            return True
    
    def load_modules(self) -> None:
        """ Load required modules
        """
        print("here")
        subprocess.run('module load singularity', shell=True)

    def run_setup(self) -> None:
        """ Creates environment variables needed for running hbase, hadoop
        """
        self.fetchUserProfileFile()
        self.readUserProfileFile()
        self.writeToProfile()
        self.load_modules()
    
    def execute(self) -> None:
        os.system(f"source {self.user_profile_path}")
        
    def replace_hidden_files_hostnames(self) -> None:
        """ Replace Psql password """
        variables = {}
        with open(self.input_file, "r") as f:
            hostname = f.readline().strip()
        with open(os.path.expanduser('~/.netrc'), 'r') as f:
            content = f.read()
        # Check if the POSTGRESHOST line exists
        if re.search(r'machine ([^\s]+)', content):
            content = re.sub(r'machine ([^\s]+)', f'machine {hostname}', content)
        print(content)
        #Write the modified content back to the bashrc file
        with open(os.path.expanduser('~/.netrc'), 'w') as f:
             f.write(content)



