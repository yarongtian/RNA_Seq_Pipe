#!/usr/bin/sh 
  
mkdir -p Alignment
mv *sortedByCoord.out.bam Alignment
mv *sortedByCoord.out.bam.bai Alignment
mv *out Alignment
mv *.flagstat Alignment
mv *.idxstat Alignment

mkdir -p Counts 
mv *featureCount Counts
mv *featureCount.summary  Counts

mkdir -p Normalized 
mv *rpkm* Normalized
mv *tpm* Normalized

mkdir -p FilteredFastq 
mv *_1.fastq FilteredFastq
mv *_2.fastq FilteredFastq
mv *_R1_fastqc.* FilteredFastq
mv *_R2_fastqc.* FilteredFastq

mkdir -p AdapterFiltered
mv *_1_val_1*  AdapterFiltered
mv *_2_val_2*  AdapterFiltered

