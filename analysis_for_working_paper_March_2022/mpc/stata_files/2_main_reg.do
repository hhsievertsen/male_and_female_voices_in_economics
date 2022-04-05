/*****************************************************************************
data_build.do: prep data for igm analysis
*******************************************************************************/
// set working directory
cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\mpc\" 
// load data
use "data\\temp\\analysisdata.dta",clear
sum vi_tenure,d
gen moremeetings=vi_tenure>55
/* Dataset to store results */
preserve
	clear 
	set obs 2
	gen female=_n-1
	expand 5
	bys female: gen count=_n
	gen beta=.
	gen ul=.
	gen ll=.
	gen y=""
	save "data\temp\coef.dta",replace
restore
* Regression */
set trace off
eststo clear
local count=1
foreach v in vi_votestatusquo vi_vote_against_lo vi_voteagainstalone_lo     {
// For table
qui: sum `v' 
local mdv: disp %4.2f r(mean)
eststo: reghdfe   `v' i_female  i_internal   ,absorb(v_date )  cluster(v_date)
estadd scalar mdv=`mdv'
// save p value
mat a=r(table)
local p`v': disp %4.3f a[4,1]
local d`v': disp %4.3f a[1,1]
// For chart
qui: reghdfe   `v' i.i_female  i_internal   ,absorb(v_date )  cluster(v_date)

margins i_female, atmeans 
mat b=r(table)
preserve
	use "data\temp\coef.dta",clear
	replace beta=b[1,1] if female==0 & count==`count'
	replace ul=b[6,1] if female==0 & count==`count'
	replace ll=b[5,1] if female==0 & count==`count'
	replace beta=b[1,2] if female==1 & count==`count'
	replace ul=b[6,2] if female==1 & count==`count'
	replace ll=b[5,2] if female==1 & count==`count'
	replace y="`y'" if  count==`count'
	save "data\temp\coef.dta",replace
restore
local count=`count'+1

}
esttab  using "output\\tab_reg_mpc.rtf",replace se label  stats(N mdv r2) b(%4.3f)  star(* 0.1 ** 0.05 *** 0.01) 


/* create chart */
use "data\temp\coef.dta",clear
gl gs " graphregion(lcolor(white) fcolor(white) )   ylab(, nogrid labcolor(black) ticks  angle(horizontal) tlcolor(gs10) tlwidth(medthick))  xscale(line noextend nofextend lcolor(gs10) lwidth(medthick))  yscale(line noextend nofextend lcolor(gs10) lwidth(medthick)) xsize(10) ysize(6)  xlab(, labcolor(gs6)  angle(horizontal) tlcolor(gs10) tlwidth(medthick))"

sort count female
gen order=_n
replace order=order+0.1 if female==0
replace order=order-0.1 if female==1
  
cap graph drop f1
tw (bar beta order if female==0 ,barwidth(0.8) lwidth(none) fcolor("84 161 112")) /// 
   (bar beta order if female==1 ,barwidth(0.8) lwidth(none) fcolor("121 142 168") ) ///
   (rspike ul ll order , lcolor(gs8)) ////
   ,$gs ylab(#7, format(%4.2f))   ///
   xlab(1.5 "Vote status quo" 3.5 `" "Vote against" "consensus" "'  ///
			 5.5 `" "Vote alone" "against consensus" "' 7.5 ,) xtitle(" ") ///
 ytitle("Coefficient",color(gs6))  ///
	legend(order( 1 "Male" 2 "Female") region(lcolor(white)) pos(12) size(*0.8)) ///
	  yline(0,lcolor(gs6))
	graph export "output\\tab_reg_chart_mpc.png" ,replace width(2000)
	
	
/* Alternative plotting difference */
* Regression */
use "data\\temp\\analysisdata.dta",clear
gen moremeetings=vi_tenure>55
set trace off
eststo clear
local count=1
foreach v in vi_votestatusquo vi_vote_against_lo vi_voteagainstalone_lo vi_vote_lower_lo  vi_vote_higher_lo  {
// For table
eststo: reghdfe   `v' i_female  i_internal   ,absorb(v_date )  cluster(v_date)
// save p value
mat b=r(table)
local p`v': disp %4.3f b[4,1]
local d`v': disp %4.3f b[1,1]
preserve
	use "data\temp\coef.dta",clear
	replace beta=b[1,1] if female==0 & count==`count'
	replace ul=b[6,1] if female==0 & count==`count'
	replace ll=b[5,1] if female==0 & count==`count'
	save "data\temp\coef.dta",replace
restore
local count=`count'+1

}
	

/* create chart */
use "data\temp\coef.dta",clear
gl gs " graphregion(lcolor(white) fcolor(white) )   ylab(, nogrid labcolor(black) ticks  angle(horizontal) tlcolor(gs10) tlwidth(medthick))  xscale(line noextend nofextend lcolor(black) lwidth(medthick))  yscale(line noextend nofextend lcolor(gs10) lwidth(medthick)) xsize(10) ysize(6)  xlab(, labcolor(gs6)  angle(horizontal) tlcolor(gs10) tlwidth(medthick))"

sort count female
gen order=_n
replace order=order+0.5 if female==0
  
cap graph drop f1
tw (bar beta order if female==0 ,barwidth(1.2) lwidth(none) fcolor("84 161 112")) ///
   (rspike ul ll order  if female==0 , lcolor(gs8)) ////
   ,$gs ylab(-0.2(0.1)0.3, format(%4.2f))   ///
   xlab(1.5 "Vote status quo" 3.5 `" "Vote against" "consensus" "'  ///
			 5.5 `" "Vote alone" "against consensus"  ,) xtitle(" ") ///
	text(0.3 1.5  "{&Delta}=`dvi_votestatusquo'",size(small)color(black) ) ///
	text(0.3 3.5  "{&Delta}=`dvi_vote_against_lo'",size(small) color(black)) ///
	text(0.3 5.5  "{&Delta}=`dvi_voteagainstalone_lo'",size(small) color(black)) ///
	text(0.27  1.5  "p=`pvi_votestatusquo'",size(small)color(black) ) ///
	text(0.27  3.5  "p=`pvi_vote_against_lo'",size(small) color(black)) ///
	text(0.27  5.5  "p=`pvi_voteagainstalone_lo'",size(small) color(black)) ///
 ytitle("Coefficient",color(black))  ///
	legend(off) ///
	  yline(0,lcolor(gs6))
	graph export "output\\tab_reg_chart_mpc_dif.png" ,replace width(2000)
	
		