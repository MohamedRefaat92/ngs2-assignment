
star_index=star_index
mkdir $star_index
STAR --runMode genomeGenerate --genomeDir star_index --genomeFastaFiles chr22_with_ERCC92.fa

#first indexing
run1Dir=1pass
mkdir $run1Dir
for f1 in $(ls ngs2-assignment-data/ | egrep '.+_1') ;do
 f1=ngs2-assignment-data/$f1
 f2=$(echo "$f1"| sed 's,_1,_2,g')
 STAR --genomeDir $run1Dir --readFilesIn $f1 $f2
done

#downsample
for file in $(ls ngs2-assignment-data) ; do seqkit head -n100000 ngs2-assignment-data/$file > downsampled/$file ; done
#first alignment
for f1 in $(ls ../downsampled/ | egrep '.+_1') ;do 
 f1=../downsampled/$f1; f2=$(echo "$f1"| sed 's,_1,_2,g')
 output_prefix=$(echo $(basename $f1)|cut -d . -f1)
 mkdir $output_prefix
 STAR --genomeDir $genomeDir --readFilesIn $f1 $f2 --outFileNamePrefix $output_prefix/$output_prefix
done

#second indexing
genomeDir_SRR=genomeDir_SRR
mkdir $genomeDir_SRR
genomeDir_shuffled=genome_shuffled
mkdir $genomeDir_shuffled
STAR --runMode genomeGenerate --genomeDir $genomeDir_SRR --genomeFastaFiles GRCh38.p12.genome.fa --sjdbFileChrStartEnd 1pass/SRR8797509_1/SRR8797509_1SJ.out.tab --sjdbOverhang 75
STAR --runMode genomeGenerate --genomeDir $genomeDir_shuffled --genomeFastaFiles GRCh38.p12.genome.fa --sjdbFileChrStartEnd 1pass/shuffled_SRR8797509_1/shuffled_SRR8797509_1SJ.out.tab --sjdbOverhang 75

#second alignment
run2Dir=2pass
mkdir $run2Dir
cd $run2Dir
for f1 in $(ls downsample/ | egrep '.+_1') ;do
 f1=downsample/$f1
 f2=$(echo "$f1"| sed 's,_1,_2,g')
 STAR --genomeDir $run2Dir --readFilesIn $f1 $f2
done

#picard
picard AddOrReplaceReadGroups I=1pass/shuffled_SRR8797509_1 Aligned.out.sam O=rg_added_sorted.bam SO=coordinate RGID=id RGLB=library RGPL=platform RGPU=machine RGSM=sample 
picard MarkDuplicates I=rg_added_sorted.bam O=dedupped.bam  CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT M=output.metrics
