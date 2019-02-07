#!/bin/bash
# SOCIAL AUTOPILOT TASKS
# https://www.oc-extensions.com/Social-AutoPilot-OpenCart-2.x

# Arguments
# max_execution tasks_interval ask_total_to_do cron_secret_key cron_action channel_id
# E.g: social_autopilot.sh 59 15 0 xxxxxxxxxxxxxxxxxxxxxxxxxx task 1

# SECONDS - special var which count execution time
SECONDS=0

if [ $# -lt 5 ]; then
   echo "Not enough arguments"
   exit 0
fi

#MAX EXECUTION SECONDS FOR SHELL SCRIPT
MAX_EXECUTION_SECONDS=$1

echo "MAX exec = ${MAX_EXECUTION_SECONDS}"

# INTERVAL - max delay between tasks
INTERVAL=$2

# Localhost debug | DO NOT FORGET TO SET to 0 on OCX server
LOCALHOST_DEBUG=0

# TASK / CRON URL
if [ $LOCALHOST_DEBUG -eq 1 ]; then
   CRON_DOMAIN="http://localhost/work/ocx3/"
else
   CRON_DOMAIN="https://www.oc-extensions.com/"
fi

# if enable do CURL to get number of tasks to do
ASK_TOTAL=$3
TASKS_TODO=0;

CRON_SECRET_KEY=$4
CRON_ACTION=$5
CRON_CHANNEL_ID=${6:-0}

CRON_URL="${CRON_DOMAIN}index.php?route=xxxx/xxxxx_xxxxxxx&secret_key=${CRON_SECRET_KEY}"

if [ $CRON_CHANNEL_ID -gt 0 ]; then
   CRON_URL+="&channel_id=${CRON_CHANNEL_ID}"
fi

CRON_URL+="&action=${CRON_ACTION}"
CRON_TOTAL_URL="${CRON_URL}-total"

CURL_PATH="curl"
CURL_OPTIONS="-k"
CURL_URL="""${CRON_URL}"""
CURL_TOTAL_URL="""${CRON_TOTAL_URL}"""

if [ $ASK_TOTAL -gt 0 ]; then
   echo "CALL Total URL => ${CURL_TOTAL_URL}"

   TASKS_TODO=$($CURL_PATH $CURL_PARAMS $CURL_TOTAL_URL)
   echo "Tasks to process: ${TASKS_TODO}"

   if [ $TASKS_TODO -eq 0 ]; then
      echo "NOTHING TO DO"
      exit 0
   fi
fi

CRON_INDEX=1
TASK_INDEX=1

while [ $SECONDS -lt $MAX_EXECUTION_SECONDS ]; do
   echo "SECONDS PASSED SINCE STARTED = ${SECONDS}"
   echo "CALL ${CRON_INDEX} => ${CRON_URL}"

   echo "Command is ${CURL_PATH} ${CURL_OPTIONS} ${CURL_URL}"

   CURL_RESPONSE=$($CURL_PATH $CURL_PARAMS $CURL_URL)
   echo "${CURL_RESPONSE}"

   if [[ $ASK_TOTAL -gt 0 && $TASK_INDEX -eq $TASKS_TODO ]]; then
      exit 0
   else
      CALL_DURATION=$((SECONDS - (CRON_INDEX - 1) * INTERVAL))
      echo "Call duration = ${CALL_DURATION}"

      if [ $CALL_DURATION -lt $INTERVAL ]; then
         REMAINING_SLEEP_TIME=$((INTERVAL - CALL_DURATION))
         echo "sleep another ${REMAINING_SLEEP_TIME} seconds"

         sleep $REMAINING_SLEEP_TIME
      fi
   fi

   CRON_INDEX=$((CRON_INDEX + 1))
   TASK_INDEX=$((TASK_INDEX + 1))
done
