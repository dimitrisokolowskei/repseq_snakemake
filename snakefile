configfile: "config.yaml"

WORK_DATA = config["WORK_DATA"]

rule all:
  input:
    expand(WORK_DATA + "{sample}_{read}_quality-pass.fastq", sample=config["samples"], read=[1, 2]),
    expand(WORK_DATA + "{sample}_{read}_primers-pass.fastq", sample=config["samples"], read=[1, 2]),
    expand(WORK_DATA + "{sample}_{read}_primers-pass_pair-pass.fastq", sample=config["samples"], read=[1, 2]),
    expand(WORK_DATA + "{sample}_{read}_consensus-pass.fastq", sample=config["samples"], read=[1, 2]),
    expand(WORK_DATA + "{sample}_{read}_consensus-pass_pair-pass.fastq", sample=config["samples"], read=[1, 2]),
    expand(WORK_DATA + "{sample}_assemble-pass.fastq", sample=config["samples"]),
    expand(WORK_DATA + "{sample}*reheader.fastq", sample=config["samples"]),
    expand(WORK_DATA + "{sample}_collapse-unique.fastq", sample=config["samples"]),
    expand(WORK_DATA + "{sample}_atleast-2.fastq", sample=config["samples"])
     

rule filter:
  input:
    WORK_DATA + "{sample}_{read}.fastq"      
  
  output:
    WORK_DATA + "{sample}_{read}_quality-pass.fastq"

  threads:
    8
  
  priority:
    100  
  
  params:
    outname="{sample}_{read}"
  
  shell:
    "FilterSeq.py quality -s {input} -q 20 --outname {params.outname} --log FS{wildcards.read}.log"


rule mask:
  input:
   R1 = WORK_DATA + "{sample}_1_quality-pass.fastq",
   R2 = WORK_DATA + "{sample}_2_quality-pass.fastq"
  
  output:
    WORK_DATA + "{sample}_{read}_primers-pass.fastq"

  threads:
    8
  
  priority:
    90
  
  params:
    outname1 = "{sample}_1",
    outname2 = "{sample}_2"


  shell:
    "MaskPrimers.py score -s {input.R1} -p c_primers.fasta --start 15 --mode cut --barcode --outname {params.outname1} --log MP1.log\n"
    "MaskPrimers.py score -s {input.R2} -p v_primers.fasta --start 0 --mode mask --barcode --outname {params.outname2} --log MP2.log"


rule pair1:
  input:
    R1 = WORK_DATA + "{sample}_1_primers-pass.fastq",
    R2 = WORK_DATA + "{sample}_2_primers-pass.fastq"
  
  output:
    WORK_DATA + "{sample}_{read}_primers-pass_pair-pass.fastq"
  
  threads:
    8

  priority:
    80 

  shell:
    "PairSeq.py -1 {input.R1} -2 {input.R2} --1f BARCODE --coord sra"


rule consensus:
  input:
    R1 = WORK_DATA + "{sample}_1_primers-pass_pair-pass.fastq",
    R2 = WORK_DATA + "{sample}_2_primers-pass_pair-pass.fastq" 
  
  output:
    WORK_DATA + "{sample}_{read}_consensus-pass.fastq"
  
  threads:
    8
  
  priority:
    70
  
  params:
    outname1 = "{sample}_1",
    outname2 = "{sample}_2"
  
  shell:
    "BuildConsensus.py -s {input.R1} --bf BARCODE --pf PRIMER --prcons 0.6 --maxerror 0.1 --maxgap 0.5 --outname {params.outname1} --log BC1.log\n"
    "BuildConsensus.py -s {input.R2} --bf BARCODE --pf PRIMER --maxerror 0.1 --maxgap 0.5 --outname {params.outname2} --log BC2.log"


rule pair2: 
  input:
    R1 = WORK_DATA + "{sample}_1_consensus-pass.fastq",
    R2 = WORK_DATA + "{sample}_2_consensus-pass.fastq" 
  
  output:
    WORK_DATA + "{sample}_{read}_consensus-pass_pair-pass.fastq"#Rolando problema aqui (arquivos sem conteúdo)
  
  threads:
    2

  priority:
    60 

  shell:
    "PairSeq.py -1 {input.R1} -2 {input.R2} --coord presto"

rule assemble:
  input:
    R1 = WORK_DATA + "{sample}_1_consensus-pass_pair-pass.fastq",
    R2 = WORK_DATA + "{sample}_2_consensus-pass_pair-pass.fastq",
  
  output:
    WORK_DATA + "{sample}_assemble-pass.fastq"
  
  threads:
    8
  
  priority:
    50
  
  params:
    "{sample}"
  
  shell:
    "AssemblePairs.py align -1 {input.R2} -2 {input.R1} --coord presto --rc tail --1f CONSCOUNT --2f CONSCOUNT PRCONS --outname {params} --log AP.log"

rule parse:
  input:
    WORK_DATA + "{sample}_assemble-pass.fastq"
  
  output:
    WORK_DATA + "{sample}*reheader.fastq"
  
  threads:
    8
  
  priority:
    40
  
  shell:
    "ParseHeaders.py collapse -s {input} -f CONSCOUNT --act min"    


rule collapse:
  input:
    WORK_DATA + "{sample}*reheader.fastq"
  
  output:
    WORK_DATA + "{sample}_collapse-unique.fastq"
  
  threads:
    8
  
  priority:
    30
  
  params:
    "{sample}"
  
  shell:
    "CollapseSeq.py -s {input} -n 20 --inner --uf PRCONS --cf CONSCOUNT --act sum --outname {params}"

rule split:
  input:
    WORK_DATA + "{sample}_collapse-unique.fastq"
  
  output:
    WORK_DATA + "{sample}_atleast-2.fastq"
  
  threads:
    8
  
  priority:
    20
  
  params:
    "{sample}"

  shell:
    "SplitSeq.py group -s {input} -f CONSCOUNT --num 2 --outname {params}"        