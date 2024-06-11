#!/bin/bash

#SBATCH --job-name=prad_hourly
#SBATCH --output=prad_hourly.o%j
#SBATCH --error=prad_hourly.e%j
#SBATCH --nodes=1
#SBATCH --qos=regular
#SBATCH --constraint=cpu
#SBATCH --mail-type=begin,end,fail
#SBATCH --mail-user=bryce.harrop@pnnl.gov
#SBATCH --account=m1867
#SBATCH --time=08:00:00

# Adjust mail-user and account as needed
# Adjust wallclock time depending on data volume
# PRAD = Process Radiative data

source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh

# Things that need editing
run_name=v2.LR.F2010.output
dir_name=/pscratch/sd/b/beharrop/E3SMv2/
years_in=000[2-4]
years_out=0002-0004
tape_no=h4
cam_or_eam=eam       # cam for v1; eam for v2

###############################################################################
datadir=${dir_name}/${run_name}/
idir=${datadir}archive/atm/hist/
odir=${datadir}post/rad_input_data/
filestring=${run_name}.${cam_or_eam}.${tape_no}.${years_in}-*.nc
outstring=${run_name}.1H_rad_data.${years_out}.nc
cat_name=${run_name}.concat.1H_rad_data.${years_out}.nc

if [ ! -d ${odir} ]; then
    mkdir -p ${odir};
fi

ncrcat -h -v QRL,QRS,FSNS,FLNS,FSNT,FLNT \
       ${idir}${filestring} ${odir}${cat_name}

# Add an extra "lev" dimension so that infld calls treat it as 3D data
# This is to avoid a bug that causes 2D data to not advance in time

ncap2 -s 'defdim("lev",1);FSNT[$time,$lev,$ncol]=FSNT;FLNT[$time,$lev,$ncol]=FLNT;FSNS[$time,$lev,$ncol]=FSNS;FLNS[$time,$lev,$ncol]=FLNS' ${odir}${cat_name} ${odir}${outstring}

# This file need not be removed for production runs where we might want to use
# the same 'forcing' after the infld bug has been fixed.
rm -f ${odir}${cat_name}

