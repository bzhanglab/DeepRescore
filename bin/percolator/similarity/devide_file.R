library(tidyverse)
library(data.table)

args <- commandArgs(T)
input <- fread(args[1])
thread <- args[2]
output_path <- args[3]

count=1
for (data in split(input, sample(1:thread, nrow(input), replace=T))){
	filename <- paste(output_path,"section_", count, sep="")
	write.table(data, filename, row.names=F, quote=F, sep="\t")
	count = count + 1
}
