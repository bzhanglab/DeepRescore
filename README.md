# [DeepRescore](https://doi.org/10.1002/pmic.201900334)
## Overview
**DeepRescore** is an immunopeptidomics data analysis tool that leverages deep learning-derived peptide features to rescore peptide-spectrum matches (PSMs). DeepRescore takes as input MS/MS data in MGF format and identification results from a search engine. The current version supports four search engines, [MS-GF+](https://github.com/MSGFPlus/msgfplus), [Comet](http://comet-ms.sourceforge.net/), [X!Tandem](https://www.thegpm.org/TANDEM/), and [MaxQuant](https://maxquant.org/).

## Installation
1. Download DeepRescore:
```sh
git clone https://github.com/bzhanglab/DeepRescore
```
2. Install [Docker](https://docs.docker.com/install/) (>=19.03).

3. Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html). More information can be found in the Nextflow [get started](https://www.nextflow.io/docs/latest/getstarted.html) page.

4. Install [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) (>=2.2.2) for [**AutoRT**](https://github.com/bzhanglab/AutoRT/)  and [**pDeep2**](https://github.com/pFindStudio/pDeep/tree/master/pDeep2) by following the instruction at [https://github.com/NVIDIA/nvidia-docker](https://github.com/NVIDIA/nvidia-docker). **Please note GPU is required to run DeepRescore**.

All other tools used by DeepRescore have been dockerized and will be automatically installed when DeepRescore is run in the first time on a computer. DeepRescore has been tested on Linux.

## Usage

```sh
○ → nextflow run DeepRescore.nf --help
N E X T F L O W  ~  version 19.10.0
Launching `deeprescore.nf` [special_hamilton] - revision: 2817bc64da
=========================================
DeepRescore => Rescore PSMs
=========================================
Usage:
nextflow run DeepRescore.nf
Arguments:
  --id_file              Identification result.
  --ms_file              MS/MS data in MGF format. If the search engine is MaxQuant, this parameter is not useful.
  --se                   The name of search engine, msgf:MS-GF+, xtandem:X!Tandem, comet:Comet or maxquant:MaxQuant.
                         Default is "msgf" (MS-GF+).
  --ms_instrument        The MS instrument used to generate the MS/MS data. 
                         This is used by pDeep2 for MS/MS spectrum prediction. Default is "Lumos".
  --ms_energy            The energy used in MS/MS data generation. 
                         This is used by pDeep2 for MS/MS spectrum prediction. Default is 0.34.
  --out_dir              Output folder, default is "./output"
  --prefix               The prefix of output file(s).
  --decoy_prefix         The prefix of decoy proteins. Default is "XXX_".
  --cpu                  The number of CPUs
  --mem                  The memory for processing the data, default is 8. The unit is G.
  --help                 Print help message

```

### Input
In general, the main inputs to run DeepRescore are identification result from one of the four search engines (MS-GF+, X!Tandem, Comet and MaxQuant) and the MS/MS data used for searching. If the identification software is MaxQuant, then the MS/MS data is not needed because MS/MS data is included in MaxQuant search result ( folder ``conbined``). Below is the table showing the detailed search result format and MS/MS data format supported for each search engine. Using MS-GF+, X!Tandem or Comet, raw MS/MS data must be converted to MGF format using [ProteoWizard](http://www.proteowizard.org/). Multiple MGF files (different fractions) from the sample or same TMT/iTRAQ experiment should be combined into one MGF file. Only oxidation of M is supported as variable modification. Please note if DeepRescore is used to rescore MaxQuant result, the FDR cutoff should be set as 100% when performing the MaxQuant search, otherwise target PSMs may be filtered by MaxQuant's FDR calculation before rescoring using DeepRescore.

| Search engine | Identification format | MS/MS data format |
|---|---|---|
| Comet | .pepxml | MGF |
| MS-GF+ | .mzid | MGF |
| X!Tandem | .xml | MGF |
| MaxQuant | /conbined/ | - |

Below is an example:
```sh
nextflow run DeepRescore.nf --id_file ./example_data/A1101.pep.xml \
	--ms_file ./example_data/A1101.mgf \
	--se comet \
	--ms_instrument Lumos \
	--ms_energy 0.34 \
	--out_dir out \
	--prefix d2 \
	--decoy_prefix XXX_ \
	--cpu 4 \
	--mem 8
```
It took about one and half hour to run the example on a Linux server (12 threads, 64 RAM, GPU: TITAN Xp). The example data can be downloaded through this link: [test_data](http://pdv.zhang-lab.org/data/download/deeprescore/example_data.tar.gz).

### Output
The final output data can be found in this folder `out_dir/DeepRescore_results`. Here `out_dir` is the output directory specified through parameter `--out_dir`. There are two files in this folder: `*_psm_final.tsv` and `*_pep_final.tsv`. The first one is the result controled FDR at PSM level and the second one is the result controled FDR at peptide level. Below is an example of `*_psm_final.tsv`. The format of `*_pep_final.tsv` is the same with `*_psm_final.tsv`. Users can filter the result based on the column `q-value` (for example, q-value <= 0.01). The result files (`*_psm_final.tsv` or `*_pep_final.tsv` + `the MS/MS data in MGF format`) can be imported into [**PDV**](https://github.com/wenbostar/PDV) for visualization.

| spectrum_title                                           | Percolator_score | q_value     | modification                  | Mod_Sequence             | Label | RT     | Mass             | Abs_Mass_Error | Ln_Total_Intensity | Match_Ions_Intensity | Rel_Match_Ions_Intensity | Max_Match_Ion_Intensity | Score  | Pep         | Delta_Score | charge | peptide                  | Proteins              | Delta_RT          | SA                | mz               |
|----------------------------------------------------------|------------------|-------------|-------------------------------|--------------------------|-------|--------|------------------|----------------|--------------------|----------------------|--------------------------|-------------------------|--------|-------------|-------------|--------|--------------------------|-----------------------|-------------------|-------------------|------------------|
| YE_20180517_SK_HLA_A1101_3Ips_a50mio_R1_02.25098.25098.2 | 1.43274          | 5.43478e-05 | Carbamidomethyl of C@23[0.0]; | QVADEGDALVAGGVSQTPSYLSCK | 1     | 59.187 | 2451.16256793088 | 0              | 14.0435918544821   | 11.9698824268126     | 0.125718571751381        | 24026.38671875          | 339.58 | 4.3576e-114 | 283.38      | 2      | QVADEGDALVAGGVSQTPSYLSCK | uc003kfu.4            | 0.130932000000001 | 0.775038384865853 | 1226.58908396544 |
| YE_20180517_SK_HLA_A1101_3IPs_a50mio_R1_01.21936.21936.3 | 1.36464          | 5.43478e-05 | -                             | PLFVNVNDQTNEGIMHESK      | 1     | 52.926 | 2171.03328724    | 0              | 16.183782828437    | 15.7096998670651     | 0.622455610654202        | 520227.46875            | 268.55 | 1.5772e-35  | 235.24      | 3      | PLFVNVNDQTNEGIMHESK      | uc010fur.3;uc002vee.4 | 0.23695           | 0.669018716842519 | 724.685562413335 |
| YE_20180517_SK_HLA_A1101_3Ips_a50mio_R2_01.21952.21952.3 | 1.34864          | 5.43478e-05 | -                             | PLFVNVNDQTNEGIMHESK      | 1     | 52.495 | 2171.03151690128 | 0              | 14.6959014960537   | 14.1948714045837     | 0.605906199334659        | 119562.108398438        | 284.15 | 1.4821e-46  | 248.85      | 3      | PLFVNVNDQTNEGIMHESK      | uc010fur.3;uc002vee.4 | 0.855877999999997 | 0.677688435645182 | 724.684972300427 |
| AC20171011_Broad_HLA_A1101_R1_Rep01.3055.3055.3          | 1.32707          | 5.43478e-05 | -                             | RTLDAKMPRK               | 1     | 11.999 | 1214.69196592591 | 0              | 15.3894885906454   | 14.7015468520804     | 0.502609506923564        | 815314.75               | 201.84 | 0.0048553   | 201.84      | 3      | RTLDAKMPRK               | uc003lvo.4;uc021ygh.2 | 0.168488          | 0.884456468503026 | 405.905121975303 |
| YE_20180517_SK_HLA_A1101_3IPs_a50mio_R1_01.19078.19078.2 | 1.29334          | 5.43478e-05 | -                             | GILAADESVGTMGNR          | 1     | 46.712 | 1489.71904591213 | 0              | 15.0714146779268   | 14.7645814265636     | 0.735773279870115        | 423094.538085938        | 305.7  | 1.1819e-36  | 222.7       | 2      | GILAADESVGTMGNR          | uc004bbk.2            | 0.180505999999994 | 0.862802817911802 | 745.867322956064 |



## How to cite:

Kai Li, Antrix Jain, Anna Malovannaya, Bo Wen, Bing Zhang (2020), **DeepRescore: Leveraging Deep Learning to Improve Peptide Identification in Immunopeptidomics**. *Proteomics*. [doi:10.1002/pmic.201900334](https://doi.org/10.1002/pmic.201900334)



