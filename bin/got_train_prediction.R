library(tidyverse)
library(data.table)

args <- commandArgs(T)
pep_pga_results <- fread(args[1]) %>% select(peptide)
psm_pga_results <- fread(args[2]) %>% select(index, peptide, evalue)
colnames(psm_pga_results)[1] <- "Title"
all_features <- fread(args[3])
auto_rt_train_folder <- args[4]
auto_rt_prediction_folder <- args[5]
pdeep2_prediction <- args[6]
raw_psm <- read.delim(args[7])
colnames(raw_psm)[1] <- "Title"
psm_pga_results <- psm_pga_results %>% filter(peptide %in% pep_pga_results$peptide)

auto_rt_train_data <- left_join(psm_pga_results, all_features, by="Title") %>% select(Mod_Sequence, RT, Title, evalue)
auto_rt_train_data <- separate(auto_rt_train_data, Title, into=c("fraction", NA, NA, NA), sep="\\.", remove=F)
auto_rt_train_data_split <- split(auto_rt_train_data, auto_rt_train_data$fraction)
auto_rt_prediction_data <- left_join(raw_psm, all_features, by="Title") %>% select(Mod_Sequence, RT, Title)
auto_rt_prediction_data <- separate(auto_rt_prediction_data, Title, into=c("fraction", NA, NA, NA), sep="\\.", remove=F)
auto_rt_prediction_data_split <- split(auto_rt_prediction_data, auto_rt_prediction_data$fraction)

pdeep2_prediction_data <- raw_psm %>% select(peptide, mods, charge)
colnames(pdeep2_prediction_data) <- c("peptide", "modification", "charge")
pdeep2_prediction_unique_data <- pdeep2_prediction_data %>% distinct()

lapply(names(auto_rt_train_data_split), function(x){
	one_data <- auto_rt_train_data_split[[x]]
	one_data <- one_data[order(one_data$Mod_Sequence, -(one_data$evalue)), ]
	one_data <- one_data[!duplicated(one_data$Mod_Sequence), ]
	one_data <- one_data %>% select(Mod_Sequence, RT, evalue)
	colnames(one_data) <- c("x", "y", "evalue")
	write.table(one_data, paste(auto_rt_train_folder, x, ".txt", sep=""), row.names=F, quote=F, sep="\t")
})

lapply(names(auto_rt_prediction_data_split), function(x){
        one_data <- auto_rt_prediction_data_split[[x]]
	one_data <- one_data %>% select(Mod_Sequence, RT, Title)
        colnames(one_data) <- c("x", "y", "index")
	write.table(one_data, paste(auto_rt_prediction_folder, x, ".txt", sep=""), row.names=F, quote=F, sep="\t")
})

write.table(pdeep2_prediction_data, paste(pdeep2_prediction, ".txt", sep=""), row.names=F, quote=F, sep="\t")
write.table(pdeep2_prediction_unique_data, paste(pdeep2_prediction, "_unique.txt", sep=""), row.names=F, quote=F, sep="\t")
