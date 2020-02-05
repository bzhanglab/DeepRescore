#!/usr/bin/env nextflow

params.help = null


result_file = file(params.result_file)
software = params.software
spectrum_file = file(params.spectrum_file)
output_path = file(params.output_path)
instrument = params.instrument
pDeep2_soft_path = params.pDeep2_path
energy = params.energy
threads = params.threads
memory = params.memory
sample = params.sample

if (software == "msgf") {
	result_type = 1
} else if (software == "xtandem") {
	result_type = 1
} else if (software == "comet") {
	result_type = 2
} else if (software == "maxquant") {
	result_type = 5
}


process got_features {

	tag "$sample"

	publishDir "$output_path", mode: "copy", overwrite: true

	input:
	file result_file
	file spectrum_file

	output:
	file("features.txt") into all_features_ch1
	file("features.txt") into all_features_ch2
	file("features.txt") into all_features_ch3
	file("features.txt") into all_features_ch4

	script:

	"""
	java -Xmx${memory}g -jar ${baseDir}/bin/PDV-1.6.1.beta.features/PDV-1.6.1.beta.features.jar \
		-r $result_file \
		-rt $result_type \
		-s $spectrum_file \
		-st 1 \
		-i * \
		-k s \
		-o ./ \
		-a 0.05 \
		-c 0 \
		-ft pdf \
		--features
	"""
}

process pga_fdr_control {

	tag "$sample"

	container "proteomics/pga:latest"

	publishDir "$output_path", mode: "copy", overwrite: true

	input:
	file feature_file from all_features_ch1

	output:
	set file("${sample}-rawPSMs.txt"), file("./peptide_level/"), file("./psm_level/") into pga_results_ch
	file("${sample}-rawPSMs.txt") into pga_results_ch2
	file("${sample}-rawPSMs.txt") into pga_results_ch3

	script:
	"""
	mkdir peptide_level psm_level

	Rscript ${baseDir}/bin/got_pga_input.R $feature_file $software ./${sample}-rawPSMs.txt

	Rscript ${baseDir}/bin/calculate_fdr.R ./ $sample ${baseDir}/bin/protein.pro-ref.fasta
	"""
}

process generate_train_prediction_data {

	tag "$sample"

	container "proteomics/pga:latest"

	publishDir "$output_path", mode: "copy", overwrite: true

	input:
	file feature_file from all_features_ch2
	set file(rawPSMs_file), file(peptide_pga_results_file), file(psm_pga_results_file) from pga_results_ch

	output:
	file("./pDeep2_prediction/") into pDeep2_prediction_ch
	file("./autoRT_train/") into autoRT_train_ch
	file("./autoRT_prediction/") into autoRT_prediction_ch

	script:
	"""
	mkdir autoRT_train autoRT_prediction pDeep2_prediction
	Rscript ${baseDir}/bin/got_train_prediction.R ${peptide_pga_results_file}/pga-peptideSummary.txt \
	${psm_pga_results_file}/pga-peptideSummary.txt $feature_file ./autoRT_train/ ./autoRT_prediction/ \
	./pDeep2_prediction/${sample}_pdeep2_prediction $rawPSMs_file
	"""
} 


process run_pdeep2 {

	tag "$sample"

	container "proteomics/pdeep2:latest"

	publishDir "${output_path}/pDeep2_prediction/", mode: "copy", overwrite: true

	input:	
	file(pdeep2_folder) from pDeep2_prediction_ch

	output:
	set file("${sample}_pdeep2_prediction_results.txt"), file{"${pdeep2_folder}/${sample}_pdeep2_prediction.txt"} into pDeep2_results_ch

	script:
	"""
	#export CUDA_VISIBLE_DEVICES=0

	python predict.py -e $energy -i $instrument -in ${pdeep2_folder}/${sample}_pdeep2_prediction_unique.txt -out ./${sample}_pdeep2_prediction_results.txt
	"""
}

process process_pDeep2_results {

	tag "$sample"

	container "proteomics/pga:latest"

	publishDir "${output_path}/pDeep2_prediction/", mode: "copy", overwrite: true

	input:
	file (rawPSMs_file) from pga_results_ch2
	file (spectrum_file)
	set file(pDeep2_results), file(pDeep2_prediction) from pDeep2_results_ch

	output:
	set file("./${sample}_format_titles.txt"), file("./${sample}_spectrum_pairs.txt"), file("./${sample}_similarity_SA.txt") into similarity_ch
 	file ("./${sample}_similarity_SA.txt") into pDee2_next_ch

	script:
	"""
	#!/bin/sh

	mv $pDeep2_results ${pDeep2_results}.mgf
	Rscript ${baseDir}/bin/format_pDeep2_titile.R $pDeep2_prediction $rawPSMs_file ./${sample}_format_titles.txt
	
	java -Xmx${memory}g -cp ${baseDir}/bin/PDV-1.6.1.beta.features/PDV-1.6.1.beta.features.jar PDVGUI.GenerateSpectrumTable \
		./${sample}_format_titles.txt $spectrum_file ${pDeep2_results}.mgf ./${sample}_spectrum_pairs.txt $software

	mkdir sections sections_results
	Rscript ${baseDir}/bin/similarity/devide_file.R ./${sample}_spectrum_pairs.txt $threads ./sections/
	for file in ./sections/*
	do
		name=`basename \$file`
		Rscript ${baseDir}/bin/similarity/calculate_similarity_SA.R \$file ./sections_results/\${name}_results.txt &
	done
	wait
	awk 'NR==1 {header=\$_} FNR==1 && NR!=1 { \$_ ~ \$header getline; } {print}' ./sections_results/*_results.txt > ./${sample}_similarity_SA.txt
	#Rscript ${baseDir}/bin/similarity/calculate_similarity_SA.R ./${sample}_spectrum_pairs.txt ./${sample}_similarity_SA.txt
	"""
}


process train_autoRT {

	tag "$sample"

	container "proteomics/autort:latest"

	publishDir "${output_path}/autoRT_train/", mode: "copy", overwrite: true

	input:
	file(sa_file) from pDee2_next_ch
	file(autoRT_train_folder) from autoRT_train_ch

	output:
	file ("./autoRT_models/") into model_prediction_ch

	script:
	"""
	#!/bin/sh

	set -e

	mkdir -p ./autoRT_models
	for file in ${autoRT_train_folder}/*.txt
	do
		fraction=`basename \${file} .txt`
		mkdir -p ./autoRT_models/\${fraction}

		python /opt/AutoRT/autort.py train \
		-i \$file \
		-o ./autoRT_models/\${fraction} \
		-e 40 \
		-b 64 \
		-u m \
		-m /opt/AutoRT/models/base_models_PXD006109/model.json \
		-rlr \
		-n 10 

	done
	wait
	"""
}

process predict_autoRT {

	tag "$sample"

	container "proteomics/autort:latest"

	publishDir "${output_path}/", mode: "copy", overwrite: true

	input:
	file autoRT_prediction_folder from autoRT_prediction_ch
	file (autoRT_models_folder)from model_prediction_ch

	output:

	file("./autoRT_prediction/") into autoRT_results_ch

	script:
	"""
	#!/bin/sh

	set -e

	mkdir -p ./autoRT_prediction
	mkdir -p ./autoRT_prediction/results
	for file in ${autoRT_prediction_folder}/*.txt
	do
		fraction=`basename \${file} .txt`
		mkdir -p ./autoRT_prediction/\${fraction}

		python /opt/AutoRT/autort.py predict \
		-t \$file \
		-s ${autoRT_models_folder}/\${fraction}/model.json \
		-o ./autoRT_prediction/\${fraction} \
		-p \${fraction}

	done
	wait
	for file in ${autoRT_prediction_folder}/*.txt
	do
		fraction=`basename \${file} .txt`
		cp ./autoRT_prediction/\${fraction}/\${fraction}.csv ./autoRT_prediction/results/
	done
	awk 'NR==1 {header=\$_} FNR==1 && NR!=1 { \$_ ~ \$header getline; } {print}' ./autoRT_prediction/results/*.csv \
	> ./autoRT_prediction/results/${sample}_results.txt
	"""
}

process generate_percolator_input {

	tag "$sample"

	container "proteomics/pga:latest"

	publishDir "${output_path}/percolator_input/", mode: "copy", overwrite: true

	input:
	file (feature_file) from all_features_ch3
	file (rawPSMs_file) from pga_results_ch3
	file (autoRT_results_folder) from autoRT_results_ch
	set file(similarity_title_file), file(similarity_pair_file), file(similarity_SA_file) from similarity_ch

	output:
	file ("./format.pin") into percolator_input_ch

	script:
	"""
	Rscript ${baseDir}/bin/percolator/format_percolator_input.R $feature_file $rawPSMs_file \
		${autoRT_results_folder}/results/${sample}_results.txt $similarity_SA_file ./format.pin $software
	"""
}

process run_percolator {
	tag "$sample"

	container "bzhanglab/percolator:3.4"

	publishDir "${output_path}/percolator_results/", mode: "copy", overwrite: true

	input:
	file (percolator_input_file) from percolator_input_ch

	output:
	set file("${sample}_pep.txt"), file("${sample}_psms.txt") into percolator_output_ch

	script:
	"""
	percolator -r ${sample}_pep.txt -m ${sample}_psms.txt format.pin
	"""
}

process generate_pdv_input {
	tag "$sample"

	container "proteomics/pga:latest"	

	input:
	set file(pep_level_result), file(psm_level_result) from percolator_output_ch
	file (features_file) from all_features_ch4

	output:
	set file("${sample}_pep_pdv_input.txt"), file("${sample}_pep_pdv_input_fdr_1.txt") into pdv_input_ch

	script:
	"""
	Rscript ${baseDir}/bin/PDV/generate_pdv_input.R ./ $sample $features_file
	"""

}






