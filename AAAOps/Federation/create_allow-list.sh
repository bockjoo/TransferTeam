#!/bin/bash

#bockjoo original BASE=/root/
BASE=/tmp
FEDINFO=/opt/TransferTeam/AAAOps/FederationNew/
export XRD_NETWORKSTACK=IPv4

declare -a redirectors=("cms-xrd-global01.cern.ch:1094" "cms-xrd-global02.cern.ch:1094" "cms-xrd-transit.cern.ch:1094")
declare -a redirectors_eu=("xrootd.ba.infn.it" "xrootd-redic.pi.infn.it" "llrxrd-redir.in2p3.fr") # bockjoo
declare -a redirectors_us=("cmsxrootd2.fnal.gov" "xrootd.unl.edu") # bockjoo
nred=${#redirectors[@]} # bockjoo

rm -f $BASE/tmpNew_*

# bockjoo original for j in "${redirectors[@]}";do
for j in $(seq 0 $(expr $nred - 1)) ; do # bockjoo
	#bockjoo original if [ "$j" == "cms-xrd-global01.cern.ch:1094" ] || [ "$j" == "cms-xrd-global02.cern.ch:1094" ]; then
        if [ "${redirectors[$j]}" == "cms-xrd-global01.cern.ch:1094" ] || [ "${redirectors[$j]}" == "cms-xrd-global02.cern.ch:1094" ]; then
 		#query european reginal redirectors
		xrdmapc --list all "${redirectors[$j]}" 2>/dev/null 1>$FEDINFO/out/xrdmapc_all_${j}.txt # bockjoo
		redir_search_eu=$(echo ${redirectors_eu[@]}  | sed 's# #|#g') # bockjoo
		redir_search_us=$(echo ${redirectors_us[@]}  | sed 's# #|#g') # bockjoo
		cat $FEDINFO/out/xrdmapc_all_${j}.txt | grep -E "$redir_search_eu" | awk '{print $3}' | cut -d ':' -f1 | sort -u > $BASE/tmpNew_euRED_${redirectors[$j]} # bockjoo
		cat $FEDINFO/out/xrdmapc_all_${j}.txt | grep -E "$redir_search_us" | awk '{print $3}' | cut -d ':' -f1 | sort -u > $BASE/tmpNew_usRED_${redirectors[$j]} # bockjoo
		#bockjoo original xrdmapc --list all "$j" | grep -E 'xrootd.ba.infn.it|xrootd-redic.pi.infn.it|llrxrd-redir.in2p3.fr:1094' | awk '{print $3}' | cut -d ':' -f1 > $BASE/tmpNew_euRED_$j	
		#bockjoo original xrdmapc --list all "$j" | grep -E 'cmsxrootd2.fnal.gov|xrootd.unl.edu' | awk '{print $3}' | cut -d ':' -f1 > $BASE/tmpNew_usRED_$j
		nline=$(wc -l $FEDINFO/out/xrdmapc_all_${j}.txt | awk '{print $1}') # bockjoo
		for i in $(cat $BASE/tmpNew_euRED_${redirectors[$j]});do
		        grep -A $nline "Man ${i}:1094" $FEDINFO/out/xrdmapc_all_${j}.txt | grep -A $nline -m 1 "^1 " > $BASE/tmpNew_$i #bockjoo look for level 1 Manager
			#bockjoo original xrdmapc --list all $i:1094 > $BASE/tmpNew_$i
			cat $BASE/tmpNew_$i | awk '{if($2=="Man") print $3; else print $2}' | tail -n +2 >> $BASE/tmpNew_total_eu_${redirectors[$j]}
		done
		
		for k in $(cat $BASE/tmpNew_usRED_${redirectors[$j]});do
			grep -A $nline "Man ${k}:1094" $FEDINFO/out/xrdmapc_all_${j}.txt | grep -A $nline -m 1 "^1 " > $BASE/tmpNew_us_$k #bockjoo
			#bockjoo original xrdmapc --list all $k:1094 > $BASE/tmpNew_us_$k	
			cat $BASE/tmpNew_us_$k | awk '{if($2=="Man") print $3; else print $2}' | tail -n +2 >> $BASE/tmpNew_total_us_${redirectors[$j]}
		done
	

		cat $BASE/tmpNew_total_eu_${redirectors[$j]} | cut -d : -f1 | grep -v "\[" | sort -u > $FEDINFO/in/prod_${redirectors[$j]}.txt 
		cat $BASE/tmpNew_total_us_${redirectors[$j]} | cut -d : -f1 | grep -v "\[" | sort -u >> $FEDINFO/in/prod_${redirectors[$j]}.txt 
		cat $BASE/tmpNew_total_eu_${redirectors[$j]} | cut -d : -f1 | grep -v "\[" | sort -u | awk -F. '{print "*."$(NF-2)"."$(NF-1)"."$NF}' | sort -u > $FEDINFO/out/list_eu_${redirectors[$j]}.allow
		cat $BASE/tmpNew_total_us_${redirectors[$j]} | cut -d : -f1 | grep -v "\[" | sort -u | awk -F. '{print "*."$(NF-2)"."$(NF-1)"."$NF}' | sort -u > $FEDINFO/out/list_us_${redirectors[$j]}.allow
		rm -f $FEDINFO/out/hostIPv4.txt $FEDINFO/out/hostIPv6.txt
		for f in $(cat $FEDINFO/in/prod_${redirectors[$j]}.txt);do
			if [ "$f" != "${1#*[0-9].[0-9]}" ]; then
				echo $f >> $FEDINFO/out/hostIPv4.txt 
			elif [ "$f" != "${1#*:[0-9a-fA-F]}" ]; then
				echo $f >> $FEDINFO/out/hostIPv6.txt
			fi
		

		done	
	else
		xrdmapc --list all "${redirectors[$j]}" | tail -n +2 | awk '{if($2=="Man") print $3; else print $2}' > $BASE/tmpNew_total
		cat $BASE/tmpNew_total | cut -d : -f1 | sort -u > $FEDINFO/in/trans.txt
		
		rm -f $FEDINFO/out/transit-hostIPv4.txt $FEDINFO/out/transit-hostIPv6.txt
		for f in $(cat $FEDINFO/in/trans.txt);do
			if [ "$f" != "${1#*[0-9].[0-9]}" ]; then
				echo $f >> $FEDINFO/out/transit-hostIPv4.txt 
			elif [ "$f" != "${1#*:[0-9a-fA-F]}" ]; then
				echo $f >> $FEDINFO/out/transit-hostIPv6.txt
			fi
		done	
	fi	
	  

	#rm $BASE/tmpNew_*

done

diff $FEDINFO/in/prod_cms-xrd-global01.cern.ch\:1094.txt $FEDINFO/in/prod_cms-xrd-global02.cern.ch\:1094.txt 
stat=$(echo $?)
if [ $stat == 1 ]; then
	cat $FEDINFO/in/prod_cms-xrd-global01.cern.ch\:1094.txt $FEDINFO/in/prod_cms-xrd-global02.cern.ch\:1094.txt | sort -u > $FEDINFO/in/prod.txt	
	cat $FEDINFO/out/list_eu_cms-xrd-global01.cern.ch\:1094.allow $FEDINFO/out/list_eu_cms-xrd-global02.cern.ch\:1094.allow | sort -u > $FEDINFO/out/list_eu.allow
	cat $FEDINFO/out/list_us_cms-xrd-global01.cern.ch\:1094.allow $FEDINFO/out/list_us_cms-xrd-global02.cern.ch\:1094.allow | sort -u > $FEDINFO/out/list_us.allow
 
else
	cp $FEDINFO/in/prod_cms-xrd-global02.cern.ch\:1094.txt $FEDINFO/in/prod.txt
	cp $FEDINFO/out/list_us_cms-xrd-global01.cern.ch\:1094.allow $FEDINFO/out/list_us.allow
	cp $FEDINFO/out/list_eu_cms-xrd-global01.cern.ch\:1094.allow $FEDINFO/out/list_eu.allow
	
fi	


echo "    "  >> $FEDINFO/out/list_us.allow
echo "* redirect cms-xrd-transit.cern.ch+:1213" >> $FEDINFO/out/list_us.allow

echo "    "  >> $FEDINFO/out/list_eu.allow
echo "* redirect cms-xrd-transit.cern.ch+:1213" >> $FEDINFO/out/list_eu.allow



#cat $FEDINFO/in/prod.txt | cut -d : -f1 | sort -u | awk -F. '{if ($NF == "uk" || $NF == "fr" || $NF == "it" || $(NF-1) == "cern" ) print $(NF-2)"."$(NF-1)"."$NF; else if ( $(NF-1) == "vanderbilt" ) print $(NF-3)"."$(NF-2)"."$(NF-1)"."$NF; else if ( $(NF-1) == "mit" ) print $(NF-2)"."$(NF-1)"."$NF;  else print $(NF-1)"."$NF}' | sort -u > $FEDINFO/in/prod_domain.txt

#Quick fix for "[" character in prod.txt 
cat $FEDINFO/in/prod.txt | awk '{ if ($1 ~ /\[+/ ) print "Unknown.Host"; else print $1;}' > $FEDINFO/in/tmp
cp $FEDINFO/in/tmp $FEDINFO/in/prod.txt
rm $FEDINFO/in/tmp



cat $FEDINFO/in/prod.txt |  sort -u | awk -F. '{if ($NF == "uk" && $(NF-2) != "rl" || $NF == "fr" || $(NF-1) == "cern" || $(NF-1) == "fnal" ) print $(NF-2)"."$(NF-1)"."$NF; else if ( $NF == "it" && $(NF-2) == "cnaf") print $(NF-4)"."$(NF-2); else if ( $NF == "it" && $(NF-2) != "cnaf" ) print $(NF-2)"."$(NF-1)"."$NF; else if ( $(NF-3) == "xrootd-vanderbilt" ) print $(NF-3)"."$(NF-2)"."$(NF-1)"."$NF; else if ( $(NF-1) == "mit" ) print $(NF-2)"."$(NF-1)"."$NF; else if ( $NF == "uk" && $(NF-2) == "rl" ) print $(NF-3)"."$(NF-2)"."$(NF-1)"."$NF; else if ( $NF == "kr") print $(NF-2)"."$(NF-1)"."$NF; else if ( $NF == "be" ) print $(NF-2)"."$(NF-1)"."$NF; else print $(NF-1)"."$NF}' | sort -u > $FEDINFO/in/prod_domain.txt

cat $FEDINFO/in/trans.txt | cut -d : -f1 | sort -u | awk -F. '{if ($NF == "uk" || $NF == "fr" || $NF == "kr" || $NF == "it" || $NF == "ch" && $(NF-2) != "cnaf" ) print $(NF-2)"."$(NF-1)"."$NF; else if ($NF == "it" && $(NF-2) == "cnaf" ) print $(NF-4)"."$(NF-3)"."$(NF-2)"."$(NF-1)"."$NF; else print $(NF-1)"."$NF}' | sort -u > $FEDINFO/in/trans_domain.txt
