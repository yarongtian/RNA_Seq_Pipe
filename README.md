# RNA_Seq_Pipe

RNA seq pipeline where the user input fastq files, star index and a gtf for the Quantification, obs works for roy. 

You can run it like 


```
/home/xabras/.conda/envs/Nextflow/bin/nextflow run ~/Scripts/RNA_Seq_Pipe/RNA_Seq_pipe_vs2.nf --fastq "/jumbo/WorkingDir/B19-053/Data/Meta/testFastq/*_{R1,R2}.fastq" --gtf /jumbo/db/Homo_sapiens/Ensembl/GRCh38.90/Annotation/Homo_sapiens.GRCh38.90.gtf --outdir /jumbo/WorkingDir/B19-053/Data/Meta/Nextflow --refGenomeDir /jumbo/db/Homo_sapiens/Ensembl/GRCh38.90/StarIndex_2.5.2b

```

Clean script is made for quickly clean the messy outputs from the nextflow´folders into suited subfolders. You might want to run some multiqc scripts to merge the reports after they are done. Run the Clean script in the nextflow output folder! 

```

./Clean.sh

```

obs: 

* The inputs cannot be zipped for now, this is due to the problem with symbolic links and gzip 

* You need to change in the script for the library strandness, by default the script calculates by stranded reverse 

* There was an error in the first real trial were the cluster seems to kill the jobs, it might have been fixed with an update of nextflow but in that case you need to use the newest version. Conda install is not for the newest version so you need to install the source using wget 

