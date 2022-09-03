# Repertoire Sequencing Workflow Automation Using Snakemake
[![Snakemake](https://img.shields.io/badge/snakemake-≥6.1.0-brightgreen.svg)](https://snakemake.github.io)
## Introduction
Repertoire sequencing (Rep-Seq) uses high-troughtput sequencing technologies to investigate the properties, dynamics and characteristics of adaptive immune responses against an acute immunogenic stimuli. This approache can unravel information on TCR or BCR repertoires. However, in this workflow, we focus on BCR repertoire data analysis only. 
## *Software* Requirements 
The *softwares* required to run this analysis are contained in a conda environment. If you don't have anaconda installed in your machine, a basic tutorial can be foud [here](https://www.digitalocean.com/community/tutorials/how-to-install-the-anaconda-python-distribution-on-ubuntu-20-04). Otherwise, you can simply import the enviroment in this repository that I've already made using:
```sh
conda env create --file environment.yaml # Create repseq environment
conda activate repseq # enters the recently created environment
```
## Snakemake Run
To run our analysis we'll need to execute the ```snakefile``` containing all the Rep-Seq steps. In your terminal, use:
```sh
snakemake -s snakefile -j 8
```