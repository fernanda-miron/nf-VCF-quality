#!/usr/bin/env nextflow

/*Modulos de prueba para  nextflow */
results_dir = "./test/results"
intermediates_dir = "./test/results/intermediates"

process tmp_files {

publishDir "${results_dir}/tmp_files/", mode:"copy"

	input:
	file vcf

	output:
	path "*.df*"

	"""
	bcftools view -h ${vcf} | tail -1 | tail -c +2 > headers.tmp
	bcftools view -H ${vcf} > wheaders.tmp
	cat headers.tmp wheaders.tmp > ${vcf}.df2
	rm *.tmp

	bcftools view -H ${vcf} \
	| cut -f8 \
	| cut -d";" -f2 \
	| sed "s#=#\t#" > p1.tmp
	bcftools view -H ${vcf} \
	| cut -f3 > p2.tmp
	paste p1.tmp p2.tmp > ${vcf}.df1
	rm *.tmp
	"""
}

process filtering {

publishDir "${results_dir}/filtred_data/", mode:"copy"

	input:
	file quality_R
	file p1
	file snp_cutoff
	file id_cutoff


	output:
	path "*.png" , emit: all_plots
	path "ID.tsv", emit: all_id_tsv
	path "SNP.tsv", emit: all_snp_tsv

	"""
	mkdir dir_my_files
	mv ${p1} dir_my_files
	Rscript --vanilla quality.R ./dir_my_files "SNP.png" "ID.png" "ID.tsv" ${snp_cutoff} ${id_cutoff} "SNP.tsv"
	"""
}

process vcf_filter {

publishDir "${results_dir}/filtred_vcf/", mode:"copy"

	input:
	file vcf
	file id_file
	file snp_file


	output:
	path "*.vcf"

	"""
	vcftools --vcf ${vcf} \
	--keep ${id_file} --exclude ${snp_file} \
	--out ${vcf} --recode --keep-INFO-all
	"""
}

process final_check {

publishDir "${results_dir}/checking_data/", mode:"copy"

	input:
	file quality_R
	file p1
	file snp_cutoff
	file id_cutoff


	output:
	path "*.png" , emit: all_plots
	path "ID.tsv", emit: all_id_tsv
	path "SNP.tsv", emit: all_snp_tsv

	"""
	mkdir dir_my_files
	mv ${p1} dir_my_files
	Rscript --vanilla final_quality.R ./dir_my_files "SNP.png" "ID.png" "ID.tsv" ${snp_cutoff} ${id_cutoff} "SNP.tsv"
	"""
}
