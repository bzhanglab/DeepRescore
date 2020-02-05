library(tidyverse)
library(data.table)

args <- commandArgs(T)

features <- fread(args[1])
raw_psms <- fread(args[2]) %>% select(index)
auto_rt <- fread(args[3])
similarity <- fread(args[4])
output <- args[5]
software=args[6]

auto_rt$error <- abs(auto_rt$y_pred - auto_rt$y)
auto_rt <- auto_rt %>% select(index, error)
auto_rt_similarity <- left_join(auto_rt, similarity, by="index")
auto_rt_similarity$similarity <- ifelse(is.na(auto_rt_similarity$similarity), 0, auto_rt_similarity$similarity)
colnames(auto_rt_similarity)[1] <- "Title"

input_features <- features %>% filter(Title %in% raw_psms$index)
input_features$Modification <- NULL
input_features$modification <- NULL
input_features$Mod_Sequence <- NULL
input_features$RT <- NULL
colnames(input_features)[3] <- "CalcMass"

if (software == "msgf"){
	input_features$`MS-GF:EValue` <- -log(input_features$`MS-GF:EValue`)
} else if (software == "xtandem"){
	input_features$`X\\!Tandem:expect` <- -log(input_features$`X\\!Tandem:expect`)
} else if (software == "comet"){
	input_features$expect <- -log(input_features$expect)
}

output_format <- left_join(input_features, auto_rt_similarity, by="Title")
output_format <- output_format %>% select(-Peptide, Peptide)
output_format <- output_format %>% select(-Proteins, Proteins)
output_format$Label <- ifelse(output_format$Proteins == "", -1, output_format$Label)
output_format$Proteins <- ifelse(output_format$Proteins == "", "XXX_Decoy", output_format$Proteins)

write.table(output_format, output, row.names=F, quote=F, sep="\t")
