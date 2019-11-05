#!/usr/bin/env nextflow

params.fastq = ''
fastqin=file(params.fastq)
params.gtf= ''
params.refGenomeDir = ''

referencegenomedir = file(params.refGenomeDir)
referenceannotation = file(params.gtf)

// setting the pair channel for the input to filtering and adapter processes for paired end data
Channel
    .fromFilePairs( params.fastq, flat: true )
    .ifEmpty { error "Cannot find any reads matching: ${params.fastq}" }
    .set { read_pairs }


// obs, dont use zipped files! You will have problems with to many symbolic links if you do, unzip them first and then zip them when the pipe is done! 


//---------------------Fastqc------------------------------

process run_fastqc {
        publishDir params.outdir, mode: 'copy', overwrite: true
        //errorStrategy 'ignore'

        clusterOptions='-pe mpi 1'
        executor 'sge'
        queue 'bfxcore.q@node3-bfx.medair.lcl,bfxcore.q@node2-bfx.medair.lcl'

        input:
	file a from fastqin
	       
	output:
	file "${a.baseName}_fastqc.*" into fastqcout

        script:
        """
	/apps/bio/apps/fastqc/0.11.2/fastqc ${a}
        """
}

//---------------------runAdapterRemoval------------------------------

process run_adapterfilt {
        publishDir params.outdir, mode: 'copy', overwrite: true
        //errorStrategy 'ignore'

        clusterOptions='-pe mpi 1'
        executor 'sge'
        queue 'bfxcore.q@node4-bfx.medair.lcl'

	// obs, when you have many modules you need to load ex not calling the entire path i only know node 4 that can handle it so far 
	// obs, this trim galore will only remove the default illumina adapters

	module 'trim_galore/0.4.0'
	module 'cutadapt/1.9'
	module 'fastqc/0.11.2'

        input:
	set pair_ID, file(R1), file(R2) from read_pairs
		       
	output:
	set pair_ID,"${pair_ID}*val_1.fq","${pair_ID}*val_2.fq" into Adaptertrimmed
	set pair_ID,"${pair_ID}*val*.zip","${pair_ID}*val*.html" into qualfiltreports

        script:
        """
	trim_galore --fastqc  -q 20 --length 30 --paired "${R1}" "${R2}" 
        """
}


//---------------------runAlignment------------------------------


process run_Alignment {
        publishDir params.outdir, mode: 'copy', overwrite: true
        //errorStrategy 'ignore'

        clusterOptions='-pe mpi 10'
        executor 'sge'
        queue 'bfxcore.q@node6-bfx.medair.lcl,bfxcore.q@node7-bfx.medair.lcl,bfxcore.q@node4-bfx.medair.lcl,bfx_short.q@node1-bfx.medair.l'

        input:
	set pair_ID, file(R1), file(R2) from Adaptertrimmed
		       
	output:
	set pair_ID,"${pair_ID}*bam" into Alignmentout, Alignmentout2, Alignmentout3
	// use two because you want to do statistics on one of them, last one is for moving files to directories 
	set pair_ID,"${pair_ID}*Log*out" into alstats
	

        script:
        """
	/apps/bio/apps/star/2.5.2b/bin/Linux_x86_64/STAR --runThreadN 10 --genomeDir ${referencegenomedir} --readFilesIn "${R1}" "${R2}" --outSAMtype BAM SortedByCoordinate --outFileNamePrefix ${pair_ID}

        """
}

//---------------------runQualassesment------------------------------

process run_qualAlignment {
        publishDir params.outdir, mode: 'copy', overwrite: true
        //errorStrategy 'ignore'

        clusterOptions='-pe mpi 1'
        executor 'sge'
        queue 'bfxcore.q@node6-bfx.medair.lcl,bfx_short.q@node1-bfx.medair.l,bfxcore.q@node4-bfx.medair.lcl'

        input:
	set pair_ID, file(bam) from Alignmentout
		       
	output:
	set pair_ID,"${pair_ID}*bai", "${pair_ID}*flagstat", "${pair_ID}*idxstat" into alstats2
	
        script:
        """
	/apps/bio/apps/samtools/1.6/samtools index ${bam}
	/apps/bio/apps/samtools/1.6/samtools flagstat ${bam} > ${pair_ID}.flagstat
	/apps/bio/apps/samtools/1.6/samtools idxstats ${bam} > ${pair_ID}.idxstat

        """
}

//---------------------runQuantification------------------------------


// obs very important than if you are using a different strand library you need to change here, default is stranded reverse!  P flag is for calculating the reads as fragments and not as reads 

process run_quantification {
        publishDir params.outdir, mode: 'copy', overwrite: true
        //errorStrategy 'ignore'

        clusterOptions='-pe mpi 5'
        executor 'sge'
        queue 'bfxcore.q@node6-bfx.medair.lcl,bfxcore.q@node4-bfx.medair.lcl,bfx_short.q@node1-bfx.medair.l'


        input:
	set pair_ID, file(bam) from Alignmentout2
		       
	output:
	set pair_ID,"${pair_ID}_featureCount" into quantification
	set pair_ID,"${pair_ID}_featureCount.summary" into quantsummary

        script:
        """
	/apps/bio/software/subread/1.6.4/bin/featureCounts -a ${referenceannotation} -T 5 -s 2 -g gene_name -t exon -p -o ${pair_ID}_featureCount $bam
        """
}


//---------------------runNormalization------------------------------

process run_Normalization {
        publishDir params.outdir, mode: 'copy', overwrite: true
        //errorStrategy 'ignore'

        clusterOptions='-pe mpi 1'
        executor 'sge'
        queue 'bfxcore.q@node2-bfx.medair.lcl,bfxcore.q@node3-bfx.medair.lcl'


        input:
	set pair_ID, file(count) from quantification
		       
	output:
	set pair_ID,"${pair_ID}*txt" into Normalized
	

        script:
        """
	Rscript ~/Scripts/tpm_rpkm2.R ${count}
        """
}


