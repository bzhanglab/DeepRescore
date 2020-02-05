library(fuzzyjoin)
library(data.table)
#library(OrgMassSpecR)
library(tidyverse)

args <- commandArgs(T)
title_list_result <- fread(args[1])
output <- args[2]

calculate_similarity <- function(x, output) {
  ori <- read.table(text=gsub("(?<=[a-z])\\s+", "\n", x[2], perl=TRUE),header=FALSE, col.names = c("mz", "intensity"))
  pdeep2 <- read.table(text=gsub("(?<=[a-z])\\s+", "\n", x[3], perl=TRUE),header=FALSE, col.names = c("mz", "intensity"))
  
  pdeep2 <- as.data.table(pdeep2)
  ori <- as.data.table(ori)
  tolerance=0.05
  
  test <- difference_left_join(pdeep2, ori, by="mz",  max_dist = 0.05)
  test$intensity.y <- ifelse(is.na(test$intensity.y), 0, test$intensity.y)
	test$intensity.x <- test$intensity.x/norm(test$intensity.x, type="2")
	test$intensity.y <- test$intensity.y/norm(test$intensity.y, type="2")
  #similarity<-cor(test$intensity.x, test$intensity.y, method ="pearson")
  similarity <- 1 - (2 * (acos(sum(test$intensity.x * test$intensity.y)))/pi)
  return (similarity)
}

title_list_result$similarity <- apply(title_list_result, 1, calculate_similarity)

cat("finish calculation")
output_data <- title_list_result %>%
        select(index, similarity)

output_data[is.na(output_data)] <- 0

write.table(output_data, output, row.names=F, quote=F, sep="\t")
