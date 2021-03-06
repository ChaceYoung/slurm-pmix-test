#!/bin/bash -lxeE

IMG_NAME=$1
COUNT=$2
BASE_DIR=`pwd`
AUX_DIR=$BASE_DIR/files
RUN_DIR=$BASE_DIR/rundir

rm -Rf $RUN_DIR
mkdir -p $RUN_DIR

if [ -z "$SLURM_HOST_PREFIX" ]; then
    echo "ERROR: Environment var SLURM_HOST_PREFIX wasn't found"
    exit 1
fi

# Setup host installation environment
# 1. Export our slurm.conf
export SLURM_CONF=$RUN_DIR/slurm.conf
export SBATCH=$SLURM_HOST_PREFIX/bin/sbatch
export SQUEUE=$SLURM_HOST_PREFIX/bin/squeue
export SCANCEL=$SLURM_HOST_PREFIX/bin/scancel

print_usage()
{
    echo "Usage:"
    echo "$0 <image-name> <nodes #>"
}

if [ -z "$IMG_NAME" ] || [ -z "$COUNT" ]; then
    echo "ERROR: Not enough arguments!"
    print_usage
    exit 1
fi

. ./run_lib.sh
init_run_lib "$AUX_DIR" "$RUN_DIR"

################################################################################
#
# Boot the virtual cluster
#
################################################################################


# Run frontend node first
rm -f $RUN_DIR/hosts
touch $RUN_DIR/hosts
run_machine $IMG_NAME "fe" 0 /slurmctl.sh frontend

# Run each node (without release!)
for i in `seq 1 $COUNT`; do
    run_machine $IMG_NAME "cndev$i" $i /slurmd.sh node
done

# Release nodes
for i in `seq 0 $COUNT`; do
    release_machine_no $i
done


################################################################################
#
# Run tests
#
################################################################################

TESTNUM=`count_test_num`

for i in `seq 1 $TESTNUM`; do
    run_test_num $COUNT $i
done

################################################################################
#
# Cleanup
#
################################################################################

run_cleanup
