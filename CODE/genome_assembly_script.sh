# Basecalling

# Albacore

# Albacore was used after first round of sequencing (12-5-2018)

read_fast5_basecaller.py -f FLO-MIN106 -k SQK-LSK109 --barcoding -r -i fast5 -t 20 -s /work5/leah/albacore_output2 --resume -o fastq

# Then switched to guppy because we heard it was more up to date (for sequencing runs 2-21-2019 on) with no special parameters

# The output FASTQ data files were initially quality checked using FASTQC (available from https://www.bioinformatics.babraham.ac.uk/projects/fastqc/). The tail ends with poor quality reads were trimmed from the FASTQ files with VSEARCH (Rognes et al 2016) and error-prone data – typically identified as singleton reads – was removed in the form of low abundant k-mers (a minimum of 3 k-mers in abundance using a k-mer size of 12) using KHMER (Crusoe et al 2015). 

# Assembly

# Canu- first assembler for all genomes

canu -p Myb241_canu -d Myb241_canu genomeSize=5m dbgThreads=40 -nanopore- Myb241total.fastq

# Additional parameters were used for BigB262 and Jub23, this made them one contig

canu -p BigB262_canu -d BigB262_canu genomeSize=5m corOutCoverage=all corMhapSensitivity=high corMinCoverage=0 corMaxEvidenceCoverageGlobal=10 corMaxEvidenceCoverageLocal=10 redMemory=32 dbgThreads=40  -nanopore-raw BigB262total.fastq

# Genome Assembly Polishing and Refinement

# Nanopolish- only for genomes without illumina reads

nanopolish index -d /Users/lradeke24/Documents/Steno_assembly/Steno_gDNA_32719/Steno_gDNA_32719/20190327_1608_MN29552_FAK62060_f81d0415/fast5/ -s Myb244_nanopolish/sequencing_summary.txt Myb244_total.fastq

bwa index Myb244_canu.contigs.fasta

bwa mem -x ont2d -t 8 Myb244_canu.contigs.fasta Myb244_total.fastq | samtools sort -reads.sorted.bam -T reads.tmp

samtools index reads.sorted.bam

python /usr/local/Cellar/nanopolish/0.10.2_1/scripts/nanopolish_makerange.py Myb244_canu.contigs.fasta | parallel --results Myb244_nanopolish/nanopolish.results -P 8 nanopolish variants --consensus -o Myb244_nanopolish/polished.{1}.vcf -w {1} -r Myb244_total.fastq -b reads.sorted.bam -g Myb244_canu.contigs.fasta -t 4 --min-candidate-frequency 0.1

nanopolish vcf2fasta -g Myb244_canu.contigs.fasta Myb244_nanopolish/polished.*.vcf > Myb244_nanopolish/Myb244_polished_genome.fa

# Pilon

# Pilon- clean up with illumina reads. Aligned paired end reads first, then another round aligning single end reads with the previous pilon assembly as reference 

bwa index R551-3_canu.contigs.fasta

bwa mem  /R551-3_canu.contigs.fasta /illumina_data/trimmed_miSeq_data/R551-3_S16_L001_R1_001.fastq  /illumina_data/trimmed_miSeq_data/R551-3_S16_L001_R2_001.fastq > R551-3_illuminatocanu_pe_aln.sam

samtools sort -o R551-3_illuminatocanu_pe_aln.sorted.bam R551-3_illuminatocanu_pe_aln.sam

samtools index R551-3_illuminatocanu_pe_aln.sorted.bam

java -Xmx8G -jar /usr/local/Cellar/pilon/1.22/pilon-1.22.jar --genome R551-3_canu.contigs.fasta --bam /R551-3/R551-3_pilon/R551-3_illuminatocanu_pe_aln.sorted.bam --output R551-3_pilon_pe --changes

# end