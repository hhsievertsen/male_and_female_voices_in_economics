/*****************************************************************************
byfield.do: byfield
*******************************************************************************/
// set working directory
*cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\igm" 
cd  "C:\Users\ecsls\Dropbox\igm\analysis\igm\"

// Load data
u "data\data_temp\analysisdata.dta",clear   
replace j_gives_opinion=1-j_didnotanswer
// Define field
gen femfield = q_lab==1|q_pub==1|q_dev==1|q_io==1
gen femfieldXfemale= i_female*femfield
label var femfieldXfemale "Female X female field"
// regressionses
eststo clear
foreach y in j_gives_opinion  j_anycomment j_uncertain  j_extreme_judgement   j_Confidence{
	eststo: reghdfe  `y'     i_female   femfieldXfemale $controls j_expert, absorb($absorb) cluster(q_Question) 
	lincom i_female+femfieldXfemale
	estadd scalar sum=r(estimate)
	estadd scalar pval=r(p)

}
	esttab  using "output_files\\tab_main_reg_byfemfield.rtf", ///
       b(%4.3f) noobs star(* 0.1 ** 0.05 *** 0.01) label  replace  nodepvar  nomtitles se	 ///
       stats( pval sum N r2, fmt(%4.2f %4.2f %10.0f %4.2f))
