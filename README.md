# DeepRescore
## Overview
**DeepRescore** is an immunopeptidomics data analysis tool that leverages deep learning-derived peptide features to rescore peptide-spectrum matches (PSMs). DeepRescore takes as input MS/MS data in MGF format and identification results from a search engine. The current version supports four search engines, MS-GF+, Comet, X!Tandem, and MaxQuant.

## Installation
1. Download DeepRescore:
```sh
git clone https://github.com/bzhanglab/DeepRescore
```
2. Install [Docker](https://docs.docker.com/install/) (>=19.03).

3. Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html). More information can be found in the Nextflow [get started](https://www.nextflow.io/docs/latest/getstarted.html) page.

4. Install [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) (>=2.2.2) for [**AutoRT**](https://github.com/bzhanglab/AutoRT/)  and [**pDeep2**](https://github.com/pFindStudio/pDeep/tree/master/pDeep2) by following the instruction at [https://github.com/NVIDIA/nvidia-docker](https://github.com/NVIDIA/nvidia-docker). **Please note GPU is required to run DeepRescore**.

All other tools used by DeepRescore have been dockerized and will be automatically installed when DeepRescore is run in the first time on a computer.

## Usage

```sh
○ → nextflow run deeprescore.nf --help
N E X T F L O W  ~  version 19.10.0
Launching `deeprescore.nf` [special_hamilton] - revision: 2817bc64da
=========================================
DeepRescore => Rescore PSMs
=========================================
Usage:
nextflow run neoflow_db.nf
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
In general, the main inputs to run DeepRescore are identification result from one of the four search engines (MS-GF+, X!Tandem, Comet and MaxQuant) and the MS/MS data used for searching. If the identification software is MaxQuant, then the MS/MS data is not needed because MS/MS data is included in MaxQuant search result ( folder ``conbined``). Below is the table showing the detailed search result format and MS/MS data format supported for each search engine. Using MS-GF+, X!Tandem or Comet, raw MS/MS data must be converted to MGF format using [ProteoWizard](http://www.proteowizard.org/). Multiple MGF files (different fractions) from the sample or same TMT/iTRAQ experiment should be combined into one MGF file.

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
The example data can be downloaded through this link: [test_data](http://pdv.zhang-lab.org/data/download/deeprescore/example_data.tar.gz).

### Output
The final output data can be found in this folder `out_dir/percolator_results`. Here `out_dir` is the output directory specified through parameter `--out_dir`. There are two files in this folder: `*_psm.txt` and `*_pep.txt`. The first one is the result controled FDR at PSM level and the second one is the result controled FDR at peptide level. Below is an example of `*_psm.txt`. The format of `*_pep.txt` is the same with `*_psm.txt`. Users can filter the result based on the column `q-value` (for example, q-value <= 0.01).

| PSMId | score | q-value | posterior_error_prob | peptide | proteinIds |
|---|---|---|---|---|---|
|YE_20180517_SK_HLA_A1101_3Ips_a50mio_R1_02.26820.26820.3 | 1.58533 | 0.000156838 | 2.97782e-12 | CEMASTGEVACFGEGIHTAFLK | uc010fur.3;uc002vee.4;uc010fus.3 |
|YE_20180517_SK_HLA_A1101_3IPs_a50mio_R1_01.26601.26601.3 | 1.40512 | 0.000156838 | 5.33093e-11 | CEMASTGEVACFGEGIHTAFLK | uc010fur.3;uc002vee.4;uc010fus.3 |
|YE_20180517_SK_HLA_A1101_3Ips_a50mio_R2_02.28378.28378.3 | 1.38068 | 0.000156838 | 7.88358e-11 | CEMASTGEVACFGEGIHTAFLK | uc010fur.3;uc002vee.4;uc010fus.3 |
|YE_20180517_SK_HLA_A1101_3Ips_a50mio_R2_02.26477.26477.3 | 1.32079 | 0.000156838 | 2.05665e-10 | CEMASTGEVACFGEGIHTAFLK | uc010fur.3;uc002vee.4;uc010fus.3 |
|YE_20180517_SK_HLA_A1101_3Ips_a50mio_R1_02.22105.22105.3 | 1.23946 | 0.000156838 | 7.56194e-10 | PLFVNVNDQTNEGIMHESK | uc010fur.3;uc002vee.4 |



