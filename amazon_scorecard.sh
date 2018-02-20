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
BUCKET_NAME=wmg-data-factory-prod-amazon

if [ "${FEED_NAME}" = "Amazon" ]
then
		FEED_COUNTRIES="us uk fr it es de at ch jp"
        RAW_S3_PATH="s3://"${BUCKET_NAME}"/SalesConsumer/raw"
fi

if [ "${FEED_NAME}" = "Amazon_Prime" ]
then
    	FEED_COUNTRIES="gb us de jp at"
        RAW_S3_PATH="s3://"${BUCKET_NAME}"/PrimeConsumer/raw"
fi

if [ "${FEED_NAME}" = "Amazon_Music_Unlimited" ]
then
    	FEED_COUNTRIES="AT DE GB US FR ES IT"
        RAW_S3_PATH="s3://"${BUCKET_NAME}"/Unlimited/raw"
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
        for CN in ${FEED_COUNTRIES};
        do
                CN_TIME=""
                REPORT_DATE=$(date -d "$start + 0 day" +"%Y-%m-%d")
                RUN_DATE=$(date -d "$start + 1 day" +"%Y-%m-%d")
                CN_TIME=`aws s3 ls ${RAW_S3_PATH}/ | grep ${CN} | grep ${start} | awk 'FNR==1 {print $1,$2}'`
				CN_DAY=`aws s3 ls ${RAW_S3_PATH}/ | grep ${CN} | grep ${start} | awk 'FNR==1 {print $1}'`
				DELAY_DAYS=$(($(($(date -d ${CN_DAY} "+%s") - $(date -d ${RUN_DATE} "+%s"))) / 86400))
				if [ ${DELAY_DAYS} -lt 0 ]
				then
					DELAY_DAYS=0
				fi
				TABLE_RECORD=${TABLE_RECORD}${FEED_NAME}","${REPORT_DATE}","${RUN_DATE}","${CN}", ,"${CN_TIME}","${DELAY_DAYS}"\n"
        done
        start=$(date -d "$start + 1 day" +"%Y%m%d")
done
echo ${TABLE_RECORD} > /home/SivaR/scorecard/${FINAL_FILE_NAME}
echo ''
echo "["`date +%Y-%m-%dT%H:%M:%S`"] End score card File Generation"
