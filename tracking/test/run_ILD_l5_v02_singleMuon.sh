#!/bin/bash
#
#==============================================================
# Running shell script in parallel over multiple cores
#==============================================================

echo "############################################################################"
echo "                             System information"
echo "                             =================="

echo "Host:"
hostname -f

echo "CPU(s):"
cat /proc/cpuinfo | grep "model name" | cut -b 14-

echo "RAM:"
cat /proc/meminfo | grep "MemTotal" | cut -b 10-

echo "Swap:"
cat /proc/meminfo | grep "SwapTotal" | cut -b 11-

echo "############################################################################"
echo "Group:      ${GROUP}"

echo "Hosttype:   ${HOSTTYPE}"

echo "JobID:      ${JOB_ID}"

echo "JobName:    ${JOB_NAME}"

echo "Job_Script: ${JOB_SCRIPT}"

echo "User:       ${LOGNAME}"

echo "Queue:      ${QUEUE}"

echo "Shell:      ${SHELL}"

echo "TMP:        ${TMP}"

echo "TMPDIR:     ${TMPDIR}"

echo "User:       ${USER}"

echo "Working_DIR:${PWD}"

echo "############################################################################"
echo
echo "############################################################################"
echo

ILDMODEL=ILD_l5_v02
ILCSOFTVER=v01-19-05

. /afs/desy.de/project/ilcsoft/sw/x86_64_gcc49_sl6/${ILCSOFTVER}/init_ilcsoft.sh


PolarAngles=('10' '20' '40' '85')
Mom=( '1' '3' '5' '10' '15' '25' '50' '100' )


#==================================================
# GENERATION - particle gun
for i in {0..3}
do

for j in {0..7}
do

python lcio_particle_gun.py ${Mom[j]} ${PolarAngles[i]}  mcparticles_MuonsAngle_${PolarAngles[i]}_Mom_${Mom[j]}.slcio 13 -1. &

done

done
wait

mv mcparticles_MuonsAngle_*_Mom_*.slcio Results/GenFiles


#==================================================
# SIMULATION
for i in {0..3}
do

for j in {0..7}
do

ddsim \
    --inputFiles Results/GenFiles/mcparticles_MuonsAngle_${PolarAngles[i]}_Mom_${Mom[j]}.slcio  \
    --outputFile ${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_${PolarAngles[i]}_Mom_${Mom[j]}_SIM.slcio \
    --compactFile $lcgeo_DIR/ILD/compact/${ILDMODEL}/${ILDMODEL}.xml \
    --steeringFile ddsim_steer.py \
    --numberOfEvents 1000 &
done
wait
done
wait

mv ${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_*_Mom_*_SIM.slcio Results/SimFiles


#==================================================
# RECONSTRUCTION
for i in {0..3}
do

for j in {0..7}
do

Marlin MarlinStdReco.xml \
    --constant..DetectorModel=ILD_l5_o1_v02 \
    --global.LCIOInputFiles=Results/SimFiles/${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_${PolarAngles[i]}_Mom_${Mom[j]}_SIM.slcio \
    --constant.lcgeo_DIR=$lcgeo_DIR \
    --constant.OutputBaseName=${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_${PolarAngles[i]}_Mom_${Mom[j]} \
    --MyRecoMCTruthLinker.UsingParticleGun=true \
> RECO_${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_${PolarAngles[i]}_Mom_${Mom[j]}.out &

done
wait
done
wait


# move all to folder RecoFiles

mv ${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_*_Mom_*_REC.slcio Results/RecoFiles

# cleanup 
rm ${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_*_Mom_*_DST.slcio
rm ${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_*_Mom_*_AIDA.root
rm ${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_*_Mom_*_PfoAnalysis.root


#==================================================
# start Diagnostics
for i in {0..3}
do

for j in {0..7}
do

# diagnostics

INFILE=Results/RecoFiles/${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_${PolarAngles[i]}_Mom_${Mom[j]}_REC.slcio

Marlin DDDiagnostics.xml \
    --global.LCIOInputFiles=$INFILE \
    --MyAIDAProcessor.FileName=analysis_${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_${PolarAngles[i]}_Mom_${Mom[j]} \
    --MyDiagnostics.FillBigTTree=true \
    --MyDiagnostics.PhysSampleOn=false \
> DIAG_${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_${PolarAngles[i]}_Mom_${Mom[j]}.out &

done
wait
done
wait


# move all to folder Analysis

mv  analysis_${ILDMODEL}_${ILCSOFTVER}_MuonsAngle_*_Mom_*.root ../Results/Analysis

# move log files to folder logFiles

#mv *.out logFiles
#mv *.err logFiles
#mv *.log logFiles



#==================================================
# generate monitor plots

cd ../macros

root -b -q D0ResolutionL5.C
root -b -q PResolutionL5.C
root -b -q meanL5.C
root -b -q sigmaL5.C

mkdir -p ~/www/ILDPerformance_${ILCSOFTVER}

cp IPResolution_${ILDMODEL}_${ILCSOFTVER}.png ~/www/ILDPerformance_${ILCSOFTVER}
cp D0_fit_${ILDMODEL}_${ILCSOFTVER}.pdf ~/www/ILDPerformance_${ILCSOFTVER}
cp PResolution_${ILDMODEL}_${ILCSOFTVER}.png ~/www/ILDPerformance_${ILCSOFTVER}
cp PR_fit_${ILDMODEL}_${ILCSOFTVER}.pdf ~/www/ILDPerformance_${ILCSOFTVER}
cp pull_mean_${ILDMODEL}_${ILCSOFTVER}.png ~/www/ILDPerformance_${ILCSOFTVER}
cp pull_sigma_${ILDMODEL}_${ILCSOFTVER}.png ~/www/ILDPerformance_${ILCSOFTVER}
