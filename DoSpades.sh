#!/bin/bash

<<HEADER
Eric Fournier 2019-07-10

Spades

HEADER

SPADES_EXEC="spades.py -m 200 -k 77,99,127 --careful -t 20"

source "/home/foueri01@inspq.qc.ca/GitScript/Jenkins/SetPath.sh"
SetStaticPath
GetProjectsNamefromRunName

STEP="Spades"

for proj in "${projects_list[@]}"

	do
	PROJECT_NAME=$proj
	SetFinalPath $PROJECT_NAME
	SAMPLE_SHEET="${SLBIO_PROJECT_PATH}"*".temp3"
	spec_arr=($(/usr/bin/python2.7 $GET_SPECIMENS_SCRIPT  $PARAM_FILE  $SAMPLE_SHEET $STEP  2>&1))
#	echo "In DoSpades $SLBIO_SPADES_FILTER_PATH"

	if [ ${#spec_arr[@]} -gt 0 ]
	then

		mkdir ${SLBIO_SPADES_PATH}
		mkdir ${SLBIO_SPADES_FILTER_PATH}	
		mkdir ${SLBIO_SPADES_STAT_PATH}	

		for spec in "${spec_arr[@]}"
			do

			PAIR_R1_TRIMMO=${SLBIO_FASTQ_TRIMMO_PATH}${spec}"_R1_PAIR.fastq.gz"
			UNPAIR_R1_TRIMMO=${SLBIO_FASTQ_TRIMMO_PATH}${spec}"_R1_UNPAIR.fastq.gz"
			PAIR_R2_TRIMMO=${SLBIO_FASTQ_TRIMMO_PATH}${spec}"_R2_PAIR.fastq.gz"
			UNPAIR_R2_TRIMMO=${SLBIO_FASTQ_TRIMMO_PATH}${spec}"_R2_UNPAIR.fastq.gz"
			OUTDIR=${SLBIO_SPADES_PATH}${spec}
			OUT_FASTA_FILTERED=${SLBIO_SPADES_FILTER_PATH}${spec}"_filter.fasta"		
			OUT_STAT=${SLBIO_SPADES_STAT_PATH}${spec}"_stat.txt"

			echo -e "Assemblage Spades pour ${spec}\t$(date "+%Y-%m-%d @ %H:%M$S")" >> $SLBIO_LOG_FILE
			SPADES_CMD="${SPADES_EXEC} --pe1-1 $PAIR_R1_TRIMMO --pe1-2 $PAIR_R2_TRIMMO --pe1-s $UNPAIR_R1_TRIMMO --pe1-s  $UNPAIR_R2_TRIMMO -o $OUTDIR"
			eval $SPADES_CMD > /dev/null 2>&1
			
			echo -e "Assembly filtration for ${spec}\t$(date "+%Y-%m-%d @ %H:%M$S")" >> $SLBIO_LOG_FILE

			seqkit fx2tab ${OUTDIR}"/contigs.fasta" | awk -v min_l=1000 'BEGIN{FS="_"}{if($4>=min_l){print $0}}' | seqkit tab2fx > ${OUT_FASTA_FILTERED}".tmp" 2>/dev/null
			dedupe2.sh in=${OUT_FASTA_FILTERED}".tmp" out=$OUT_FASTA_FILTERED 2>/dev/null
			rm ${OUT_FASTA_FILTERED}".tmp"

			echo -e "Calcul des statistiques d'assemblage pour ${spec}\t$(date "+%Y-%m-%d @ %H:%M$S")" >> $SLBIO_LOG_FILE

			awk 'BEGIN{FS="_";print "Contig\tLength\tCov\n"}{if($1 ~ ">NODE"){print $2"\t"$4"\t"$6}}' $OUT_FASTA_FILTERED > ${OUT_STAT}".tmp"
			awk 'NR == 1;NR > 1 {print $0 | "sort -rn -k 2"}' ${OUT_STAT}".tmp" > $OUT_STAT
			rm ${OUT_STAT}".tmp"	

		done

		rm -r ${SLBIO_SPADES_PATH}

	fi
done







