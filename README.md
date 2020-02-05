# DeepRescore
## Overview
**DeepRescore: a novel immunopeptidomics data analysis tool that leverages deep learning-derived peptide features to rescore peptide-spectrum matches (PSMs).**

DeepRescore requires two input files: 

  1. Search engine searching result file; 
  2. Spectrum file.

## Installation
1. Download DeepRescore:
```sh
git clone https://github.com/bzhanglab/DeepRescore
```
2. Install [Docker](https://docs.docker.com/install/) (>=19.03).

3. Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html). More information can be found in the Nextflow [get started](https://www.nextflow.io/docs/latest/getstarted.html) page.

4. Download [pDeep2](https://github.com/pFindStudio/pDeep/tree/master/pDeep2). And please configure pDeep2 as instruction.

## Usage
Users can modify all arguments in `nextflow.config` file.
```groovy
params {
        sample = "A1101"
        software = "comet" //msgf;xtandem;maxquant
        result_file = "/data/A1101.pep.xml"
        spectrum_file = "/data/A1101.mgf"
        output_path = "/data/output/"
        
        pDeep2_path = "/data/pDeep2/"
        instrument = "Lumos"
        energy = 0.34

        memory = 16 //In GB
        threads = 12
}
```
## Input
DeepRescore now supports four search engines: Comet, MS-GF+, X!Tandem and MaxQuant. As each seach engine has different input and output format, DeepRescore requires input files in different formats according to the search engine.

| search engine | seaching results format | spectrum file format |
|---|---|---|
| Comet | .pepxml | .mgf |
| MS-GF+ | .mzid | .mgf |
| X!Tandem | .mzid | .mgf |
| MaxQuant | /conbined/ | /conbined/generatesMGF/|

Notes:
  1. X!Tandem outputs results in `.xml` in default. We recommand users convert it to .mzid by [**mzidlib**](https://github.com/PGB-LIV/mzidlib).
  2. MaxQuant outputs results and intermediate files into `combined` folder. DeepRescore could generate MGF files by these intermediate files in `combined` names `generatesMGF`.

##  Example data

The test data used for above examples can be downloaded by clicking [test data ](http://pdv.zhang-lab.org/data/download/deeprescore_example_data/example_data.tar.gz). 
