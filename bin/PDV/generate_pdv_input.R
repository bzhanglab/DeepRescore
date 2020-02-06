library(tidyverse)
library(data.table)

args <- commandArgs(T)
result_folder <- args[1]
sample <- args[2]
features_data <- fread(args[3])
percolator_input <- fread(args[4]) %>% select(error, similarity, Title)
colnames(percolator_input) <- c("Delta_RT", "SA", "Title")
features_data <- left_join(features_data, percolator_input, by="Title")

pep_result <- fread(paste(result_folder, sample, "_pep.txt", sep="")) %>%
	select(PSMId, score, `q-value`)
colnames(pep_result) <- c("Title", "Percolator_score", "q_value")

pdv_input <- left_join(pep_result, features_data, by="Title")

pdv_input <- rename(pdv_input, spectrum_title=Title, peptide=Peptide, charge=Charge)
pdv_input$mz <- (1.0078*pdv_input$charge + pdv_input$Mass)/pdv_input$charge
pdv_input$Modification <- NULL
pdv_input$Mass_Error <- NULL
pdv_input$modification <- ifelse(pdv_input$modification == "", "-",pdv_input$modification)

pdv_input_fdr_1 <- pdv_input %>% filter(q_value <= 0.01)

write.table(pdv_input, paste(result_folder, sample, "_pep_final.tsv", sep=""), row.names=F, quote=F, sep="\t")
write.table(pdv_input_fdr_1, paste(result_folder, sample, "_pep_final_qvalue0.01.tsv", sep=""), row.names=F, quote=F, sep="\t")

psm_result <- fread(paste(result_folder, sample, "_psms.txt", sep="")) %>%
        select(PSMId, score, `q-value`)
colnames(psm_result) <- c("Title", "Percolator_score", "q_value")

pdv_input <- left_join(psm_result, features_data, by="Title")

pdv_input <- rename(pdv_input, spectrum_title=Title, peptide=Peptide, charge=Charge)
pdv_input$mz <- (1.0078*pdv_input$charge + pdv_input$Mass)/pdv_input$charge
pdv_input$Modification <- NULL
pdv_input$Mass_Error <- NULL
pdv_input$modification <- ifelse(pdv_input$modification == "", "-",pdv_input$modification)

pdv_input_fdr_1 <- pdv_input %>% filter(q_value <= 0.01)

write.table(pdv_input, paste(result_folder, sample, "_psm_final.tsv", sep=""), row.names=F, quote=F, sep="\t")
write.table(pdv_input_fdr_1, paste(result_folder, sample, "_psm_final_qvalue0.01.tsv", sep=""), row.names=F, quote=F, sep="\t")
