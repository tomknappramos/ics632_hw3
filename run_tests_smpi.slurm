#!/bin/bash
#SBATCH -n 80   # Number of tasks
#SBATCH -c 20   # Number of cores requested (MAX)
#SBATCH -N 4    # Number of nodes requested (MAX)
#SBATCH -t 300  # Runtime in minutes
#SBATCH -o job.out # Standard out goes to this file
#SBATCH -e job.err # Standard err goes to this file
#SBATCH --mail-type ALL
#SBATCH --mail-user tknappra@hawaii.edu
#SBATCH -p ics632.q
#SBATCH --account=ics_632

# setup vars
epochs=5			# tests per thread amount (not needed in local testing)

num_bytes=10000000

chunk_size_start=10000
chunk_size_mult=10
chunk_size_end=$num_bytes

RUN_BASICS=false

#
# SLURM:
#
# run: default_bcast
#	   naive_bcast
#	   asynchronous_pipelined_ring_bcast 
#
# byte buffer: 10^9 = 1000000000
#
# smaller byte buffer to start
# 
# run each with a certain amount of trials --> lets try 5?
#
#	--> run async_pipelined with trials for the various chunk sizes --> try some of the better oness
#

#
# LOCAL:
#  see 
# 
#
#
#
#

results_dir=results_smpi

def_res=def_time.txt
naive_res=naive_time.txt
ring_res=ring_time.txt
pipeline_res=pipeline_time.txt
async_res=async_pipeline_time.txt

# make directory
mkdir -p $results_dir

# clear potential previous results

if [ "$RUN_BASICS" = true ] ; then
> $results_dir/$def_res
> $results_dir/$naive_res
> $results_dir/$ring_res
fi

> $results_dir/$pipeline_res
> $results_dir/$async_res


### compile ###
smpicc bcast_skeleton.c -o bcast_skeleton -D NUM_BYTES=$num_bytes

# BASICS
if [ "$RUN_BASICS" = true ] ; then

###### default broadcast ########
echo ""
echo "********************************************* default broadcast **************************************************"
echo ""
smpirun --cfg=smpi/bcast:mpich -np 50 -platform ring_50.xml -hostfile hostfile_50.txt ./bcast_skeleton default_bcast -c 1 > res.txt
str_t=$(cat res.txt | grep "time:" | sed "s/^.*time:/time:/" | sed "s/time: //" | sed "s/ seconds//")
echo -n "$str_t, " >> $results_dir/$def_res


###### naive broadcast ########
echo ""
echo "********************************************* naive broadcast **************************************************"
echo ""
smpirun --cfg=smpi/bcast:mpich -np 50 -platform ring_50.xml -hostfile hostfile_50.txt ./bcast_skeleton naive_bcast -c 1 > res.txt
str_t=$(cat res.txt | grep "time:" | sed "s/^.*time:/time:/" | sed "s/time: //" | sed "s/ seconds//")
echo -n "$str_t, " >> $results_dir/$naive_res


###### ring broadcast ########
echo ""
echo "********************************************* ring broadcast **************************************************"
echo ""
smpirun --cfg=smpi/bcast:mpich -np 50 -platform ring_50.xml -hostfile hostfile_50.txt ./bcast_skeleton ring_bcast -c 1 > res.txt
str_t=$(cat res.txt | grep "time:" | sed "s/^.*time:/time:/" | sed "s/time: //" | sed "s/ seconds//")
echo -n "$str_t, " >> $results_dir/$ring_res

fi
# END BASICS



###### pipelined ring broadcast ########
echo ""
echo "********************************************* pipelined ring broadcast **************************************************"
echo ""

for ((i=chunk_size_start; i<=chunk_size_end; i=i*chunk_size_mult))
do
	smpirun --cfg=smpi/bcast:mpich -np 50 -platform ring_50.xml -hostfile hostfile_50.txt ./bcast_skeleton pipelined_ring_bcast -c $i > res.txt
	str_t=$(cat res.txt | grep "time:" | sed "s/^.*time:/time:/" | sed "s/time: //" | sed "s/ seconds//")
	echo "$i, $str_t" >> $results_dir/$pipeline_res
	
	# x5
	i_mid=$((i*5))
	if (( i_mid <= chunk_size_end )); then
		smpirun --cfg=smpi/bcast:mpich -np 50 -platform ring_50.xml -hostfile hostfile_50.txt ./bcast_skeleton pipelined_ring_bcast -c $i_mid > res.txt
		str_t=$(cat res.txt | grep "time:" | sed "s/^.*time:/time:/" | sed "s/time: //" | sed "s/ seconds//")
		echo "$i_mid, $str_t" >> $results_dir/$pipeline_res
	fi
	
done


###### async pipelined ring broadcast ########
echo ""
echo "********************************************* async pipelined ring broadcast **************************************************"
echo ""

for ((i=chunk_size_start; i<=chunk_size_end; i=i*chunk_size_mult))
do
	smpirun --cfg=smpi/bcast:mpich -np 50 -platform ring_50.xml -hostfile hostfile_50.txt ./bcast_skeleton asynchronous_pipelined_ring_bcast -c $i > res.txt
	str_t=$(cat res.txt | grep "time:" | sed "s/^.*time:/time:/" | sed "s/time: //" | sed "s/ seconds//")
	echo "$i, $str_t" >> $results_dir/$async_res
	
	# x5
	i_mid=$((i*5))
	if (( i_mid <= chunk_size_end )); then
		smpirun --cfg=smpi/bcast:mpich -np 50 -platform ring_50.xml -hostfile hostfile_50.txt ./bcast_skeleton asynchronous_pipelined_ring_bcast -c $i_mid > res.txt
		str_t=$(cat res.txt | grep "time:" | sed "s/^.*time:/time:/" | sed "s/time: //" | sed "s/ seconds//")
		echo "$i_mid, $str_t" >> $results_dir/$async_res
	fi
	
done



# log everything
cat $results_dir/$def_res
echo ""
cat $results_dir/$naive_res
echo ""
cat $results_dir/$ring_res
echo ""
cat $results_dir/$pipeline_res
echo ""
cat $results_dir/$async_res
echo ""
