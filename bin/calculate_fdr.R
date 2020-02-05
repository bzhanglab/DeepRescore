library(tidyverse)
library(PGA)

args <- commandArgs(T)
folder_path <- args[1]
sample <- args[2]
database <- args[3]

calculateFDR(psmfile=paste(folder_path, sample, "-rawPSMs.txt", sep=""),
	db=database,
	fdr=0.01,
	decoyPrefix="XXX_",
	better_score_lower=FALSE,
	remap=FALSE,
        peptide_level=TRUE,
	score_t = 0,
	protein_inference=FALSE,
	out_dir=paste(folder_path, "peptide_level", sep=""),
	xmx=20)
calculateFDR(psmfile=paste(folder_path, sample, "-rawPSMs.txt", sep=""),
        db=database,
        fdr=0.01,
        decoyPrefix="XXX_",
        better_score_lower=FALSE,
        remap=FALSE,
        peptide_level=FALSE,
        score_t = 0,
        protein_inference=FALSE,
        out_dir=paste(folder_path, "psm_level", sep=""),
        xmx=20)
