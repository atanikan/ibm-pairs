#!/bin/bash -l
# UG Section 2.5, page UG-24 Job Submission Options
# Add another # at the beginning of the line to comment out a line
# NOTE: adding a switch to the command line will override values in this file.

# These options are MANDATORY at ALCF; Your qsub will fail if you don't provide them.
#PBS -A IBM-GSS
#PBS -l walltime=00:60:00
#file systems used by the job
#PBS -l filesystems=home:grand


# Highly recommended
# The first 15 characters of the job name are displayed in the qstat output:
#PBS -N GSS-ANSIBLE-TEST

# If you need a queue other than the default, which is prod (uncomment to use)
#PBS -q debug

# Controlling the output of your application
# UG Sec 3.3 page UG-42 Managing Output and Error Files
# By default, PBS spools your output on the compute node and then uses scp to move it the
# destination directory after the job finishes.  Since we have globally mounted file systems
# it is highly recommended that you use the -k option to write directly to the destination
# the doe stands for direct, output, error
#PBS -k doe
##PBS -o <path for stdout>
##PBS -e <path for stderr>

# If you want to merge stdout and stderr, use the -j option
# oe=merge stdout/stderr to stdout, eo=merge stderr/stdout to stderr, n=don't merge
#PBS -j n

# Controlling email notifications
# UG Sec 2.5.1, page UG-25 Specifying Email Notification
# When to send email b=job begin, e=job end, a=job abort, j=subjobs (job arrays), n=no mail
#PBS -m be
# Be default, mail goes to the submitter, use this option to add others (uncomment to use)
##PBS -M <email addresses>

# Setting job dependencies
# UG Section 6.2, page UG-109 Using Job Dependencies
# There are many options for how to set up dependencies;  afterok will give behavior similar
# to Cobalt (uncomment to use)
##PBS depend=afterok:<jobid>:<jobid>

# Environment variables (uncomment to use)
# UG Section 6.12, page UG-126 Using Environment Variables
# RG Sect 2.57.7, page RG-233 Environment variables PBS puts in the job environment
##PBS -v <variable list>
## -v a=10, "var2='A,B'", c=20, HOME=/home/zzz
##PBS -V exports all the environment variables in your environment to the compute node


# The rest is an example of how an MPI job might be set up
echo Working directory is $PBS_O_WORKDIR
cd $PBS_O_WORKDIR

echo Jobid: $PBS_JOBID
echo Running on host `hostname`
echo Running on nodes `cat $PBS_NODEFILE`

NNODES=`wc -l < $PBS_NODEFILE`
NRANKS=1           # Number of MPI ranks per node
NDEPTH=1           # Number of hardware threads per rank, spacing between MPI ranks on a node
NTHREADS=1         # Number of OMP threads per rank, given to OMP_NUM_THREADS

NTOTRANKS=$(( NNODES * NRANKS ))

echo "NUM_OF_NODES=${NNODES}  TOTAL_NUM_RANKS=${NTOTRANKS}  RANKS_PER_NODE=${NRANKS}  THREADS_PER_RANK=${NTHREADS}"
module load conda
conda activate base
sleep 3600
