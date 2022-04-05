/*****************************************************************************
byfield.do: byfield
*******************************************************************************/
// set working directory
cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\igm" 

// Load data
u "data\data_temp\analysisdata.dta",clear   
replace j_gives_opinion=1-j_didnotanswer

gl absorb1  "i_inst i_phdyear"

egen a = sum(j_uncertain), by(q_id i_US_sample)
egen b = count(j_uncertain), by(q_id i_US_sample)
gen background=(a-j_uncertain)/(b-1)
replace background = a/b if background==.
gen fem_background = i_female*background
label var fem_background "Uncertainty X Female"

eststo clear
foreach y in j_gives_opinion  j_anycomment j_uncertain  j_extreme_judgement   j_Confidence{
	   
	eststo: reghdfe `y' i_female  background fem_background $controls,   absorb($absorb)
		lincom i_female+fem_background
	estadd scalar sum=r(estimate)
	estadd scalar pval=r(p)
}
esttab  using "output_files\\tab_main_reg_uncertain.rtf", ///
       b(%4.3f) noobs star(* 0.1 ** 0.05 *** 0.01) label  replace  nodepvar  nomtitles se	 ///
       stats( pval sum N r2, fmt(%4.2f %4.2f %10.0f %4.2f))
