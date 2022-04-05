/*****************************************************************************
appendix_descriptives.do
*******************************************************************************/
// set working directory
cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\igm" 

		
/* Brief version */
		// Define program to create sum stat table */
		cap program drop mystats
		program mystats
			syntax varlist, name(string) [,nada]
			// open a file 
			cap file close myfile
			file open myfile using "output_files\\`name'.csv",replace write
			foreach v in `varlist' {
			qui: sum `v'  
				local s1: disp %4.2f r(mean) 
				local s2: disp %4.2f r(sd)  
				local s3: disp %5.2f r(min)  
				local s4: disp %5.2f r(max)  
				// Variable label 
				local label : variable label `v'
				// Write values to file 
				file write myfile";`label';`s1';`s2';`s3';`s4'" _n
			}
			// write N 
			if "`nada'"!=""{
				local s1: disp %7.0f r(mean)
					// Write Ns 
					qui: sum MN
				local s1: disp %7.0f r(mean)
				file write myfile";Observations;`s1'"
			}
			// close file
			file close myfile
		end


		// individual characteristics 
		u "data\data_temp\analysisdata.dta",clear
		bys i_Name: keep if _n==1
		gen MN=_N
		replace i_cites_all=i_cites_all/1000
		mystats i_US_sample i_us_phd  i_age  i_cites_all i_hi_all i_num_q i_numansw_q i_female, name("tab_simple_desc_experts")  nada
		// question characteristics 
		u "data\data_temp\analysisdata.dta",clear
		bys q_Question : keep if _n==1
		gen MN=_N
		mystats  q_theory_alt q_evidence_alt q_neither_alt  , name("tab_simple_desc_questions") nada
		// response 
		u "data\data_temp\analysisdata.dta",clear
		replace j_gives_opinion=1-j_didnotanswer
		gen MN=_N
		label var  j_anycomment "Any comment"
		mystats  j_expert j_strdisagree j_disagree j_uncertain j_agree j_stragree j_anycomment j_Confidence j_gives_opinion, name("tab_simple_desc_responses") nada

		