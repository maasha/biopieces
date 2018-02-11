# Biopieces
### Biopieces is a bioinformatic framework of tools easily used and easily created.

The Biopieces are a collection of bioinformatics tools that can be pieced
together in a very easy and flexible manner to perform both simple and complex
tasks. The Biopieces work on a data stream in such a way that the data stream
can be passed through several different Biopieces, each performing one specific
task: modifying or adding records to the data stream, creating plots, or
uploading data to databases and web services. The Biopieces are executed in a
command line environment where the data stream is initialized by specific
Biopieces which read data from files, databases, or web services, and output
records to the data stream that is passed to downstream Biopieces until the data
stream is terminated at the end of the analysis as outlined below:

```
read_data | calculate_something | write_results
```

The following example demonstrates how a next generation sequencing experiment
can be cleaned and analyzed – including plotting of scores and length
distribution, removal of adaptor sequence, trimming and filtering using quality
scores, mapping to a specified genome, and uploading the data to the UCSC genome
browser for further analysis:

```
read_fastq -i data.fq |                               #  Initialize data stream from a FASTQ file.
plot_scores -t png -o scores_unclean.png |            #  Plot scores before cleaning.
find_adaptor -c 24 -a TCGTATGCCGTCTTC -p |            #  Locate adaptor - including partial adaptor.
clip_adaptor |                                        #  Clip any located adaptor.
trim_seq |                                            #  End trim sequences according to quality scores.
grab -e 'SEQ_LEN > 18'                                #  Filter short sequences.
mean_scores -l |                                      #  Locate local quality score minima.
grab -e 'SCORES_MEAN_LOCAL >= 15' |                   #  Filter low local quality score minima.
write_fastq -o data_clean.fq |                        #  Write the cleaned data to a FASTQ file.
plot_scores -t png -o scores_clean.png |              #  Plot scores after cleaning.
plot_distribution -k SEQ_LEN -t png -o lengths.png |  #  Plot sequence length distribution.
bowtie_seq -c 24 -g hg19 -m 2 |                       #  Map sequences to the human genome with Bowtie.
upload_to_ucsc –d hg19 –t my_data –x                  #  Upload the results to the UCSC Genome Browser.                                                                                     ```

The advantage of the Biopieces is that a user can easily solve simple and complex tasks without having any programming experience. Moreover, since the data format used to pass data between Biopieces is text based, different developers can quickly create new Biopieces in their favorite programming language - and all the Biopieces will maintain compatibility. Finally, templates exist for creating new Biopieces in Perl and Ruby.

There are currently ~190 Biopieces.

To learn more about Biopieces have a look at the Biopieces Introduction.

To browse the available Biopieces go to the Biopieces [Wiki](http://github.com/maasha/biopieces/wiki).


If you want to install the Biopieces go to the Biopieces [Installation Instructions](https://github.com/maasha/biopieces/wiki/Installation).

If you want to contribute Biopieces go to the Biopieces [HowTo](https://github.com/maasha/biopieces/wiki/HowTo).

Browse publications using Biopieces [here](https://scholar.google.dk/scholar?hl=en&as_sdt=0%2C5&q=biopieces&btnG=).

For important messages, questions, discussion, and suggestions join the Biopieces [Google Group](https://groups.google.com/forum/#!forum/biopieces).

Biopieces was developed with support from the Danish Agency for Science, Technology and Innovation (grant no 272-06-0325).
