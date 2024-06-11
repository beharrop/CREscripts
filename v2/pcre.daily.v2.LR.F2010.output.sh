#!/bin/bash

#SBATCH --job-name=pcre_daily
#SBATCH --output=pcre_daily.o%j
#SBATCH --error=pcre_daily.e%j
#SBATCH --nodes=1
#SBATCH --qos=debug
#SBATCH --constraint=cpu
#SBATCH --mail-type=begin,end,fail
#SBATCH --mail-user=bryce.harrop@pnnl.gov
#SBATCH --account=m1867
#SBATCH --time=0:20:00

# Adjust mail-user and account as needed
# Adjust wallclock time depending on data volume
# PCRE = Process Cloud Radiative Effect data

source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh

# Things that need editing
run_name=v2.LR.F2010.output
dir_name=/pscratch/sd/b/beharrop/E3SMv2/
years_in=000[2-4]
years_out=0002-0004
tape_no=h2
cam_or_eam=eam       # cam for v1; eam for v2

###############################################################################
datadir=${dir_name}/${run_name}/
idir=${datadir}archive/atm/hist/
odir=${datadir}post/cre_input_data/
filestring=${run_name}.${cam_or_eam}.${tape_no}.${years_in}-*.nc
outstring=${run_name}.1D_cre_data.${years_out}.nc
cat_name=${run_name}.concat.1D_cre_data.${years_out}.nc

if [ ! -d ${odir} ]; then
    mkdir -p ${odir};
fi

ncrcat -h -v QRL,QRS,QRLC,QRSC,FSNS,FLNS,FSNSC,FLNSC,FSNT,FSNTC,FLNT,FLNTC \
       ${idir}${filestring} ${odir}${cat_name}

# Add an extra "lev" dimension so that infld calls treat it as 3D data
# This is to avoid a bug that causes 2D data to not advance in time
mid_name_1=temp_file_make_vars.1D.nc
mid_name_2=temp_file_trimmed.1D.nc

# To preserve sign conventions with the code, all terms are computed
# here as all-sky minus clear-sky fluxes.  This means the LWCF in the
# input file will be opposite in sign to that of LWCF output from the
# model.
ncap2 -s 'QRS_CLD=(QRS-QRSC)' \
      -s 'QRL_CLD=(QRL-QRLC)' \
      -s 'SWCF_SFC=(FSNS-FSNSC)' \
      -s 'LWCF_SFC=(FLNS-FLNSC)' \
      -s 'SWCF=(FSNT-FSNTC)' \
      -s 'LWCF=(FLNT-FLNTC)' \
      ${odir}${cat_name} ${odir}${mid_name_1}

ncks -v LWCF,LWCF_SFC,SWCF,SWCF_SFC,QRL_CLD,QRS_CLD,lev,hyam,hybm,P0,ilev,hyai,hybi,time,time_bnds ${odir}${mid_name_1} ${odir}${mid_name_2}

ncap2 -s 'defdim("lev",1);SWCF[$time,$lev,$ncol]=SWCF;LWCF[$time,$lev,$ncol]=LWCF;SWCF_SFC[$time,$lev,$ncol]=SWCF_SFC;LWCF_SFC[$time,$lev,$ncol]=LWCF_SFC' ${odir}${mid_name_2} ${odir}${outstring}


# clean up temp files
rm -f ${odir}${mid_name_1} ${odir}${mid_name_2}

# This file need not be removed for production runs where we might want to use
# the same 'forcing' after the infld bug has been fixed.
rm -f ${odir}${cat_name}

