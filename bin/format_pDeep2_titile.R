library(tidyverse)
library(data.table)

args <- commandArgs(T)
pdeep2_input <- fread(args[1])
raw_psm <- fread(args[2]) %>% select(index)
output <- args[3]

pdeep2_input$pdeep_title <- paste(pdeep2_input$peptide, pdeep2_input$modification, pdeep2_input$charge, sep="|")
final_data <- bind_cols(raw_psm, pdeep2_input)

write.table(final_data, output, row.names=F, quote=F, sep="\t")
