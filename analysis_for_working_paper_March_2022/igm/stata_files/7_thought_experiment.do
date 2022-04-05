/*****************************************************************************
thought_experiment.do
*******************************************************************************/
// set working directory
cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\igm" 

// globals
gl controls "i_cites_all i_hi_all  i_US_sample i_American i_European"
gl absorb   "q_Question i_inst i_phdyear"
gl gs " graphregion(lcolor(white) fcolor(white) )   ylab(, format(%4.2f) nogrid labcolor(black) ticks  angle(horizontal) tlcolor(gs10) tlwidth(medthick)) xscale(line noextend nofextend lcolor(gs10) lwidth(medthick))  yscale(line noextend nofextend lcolor(gs10) lwidth(medthick)) xsize(10) ysize(6) "

graph drop _all

postutil clear
postfile table femsh using "data\data_temp\winner.dta", replace

forvalues i = 1/1000 {
	// Load data 
u "data\data_temp\analysisdata.dta",clear

qui: byso q_id: gen newid = runiform()
qui: egen temp = min(newid), by(q_id i_female)
qui: gen pair = newid==temp
qui: keep if pair==1
qui: replace j_certainty = 0 if j_didnotanswer==1
qui: keep q_id i_female j_certainty j_Confidence
qui: reshape wide j_certainty j_Confidence, i(q_id) j(i_female)

qui: gen malewin = j_certainty0>j_certainty1
qui: replace malewin = 1 if (j_certainty1==1 & j_certainty0==1) & (j_Confidence0>j_Confidence1)
qui: replace malewin = 1 if (j_certainty1==2 & j_certainty0==2) & (j_Confidence0>j_Confidence1)

qui: gen femwin = j_certainty1>j_certainty0
qui: replace femwin = 1 if (j_certainty1==1 & j_certainty0==1) & (j_Confidence1>j_Confidence0)
qui: replace femwin = 1 if (j_certainty1==2 & j_certainty0==2) & (j_Confidence1>j_Confidence0)

qui: su malewin
qui: scalar m0 = r(mean)
qui: su femwin
qui: scalar m1 = r(mean)
qui: gen femsh = m1/(m1+m0)
qui: su femsh
qui: post table (r(mean)) 
        
    }

postclose table

u "data\data_temp\winner.dta",clear
su femsh
local a=r(mean)
local da: disp %4.2f `a'
gen above=femsh>=0.5
tab above

gen r=floor(femsh*100)
replace r=r+0.5
collapse (count) n=femsh, by(r)
sum n
gen share=n/r(sum)
replace r=r/100
tw (bar share r , fcolor("84 161 112") lwidth(none) barwidth(0.0095)) ///
   (bar share r if r>=.50 , fcolor("179 11 2") lwidth(none) barwidth(0.0095)) ///
    ,$gs xlab(0.3(0.05)0.55, tlcolor(gs10) format(%4.2f)) xtitle("Female expert heard ") legend(off) ///
	xline(`a') text(0.195 `a'  "Mean: `da'") ytitle("Share")
	graph export  "output_files\\fig_thoughtexperiment.png", width(2000) replace


