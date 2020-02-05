library(tidyverse)

args <- commandArgs(T)

input <- read.delim(args[1])
software <- args[2]
output <- args[3]

if (software == "msgf"){
	output_data <- input %>%
		select(Title, Charge, Mass, Peptide, Modification, Proteins, MS.GF.EValue)
	output_data$MS.GF.EValue <- -log(output_data$MS.GF.EValue)
} else if (software == "comet"){
        output_data <- input %>%
                select(Title, Charge, Mass, Peptide, Modification, Proteins, expect)
	output_data <- output_data %>% filter(str_length(Peptide) >= 8, str_length(Peptide) <= 25) 
	output_data$expect <- -log(output_data$expect)
} else if (software == "xtandem"){
        output_data <- input %>%
                select(Title, Charge, Mass, Peptide, Modification, Proteins, X..Tandem.expect)
	output_data <- output_data %>% filter(!str_detect(Modification, "pyro-Glu"), !str_detect(Modification, "Acetyl"), !str_detect(Modification, "Ammonia-loss"), str_length(Peptide) >= 8, str_length(Peptide) <= 25)
	output_data$X..Tandem.expect <- -log(output_data$X..Tandem.expect)
} else if (software == "maxquant"){
        output_data <- input %>%
                select(Title, Charge, Mass, Peptide, Modification, Proteins, Score)
}

colnames(output_data) <- c("index", "charge", "mass", "peptide", "mods", "protein", "score")

write.table(output_data, output, row.names=F, quote=F, sep="\t")
