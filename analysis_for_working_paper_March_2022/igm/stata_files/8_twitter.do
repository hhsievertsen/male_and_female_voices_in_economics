/*****************************************************************************
twitter.do
*******************************************************************************/
// set working directory
cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\igm" 

// globals
gl controls "i_cites_all i_hi_all  i_US_sample i_American i_European"
gl absorb   "q_Question i_inst i_phdyear"
gl gs " graphregion(lcolor(white) fcolor(white) )   ylab(, format(%4.2f) nogrid labcolor(black) ticks  angle(horizontal) tlcolor(gs10) tlwidth(medthick)) xscale(line noextend nofextend lcolor(gs10) lwidth(medthick))  yscale(line noextend nofextend lcolor(gs10) lwidth(medthick)) xsize(10) ysize(6) "

// Dataset to store results 
preserve
	clear 
	set obs 6
	gen count=_n
	gen beta=.
	gen ul=.
	gen ll=.
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
	save "data\data_temp\coef.dta",replace
	restore
end


// Load twitter
import excel "data\data_manual\twitter.xlsx", sheet("Sheet1") firstrow clear
merge 1:m i_Name using  "data\data_temp\analysisdata.dta",nogen 
replace j_gives_opinion=1-j_didnotanswer
// Create new variables
gen t_twitter = t_followers !=.
// collapse
collapse (mean) j_gives_opinion  j_uncertain  j_extreme_judgement  j_anycomment j_Confidence ///
         (firstnm) t_twitter t_followers t_month t_year $controls i_female , by(i_Name)
foreach v in  j_gives_opinion  j_uncertain  j_extreme_judgement  j_anycomment j_Confidence{
	gen fX`v'=i_female*`v'
}
gen twitterage=(ym(2021,12)-ym(t_year,t_month))/12
replace t_followers = ln(t_followers)

label var j_gives_opinion  "Gives opinion"
label var j_uncertain    "Uncertain"
label var j_extreme_judgement  "Extreme"
label var j_anycomment  "Any comment"
label var j_Confidence "Confidence"
label var i_female "Female"
label var twitterage "Twitter age (years)"
label var  fXj_gives_opinion  "Female X Gives opinion"
label var  fXj_uncertain    "Female X Uncertain"
label var  fXj_extreme_judgement  "Female X Extreme"
label var  fXj_anycomment  "Female X Any comment"
label var  fXj_Confidence "Female X  Confidence"
// Charts

cap graph drop gf1 
cap graph drop gf2
tw (scatter t_followers j_Confidence if i_female==0, mcolor(gs5)) ///
	(scatter t_followers j_Confidence if i_female==1, mcolor(gs10)) ///
	(lfit t_followers j_Confidence if i_female==0, lcolor(gs5)  lwidth(thick)) ///
	(lfit t_followers j_Confidence if i_female==1, lcolor(gs10)  lwidth(thick)), ///
	saving(mnconf.gph, replace) ytitle("ln(twitter followers)") ///
	xtitle("Confidence") xlab(3(1)8) name(gf1) ///
	$gs legend(order(1 "Male" 2 "Female") region(lcolor(white)))
	
tw (scatter t_followers j_extreme_judgement if i_female==0, mcolor(gs5)) ///
(scatter t_followers j_extreme_judgement if i_female==1, mcolor(gs10)) ///
(lfit t_followers j_extreme_judgement if i_female==0, lcolor(gs5) lwidth(thick)) ///
 (lfit t_followers j_extreme_judgement if i_female==1, lcolor(gs10)  lwidth(thick) ), ///
 saving(mnstrong.gph, replace) legend(off) ytitle("ln(twitter followers)") ///
 xtitle("Strong opinion") ///
  $gs xlab(0(0.1)0.6) name(gf2), 


grc1leg gf1 gf2, graphregion(fcolor(white)) ycommon

 graph export "output_files\\fig_twitter.png", width(2000) replace

eststo clear
// Baseline
eststo: reg t_followers i_female   $controls twitterage,robust
lincom  i_female
mp 1 
local count=2		
// By dep vars
foreach v in j_gives_opinion  j_anycomment j_uncertain  j_extreme_judgement   j_Confidence{
		eststo: reg t_followers i_female `v' fX`v'  $controls twitterage,robust
		lincom  fX`v'
		mp `count'
		local count=`count'+1
}

	esttab  using "output_files\\tab_twitter_reg.rtf", ///
       b(%4.3f) noobs stats(N r2) star(* 0.1 ** 0.05 *** 0.01) label  replace  nodepvar  nomtitles se ///
	   keep(i_female twitterage fXj_gives_opinion fXj_uncertain fXj_extreme_judgement fXj_anycomment fXj_Confidence  j_gives_opinion  j_uncertain  j_extreme_judgement  j_anycomment j_Confidence twitterage)
// Chart

use "data\data_temp\coef.dta",clear
	tw (bar beta count ,barwidth(0.8) lwidth(none) fcolor("84 161 112")) /// 
	   (rspike ul ll count , lcolor(gs8)) ///
	   ,$gs  ylab(,axis(1))    ///
	   xlab(1 "Female" 2 `" "Gives opinion" "X female" "' 3 `" "Any comment" "X female" "' 4 `" "Uncertain" "X female" "' 5 `""Strong" "X female" "' 6 `""Confidence" "X female" "' ,) xtitle(" ") ///
		  ytitle("`lab'",color(black))  ///
		legend(off)   ///
		$gs2 yline(0,lcolor(gs6)) ylab(,format(%4.2f) labgap(large))

