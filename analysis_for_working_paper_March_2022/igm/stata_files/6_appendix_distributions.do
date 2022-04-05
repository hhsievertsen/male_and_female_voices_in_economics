/*****************************************************************************
appendix_distributions.do
*******************************************************************************/
// set working directory
cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\igm" 

// globals
gl controls "i_cites_all i_hi_all  i_US_sample i_American i_European"
gl absorb   "q_Question i_inst i_phdyear"
gl gs " graphregion(lcolor(white) fcolor(white) ) bar(1, fcolor(black) lcolor(black))  ylab(, format(%4.1f) nogrid labcolor(black) ticks  angle(horizontal) tlcolor(gs10) tlwidth(medthick)) yscale(line noextend nofextend lcolor(gs10) lwidth(medthick)) xsize(10) ysize(6) "


graph drop _all
// Load data 
u "data\data_temp\analysisdata.dta",clear
		replace j_gives_opinion=1-j_didnotanswer
reghdfe j_gives_opinion 	i_female $controls	, absorb($absorb)
local beta: disp %4.2f _b[i_female]
local se: disp %4.2f _se[i_female]
reghdfe j_gives_opinion 	 $controls	, absorb($absorb) residuals(resid)
collapse (mean) resid i_female, by(i_Name)
quantiles resid, gen(q1) n(5)
su i_female
graph bar i_female,  $gs over(q1, axis(lcolor(gs10) lwidth(medthick)) ) subtitle("Gender difference: `beta'(`se')")  ytitle("Share of women")   title("Gives opinion",color(black)) b1title("1=least likely, 5 = most likely") yline(0.21)  ylab(0 0.1 0.2 0.3 0.4)  name(fig1)


// Load data 
u "data\data_temp\analysisdata.dta",clear
reghdfe j_uncertain 	i_female $controls	, absorb($absorb) 
local beta: disp %4.2f _b[i_female]
local se: disp %4.2f _se[i_female]
reghdfe j_uncertain 	 $controls	, absorb($absorb) residuals(resid)

collapse (mean) resid i_female, by(i_Name)
quantiles resid, gen(q1) n(5)
su i_female
graph bar i_female,$gs over(q1, axis(lcolor(gs10) lwidth(medthick)) )   subtitle("Gender difference: `beta'(`se')")  ytitle("Share of women") title("Uncertain",color(black)) b1title("1=least likely, 5 = most likely") yline(0.21)  ylab(0 0.1 0.2 0.3 0.4) name(fig2)
 
// Load data 
u "data\data_temp\analysisdata.dta",clear
reghdfe j_extreme 	i_female $controls	, absorb($absorb) 
local beta: disp %4.2f _b[i_female]
local se: disp %4.2f _se[i_female]
reghdfe j_extreme 	 $controls	, absorb($absorb) residuals(resid)
collapse (mean) resid i_female, by(i_Name)
quantiles resid, gen(q1) n(5)
su i_female
graph bar i_female,$gs  over(q1, axis(lcolor(gs10) lwidth(medthick)) )    subtitle("Gender difference: `beta'(`se')")  ytitle("Share of women") title("Strong opinion",color(black)) b1title("1=least likely, 5 = most likely") yline(0.21)  ylab(0 0.1 0.2 0.3 0.4) name(fig3)

// Load data 
u "data\data_temp\analysisdata.dta",clear
reghdfe j_anycomment 	i_female $controls	, absorb($absorb) 
local beta: disp %4.2f _b[i_female]
local se: disp %4.2f _se[i_female]
reghdfe j_anycomment 	 $controls	, absorb($absorb) residuals(resid)
collapse (mean) resid i_female, by(i_Name)
quantiles resid, gen(q1) n(5)
su i_female
graph bar i_female, $gs over(q1, axis(lcolor(gs10) lwidth(medthick)) )  subtitle("Gender difference: `beta'(`se')")   ytitle("Share of women") title("Any comment",color(black)) b1title("1=least likely, 5 = most likely") yline(0.21)  ylab(0 0.1 0.2 0.3 0.4) name(fig4)

// Load data 
u "data\data_temp\analysisdata.dta",clear
reghdfe j_Confidence 	i_female $controls	, absorb($absorb) 
local beta: disp %4.2f _b[i_female]
local se: disp %4.2f _se[i_female]
reghdfe j_Confidence 	 $controls, absorb($absorb) residuals(resid)
collapse (mean) resid i_female, by(i_Name)
quantiles resid, gen(q1) n(5)
su i_female

graph bar i_female, $gs over(q1, axis(lcolor(gs10) lwidth(medthick)) )  subtitle("Gender difference: `beta'(`se')")    ytitle("Share of women") title("Confidence",color(black)) b1title("1=least confident, 5 = most confident") yline(0.21) ylab(0 0.1 0.2 0.3 0.4) name(fig5)

graph combine fig1 fig4 fig2 fig3 fig5, graphregion(fcolor(white)) cols(2) ysize(10) xsize(8)
graph export  "output_files\\fig_distributions.png", width(2000) replace
	