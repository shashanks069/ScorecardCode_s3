#!/bin/bash -ex

if [ $# -ne 3 ]
then
   echo 'Error running script - Invalid No. of Arguments'
   echo 'Syntax: '$0 '<1. Feed Name> <2. Raw Start Date> <3. Raw End Date> '
   exit 1
fi

FEED_NAME=${1}
RAW_START_DATE=${2}
RAW_END_DATE=${3}
BUCKET_NAME=wmg-data-factory-prod

if [ "${FEED_NAME}" = "AppleMusic" ]
then
        FEED_VENDORS="86758076 86758078 86757954 86757895 86758080"
        RAW_S3_PATH="s3://${BUCKET_NAME}/data/${FEED_NAME}/raw/Streams"
fi

if [ "${FEED_NAME}" = "itunes" ]
then
        FEED_VENDORS="80040002 85004045 80026919 80031942 80030465 80073730 80033280"
        RAW_S3_PATH="s3://${BUCKET_NAME}/data/${FEED_NAME}/raw"
fi

echo ${RAW_S3_PATH}

FINAL_FILE_NAME=${FEED_NAME}"-"${RAW_START_DATE}"-"${RAW_END_DATE}".txt"
EPOCH_TIME=$(date +%s)

echo ''
echo "["`date +%Y-%m-%dT%H:%M:%S`"] Start score card Generation"
echo ''

set +o errexit

echo ''
echo "["`date +%Y-%m-%dT%H:%M:%S`"] Collecting all the S3 files between ${RAW_START_DATE} and ${RAW_END_DATE}"
echo ''

start=${RAW_START_DATE}
end=${RAW_END_DATE}
TABLE_RECORD=""
CN_TIME=""
while [ $start -le $end ]
do
        DAY=`echo ${start} |cut -d'=' -f2`
        Y=`date -d "${DAY}" '+%Y'`
        M=`date -d "${DAY}" '+%m'`
        D=`date -d "${DAY}" '+%d'`
        for CN in ${FEED_VENDORS};
        do
                CN_TIME=""
                REPORT_DATE=$(date -d "$start + 0 day" +"%Y-%m-%d")
                RUN_DATE=$(date -d "$start + 1 day" +"%Y-%m-%d")
                CN_TIME=`aws s3 ls ${RAW_S3_PATH}/year=${Y}/month=${M}/day=${DAY}/ | grep ${CN} | awk 'FNR==1 {print $1,$2}'`
                CN_DATE=`aws s3 ls ${RAW_S3_PATH}/year=${Y}/month=${M}/day=${DAY}/ | grep ${CN} | awk 'FNR==1 {print $1}'`
                DELAY_DAYS=$(($(($(date -d ${CN_DATE} "+%s") - $(date -d ${RUN_DATE} "+%s"))) / 86400))
                if [ -z "${CN_DATE}" ]
                then
                    CN_TIME="2099-12-31 23:59:59"
                    DELAY_DAYS=99
                fi
                if [ ${DELAY_DAYS} -lt 0 ]
                then
                    DELAY_DAYS=0
                fi
                TABLE_RECORD=${TABLE_RECORD}${FEED_NAME}","${REPORT_DATE}","${RUN_DATE}", ,"${CN}","${CN_TIME}","${DELAY_DAYS}"\n"
        done
        start=$(date -d "$start + 1 day" +"%Y%m%d")
done
echo ${TABLE_RECORD} > /home/SivaR/scorecard/${FINAL_FILE_NAME}
echo ''
echo "["`date +%Y-%m-%dT%H:%M:%S`"] End score card File Generation"
