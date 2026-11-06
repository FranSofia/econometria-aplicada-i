***************************************
* Project: "Gonzalez & Karlan" - "Sex Ed, Colombia"
* Date: 
* Purpose: Do-file produces main analysis tables
***************************************

clear all
version 15.0
cap log close
set more off

   *SET FILE DIRECTORY & GLOBALS*
global path "YOUR PATH HERE"
global do "${path}\do"
global data "${path}\data"
global log "${path}\log"
global output "${path}\output"
global ssc "${path}\adofiles"

*CREATE LOGFILE*
log using "${log}\replication", smcl replace	

*CALL USER-WRITTEN COMMANDS
sysdir set PLUS "${ssc}"

*SET FILE PATH
cd "${path}"

*CALL DATASET
use "${data}\Colombia_Sex_Ed.dta", replace 


********************

* Table 2 - Baseline summary statistics and balance*

mat A=J(41,5,.)
mat A_STARS=J(41,5,0)

		qui tabstat calendarioa jornada schoolday bigcity grupostotales averagestudents nmerodecomputadores nosexed, by (treatmentstatus)  stats(mean semean) format(%9.2f) save
		mat A[1,1]=vec(r(Stat3))
		mat A[1,2]=vec(r(Stat2))
		mat A[1,3]=vec(r(Stat1))
		qui tabstat Male r1_notsexuallyactive age educationmother educationfather socioecon_level havePCathome_r1 havecellphone_r1 nointernetschool_r1 nointernetuse_r1 religion_r1, by (treatmentstatus )  stats(mean semean) format(%9.2f) save
		mat A[19,1]=vec(r(Stat3))
		mat A[19,2]=vec(r(Stat2))
		mat A[19,3]=vec(r(Stat1))
		
	local j 0
	foreach i in calendarioa jornada schoolday bigcity grupostotales averagestudents nmerodecomputadores nosexed Male  r1_notsexuallyactive age educationmother educationfather socioecon_level havePCathome_r1 havecellphone_r1 nointernetschool_r1 nointernetuse_r1 religion_r1 {
	local ++j

	foreach group in t_c s_c {
		local t 0
		local p 0
		local s 0
		local c 4
		reg `i' `group', cluster(Clusters)
		if "`group'"=="s_c" {
		local c= 5
		}
		matrix A[`j',`c'] = _b[`group']	
		local t = _b[`group']/_se[`group']
		local p = 2*ttail(e(df_r),abs(`t'))
		if `p'<0.01 {
		local s=1
		}
		else if `p'<0.05 & `p'>=0.01 {
		local s=2
		}
		else if `p'>=0.05 & `p'<0.1 {
		local s=3
		}
		matrix A_STARS[`j',`c'] = `s'		
		local j2 = `j'+1
		matrix A[`j2',`c'] = _se[`group']	
	}
	local ++j

		if "`j'"=="16" {
		di "1"
		local ++j
		local ++j
			}
	}




	foreach var in calendarioa jornada schoolday bigcity grupostotales averagestudents nmerodecomputadores nosexed Male r1_notsexuallyactive age educationmother educationfather socioecon_level havePCathome_r1 havecellphone_r1 nointernetschool_r1 nointernetuse_r1 religion_r1 {
   		local lbl: variable label `var'
	    if "`var'"=="nosexed" {
		local rnames `"`rnames' "`lbl'" "       s.e." " p-value joint significance" " ." "'
		}
   		else if "`var'"=="religion_r1" {
		local rnames `"`rnames' "`lbl'" "       s.e." "p-value joint significance" " ." "'
		}
    	else if "`var'"!="nosexed" & "`var'"!="religion_r1" {
   		local rnames `"`rnames' " `lbl'" " s.e." "'
		}

	}

	local cnames `" "Treatment students (1)" "Spillover students (2)" "Control students (3)" "Difference (1-3)" "Difference (2-3)""'


reg t_c calendarioa jornada schoolday bigcity grupostotales_survey averagestudents_survey nmerodecomputadores_survey nosexed_survey , cluster(Clusters)
	local f =Ftail(e(df_m),e(df_r), e(F))
	matrix A[17,4]=`f'
reg s_c calendarioa jornada schoolday bigcity grupostotales_survey averagestudents_survey nmerodecomputadores_survey nosexed_survey , cluster(Clusters)
	local f =Ftail(e(df_m),e(df_r), e(F))
	matrix A[17,5]=`f'
reg t_c Male r1_notsexuallyactive age educationmother educationfather socioecon_level havePCathome_r1 havecellphone_r1 nointernetschool_r1 nointernetuse_r1 religion_r1, cluster(Clusters)
	local f =Ftail(e(df_m),e(df_r), e(F))
	matrix A[41,4]=`f'
reg s_c Male r1_notsexuallyactive age educationmother educationfather socioecon_level havePCathome_r1 havecellphone_r1 nointernetschool_r1 nointernetuse_r1 religion_r1, cluster(Clusters)
	local f =Ftail(e(df_m),e(df_r), e(F))
	matrix A[41,5]=`f'

	xml_tab A, save("$output\Table2") replace sheet(`1', color(1))  cnames(`cnames') title(Table 2. Baseline Summary Statistics and Balance) notes("Clustered standard errors") noisily line(COL_NAMES 13 LAST_ROW 13) rnames(`rnames') font("Times New Roman" 10)

	matrix drop A


* Table 3 - Knowledge indicators

cap erase Table3.txt

foreach x in know_std_prev know_sexual_violence know_std_prevmeth know_preg_prev know_condom_use know {
    foreach y in r2 r3 {
  reg `y'_`x' treat spill r1_`x' dummyr1_`x' internetsurvey ,  cluster(Clusters)
  local num "append"
            if "`y'_`x'"=="r2_know_std_prev" {
      local num "replace"
      }
outreg2 treat spill using "${output}\Table3.xml", `num'  bdec(3) ctitle("`y'_`x'") slow(1000)  drop(internetsurvey r1_`x' dummyr1_`x')
}
}


*Table 4 - Attitude indicators

cap erase Table4.txt

foreach x in att_condom_use att_sexually_conserv att_sexual_violence  att {
    foreach y in r2 r3 {
  reg `y'_`x' treat spill r1_`x' dummyr1_`x' internetsurvey ,  cluster(Clusters)
	local num "append"
        if "`y'_`x'"=="r2_att_condom_use" {
	   local num "replace"
	   }	
outreg2 treat spill using "${output}/Table4.xml", `num'  bdec(3) ctitle("`y'_`x'") slow(1000) drop(internetsurvey r1_`x' dummyr1_`x')
}
}


*Table 5 - Sexual activity and condom voucher demand*

cap erase Table5.txt

foreach x in nosex6months timeshadsex6months sexpartners STDs havebeenpregn {
  local num "append"
    if "`x'"=="nosex6months" {
	 local num "replace"
	  }
  local phone ""
  local baseline ""
	if "`x'"=="nosex6months" | "`x'"=="havebeenpregn" {
	local phone phonesurvey
	}
	if "`x'"!="nosex6months" & "`x'"!="timeshadsex6months" {
	local baseline "r1_`x' dummyr1_`x' "
	}
 reg r3_`x' treat spill  internetsurvey  `baseline'  `phone' ,  cluster(Clusters)
 summ r3_`x' if e(sample) ==1 & treat==0 & spill==0
    local mean=r(mean)
	outreg2 treat spill using "${output}\Table5.xml", `num'  bdec(3) ctitle("`x'") addstat (mean of dep. var. control group, `mean') slow(5000) drop(internetsurvey r1_`x' dummyr1_`x' phonesurvey)
		}

   local x redeemedvoucher
   reg redeemedvoucher treat spill ,  cluster(Clusters)
   summ redeemedvoucher if e(sample) ==1  & treat==0 & spill==0
   local mean=r(mean)
   outreg2 treat spill  using "${output}\Table5.xml", bdec(3) ctitle("`x'") addstat (mean of dep. var. control group, `mean') slow(5000)

	
	 *Discussed in paper but not reported:
    //reg redeemedvoucher treat spill bus_reimbursement has_cellphone,  cluster(Clusters)
	
	


*Table 7 - Knowledge: Network spillover and reinforcing interaction effects

cap erase Table7.txt

foreach x in know_std_prev know_sexual_violence know_std_prevmeth know_preg_prev know_condom_use know {
  reg r3_`x' treat spill trat_mptrat spill_mptrat popul r1_`x' dummyr1_`x' internetsurvey, cluster(Clusters)
  test spill_mptrat = trat_mptrat
	local num "append"
        if "`x'"=="know_std_prev" {
	  local num "replace"
	   }
	local p1 = r(p)
outreg2 treat spill using "${output}/Table7.xml", `num'  bdec(3) ctitle("`x'") addstat (p-value treatment*friends=spillover*friends, `p1') slow(5000) drop(internetsurvey r1_`x' dummyr1_`x')
    }
	
	
*Table 8- Attitudes: Network spillover and reinforcing interaction effects*

cap erase Table8.txt

foreach x in att_condom_use att_sexually_conserv att_sexual_violence att {
  reg r3_`x' treat spill trat_mptrat spill_mptrat popul r1_`x' dummyr1_`x' internetsurvey , cluster(Clusters)
  test spill_mptrat = trat_mptrat
	local num "append"
        if "`x'"=="att_condom_use" {
	   local num "replace"
	   }
	local p1 = r(p)
outreg2 treat spill using "${output}/Table8.xml", `num'  bdec(3) ctitle("`x'") addstat (p-value treatment*friends=spillover*friends, `p1') slow(1000) drop(internetsurvey r1_`x' dummyr1_`x')
}


* Table 9- Sexual activity and condom demand: Network spillover and reinforcing interaction effects*

 foreach x in nosex6months timeshadsex6months sexpartners {
	   local num ""
           if "`x'"=="nosex6months" {
	       local num "replace"
	       }
	local phone ""
	local baseline ""
	   if "`x'"=="nosex6months"  {
	   local phone phonesurvey
	   }
	   if "`x'"!="nosex6months" & "`x'"!="timeshadsex6months" {
	   local baseline "r1_`x' dummyr1_`x' "
	   }
	xi: reg r3_`x' treat spill trat_mptrat spill_mptrat popul internetsurvey `baseline' `phone' , cluster(Clusters)
	summ r3_`x' if e(sample) ==1 & control==1
    local mean_control =r(mean)
	local sd_control=r(sd)
	test spill_mptrat = trat_mptrat
	local p1 = r(p)
	outreg2 treat spill using "${output}\Table9.xml", `num'  bdec(3) ctitle("`x'") drop(internetsurvey r1_`x' dummyr1_`x' `phone') addstat (p-value treatment*friends=spillover*friends, `p1', Mean of dep. var. control group, `mean_control', SD of dep. var. control group, `sd_control') slow(5000)
    }

    xi: reg redeemedvoucher treat spill trat_mptrat spill_mptrat popul internetsurvey has_cellphone, cluster(Clusters)
    	summ redeemedvoucher if e(sample) ==1  & control==1
        local mean_control =r(mean)
		local sd_control=r(sd)
		test spill_mptrat = trat_mptrat
		local p1 = r(p)
		outreg2 using "${output}/Table9.xml", append  bdec(3) ctitle("`x'")  drop(internetsurvey has_cellphone) addstat (p-value treatment*friends=spillover*friends, `p1', Mean of dep. var. control group, `mean_control', SD of dep. var. control group, `sd_control') slow(5000)



*Appendix Table 1: Summary statistics at baseline*

mat A=J(50,7,.)
mat A_STARS=J(50,7,0)
#delimit ;
local i 0;
foreach y in STDs_symptoms_vomit STDs_symptoms_headache STDs_symptoms_fluids
 STDs_symp_lessionparts STDs_symp_painfulur getHIVby_badhygiene
 getHIVby_food getHIVby_pool getHIVby_condom  getHIVby_nocondom  getHIVby_blood
 sexviolence_privateparts sexviolence_husband sexviolence_drunk sexviolence_wantedsex sexviolence_threatens morelikelytoabuse
 avoidSTDs_rythm avoidSTDs_injection avoidSTDs_withdrawal avoidSTDs_condoms
 thinkpulloutissafe myth_pregnant1stsex avoidpreg_rythm avoidpreg_withdrawal avoidpreg_inject avoidpreg_condom pill_sideeffects
 timesuseacondom avoidSTDs_condoms   getHIVby_nocondom getHIVby_condom condomsafest_pregnancy avoidpreg_condo
 bringacondom  nocondomifshenotwantto girl_responsiblepregn suretoaskuse_condom ifdonthavecondoms willuse_condoms
 ok_lotofsexualpartners waittosexolder appropage_girl appropage_boy waittohavesex
 sexviolence_nottell  sexviolence_tellathome sexviolence_police sexviolence_doctor sexviolence_other { ;

local ++i;
cap sum r1_`y' if r1_`y'!=. & dummyr1_`y'!=1, detail;
mat A[`i',1]=r(mean);
mat A[`i',2]=r(sd);
mat A[`i',3]=r(min);
mat A[`i',4]=r(max);
mat A[`i',5]=r(p25);
mat A[`i',6]=r(p75);
cap qui sum r1_`y' if r1_`y'!=. & dummyr1_`y'!=1, detail;
mat A[`i',7]=r(N);
local rnames `"`rnames' "`y'" "';
};
#delimit cr
xml_tab A, save("$output\AppT1") replace line(COL_NAMES 13 LAST_ROW 13)  rnames(`rnames') cnames("Mean" "SD" "MIN" "MAX" "Q25" "Q75" "N")



*Appendix Table 2 Attrition*

cap erase AppT2.txt

gen attrited_1=0 if answer_round_1==1
replace attrited_1=1 if answer_round_1==1 & answer_round_2==0
gen attrited_2=0 if answer_round_1==1
replace attrited_2=1 if answer_round_1==1 & answer_round_3==0
gen attrited_v=0 if answer_round_1==1
replace attrited_v=1 if answer_round_1==1 & redeemedvoucher==.

reg attrited_1 treat spill, cluster(Clusters)
	outreg2 treat spill using "${output}\AppT2.xml", replace  bdec(3) ctitle("`x'")
reg attrited_2 treat spill, cluster(Clusters)
	outreg2 treat spill using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")
reg attrited_v treat spill, cluster(Clusters)
	outreg2 treat spill using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")
	
 gen t_SES=treat*socioecon_level
 gen s_SES=spill*socioecon_level
 gen t_Efather=treat*educationfather
 gen s_Efather=spill*educationfather
 gen t_Emother=treat*educationmother
 gen s_Emother=spill*educationmother
reg attrited_1 t_SES s_SES socioecon_level, cluster(Clusters)
	outreg2 t_SES s_SES socioecon_level using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")
reg attrited_2 t_SES s_SES socioecon_level, cluster(Clusters)
	outreg2 t_SES s_SES socioecon_level using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")
reg attrited_v t_SES s_SES socioecon_level, cluster(Clusters)
	outreg2 t_SES s_SES socioecon_level using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")
reg attrited_1 t_Efather s_Efather educationfather, cluster(Clusters)
	outreg2 t_Efather s_Efather educationfather using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")
reg attrited_2 t_Efather s_Efather educationfather, cluster(Clusters)
	outreg2 t_Efather s_Efather educationfather using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")
reg attrited_v t_Efather s_Efather educationfather, cluster(Clusters)
	outreg2 t_Efather s_Efather educationfather using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")
reg attrited_1 t_Emother s_Emother educationmother, cluster(Clusters)
	outreg2 t_Emother s_Emother educationmother using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")
reg attrited_2 t_Emother s_Emother educationmother, cluster(Clusters)
	outreg2 t_Emother s_Emother educationmother using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")
reg attrited_v t_Emother s_Emother educationmother, cluster(Clusters)
	outreg2 t_Emother s_Emother educationmother using "${output}\AppT2.xml", append  bdec(3) ctitle("`x'")

log close
