/*****************************************************************************
descriptives.do: descriptive stats
*******************************************************************************/
// set working directory
cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\igm" 

/* Full version with test*/
		// Define program to create sum stat table */
		cap program drop mystats
		program mystats
			syntax varlist, name(string) [,nada]
			// open a file 
			cap file close myfile
			file open myfile using "output_files\\`name'.csv",replace write
			foreach v in `varlist' {
				// Female
				qui: sum `v'  if i_female==1
				local s1: disp %4.2f r(mean) 
				local s2: disp %4.2f r(sd)  
				// Male
				qui: sum `v'  if i_female==0
				local s3: disp %4.2f r(mean) 
				local s4: disp %4.2f r(sd)  
				// t test
				qui: ttest `v',by(i_female)
				local s5: disp %4.2f r(p) 
				// Variable label 
				local label : variable label `v'
				// Write values to file 
				file write myfile";`label';`s1';`s2';`s3';`s4';`s5'" _n
			}
			// write N 
			if "`nada'"!=""{
				qui: sum MN if i_female==1
				local s1: disp %7.0f r(mean)
				qui: sum MN if i_female==0
				local s2: disp %7.0f r(mean)
					// Write Ns 
				file write myfile";Observations;`s1';;`s2'"
			}
			// close file
			file close myfile
		end


		// individual characteristics 
		u "data\data_temp\analysisdata.dta",clear
		replace j_gives_opinion=1-j_didnotanswer
		bys i_Name: keep if _n==1
		bys i_female: gen MN=_N
		mystats i_US_sample  i_age  i_cites_all i_num_q i_numansw_q, name("tab_desc_experts")  nada
		// question characteristics 
		u "data\data_temp\analysisdata.dta",clear
		replace j_gives_opinion=1-j_didnotanswer
		bys i_Name: replace i_num_q=. if _n>1
		bys i_female: egen MN=mean(i_num_q)
		*bys q_Question i_female: keep if _n==1
		mystats  q_theory_alt q_evidence_alt q_neither_alt  , name("tab_desc_questions") nada
		// response 
		u "data\data_temp\analysisdata.dta",clear
		replace j_gives_opinion=1-j_didnotanswer
		bys i_female: gen MN=_N
		label var  j_anycomment "Any comment"
		mystats   j_expert j_strdisagree j_disagree j_uncertain j_agree j_stragree j_anycomment j_Confidence j_gives_opinion, name("tab_desc_responses") nada
	