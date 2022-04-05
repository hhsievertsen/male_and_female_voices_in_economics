/*****************************************************************************
3_mainregression: create main table and charts of ols reg results
*******************************************************************************/
// set working directory
*cd  "C:\Users\hs17922\OneDrive - University of Bristol\Desktop\expert_economists_gender\analysis\igm" 
*cd  "C:\Users\ecsls\Dropbox\igm\analysis\igm"
cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\igm" 

// settings
set matsize 5000
gl controls "i_cites_all i_hi_all  i_US_sample i_American i_European"
gl absorb   "q_Question i_inst i_phdyear"

// graph settings
gl gs " graphregion(lcolor(white) fcolor(white) )   ylab(, nogrid labcolor(black) ticks  angle(horizontal) tlcolor(gs10) tlwidth(medthick)) xscale(line noextend nofextend lcolor(gs10) lwidth(medthick)) yscale(line noextend nofextend lcolor(gs10) lwidth(medthick)) xsize(10) ysize(6) xlab(, labcolor(black)  angle(horizontal) tlcolor(gs10) tlwidth(medthick))"
	

// Dataset to store results 
preserve
	clear 
	set obs 7
	gen count=_n
	gen beta=.
	gen ul=.
	gen ll=.
	gen spec=""
	gen y=""
	save "data\data_temp\coef.dta",replace
restore
// program to store
cap program drop mp
program mp 
	preserve
	use "data\data_temp\coef.dta",clear
	replace beta=r(estimate) if count==`1'
	replace ul=r(ub) if count==`1'
	replace ll=r(lb) if count==`1'
	replace spec="`2'"  if count==`1'
	save "data\data_temp\coef.dta",replace
	restore
end

// Load data 
u "data\data_temp\analysisdata.dta",clear
     
replace j_gives_opinion=1-j_didnotanswer
// loop over dep var
local count=1
graph drop _all
eststo clear
foreach v in j_gives_opinion  j_anycomment j_uncertain  j_extreme_judgement   j_Confidence{
	if `count'!=5{
		gl gs2 " xscale(off fill)"
	}
		else {
		gl gs2 " "
	}
	if `count'==2{
		gl gs2 "ylab(-0.25(0.05)0) xscale(off fill)"
	} 
	// 1 baseline
		eststo ms`count': reghdfe  `v'     i_female  $controls , absorb($absorb) cluster(q_Question) 
		lincom  i_female
		mp 1 "Baseline"
		sum `v'
		estadd scalar mdv=r(mean)
	// 2 Interacted
		eststo mf`count':  reghdfe `v'     i_female j_PF j_NF j_TNF j_PNF j_NNF j_TN j_PN j_NN $controls , absorb($absorb) cluster(q_Question)     
		// Theory Expert
		lincom  i_female
		mp 2 "TX"
		// Theory Non-expert
		lincom  i_female+j_TNF
		mp 3 "TN"
		// Positive Expert
		lincom  i_female+j_PF
		mp 4 "PX"
		// Positive Non-expert
		lincom  i_female+j_PF+j_PNF
		mp 5 "PN"
		// Normative Expert
		lincom  i_female+j_NF 
		mp 6 "NX"
		// Normative Non-expert
		lincom  i_female+j_NF+ j_NNF
		mp 7 "NN"
		sum `v'
		estadd scalar mdv=r(mean)
	// title
	local lab: variable label `v' 
	// chart
	preserve
	use "data\data_temp\coef.dta",clear
	tw (bar beta count ,barwidth(0.8) lwidth(none) fcolor("84 161 112")) /// 
	   (rspike ul ll count , lcolor(gs8)) ///
	   ,$gs  ylab(,axis(1))    ///
	   xlab(1 "Baseline" 2 "TX" 3 "TN" 4 "PX" 5 "PN" 6 "NX" 7 "NN" ,) xtitle(" ") ///
		  ytitle("`lab'",color(black))  ///
		legend(off)  name(f`count')  ///
		$gs2 yline(0,lcolor(gs6)) ylab(,format(%4.2f) labgap(large))
	restore


	local count=`count'+1
	
}

// table baseline
	esttab  ms1 ms2 ms3 ms4 ms5 using "output_files\\tab_main_reg_baseline.rtf", ///
       b(%4.3f) noobs star(* 0.1 ** 0.05 *** 0.01) label  replace  nodepvar  nomtitles se	///       
	stats(  N r2 mdv, fmt( %10.0f %4.2f))       
// table full
	esttab  mf1 mf2 mf3 mf4 mf5 using "output_files\\tab_main_reg_interacted.rtf", ///
       b(%4.3f) noobs star(* 0.1 ** 0.05 *** 0.01) label  replace  nodepvar  nomtitles se	///       
	stats(  N r2 mdv, fmt( %10.0f %4.2f))
	
graph combine f1 f2 f3 f4 f5  , cols(1)   imargin(-7 -4 -7 -7) xsize(10) ysize(16) graphregion(fcolor(white) lcolor(white))	

graph export  "output_files\\fig_reg_chart.png", width(2000) replace
	