#! /bin/bash

# Provide the filenames of the .csv files that contain the barcode sequences. These files should be located in the working directory.
ROUND1="Round1_barcodes_new2.txt"
ROUND2="Round2_barcodes_new2.txt"
ROUND3="Round3_barcodes_new2.txt"


# Provide the filenames of the .fastq files of interest. For this experiment paired end reads are required.
FASTQ_F="SRR6750041_1_smalltest.fastq"
FASTQ_R="SRR6750041_2_smalltest.fastq"



# Add the barcode sequences to a bash array.
declare -a ROUND1_BARCODES=( $(cut -b 1- $ROUND1) )
#printf "%s\n" "${ROUND1_BARCODES[@]}"

declare -a ROUND2_BARCODES=( $(cut -b 1- $ROUND2) )
#printf "%s\n" "${ROUND2_BARCODES[@]}"

declare -a ROUND3_BARCODES=( $(cut -b 1- $ROUND3) )
#printf "%s\n" "${ROUND3_BARCODES[@]}"

# Initialize the counter
count=1

# Make folder for results files
mkdir results


#######################################
# STEP 1: Demultiplex using barcodes  #
#######################################
# Search for the barcode in the sample reads file
# Use a for loop to iterate a search for each barcode.  If a match for the first barcode is found search for a match for a second barcode. If a match for the second barcode is found search through the third list of barcodes.

# Generate a progress message
echo Beginning STEP1: Demultiplex using barcodes

# Clean up by removing results files that may have been generated by a previous run.
rm ROUND*
rm results/result*

# Begin the set of nested loops that searches for every possible barcode. We begin by looking for ROUND1 barcodes 
for barcode1 in "${ROUND1_BARCODES[@]}";
    do
    grep -B 1 -A 2 "$barcode1" $FASTQ_R > ROUND1_MATCH.fastq
    echo barcode1.is.$barcode1
    
        if [ -s ROUND1_MATCH.fastq ]
        then
            
            # Now we will look for the presence of ROUND2 barcodes in our reads containing barcodes from the previous step
            for barcode2 in "${ROUND2_BARCODES[@]}";
            do
            grep -B 1 -A 2 "$barcode2" ROUND1_MATCH.fastq > ROUND2_MATCH.fastq
               
                if [ -s ROUND2_MATCH.fastq ]
                then

                    # Now we will look for the presence of ROUND3 barcodes in our reads containing barcodes from the previous step 
                    for barcode3 in "${ROUND3_BARCODES[@]}";
                    do
                    grep -B 1 -A 2 "$barcode3" ./ROUND2_MATCH.fastq | sed '/^--/d' > ROUND3_MATCH.fastq

                    # If matches are found we will write them to an output .fastq file itteratively labelled with an ID number
                    if [ -s ROUND3_MATCH.fastq ]
                    then
                    mv ROUND3_MATCH.fastq results/result.$count.2.fastq
                    fi

                    count=`expr $count + 1`
                    done
                fi
            done
        fi
    done

find results/ -size  0 -print0 |xargs -0 rm --

##########################################################
# STEP 2: For every cell find matching paired end reads  #
##########################################################
# Generate a progress message
echo Beginning STEP2: finding read mate pairs

# Now we need to collect the other read pair. To do this we can collect read IDs from the results files we generated in step one.
# Generate an array of cell filenames
declare -a cells=( $(ls results/) )

# Loop through the cell files in order to extract the read IDs for each cell
for cell in "${cells[@]}";
    do 
    grep -Eo '@[^ ]+' results/$cell > readIDs.txt # Grep for only the first word 
    declare -a readID=( $(grep -Eo '^@[^ ]+' results/$cell) )
        for ID in "${readID[@]}";
        do
        echo $ID
        grep -A 3 "$ID " $FASTQ_F | sed '/^--/d' >> results/$cell.MATEPAIR # Write the mate paired reads to a file
        done
    done


#All finished
echo all finished goodbye
