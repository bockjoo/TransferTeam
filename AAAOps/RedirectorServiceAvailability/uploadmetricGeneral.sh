#bin/sh


DATE=$(date)
echo $DATE
echo "ExecutingScript"

cd /opt/TransferTeam.Jhonatan/AAAOps/XfedKibana_JSON

logs=logs

# General script
date
echo INFO executing XRDFED-kibana-probe_JSON_General.py 
python XRDFED-kibana-probe_JSON_General.py > $logs/XRDFED_probe_json.log 2>&1
status=$?
echo INFO $logs/XRDFED_probe_json.log
cat $logs/XRDFED_probe_json.log
date
echo INFO running send_metrics.py
python3 send_metrics.py > $logs/XRDFED_send.log 2>&1
echo INFO content of logs/XRDFED_send.log
cat $logs/XRDFED_send.log
date
echo INFO Done

if [ -f /opt/TransferTeam.Jhonatan/AAAOps/XfedKibana_JSON/logs/uploadmetricGeneral.log ] ; then
   a=1
   [ $status -eq 0 ] && { grep -q -i "caught overall timeout" $logs/XRDFED_probe_json.log ; [ $(expr $a + $?) -eq $a ] && status=1 ; } ;
   if [ $status -ne 0 ] ; then
      printf "$(/bin/hostname) $(basename $0)\n$(date)\n$(ls -al /opt/TransferTeam.Jhonatan/AAAOps/XfedKibana_JSON/logs/uploadmetricGeneral.log)\n$(cat /opt/TransferTeam.Jhonatan/AAAOps/XfedKibana_JSON/logs/uploadmetricGeneral.log)\n" | mail -s "$(/bin/hostname) uploadmetricGeneral.log" bockjoo@gmail.com -a /opt/TransferTeam.Jhonatan/AAAOps/XfedKibana_JSON/logs/uploadmetricGeneral.log
   fi
fi

