/*****************************************************************************
data_build.do: prep data for igm analysis
*******************************************************************************/
// set working directory
cd  "C:/Users/hs17922/Dropbox/Work/Research/Projects/14 igm/analysis/igm" 
*cd  "C:/Users/ecsls/Dropbox/igm/analysis/igm"

 *cd "/Users/hhs/Dropbox/Work/Research/Projects/14 igm/analysis/igm"

/*****************************************************************************
1) merge datasets 
*******************************************************************************/
	//  temporary datasets (only used for this part)
		tempfile data1 data2
	//	(A) load scraped data 
		* load scraped questions us
		use "data/data_scraped/cleaned_data_US.dta",clear
		save `data1',replace
		* load scraped questions eu
		use "data/data_scraped/cleaned_data_EU.dta",clear
		* append datasets
		append using `data1'
		save `data1', replace
	// (B) load question field data
		import excel "data/data_manual/igm_qfield_sarah.xlsx", sheet("Sheet1") clear firstrow
		keep dev_ec int_ec fin_ec io_ec lab_ec pub_ec mac_ec Qtext
		merge 1:m Qtext using `data1',nogen
		save `data1', replace
	// (C) load question type data
		* Sarah and Hans
		import excel "data/data_manual/igm_qtype_sarah.xlsx", sheet("Sheet1") clear firstrow
		keep distrib efficiency neither evidence theory Qtext covid19
		merge 1:m Qtext using `data1',nogen
		save `data1', replace
		* Ali and Arpad 
		merge m:1 Qtext using  "data/data_manual/igm_macroopions.dta" ,nogen
		save `data1', replace
	// (D) load unique question identifier
		import excel "data/data_manual/igm_unique_questions_renaming_european_questions.xlsx", sheet("Sheet1") clear firstrow
		merge 1:m Qtext using `data1',nogen keep(3)
		save `data1', replace
	// (E) load expert data
		rename Name name
		merge m:1 name using "data/data_manual/IGMpeople.dta",nogen
		* rename
		save `data1', replace
	// (F) load Gordohn and Dahl (2013) identifiers
		import excel "data/data_manual/igm_gd_match.xlsx", sheet("Sheet1") firstrow clear
		foreach var in Topic  date litsize qfield1 qfield2 qfield3 redistribute markets conservative {
			rename `var' gd_`var'
		}
		merge 1:m Qtext using `data1', keep(3 2)
		gen q_gd_sample=_merge==3
		drop _merge
		save `data1', replace
	// (G) add question date
		import excel "data/data_manual/unique_qs_with_id.xlsx", sheet("Sheet1") firstrow clear
		rename q_Question_old Qtext
		destring q_date,replace force
		generate statadate = q_date + td(30dec1899)
		format statadate %td
		drop q_date
		rename statadate q_date
		merge 1:m Qtext using `data1', keep(3 2) nogen
	// cleaning
		drop Question
		encode Qtext_new, generate(Question)
		encode Qtext, generate(Question_old)
		egen q_Question_id=group(Question)
		encode Qtext, generate(Question_original)
		drop Qtext_new Qtext Question_ID 
		rename name Name
		rename us US_sample
		replace Confidence=10 if Confidence==11
/*****************************************************************************
2) question characteristics 
*******************************************************************************/
	// rename fields
	foreach x in dev int fin io lab pub mac{
		ren `x'_ec q_`x'
	}
	ren q_int q_inter
	// set missing
	foreach x in theory evidence neither efficiency distrib q_dev q_inter q_fin q_io q_lab q_pub q_mac{
		replace `x' = 0 if `x'==.
	}
	// indicator for question type
	gen  q_qtype = 1 if theory==1
	replace  q_qtype = 2 if evidence==1
	replace  q_qtype = 3 if neither==1
	label def qtype 1 "Theory" 2 "Evidence" 3 "Neither"
	label values  q_qtype qtype
	// including views by colleagues
		foreach v in "" "_ali" "_arpad"{
		destring theory`v' evidence`v' neither`v',replace
		replace theory`v'=0 if theory`v'==.
		replace evidence`v'=0 if evidence`v'==.
		replace neither`v'=0 if neither`v'==.
	}
	gen theory_sum=theory+theory_ali+theory_arpad
	gen evidence_sum=evidence+evidence_ali+evidence_arpad
	gen neither_sum=neither+neither_ali+neither_arpad
	// all agree 
	gen qtype_alt=1 if theory_sum==3
	replace qtype_alt=2 if evidence_sum==3
	replace qtype_alt=3 if neither_sum==3
	gen qtype_alt_w=3 if qtype_alt!=.
	// two of us agree 
	replace qtype_alt=1 if theory_sum==2
	replace qtype_alt=2 if evidence_sum==2
	replace qtype_alt=3 if neither_sum==2
	replace qtype_alt_w=2 if qtype_alt!=. & qtype_alt_w==.
	// no majority, so we use Sarah and Hans 
	replace qtype_alt=1 if theory==1 & qtype_alt==.
	replace qtype_alt=2 if  evidence==1 & qtype_alt==.
	replace qtype_alt=3 if neither==1 & qtype_alt==.
	replace qtype_alt_w=1 if qtype_alt!=. & qtype_alt_w==.
	label values qtype_alt qtype
	// correct confidence
	// rename variables
	foreach v in theory evidence neither efficiency distrib qtype_alt_w qtype_alt covid19 theory_arpad evidence_arpad neither_arpad theory_ali evidence_ali neither_ali renamed gd_Topic gd_date gd_litsize gd_qfield1 gd_qfield2 gd_qfield3 gd_redistribute gd_markets gd_conservative {
		rename `v' q_`v'
	}
/*****************************************************************************
3) expert characteristics 
*******************************************************************************/
	
	// Expert field: NBER
	foreach v in AG AP CF CH DAE DEV ED EFG EEE HC IFM ITI IO LE LS ME PE POL PR{
		cap gen byte i_`v'=0
		forval i=1/7{
			replace i_`v'=1 if nber`i'=="`v'"
		}
	}
	// Expert field: CEPR
	foreach v in DE EH FE IMF IO IT LE MEF MG PE{
		cap gen byte i_C_`v'=0
		forval i=1/6{
			replace i_C_`v'=1 if cepr`i'=="`v'"
		}
	}
	// looking at how NBER codes map to CEPR codes - for the people who have both
	foreach x in AG AP CF CH DAE DEV ED EFG EEE HC IFM ITI IO LE LS ME PE POL PR{
		di "Subject is NBER `x' "
		su i_C_DE i_C_EH i_C_FE i_C_IMF i_C_IO i_C_IT i_C_LE i_C_MEF i_C_MG i_C_PE if i_`x'==1
	}

	/* creating a narrower set of six fields - first for NBER separately, then for 
	CEPR separately - to see how they map within network - then combining */
	// NBER
	gen i_dev = i_DEV==1|i_POL==1|i_EEE==1
	gen i_inter = i_IFM==1|i_ITI==1
	gen i_fin = i_AP==1|i_CF==1
	gen i_io  = i_IO==1|i_PR==1
	gen i_lab = i_LS==1|i_ED==1
	gen i_pub = i_AG==1|i_PE==1|i_HC==1|i_CH==1|i_EEE==1
	gen i_mac = i_EFG==1|i_ME==1
	// CEPR
	gen i_cdev = i_C_DE==1
	gen i_cinter = i_C_IMF==1|i_C_IT==1
	gen i_cfin = i_C_FE==1
	gen i_cio  = i_C_IO==1
	gen i_clab = i_C_LE==1
	gen i_cpub = i_C_PE
	gen i_cmac = i_C_MEF==1|i_C_MG==1
	// Create  NBER and CEPR indicators 
	encode nber1, gen(temp)
	gen i_NBER = temp!=.
	drop temp
	encode cepr1, gen(temp)
	gen i_CEPR = temp!=.
	drop temp
	tab i_NBER i_CEPR
	/* looking at how the broader fields map */
	foreach x in dev inter fin io lab pub mac{
		tab i_`x' i_c`x' if i_NBER==1&i_CEPR==1
	}
	replace i_dev = 1 	if i_dev==0 & i_cdev==1
	replace i_inter = 1 if i_inter==0 & i_cinter==1
	replace i_fin = 1 	if i_fin==0 & i_cfin==1
	replace i_io  = 1 	if i_io==0  & i_cio==1
	replace i_lab = 1 	if i_lab==0 & i_clab==1
	replace i_pub = 1 	if i_pub==0 & i_cpub==1
	replace i_mac = 1 	if i_mac==0 & i_cmac==1
	/* and how many people are classified for each field - out of the 94 people for whom we observe at least one affiliation */ 
	tab i_dev
	tab i_inter
	tab i_fin
	tab i_io
	tab i_lab
	tab i_pub
	tab i_mac
	/* now code the people who don't have an affiliation */

			   /*Aaron Edlin io
		 Agnès Bénassy-Quéré int mac
		  Canice Prendergast io
			   Cecilia Rouse lab 
				 Eric Maskin io pub
				  Ernst Fehr io pub lab
			 Larry Samuelson io pub
			  Martin Hellwig pub mac
					Ray Fair mac
		 Richard Schmalensee io*/
		 
		 replace i_inter = 1 if Name=="Agnès Bénassy-Quéré"
		 replace i_io = 1  if Name=="Aaron Edlin" | Name=="Canice Prendergast" | Name=="Eric Maskin" | Name=="Ernst Fehr" | Name=="Larry Samuelson" | Name == "Richard Schmalensee"
		 replace i_lab = 1 if Name=="Cecilia Rouse" | Name=="Ernst Fehr"
		 replace i_pub = 1 if Name=="Ernst Fehr" | Name=="Eric Maskin" | Name=="Larry Samuelson" | Name=="Martin Hellwig"
		 replace i_mac = 1 if Name=="Agnès Bénassy-Quéré" | Name=="Ray Fair" | Name=="Martin Hellwig"		 
	// tidy up
	forval i=1/7{
			cap rename nber`i' i_nber`i'
			cap rename cepr`i' i_cepr`i'
			}

			
	// expert characteristics 
		gen j_expert = 0
		foreach x in dev inter fin io lab pub mac{
		replace j_expert  = 1 if j_expert ==0 & i_`x'==1 & q_`x'==1
		}
		label def expert 0 "Non-expert" 1 "Expert"
		label values j_expert expert
	// generating female dummy 
		gen i_female=gender=="f"
		drop gender
		label def female 0 Male 1 Female
		label values i_female female
	// expert id  & name*/
		encode Name, gen(i_id)
		rename Name i_Name
	// cleaning up Institution coding 
		rename institution Institution
		replace Institution = "LSE" if Institution=="London School of Economics"
		replace Institution = "University of Oxford" if Institution=="Oxford"
		replace Institution = "Goethe University Frankfurt" if Institution=="Goethe-Universität Frankfurt"
		replace Institution = "Chicago" if Institution=="Chicago Booth"
		replace Institution = "University of Zurich" if Institution=="Universität Zurich"
		encode Institution, gen(i_inst)
		rename Institution i_Institution
	// two people don't have phds - replace with year of first job and year of MPhil 
		replace phdyear = 1975 if i_Name=="Richard William Blundell"
		replace phdyear = 1982 if i_Name=="Luigi Guiso"
		gen i_age = 2020 - phdyear
		gen i_age2 = i_age^2
		rename phdyear i_phdyear
	/* 14 people don't have cites/ h_indices
		edlin	agnes	homstr 	prende	rouse	goldin	lazear	maskin	stock	samuel	stokey	hart	de gra	fair
		3708	5294	62208	10599	13441	28909	34119	34090	92597	16509	19377	77085	18083	12217
		26	    39		54		27		48		69		49		68		91		59		30		71		62		53  */
	// dummies to denote imputed data 
		gen hi_cal = hi_all==.
		gen cites_cal = cites_all==.
		replace hi_all = 26 if i_Name=="Aaron Edlin"
		replace cites_all = 3708 if i_Name=="Aaron Edlin"
		replace hi_all = 39 if i_Name=="Agnès Bénassy-Quéré"
		replace cites_all = 5294 if i_Name=="Agnès Bénassy-Quéré"
		replace hi_all = 54 if i_Name=="Bengt Holmström"
		replace cites_all = 62208 if i_Name=="Bengt Holmström"
		replace hi_all = 27 if i_Name=="Canice Prendergast"
		replace cites_all = 10599 if i_Name=="Canice Prendergast"
		replace hi_all = 48 if i_Name=="Cecilia Rouse"
		replace cites_all = 13441 if i_Name=="Cecilia Rouse"
		replace hi_all = 69 if i_Name=="Claudia Goldin"
		replace cites_all = 28909 if i_Name=="Claudia Goldin"
		replace hi_all = 49 if i_Name=="Edward Lazear"
		replace cites_all = 34119 if i_Name=="Edward Lazear"
		replace hi_all = 68 if i_Name=="Eric Maskin"
		replace cites_all = 34090 if i_Name=="Eric Maskin"
		replace hi_all = 91 if i_Name=="James Stock"
		replace cites_all = 92597 if i_Name=="James Stock"
		replace hi_all = 59 if i_Name=="Larry Samuelson"
		replace cites_all = 16509 if i_Name=="Larry Samuelson"
		replace hi_all = 30 if i_Name=="Nancy Stokey"
		replace cites_all = 19377 if i_Name=="Nancy Stokey"
		replace hi_all = 71 if i_Name=="Oliver Hart"
		replace cites_all = 77085 if i_Name=="Oliver Hart"
		replace hi_all = 62 if i_Name=="Paul De Grauwe"
		replace cites_all = 18083 if i_Name=="Paul De Grauwe"
		replace hi_all = 53 if i_Name =="Ray Fair"
		replace cites_all = 12217 if i_Name=="Ray Fair"  
		foreach v in cites_all hi_all cites_cal hi_cal{
			ren `v' i_`v'
		}
	// rename
	foreach v in nationality US_sample  us_based us_phd phdinst hi_2015 cites_2015  European American{
		rename `v' i_`v'
	}
	// age
	gen i_age2012 = 2012 - i_phdyear
	gen i_older = i_age2012>30
	gen i_midcareer = i_age2012>15&i_age2012<=30
/*****************************************************************************
4) votes
*******************************************************************************/
	// vote
		encode Vote, gen(j_response)
	// expand uncertain to include no opinion and did not answer 
		gen 	j_likert = -2 if j_response==8 /* strongly disagree */
		replace j_likert = -1 if j_response==5  /* disagree */
		replace j_likert = 0  if j_response==9 /* uncertain */ /*| response==6 | response==4 | response==1 | response==2*/
		replace j_likert = 1  if j_response==3 /*agree */
		replace j_likert = 2  if j_response==7 /* strongly agree */

	/*  look at people voting with/ against consensus:
		create consensus variable 

		For the question
		The consensus is defined as the majority view if the majority agrees/ disagrees (where uncertainty is coded as either agree or disagree) 
		if the modal response is uncertain, asssume that there is no consensus

		For the individual 
		= 1 if you agree with the consensus (ie you (dis)agree and the majority view is (dis)agree). Also if you are uncertain and the mode is uncertain
		=-1 if you do not agree with the consensus (ie you do not (dis)agree and the majority view is (dis)agree
		= 0 if you are uncertain (and there is a consensus on agree/disagree)

		Pooled - across US and EUR samples
		Separated - for US and EUR samples separately 

		how individuals vote - collapse into three categories and then look at the average vote by question */

		gen j_agreedisagree = 1 if j_likert>=1 & j_likert!=.
		replace j_agreedisagree = -1 if j_likert<=-1
		replace j_agreedisagree = 0 if j_likert==0
		egen j_temp_pooled = mean(j_agreedisagree), by(Question)
		egen j_temp_separated = mean(j_agreedisagree), by(i_US_sample Question)
		egen j_qmode = mode(j_agreedisagree), by(Question)
		egen j_qmode_sep = mode(j_agreedisagree), by(i_US_sample Question)
		/* Hans: leave out means/modes  */
		//leave out mean pooled
		egen a = sum(j_agreedisagree), by(Question)
		egen b = count(j_agreedisagree), by(Question)
		gen j_temp_pooled_lo=(a-j_agreedisagree)/(b-1)
		drop a b
		//leave out mean separated
		egen a = sum(j_agreedisagree), by(Question i_US_sample)
		egen b = count(j_agreedisagree), by(Question i_US_sample)
		gen j_temp_separated_lo=(a-j_agreedisagree)/(b-1)
		drop a b
		// leave out mode pooled
			tempfile temp 
			preserve
				// calculate frequencey of responses
				keep   Question j_agreedisagree i_female
				collapse (count) n=i_female, by(Question j_agreedisagree)
				drop if j_agreedisagree==.
				// make wide
				replace j_agreedisagree=j_agreedisagree+2
				reshape wide n ,i(Question)  j(j_agreedisagree)
				save `temp',replace
			restore
			merge m:1 Question using `temp', nogen
			gen max=0
			gen maxv=.
			forval i=1/3{ /* node this favours agree with consensus */
				replace n`i'=n`i'-1 if j_agreedisagree==`i'-2
				replace maxv=`i' if n`i'>max
				replace max=n`i' if n`i'>max
			}
			gen j_qmode_lo=maxv-2
			drop maxv max n1 n2 n3 
		// leave out mode separated
			tempfile temp 
			preserve
				// calculate frequencey of responses
				keep   Question j_agreedisagree i_female i_US_sample
				collapse (count) n=i_female, by(Question j_agreedisagree i_US_sample)
				drop if j_agreedisagree==.
				// make wide
				replace j_agreedisagree=j_agreedisagree+2
				reshape wide n ,i(Question i_US_sample)  j(j_agreedisagree)
				save `temp',replace
			restore
			merge m:1 Question i_US_sample using `temp', nogen
			gen max=0
			gen maxv=.
			forval i=1/3{ /* node this favours agree with consensus */
				replace n`i'=n`i'-1 if j_agreedisagree==`i'-2
				replace maxv=`i' if n`i'>max
				replace max=n`i' if n`i'>max
			}
			gen j_qmode_sep_lo=maxv-2
			drop maxv max n1 n2 n3 	
			
	// define consensus vote - agree (1) disagree (-1) uncertain/ no opinion (0) - based on mean, by question*/
		gen j_consensus = 1 if j_temp_pooled>0 & j_temp_pooled!=.
		replace j_consensus = -1 if j_temp_pooled<0
		replace j_consensus = 0 if j_qmode==0 /* replace consensus is missing if the modal response is uncertain */
		replace j_consensus =. if j_likert==.
		// leave out
		gen j_consensus_lo = 1 if j_temp_pooled_lo>0 & j_temp_pooled_lo!=.
		replace j_consensus_lo = -1 if j_temp_pooled_lo<0
		replace j_consensus_lo = 0 if j_qmode_lo==0 /* replace consensus is missing if the modal response is uncertain */
		replace j_consensus_lo =. if j_likert==.
		gen j_consensus_sep = 1 if j_temp_separated>0 & j_temp_separated!=.
		replace j_consensus_sep = -1 if j_temp_separated<0
		replace j_consensus_sep = 0 if j_qmode_sep==0 /* replace consensus is missing if the modal response is uncertain */
		replace j_consensus_sep =. if j_likert==.
		//  leave out
		gen j_consensus_sep_lo = 1 if j_temp_separated_lo>0 & j_temp_separated_lo!=.
		replace j_consensus_sep_lo = -1 if j_temp_separated_lo<0
		replace j_consensus_sep_lo = 0 if j_qmode_sep_lo==0 /* replace consensus is missing if the modal response is uncertain */
		replace j_consensus_sep_lo =. if j_likert==.
	// now look at whether individuals vote with/ against the consensus - not defined if mode is uncertain */
		label def consensusvote 1 "Vote with" 0 "Uncertain" -1 "Vote against"
		foreach v in "" "_lo" "_sep" "_sep_lo"{
			// voted against
			gen j_voteagainst`v' = 1 if j_consensus`v'==1 & j_agreedisagree==-1
			replace j_voteagainst`v' = 1 if j_consensus`v'==-1 & j_agreedisagree==1
			replace j_voteagainst`v' = 0 if j_voteagainst`v'==. & j_likert!=.
			replace j_voteagainst`v' = . if j_qmode`v'==0 | j_likert==.
			// voted with
			gen j_votewith`v' = 1 if j_consensus`v'==1 & j_agreedisagree==1
			replace j_votewith`v' = 1 if j_consensus`v'==-1 & j_agreedisagree==-1
			replace j_votewith`v' = 0 if j_votewith`v'==. & j_likert!=.
			replace j_votewith`v' = . if j_qmode`v'==0 | j_likert==.
			// consensus vote
			gen j_consensusvote`v' = 1 if j_votewith`v'==1
			replace j_consensusvote`v' = 0 if j_likert==0
			replace j_consensusvote`v' = -1 if j_voteagainst`v'==1
			replace j_consensusvote`v' = . if j_consensus`v'==0  | j_likert==.
			label values j_consensusvote`v' consensusvote  
		}

	// generate different measures of uncertain: narrow = response is uncertain; broad = includes did not answer, no opininion  
		gen j_uncertain_narrow = j_response==9
		gen j_no_opinion = j_response==6
		gen j_gives_opinion = 1-j_no_opinion
		gen j_didnotanswer = j_response==4 | j_response==1 | j_response==2
		gen j_uncertain = j_uncertain_narrow==1 | j_no_opinion==1 | j_didnotanswer==1

	/* share by question who vote with/ against consensus and are uncertain (defined broadly) */
		gen temp = j_uncertain
		replace temp = . if j_consensus==0
		egen j_q_votewith = mean(j_votewith), by(Question)
		egen j_q_voteagainst = mean(j_voteagainst), by(Question)
		egen j_q_uncertain = mean(temp), by(Question)
		egen j_q_no_opinion = mean(j_no_opinion), by(Question)
		drop temp
		gen temp = j_uncertain
		replace temp = . if j_consensus_sep==0
		egen j_q_votewith_sep = mean(j_votewith), by(i_US_sample Question)
		egen j_q_voteagainst_sep = mean(j_voteagainst), by(i_US_sample Question)
		egen j_q_uncertain_sep = mean(temp), by(i_US_sample Question)
		egen j_q_no_opinion_sep = mean(j_no_opinion), by(i_US_sample Question)

	// code certainty the same way as Sarsons and Xu 
		gen j_certainty = 0 if j_likert==0
		replace j_certainty = 1 if j_likert==1 | j_likert==-1
		replace j_certainty = 2 if j_likert==2 | j_likert==-2

		label def certainty 0 "uncertain" 1 "agree/disagree" 2 "strongly agree/disagree"
		label values j_certainty certainty

		gen j_strong = j_certainty==2 
		destring Confidence, replace force
		rename Confidence j_Confidence
	
		gen j_numwords = wordcount(Comment)
		replace j_numwords = . if j_didnotanswer==1 | j_no_opinion==1
		gen j_anycomment = j_numwords>0 & j_numwords!=.
		replace j_anycomment = . if j_didnotanswer==1 | j_no_opinion==1
		rename Comment j_Comment
		
/*****************************************************************************
5) cleaning
*******************************************************************************/	
	// drop variables
	drop i_AG i_AP i_CF i_CH i_DAE i_DEV i_ED i_EFG i_EEE i_HC i_IFM i_ITI i_IO i_LE i_LS i_ME i_PE i_POL i_PR
	drop i_C_DE i_C_EH i_C_FE i_C_IMF i_C_IO i_C_IT i_C_LE i_C_MEF i_C_MG i_C_PE
	drop j_qmode j_qmode_sep j_temp_pooled_lo j_temp_separated_lo j_qmode_lo j_qmode_sep_lo
	drop j_temp_pooled j_temp_separated
	drop j_q_votewith_sep j_q_voteagainst_sep j_q_uncertain_sep j_q_no_opinion_sep
	drop temp
	drop i_Institution
	drop q_theory_arpad q_evidence_arpad q_neither_arpad q_theory_ali q_evidence_ali q_neither_ali
	// GD sample indicator 
	replace q_gd_sample=0 if i_US_sample==0
	// Number of answers per question 
	egen q_id= group(Question)
	so Question i_id
	by Question: gen q_qcount = _n
	so i_US_sample Question i_id
	by i_US_sample Question: gen q_qcount_sep = _n
	egen temp = count(Question) if i_US_sample==1, by(Question)
	egen q_UStot = mean(temp), by(Question)
	replace q_UStot=0 if q_UStot==.
	drop temp
	egen temp = count(Question) if i_US_sample==0, by(Question)
	egen q_EUtot = mean(temp), by(Question)
	replace q_EUtot=0 if q_EUtot==.
	drop q_qcount q_qcount_sep
	// Questions asked in both US and Europe 
	gen q_commonQ = q_UStot>0&q_EUtot>0
	drop q_UStot q_EUtot
	// rename  variables
	rename Question q_Question
	rename Question_old q_Question_old
	// Individual responses
	bys i_Name: gen i_num_q=_N
	gen answered=j_likert!=.
	bys i_Name: egen i_numansw_q=sum(answered)
	drop answered
	// question types
	gen q_theory_alt  =q_qtype_alt==1
	gen q_evidence_alt=q_qtype_alt==2
	gen q_neither_alt =q_qtype_alt==3
	// Rename responses
	gen j_strdisagree=j_likert	==-2 if j_likert!=.
	gen j_disagree=j_likert		==-1 if j_likert!=.
	gen j_agree=j_likert		==1  if j_likert!=.
	gen j_stragree=j_likert		==2  if j_likert!=.
	replace j_uncertain=. 			 if j_likert==. 
	// Redefine didnotanswer to include no_opinion
	replace j_didnotanswer = 1 if j_no_opinion==1 
	replace j_gives_opinion=0 if j_didnotanswer==1
	// Extreme judgements
	gen j_extreme_judgement=inlist(j_likert,-2,2)
	replace j_extreme_judgement = . if j_didnotanswer==1
	// Vote against
	gen vote_against=j_consensusvote_lo==-1
	replace vote_against=. if j_consensusvote_lo==.
	// Vote uncertain
	gen vote_uncertain=j_consensusvote_lo==0
	replace vote_uncertain=. if j_consensusvote_lo==.
	// Outside field
	gen j_outsidefield=1-j_expert
	// Interaction terms
	gen j_expXfem=i_female*j_expert
	gen j_femaleXevidence=q_evidence*i_female
	gen j_femaleXtheory=q_theory*i_female
	gen j_femaleXneither=q_neither*i_female
	gen j_femaleXevidenceXout=j_femaleXevidence*j_outsidefield
	gen j_femaleXtheoryXout=j_femaleXtheory*j_outsidefield
	gen j_femaleXneitherXout=j_femaleXneither*j_outsidefield
	gen j_TX=q_theory*j_expert
	gen j_PX=q_evidence*j_expert 
	gen j_NX=q_neither*j_expert
	gen j_nexpert=1-j_expert
	gen j_TN=q_theory*j_nexpert
	gen j_PN=q_evidence*j_nexpert 
	gen j_NN=q_neither*j_nexpert
	gen j_TXF=j_TX*i_female
	gen j_PXF=j_PX*i_female
	gen j_NXF=j_NX*i_female
	gen j_TNF=j_TN*i_female
	gen j_PNF=j_PN*i_female
	gen j_NNF=j_NN*i_female
	gen j_TF=q_theory*i_female
	gen j_PF=q_evidence*i_female 
	gen j_NF=q_neither*i_female
	
/*  Question level */
	label var q_theory_alt "Type: Economic theory"
	label var q_evidence_alt "Type: Empirical evidence"
	label var q_neither_alt "Type: Judgement"
	label var q_efficiency "Topic: efficiency"
	label var q_distrib "Topic: distribution"
	label var q_covid19 "Topic: Covid-19"
	label var q_dev "Field: development"
	label var q_fin "Field: financial"
	label var q_io "Field: IO"
	label var q_lab "Field: labour"
	label var q_pub "Field: public"
	label var q_mac "Field: macroeconomics"
	label var q_int "Field: international"
	label var q_gd_Topic "Topic classification by GD"
	label var q_gd_date 	"Date by GD"
	label var q_gd_litsize  "Literature size by GD"
	label var q_gd_qfield1 "Question field 1 by GD"
	label var q_gd_qfield2 "Question field 2 by GD"
	label var q_gd_qfield3 "Question field 3 by GD"
	label var q_gd_redistribute "Topic redistribution by GD"
	label var q_gd_markets "Topic market by GD"
	label var q_gd_conservative "Topic conservative by GD"
	label var q_gd_sample "Included in GD study"
	label var q_id "Question ID"
	label var q_qtype	"Question type (Theory, Evidence, Neither)"
	label var q_qtype_alt "Question type (Ali, Arpad, Hans/Sarah agree) (Theory, Evidence, Neither)"
	label var q_qtype_alt_w "How many agree on the question type"
	label var q_commonQ 	"Question is asked both in US and EUROPE"
	label var q_renamed 	"Question has been renamed"
	label var q_theory 		"Type: theory"
	label var q_evidence	"Type: evidence"
	label var q_neither	"Question is classified as neither theory or evidence"
/* Individual level */
	label var i_Name 		"Name (of expert)"
	label var i_nationality	"Nationality (of expert)"
	label var i_American 	"Nationality==American (of expert)"
	label var i_European 	"Nationality==European (of expert)"
	label var i_us_based	"Based in the US (expert)"
	forval i=1/7{
		cap label var i_nber`i' "NBER field number `i'"
		cap label var i_cepr`i' "CEPR field number `i'"
	}
	label var i_num_q 		"Number of questions"
	label var i_numansw_q 	"Number of questions answered"
	label var i_US_sample 	"US sample"
	label def i_US_sample 0 "European panel" 1 "US panel"
	label values i_US_sample i_US_sample
	label var i_cites_all   "Citations (total)"
	label var i_cites_2015  "Citations (since 2015)"
	label var i_hi_all      "H-index (total)"
	label var i_hi_2015     "H-index (since 2015)"
	label var i_female      "Female"
	label var i_us_phd      "PhD from US institution"
	label var i_phdyear     "PhD year"
	label var i_NBER        "NBER affiliate" 
	label var i_CEPR        "CEPR affiliate"
	label var i_dev 		"Development econ (NBER fields)"
	label var i_inter 		"International econ (NBER fields)"
	label var i_fin 		"Finance (NBER fields)"
	label var i_io 			"Industrial Organisation (NBER fields)"
	label var i_lab 		"Labour econ (NBER fields)"
	label var i_pub 		"Public finance (NBER fields)"
	label var i_mac 		"Macro (NBER fields)"
	label var i_cdev 		"Development econ (CEPR fields)"
	label var i_cinter 		"International econ (CEPR fields)"
	label var i_cfin 		"Finance (CEPR fields)"
	label var i_cio 		"Industrial Organisation (CEPR fields)"
	label var i_clab 		"Labour econ (CEPR fields)"
	label var i_cpub 		"Public finance (CEPR fields)"
	label var i_cmac 		"Macro (CEPR fields)"
	//label var i_numfields 	"Number of fields covered (NBER)"
	label var i_id 			"Individual identifier"
	label var i_inst 		"Institution of expert"
	label var i_age			"Age of expert (2020-PhD Year)"
	label var i_age2		"Age of expert squared (2020-PhD Year)"
	label var i_age2012		"Age of expert (2012-PhD Year)"
	label var i_older		"Age of expert (2012-PhD Year)>30"
	label var i_midcareer 	"30<=Age of expert (2012-PhD Year)>15"
	label var i_hi_cal 		"H index is calculated"
	label var i_hi_all		"H index overall"
	label var i_num_q		"Number of questions received"
	label var i_numansw_q		"Number of questions answered"
	label var i_cites_cal 	"Citations are calculated"
/* Response level */
	label var j_Confidence "Confidence (1=lowest, 10=highest)"
	label var j_strdisagree "Response: Strongly Disagree"
	label var j_disagree 	"Response: Disagree"
	label var j_uncertain 	"Response: Uncertain"
	label var j_agree 		"Response: Agree"
	label var j_stragree 	"Response: Strongly Agree"
	label var j_expert 		"Expert's field"
	label var j_response	"Response to question"
	label var j_likert 		"Response to question converted to likert scale"
	label var j_agreedisagree 		"Response convert to agree, uncertain, disagree"
	label var j_consensus   		"Consensus vote"
	label var j_consensus_lo   		"Consensus vote (leave out focal)"
	label var j_consensus_sep 		"Consensus vote (Separate for US/EUR)"
	label var j_consensus_sep_lo 	"Consensus vote(Separate for US/EUR) (leave out focal)"
	label var j_voteagainst   		 "1 if voted against consensus"
	label var j_votewith   			 "1 if voted with consensus"
	label var j_consensusvote 		 "1 if voted with consens, -1 if voted against"
	label var j_voteagainst_lo   		 "1 if voted against consensus (Leave out measure)"
	label var j_votewith_lo   			 "1 if voted with consensus  (Leave out measure)"
	label var j_consensusvote_lo 		 "1 if voted with consens, -1 if voted against  (Leave out measure)"
	label var j_voteagainst_sep   		 "1 if voted against consensus (Sep measure)"
	label var j_votewith_sep   			 "1 if voted with consensus  (Sep measure)"
	label var j_consensusvote_sep 		 "1 if voted with consens, -1 if voted against  (Sep measure)"
	label var j_voteagainst_sep_lo   		 "1 if voted against consensus (Sep measure; LO)"
	label var j_votewith_sep_lo   			 "1 if voted with consensus  (Sep measure; LO)"
	label var j_consensusvote_sep_lo 		 "1 if voted with consens, -1 if voted against  (Sep measure; LO)"
	label var j_no_opinion "No opinion"
	label var j_gives_opinion "Gives opinion"
	label var j_didnotanswer "Did not respond"
	label var j_uncertain_narrow "Responded Uncertain"
	label var j_Confidence "Confidence (1=lowest, 10=highest)"
	label var j_consensus_sep_lo "1 if voted with consens, -1 if voted against (Separate for US/EUR) (leave out focal)"
	label var j_q_votewith 		"Fraction voting with consensus"
	label var j_q_voteagainst 	"Fration voting against consensus"
	label var j_q_uncertain		"Fraction that is unertain"
	label var j_q_no_opinion 	"Fraction with no opinion"
	label var j_certainty 		"Certainty using Sarsons and Xu definition"
	label var j_strong 		    "Strongly agree/disagree"
	label var j_numwords   "number of words in comment"
	label var j_anycomment "whether expert commented"
	label var j_outsidefield "Not expert's field"
	label var j_expert "Expert"
		
/* Interactions */
	label var j_expXfem "Female $\times$ Expert"
	label var j_femaleXevidence "Female $\times$ Evidence"
	label var j_femaleXneither "Female $\times$ Judgement"
	label var j_femaleXtheory "Female $\times$ Theory"
	label var j_didnotanswer "No opinion"
	label var j_uncertain "Uncertain"
	label var j_extreme_judgement  "Strong opinion"
	label var vote_against  "Vote against"
	label var j_anycomment "Any comment"
	label var j_Confidence "Confidence"



* save
order i_* q_* j_*
	// save
	keep i_* q_* j_*
	order i_* q_* j_*
	compress

save "data/data_temp/analysisdata.dta",replace
