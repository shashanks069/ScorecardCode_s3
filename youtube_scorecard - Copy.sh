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

if [ "${FEED_NAME}" = "ytraw" ]
then
        RAW_S3_PATH="s3://"${BUCKET_NAME}"/data/youTubeInsights/raw/rawdata/dataformat=3"
		FEED_NAME="Youtube_Insights"
fi

if [ "${FEED_NAME}" = "ytreport" ]
then
        RAW_S3_PATH="s3://"${BUCKET_NAME}"/data/youTubeInsights/raw/report/dataformat=5"
		FEED_NAME="Youtube_Insights_Report"
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
        CN_TIME=""
        REPORT_DATE=$(date -d "$start + 0 day" +"%Y-%m-%d")
        RUN_DATE=$(date -d "$start + 10 day" +"%Y-%m-%d")
        CN_TIME=`aws s3 ls ${RAW_S3_PATH}/year=${Y}/month=${M}/day=${DAY}/ | awk 'FNR==1 {print $1,$2}'`
        CN_DATE=`aws s3 ls ${RAW_S3_PATH}/year=${Y}/month=${M}/day=${DAY}/ | awk 'FNR==1 {print $1}'`
        DELAY_DAYS=$(($(($(date -d ${CN_DATE} "+%s") - $(date -d ${RUN_DATE} "+%s"))) / 86400))
        if [ ${DELAY_DAYS} -lt 0 ]
        then
            DELAY_DAYS=0
        fi
        if [ -n "${CN_DATE}" ]
        then
            TABLE_RECORD=${TABLE_RECORD}${FEED_NAME}","${REPORT_DATE}","${RUN_DATE}",All Countries, ,"${CN_TIME}","${DELAY_DAYS}"\n"
        fi
        start=$(date -d "$start + 1 day" +"%Y%m%d")
done
echo ${TABLE_RECORD} > /home/SivaR/scorecard/${FINAL_FILE_NAME}
echo ''
echo "["`date +%Y-%m-%dT%H:%M:%S`"] End score card File Generation"
