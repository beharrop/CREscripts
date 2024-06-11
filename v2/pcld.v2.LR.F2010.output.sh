#!/bin/bash

#SBATCH --job-name=pcld_control
#SBATCH --output=pcld_control.o%j
#SBATCH --error=pcld_control.e%j
#SBATCH --nodes=1
#SBATCH --qos=regular
#SBATCH --constraint=cpu
#SBATCH --mail-type=begin,end,fail
#SBATCH --mail-user=user.name@institution.ext
#SBATCH --account=m1867
#SBATCH --time=2:00:00

# Adjust mail-user and account as needed
# Adjust wallclock time depending on data volume
# PCLD = Process Cloud Locking Data

source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh

# Things that need editing
run_name=v2.LR.F2010.output
dir_name=/pscratch/sd/b/beharrop/E3SMv2/
years_in=000[2-4]
years_out=0002-0004
tape_no=h3
cam_or_eam=eam       # cam for v1; eam for v2

###############################################################################
datadir=${dir_name}/${run_name}/
idir=${datadir}archive/atm/hist/
odir=${datadir}post/cloud_locking_data/
filestring=${run_name}.${cam_or_eam}.${tape_no}.${years_in}-*.nc
outstring=${run_name}.cloud_locking_data.${years_out}.nc
outstring_in=${run_name}.cloud_locking_data_in.${years_out}.nc

if [ ! -d ${odir} ]; then
    mkdir -p ${odir};
fi

ncrcat -h ${idir}${filestring} ${odir}${outstring}

