/*****************************************************************************
data_build.do: prep data for igm analysis
*******************************************************************************/
// set working directory
cd  "C:\Users\hs17922\Dropbox\Work\Research\Projects\14 igm\analysis\mpc\" 
 
*cd  "/Users/hhs/Dropbox/Work/Research/Projects/14 igm/analysis/mpc" 

// load data
use "data/raw/mpcvoting.dta",clear
// clean (A lot of this is based on guessing)
rename date v_date
format v_date %td
rename member i_id
rename rate v_finalvote
gen   vi_expertvote=round(m,0.0001) //rounding issues
rename female i_female
rename internal i_internal
rename lastrate v_lastrate
drop temp n mnvote nonconsensus change trend  m
// most popular vote
bys v_date: gen  v_votes=_N
bys v_date vi_expertvote: gen vi_votefreq=_N
bys v_date: egen v_maxvotefreq=max(vi_votefreq)
gen _mpopularvote=vi_expertvote if v_maxvotefreq==vi_votefreq
bys v_date: egen _mpopularvotesd=sd(_mpopularvote)    // No ties
gen v_mostpopvoteshare=v_maxvotefreq/v_votes               // Never <0.5
bys v_date: egen v_mostpopvote=max(_mpopularvote)
drop _*

// most popular vote leave focal out (not very efficient, but works)
gen v_mostpopvote_lo=.
gen v_mostpopvoteshare_lo=.
levelsof(i_id),local(id)
tempfile tf
foreach v in `id' {
	preserve
		keep if i_id!=`v'
		bys v_date: gen  _v_votes=_N
		bys v_date vi_expertvote: gen _vi_votefreq=_N
		bys v_date: egen _v_maxvotefreq=max(_vi_votefreq)
		gen _mpopularvote=vi_expertvote if _v_maxvotefreq==_vi_votefreq
		gen _v_mostpopvoteshare=_v_maxvotefreq/_v_votes
		bys v_date: egen _v_mostpopvote=max(_mpopularvote)
		keep v_date _v_mostpopvoteshare _v_mostpopvote
		bys v_date: keep if _n==1
		gen i_id=`v'
		save `tf',replace
	restore
	merge 1:1 v_date i_id using `tf', nogen keep(1 3)
	replace v_mostpopvote_lo=_v_mostpopvote if _v_mostpopvote!=.
	replace v_mostpopvoteshare_lo=_v_mostpopvoteshare if _v_mostpopvoteshare!=.
	drop _*
}	
// Expert tenure
sort i_id v_date
by i_id (v_date): gen vi_tenure=_n
// vote characteristics
gen v_all_agree=v_mostpopvoteshare==1
gen v_vote_statusquo=v_lastrate==v_finalvote
gen v_vote_increase=v_lastrate>v_finalvote
gen v_vote_decrease=v_lastrate<v_finalvote
// vote times expert characteristics
gen vi_vote_against=vi_expertvote!=v_mostpopvote 
gen vi_vote_against_lo=vi_expertvote!=v_mostpopvote_lo
replace vi_vote_against_lo=. if v_mostpopvoteshare_lo<=0.5
gen int c=round(v_mostpopvoteshare_lo*10)
gen vi_vote_pivotal_lo=c==5
drop c
gen vi_vote_lower_lo=vi_vote_against==1 & v_mostpopvote_lo<vi_expertvote
gen vi_vote_higher_lo=vi_vote_against==1 & v_mostpopvote_lo>vi_expertvote
replace vi_vote_higher_lo=. if v_mostpopvoteshare_lo<=0.5
replace vi_vote_lower_lo=. if v_mostpopvoteshare_lo<=0.5
gen vi_voteagainstalone_lo=v_mostpopvoteshare_lo==1 & vi_expertvote!=v_mostpopvote_lo
replace vi_voteagainstalone_lo=. if v_mostpopvoteshare_lo<=0.5
gen vi_votestatusquo=vi_expertvote==v_lastrate
// labels
label var vi_tenure "Experience"
label var v_date "Date of vote"
label var i_id "Expert id"
label var v_finalvote "Decided rate"
label var v_lastrate "Last rate"
label var i_internal "Internal member"
label var i_female "Female"
label var vi_expertvote "Member's vote"
label var v_votes "Number of votes"
label var vi_votefreq "Number of votes for given vote"
label var v_maxvotefreq "Number of votes for most popular vote"
label var v_mostpopvoteshare "Vote share most popular vote"
label var v_mostpopvote "Most popular vote"
label var v_mostpopvote_lo "Most popular vote (LO)"
label var v_mostpopvoteshare_lo "Vote share most popular vote (LO)"
label var v_all_agree "Unanimous vote"
label var vi_vote_against "Vote against majority"
label var vi_vote_against_lo "Vote against majority"
label var vi_vote_pivotal_lo "Vote was pivotal"
label var vi_vote_lower_lo "Vote lower than majority"
label var vi_vote_higher_lo "Vote higher than majority"
label var vi_voteagainstalone_lo "Only one voting against"
label var vi_votestatusquo "Vote status quo"
label var v_vote_statusquo "Vote status quo"
label var v_vote_increase "Vote increase"
label var v_vote_decrease "Vote decrease"

// save
save "data/temp/analysisdata.dta",replace




