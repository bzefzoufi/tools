# Welcome to FIO Benchmarking
## Getting number of jobs to run
echo -e 'Please provide the number of jobs for testing, at least 1 and consider as max 16 for throttling'
read -p 'Number of jobs': jobn
## Loop on protocols and profiles
declare -a adp=("iscsi" "nvme" "fc")
declare -a arr=("fs_randread" "fs_seqread" "fs_randwrite" "fs_seqwrite")
for prot in "${adp[@]}"
do
## Add number of jobs
sed -i 's/numjobs.*/numjobs='$jobn'/' fio_job_$prot
##
mkdir $prot
cd $prot
for wrk in "${arr[@]}"	
do
	mkdir $wrk
	mkdir $wrk/plotclat
	mkdir $wrk/plotslat
	mkdir $wrk/plotlat
	mkdir $wrk/plotbw
	mkdir $wrk/plotiops
## Run the fio job, parameters to be defined in fiojob file
cd $wrk
fio ../../fio_job_$prot --section=$wrk 2>&1 | ts |tee -a $HOSTNAME'_'$wrk'_'$prot.txt
## Removing the last bit added about priority for fio2plot plugin (design limitation) 
for i in $(eval echo "{1..$jobn}")
do
sed -i 's/.$// ; s/.$// ; s/.$//' $wrk'_bw.'$i.log
sed -i 's/.$// ; s/.$// ; s/.$//' $wrk'_iops.'$i.log
sed -i 's/.$// ; s/.$// ; s/.$//' $wrk'_clat.'$i.log
sed -i 's/.$// ; s/.$// ; s/.$//' $wrk'_slat.'$i.log
sed -i 's/.$// ; s/.$// ; s/.$//' $wrk'_lat.'$i.log
done
## Plotting the Bandwith
fio2gnuplot -b -g -t "Bandwith/s" -d plotbw
## Plotting the IOPS
fio2gnuplot -i -g -t "IOPS" -d plotiops
## Plotting the Latency
fio2gnuplot -p "*_clat*" -g -t "Completion Latency in msec" -d plotclat
fio2gnuplot -p "*_slat*" -g -t "Submission Latency in msec" -d plotslat
fio2gnuplot -p "*_lat*" -g -t "Total Latency in msec" -d plotlat
## Cleaning up raw data
rm -rf *.log
cd ..
done
cd ..
done
