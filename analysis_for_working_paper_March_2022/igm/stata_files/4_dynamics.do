/*****************************************************************************
dynamics.do
*******************************/
// set working directory
*cd  "C:\Users\hs17922\OneDrive - University of Bristol\Desktop\expert_economists_gender\analysis\igm" 
*cd  "C:\Users\ecsls\Dropbox\igm\analysis\igm"
cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\igm" 
// Load data 
u "data\data_temp\analysisdata.dta",clear
// settings
set matsize 5000
gl controls "i_cites_all i_hi_all  i_US_sample i_American i_European"
gl absorb   "q_Question i_inst i_phdyear"
// graph settings
gl gs " graphregion(lcolor(white) fcolor(white) )   xscale(line noextend nofextend lcolor(gs10) lwidth(medthick)) yscale(range(0, .1 ) line noextend nofextend lcolor(gs10) lwidth(medthick)) xsize(10) ysize(6) xlab(, labcolor(black)  angle(horizontal) tlcolor(gs10) tlwidth(medthick))"
	 
graph drop _all
// Dataset to store results 
preserve
	clear 
	set obs 5
	gen count=_n
	gen beta=.
	gen ul=.
	gen ll=.
	gen y=""
	save "data\data_temp\coef.dta",replace
restore
// load data
u "data/data_temp/analysisdata.dta",clear
replace j_gives_opinion=1-j_didnotanswer
// create new variables
drop if q_date==.
sort i_id q_date 
by i_id (q_date): gen count = _n
egen maxcount = max(count), by(i_id)  
keep if maxcount>200
gen group="Question 1 - 50" if count<=50
replace group= "Question 51 - 100" if count<=100 & count>50
replace group= "Question 151 - 150" if count<=150 & count>100
replace group= "Question 150 - 200" if count<=200 & count>150
replace group= "Question >200" if count>200
gen g=1 if count<=50
replace g= 2 if count<=100 & count>50
replace g= 3 if count<=150 & count>100
replace g= 4 if count<=200 & count>150
replace g= 5  if count>200

// Loop over outcome vars
local count=1
foreach y in j_gives_opinion  j_anycomment j_uncertain  j_extreme_judgement   j_Confidence{
	eststo clear
	if "`y'"!="j_Confidence"{
		gl gs2 "xscale(off fill)"
	}
	else{
		gl gs2 " "
	}
	gl gs3 "#5"
	if "`y'"=="j_anycomment"{
		gl gs3 "-0.8(0.2)0"
	}
	else{
		gl gs3 "#5"
	}
		forval i=1/3{	
			eststo: reghdfe `y' 		i_female $controls if g==`i'	, absorb($absorb) cluster(q_Question)
			mat b=r(table)
			preserve
			use "data\data_temp\coef.dta",clear
			replace beta=b[1,1] if count==`i'
			replace ul=b[6,1] if  count==`i'
			replace ll=b[5,1] if  count==`i'
			save "data\data_temp\coef.dta",replace
			restore
		}


		// Coefplot manual
		local lab: variable label `y'
		preserve

		use "data\data_temp\coef.dta",clear
				drop if count>3
		sort count 
		cap graph drop f1
		tw (bar beta count ,lwidth(none) barwidth(0.8) fcolor("84 161 112")) /// 
		 (rspike ul ll count ,lcolor(gs6)) /// 
			,$gs   	///
			xlab(1 "1-50" 2 "51-100" ///
					 3 "101-150" ) xtitle("Question number") ///
			 ytitle("`lab'",color(black)) ylab($gs3, format(%4.2f) nogrid labcolor(black) ticks  angle(horizontal) tlcolor(gs10) tlwidth(medthick))    ///
				legend(off)  name(fig`count')  yline(0,lcolor(gs6)) $gs2 

	restore
		// table
	esttab  using "output_files\\tab_dynamics_reg_`v'.rtf", ///
       b(%4.3f) noobs star(* 0.1 ** 0.05 *** 0.01) label  replace  nodepvar  nomtitles se	 
	local count=`count'+1
}

	
graph combine fig1 fig2 fig3 fig4 fig5 , cols(1)   imargin(-7 -4 -7 -7) xsize(10) ysize(14) graphregion(fcolor(white) lcolor(white))	


graph export  "output_files\\fig_dynamics.png", width(2000) replace



// Non parametric
// load data
u "data/data_temp/analysisdata.dta",clear
replace j_gives_opinion=1-j_didnotanswer
graph drop _all
drop if q_date==.
sort i_id q_date 
by i_id (q_date): gen count = _n
egen maxcount = max(count), by(i_id) 

foreach y in j_gives_opinion  j_anycomment j_uncertain  j_extreme_judgement   { 
	lpoly `y' count if i_female==0 & count<=100 & maxcount>100,ylab(, format(%4.1f) angle(horizontal)) xtitle("Question number") lineopts(lcolor(black) lwidth(medthick)) $gs noscatter kernel(biweight) degree(1) ylab(-0.2 0 0.2 0.4 0.6 0.8,  tlcolor(gs10) tlwidth(medthick)) ci  title(Men, color(black)) legend(off) name(f`y'_male)
	lpoly `y' count if i_female==1 & count<=100 & maxcount>100, xtitle("Question number") lineopts(lcolor(black) lwidth(medthick)) $gs noscatter kernel(biweight) degree(1) ylab(-0.2 " " 0 " " 0.2 " " 0.4 " " 0.6 " "  0.8 " ",noticks ) ci  title(Women, color(black)) legend(off) yscale(noline)  ytitle(" ") name(f`y'_female)
	graph combine   f`y'_male f`y'_female ,graphregion(fcolor(white))
	graph export  "output_files\\fig_dynamics_np_`y'.png", width(2000) replace
	}
graph drop _all
foreach y in j_Confidence {  
	lpoly `y' count if i_female==0 & count<=100 & maxcount>100,ylab(, format(%4.1f) angle(horizontal)) xtitle("Question number") lineopts(lcolor(black) lwidth(medthick)) $gs noscatter kernel(biweight) degree(1) ylab(0(2)10,  tlcolor(gs10) tlwidth(medthick)) ci  title(Men, color(black)) legend(off) name(f`y'_male)
	lpoly `y' count if i_female==1 & count<=100 & maxcount>100, xtitle("Question number") lineopts(lcolor(black) lwidth(medthick)) $gs noscatter kernel(biweight) degree(1) ylab(0 " " 2 " " 4 " " 6 " " 8 " " 10 " " ,noticks ) ci  title(Women, color(black)) legend(off) yscale(noline)  ytitle(" ") name(f`y'_female)
	graph combine   f`y'_male f`y'_female ,graphregion(fcolor(white))
	graph export  "output_files\\fig_dynamics_np_`y'.png", width(2000) replace
	}

