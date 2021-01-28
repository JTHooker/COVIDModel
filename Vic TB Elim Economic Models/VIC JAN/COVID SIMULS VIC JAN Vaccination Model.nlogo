;; This version of the model has been speifically designed to estimate issues associated with Victoria's second wave of infections, beginning in early July
;; The intent of the model is for it to be used as a guide for considering differences in potential patterns of infection under various policy futures
;; As with any model, it's results should be interpreted with caution and placed alongside other evidence when interpreting results



extensions [ rngs profiler ]

globals [

  anxietyFactor
  NumberInfected
  InfectionChange
  TodayInfections
  YesterdayInfections
  five
  fifteen
  twentyfive
  thirtyfive
  fortyfive
  fiftyfive
  sixtyfive
  seventyfive
  eightyfive
  ninetyfive
  InitialReserves
  AverageContacts
  AverageFinancialContacts
  ScalePhase
  Days
  GlobalR
  CaseFatalityRate
  DeathCount
  DailyCases
  Scaled_Population
  ICUBedsRequired
  scaled_Bed_Capacity
  currentInfections
  eliminationDate
  PotentialContacts
  bluecount
  yellowcount
  redcount
  todayInfected
  cumulativeInfected
  scaledPopulation
  MeanR
  EWInfections
  StudentInfections
  meanDaysInfected
  lasttransday
  lastPeriod
  casesinperiod28
  casesinperiod14
  casesinperiod7
  resetDate ;; days after today that the policy is reviewed
  cashposition
  Objfunction ;; seeks to minimise the damage - totalinfection * stage * currentInfections
  decisionDate ;; a date (ticks) when policy decsions were made
  prior0
  prior1
  prior2
  prior3
  prior4
  prior5
  prior6
  prior7
  prior8
  prior9
  prior10
  prior11
  prior12
  prior13
  prior14
  prior15
  prior16
  prior17
  prior18
  prior19
  prior20
  prior21
  prior22
  prior23
  prior24
  prior25
  prior26
  prior27
  prior28

  stageHasChanged
  stageToday
  stageYesterday

  PrimaryUpper
  SecondaryLower

  meanIDTime


  ;; log transform illness period variables
  Illness_PeriodVariance
  M
  BetaillnessPd
  S


  ;; log transform incubation period variables
  Incubation_PeriodVariance
  MInc
  BetaIncubationPd
  SInc


  ;; log transform compliance period variables
  Compliance_PeriodVariance
  MComp
  BetaCompliance
  SComp

]


breed [ simuls simul ]
breed [ resources resource ]
breed [ medresources medresource ] ;; people living in the city
breed [ packages package ]


directed-link-breed [red-links red-link]


simuls-own [
  timenow ;; the number of days since initial infection
  health ;; baseline health of the individual
  inICU ;; whether the person is in ICU or not
  anxiety ;; person's level of anxiety aboutt he pandemic
  sensitivity ;; person's sensitivity to news about the pandemic
  R ;; the estimated RNaught of individuals
  income ;; people's income from wage / salary
  expenditure ;; people's expenditure
  reserves ;; cash reserves available to the person
  agerange ;; the age of the person in deciles
  contacts ;; the number of contacts the person has made in the model
  IncubationPd ;; the incubation perios of the illness ascribed to the person
  DailyRisk ;; the risk of death of the person per day based on their agerange
  RiskofDeath ;; the overall risk of deth for the person if they contract the illness based on their age
  Pace ;; the speed that pthe person moves around the environment
  PersonalTrust ;; the level of trust the person has in the Government
  WFHCap ;; capacity of the person to work from home
  RequireICU ;; a measure of whether the person needs ICU or not
  NewV ;; the calculation of the association the person has between the their experiences in the world and their experiences of the illness - used in R-W implementation
  saliencyMessage ;; saliency of the information coming to the person about COVID 19
  saliencyExperience ;; The saliency of the person's experiences in the world
  vMax ;; the maximum association the person can make between COVID-19 and their experience of the world
  vMin ;; the minimum association the person can '' '' '' '' '' ''' '' '' ''' '' '' '' '' '' ''' '' ' ''
  CareAttitude ;; the extent to which the person cares about protecting themselves and others from Covid
  SelfCapacity ;; The capacity of the person to care about protecting themselves and others form COVID
  newAssociationstrength ;;  a variable that is used in the calculation and carry-forward of NewV as above
  ownIllnessPeriod ;; unique illness period associated with the individual
  ownIncubationPeriod ;; unique incubation pd for the person - related to IncubationPd so can probably be cleaned up - IncubationPd is a legacy var as previously all incubation periods were identical
  ownComplianceWithIsolation ;; unique variable associated with compliance to Isocation of cases if infected
  asymptom ;; whether the person is asymptomatic or not
  personalVirulence ;; the infectivity of the person
  tracked ;; whether the person has been tracked by the health system
  Asymptomaticflag ;; indicator identifying Asymptomatic cases
  EssentialWorker ;; Variable used to determine whether the person is classified as an essential worker or not
  EssentialWorkerFlag ;; indicator of whether the person is an essentialworker or not
  Own_WFH_Capacity ;; Ability of the person to work from home
  hunted ;; has the person been traced using the phoneApp
  haveApp ;; for use in deterimining if the person has downloaded the app
  wearsMask ;; for use in determining if the person wears a face mask
  householdUnit ;; the id of the household the person belongs to
  studentFlag ;; identifies if the person is a student or not
  wearingMask ;; identifies if the person is wearing a mask or not
  currentVirulence ;; current virulence of the person on the day of their infection
  Imported ;; identifies imported cases
  adultsInHousehold ;; counts how many adults in a household for peole under 70
  homeLocation ;; this is where these people live
  ownMaskEfficacy ;; the efficacy of the person's own mask
  reported ;; has the person's case been reported yet
  detectable ;; Is the infected person detectable likelihood
  unDetectedFlag;; Indicates whether they are detected or not.
  returntoschool ;; a random number between 0 and 100 that determines whether the person will return to school (assuming they are a student) at time x
  isolating ;; is the person currently isolating?
  vaccinated ;; is the person vaccinated?
  vacc_Effective ;; is this effective in this person?
  IDTime ;; days into infection the person is identified as a case


  contacts7 ;; contacts from seven days ago
  contacts6
  contacts5
  contacts4
  contacts3
  contacts2
  contacts1 ;; contacts from today

]


Packages-own [
  value ;; stimulus value
]


patches-own [
  utilisation ;; indicator of whether any people are located on that patch of the environment or not
  destination ;; indicator of whether this location is a place that people might gather
]

medresources-own [
  capacity ;; bed capacity of hospital system
]

resources-own [
  volume ;; resources avaialable in resource pile
]


to setup
  ;;random-seed 50

  profiler:start

  rngs:init
   ;; random-seed  100 ;; for use in setting random nuber generator seeds

  clear-all
  ;;import-drawing "Background1.png" ;; imports MSD image

  ;; illness period estimation using ln transform
  set Illness_Periodvariance se_Illnesspd
  set BetaIllnessPd  ln ( 1 + ( illness_PeriodVariance / illness_period ^ 2))
  set M ( ln illness_period ) - ( BetaillnessPd / 2)
  set S sqrt BetaIllnessPd

    ;; illness period estimation using ln transform
  set Incubation_Periodvariance se_Incubation
  set BetaIncubationPd  ln ( 1 + ( incubation_PeriodVariance / incubation_period ^ 2))
  set MInc ( ln incubation_period ) - ( BetaincubationPd / 2)
  set SInc sqrt BetaIncubationPd

    ;;

   ;; illness period estimation using beta distribution transform
;  set compliance_PeriodVariance se_Compliance
;  set BetaCompliance  ln ( 1 + ( compliance_PeriodVariance / compliance_with_isolation ^ 2))
;  set MComp ( ln compliance_with_isolation ) - ( BetaCompliance / 2)
;  set SComp sqrt BetaCompliance


;to-report newvar [ #alpha #beta ]
;  let XX random-gamma #alpha 6
;  let YY random-gamma #beta 1
;  report XX / (XX + YY)
;end


  ask red-links [ set color red ]
;; sets color of patches to black
  ask patches [ set pcolor black ]
  ask n-of (count patches * Outside ) patches [ set pcolor green ] ;; sets a proportion of interactions outside vs inside
  ask n-of 100 patches with [ pcolor = black ] [ set destination 1 ] ;; a beta function for testing locating many people in one place at a single time

 ;; setting up the hospital
  ask n-of 1 patches [ sprout-medresources 1 ]
  ask medresources [ set color white set shape "Health care" set size 5 set xcor 20 set ycor -20 ]
  calculateScaledBedCapacity
  ask medresources [ ask n-of Scaled_Bed_Capacity patches in-radius 5 [ set pcolor white ] ]
  ask n-of Available_Resources patches [ sprout-resources 1 ]

 ;; sets up resources that people want to purchase
  ask resources [ set color white set shape "square" set size 5 set volume one-of [ 2.5 5 7.5 10 ]  resize set xcor -20 set ycor one-of [ -30 -10 10 30 ] resetlanding ]

 ;; set up people in the environment and allocates characteristics to them
  ask n-of Population patches with [ pcolor = black ]
    [ sprout-simuls 1
      [ set size 2 set shape "dot" set color 85 set householdUnit random 1000 set agerange 95  set timenow 0 set IncubationPd int ownIncubationPeriod set InICU 0 set anxiety 0 set sensitivity random-float 1 set R 0
        set income random-exponential mean_Individual_Income    move-to one-of patches with [ pcolor = black  ]
        set riskofdeath .01 set personalTrust random-normal 75 10  set WFHCap random 100 set requireICU random 100 set personalVirulence random-normal Global_Transmissability 10 set haveApp random 100
        set wearsMask random 100 ;; resethealth resetincome calculateincomeperday calculateexpenditureperday resettrust

        set detectable random 100 ;; identifies whether the person is detectable or not
        set returntoschool random 100

        set ownIllnessPeriod ( exp random-normal M S ) ;; log transform of illness period
        set ownIncubationPeriod ( exp random-normal Minc Sinc ) ;;; log transform of incubation period
        ;;set ownComplianceWithIsolation ( exp random-normal Mcomp SComp )  ;; log transform of compliance with isolation


        rngs:init ;; replacing previous log transform with beta distribution
        let stream_id random-float 999
        let seed random-float 999
        rngs:set-seed stream_id seed
        let complianceDist rngs:rnd-beta  stream_id 450.3 23.7
        set ownComplianceWithIsolation complianceDist
        let maskWearEfficacy rngs:rnd-beta stream_id 24.3 8.08
        set ownMaskEfficacy maskWearEfficacy * Mask_Efficacy_Discount  ;; assigning mask efficacy to individuals around a distribution with median 75% or 75% x 1/3 if 33 as per request based on Burnett Institute #s

        set asymptom random 100
        set essentialWorker random 100
        if agerange >= 18 and agerange < 70 [ set essentialWorker random 100 ]
        setASFlag
        iterateAsymptomAge
        resetPersonalVirulence
        assignApptoEssential
        assigndetectablestatus ;; identifies people unlikely to be found
       ;set pta random-float ((Proportion_time_avoid - (Proportion_Time_Avoid * .2)) + random-float (Proportion_time_avoid + (1 - Proportion_time_avoid) * .2))
       ;set ppa random-float ((Proportion_People_avoid - (Proportion_People_Avoid * .2)) + random-float (Proportion_People_avoid + (1 - Proportion_People_avoid) * .2))

       ]]

  ;; set up initial infected people

  set scalephase InitialScale

  set resetdate 7 ;; sets up the initial date for looking at policy-changes

  ask n-of ( Current_Cases ) simuls [  set color red set tracked 1 set reported 1 set timenow random int OwnIllnessperiod UpdatePersonalVirulence
    if timenow <= 7 [ iteratetimenow ] ] ;; includes a proportion reported cases in the community at the initialisation step matched to current day data

  ;; put a function in here that iterates this


  ask n-of ((Current_Cases * (AsymptomaticPercentage / 100)  * ( Undetected_Proportion / 100 ))) simuls [  set color red set asymptomaticFlag 1 set undetectedFlag 1 set tracked 0 set reported 0 set timenow random int OwnIllnessperiod UpdatePersonalVirulence
    if timenow <= 7 [ set timenow random int Ownillnessperiod UpdatepersonalVirulence ] ] ;; includes a proportion of undetected cases in the community at the initialisation step

 ;; ask n-of 90 simuls with [ color = 85 ] [  set reported 1 set color yellow set timenow 0 set health (100 - agerange ) set inICU 0 set requireICU 0  ] ;; this is for the MJA paper

  if count simuls with [ color = red ] <= 1 [ ask n-of 1 simuls [ set xcor 0 set ycor 0 set color red set timenow int ownIllnessperiod - 1 ] ;; sould be 'ownincubationperiod' for new outbreaks
 ]

  ;; assigns death risks for people based on their age-range

  set five int ( Population * .126 ) ;; insert age range proportions here
  set fifteen int ( Population * .121 )
  set twentyfive int ( Population * .145 )
  set thirtyfive int ( Population * .145 )
  set fortyfive int ( Population * .129 )
  set fiftyfive int ( Population * .121 )
  set sixtyfive int ( Population * .103 )
  set seventyfive int ( Population * .071 )
  set eightyfive int ( Population * .032 )
  set ninetyfive int ( Population * .008 )

  matchages ;; assigns risk to age ranges (see below)

  ask simuls [ set health ( 100 - Agerange + random-normal 0 2 ) calculateDailyrisk setdeathrisk    ] ;; spend CalculateIncomePerday

  ;;assigns health based on age plus error, perfoms all other functions listed in the brackets - see details of each, below

  set contact_radius 0 ;; sets contact radius of people
  set days 0 ; used to count days since events - currently redundant
  set Quarantine false
  set eliminationDate 0 ; used to identify the date of elimination where no current, unrecovered cases exist
  set Proportion_People_Avoid PPA ;; used to set the proportion of people who are socially distancing
  set Proportion_Time_Avoid PTA ;; used to set the proportion of time that people who are socially distancing are socially distancing (e.g., 85% of people 85% of the time)
  set spatial_distance false
  set case_isolation false
  ;;set stage 0 ;; starts the simulation off at zero policy settings

  ;; setting households up


  ask simuls with [ agerange > 18 and agerange <= 60 ] [ if 95 > random 100 [ set householdUnit random 600 ] ] ;; allocates adults to a household unit range
  ask simuls with [ agerange > 60 and agerange <= 80 ] [ if 95 > random 100 [ set householdUnit random 200 + 600 ] ] ;; allocated older adults to household Units that don't include young children or teenagers
  ask simuls with [ agerange > 80 ] [ if 95 > random 100 [ set householdUnit random 300 + 600 ] ] ;; allocated older adults 80+  to household Units that don't include young children or teenagers
  ask simuls with [ agerange > 18 and agerange <= 60 ] [ if 95 > random 100 [ if count simuls with [ householdUnit = [ householdUnit ] of myself ] > 2 [
    set householdUnit random 600 ] ] ]  ;; allocates up to two adults per household
  ask simuls with [ agerange = 15 and agerange = 5 and studentFlag != 1 ] [ if 95 > random 100 [ set householdUnit [ householdUnit ] of one-of simuls with [ householdUnit <= 600 and agerange > ([ agerange ] of myself + 20) ] ]  ] ;; Identifies students
 ;; ask simuls [ if agerange < 20 [ set studentFlag 1 ]  ]

  ;; allocates children and teenagers to a household where there are adults at least 20 years older than them and there are not more than 2 adults in the house

  resetHouseholdUnit ;; iterates this process
  ask simuls [ resetlandingSimul ]




  ask simuls [
    if any? other simuls in-radius 3 with [ color = red ] and Household_Attack > random 100 [ set color yellow ]
  ] ;; this ensures that half the people in households with existing infections have also had an infection and prevents a big spike early-on


  ask simuls [
    if agerange = 5 and 60 > random 100 [ set AsymptomaticFlag 1 ]
  ]



  ;;set tracking false ;; ensures this is set to false each time the model starts
  ;;set link_switch false ;; ensures this is set to false each timme the model starts
  ;;set schoolspolicy false ;; ensures that the schools settings don't begin before the policy trigger starts
  ;;set maskPolicy false ;; that the mask policy doesn't begin before the policy trigger starts
  ;;set assignAppEss false ;; that the assigning the App to EssentialWorkers doesn't begin before the policy trigger starts
  reset-ticks
   setupstages ;; setting up for the MJA runs
end

to matchages
  ask n-of int five simuls [ set agerange 5 ]
  ask n-of int fifteen simuls with [ agerange != 5 ] [ set agerange 15 ]
  ask n-of int twentyfive simuls with [ agerange > 15 ] [ set agerange 25 ]
  ask n-of int thirtyfive simuls with [ agerange > 25 ] [ set agerange 35 ]
  ask n-of int fortyfive simuls with [ agerange > 35 ] [ set agerange 45 ]
  ask n-of int fiftyfive simuls with [ agerange > 45 ] [ set agerange 55 ]
  ask n-of int sixtyfive simuls with [ agerange > 55 ] [ set agerange 65 ]
  ask n-of int seventyfive simuls with [ agerange > 65 ] [ set agerange 75 ]
  ask n-of int eightyfive simuls with [ agerange > 75 ] [ set agerange 85 ]
 ;; ask n-of int ninetyfive simuls with [ agerange > 85 ] [ set agerange 95 ] ;;; remaining people in the model are in their 90's as everying is set an agerange of 95 at initialisation
end

to setdeathrisk
  if agerange = 5 [ set riskofDeath 0 ] ;; risk of death associated with ageranges if they contract COVID-19
  if agerange = 15 [ set riskofDeath .002 ]
  if agerange = 25 [ set riskofDeath .002 ]
  if agerange = 35 [ set riskofDeath .002 ]
  if agerange = 45 [ set riskofDeath .004 ]
  if agerange = 55 [ set riskofDeath .01  ]
  if agerange = 65 [ set riskofDeath .05  ]
  if agerange = 75 [ set riskofDeath .05  ]
  if agerange = 85 [ set riskofDeath .151 ]
  if agerange = 95 [ set riskofDeath .151 ] ;; updated from department of health Report 22 - does not map directly to age deciles here
end

to resetlanding
  if any? other resources-here [ set ycor one-of [ -30 -10 10 30 ] resetlanding ] ;; ensures that resources don't start on top of one another in the model
end

to iteratetimenow
  set timenow random int Ownillnessperiod UpdatepersonalVirulence
  if timenow <= 7 [ iteratetimenow ]

end

to resethouseholdUnit ;; allocates children to households
  if schoolsPolicy = true [
    ask simuls with [ agerange > 18 and agerange <= 60 ] [ if count simuls with [ householdUnit = [ householdUnit ] of myself ] > 2 and 95 > random 100 [
    set householdUnit random 600 ] ] ;; allows for upo 5% of houses to be sharehouses / care facilities, etc.
  ask simuls with [ agerange > 60 ] [ if count simuls with [ householdUnit = [ householdUnit ] of myself ] > 2 and 93 < random 100 [
    set householdUnit [ householdUnit ] of one-of simuls with [ count other simuls with [ householdUnit = [ householdUnit ] of myself ] = 0  ]]];; allows for older people in group homes to make up to 7% of housing units
  ]
end

to resetlandingSimul
  move-to one-of simuls with [ pcolor = black and householdUnit = [ houseHoldUnit ] of myself ] ;; now working so home locations are not in green space
  set homeLocation patch-here
  if 50 > random 100 [ move-to one-of patches with [ pcolor = black and utilisation = 0 ] ]
  ;; if any? other simuls-here with [ householdUnit != [ householdUnit] of myself ] [
  ;; iterates / sorts people into households
end

;to resetincome
;  if agerange >= 18 and agerange < 70 and income < 10000 [ ;;assigns income to working age-people
;    set income random-exponential Mean_Individual_Income ]
;end

;to resethealth
;  if health < 0 [
;    set health (100 - agerange) + random-normal 0 5 ] ;; sets a level of health related to age, which makes older pople more vulnerable - now redundant in current verison but potentially undeful to keep
;end

;to resettrust
;  if personalTrust > 100 or PersonalTrust < 0 [ ;; trust of individuals in the Goovernment
;    set personalTrust random-normal 75 10 ]
;end

;to calculateIncomeperday
;  if agerange >= 18 and agerange < 70 [ ;; estimates earnings per day based on contacts
;    set income income ]
;end
;
;to calculateexpenditureperday
;  set expenditure income ;; sets levels of expenditure to be equal to income for simplicity
;end

to calculatedailyrisk
  set dailyrisk ( riskofDeath / Illness_period ) ;; estimates risk of death per day for the duration of the period of illness -used for stats more than calibrated to real world given most people die late in the illness period
end

to resetPersonalVirulence ;; ensures that personalVirulence is within bounds
  if personalVirulence > 100 [ set personalVirulence random-normal global_Transmissability 10 ]
  if personalVirulence < 0 [ set personalVirulence random-normal global_Transmissability 10 ]
end

to iterateAsymptomAge ;;
  if freeWheel = false and PolicyTriggerOn = true and schoolsPolicy = true [
    ask n-of ((count simuls with [ agerange < 19 ] ) * AsymptomaticPercentage ) simuls with [ agerange <= 18 ] [ set asymptom random asymptomaticPercentage ] ;; places proportion of people under 18 into the asymptomatic category
    ask n-of ((count simuls with [ agerange < 19 ] ) * AsymptomaticPercentage ) simuls with [ agerange > 18 ] [ set asymptom random (asymptomaticPercentage ) + (100 - AsymptomaticPercentage) ] ;; takes older people out of the asymptomatic category
    ;and puts them in the symptomatic category to keep total percentages of asymptomatic cases consistent with input slider
  ]
end

to assignApptoEssential ;; allocates the COVID-Safe app to essential works that can be adjusted using the EWAppUptake slider, which maxes at 1.0 meaning 100% allocation
  if AssignAppEss = true [
    ask n-of ( count simuls with [ essentialWorkerFlag = 1 ] * eWAppUptake ) simuls with [ essentialWorkerFlag = 1 ] [ set haveApp (random App_Uptake)]] ;; assigns the app to a proportion of essential workers determined by EWAppUptake
end

to setASFlag
  if asymptom <= asymptomaticPercentage [ set asymptomaticFlag 1  ] ;;; records an asymptomatic flag for individual people
end

to assigndetectablestatus
  if asymptomaticFlag = 1 and detectable < Undetected_Proportion [ set unDetectedFlag 1 ]
end

to go ;; these funtions get called each time-step
  ask simuls [ move recover settime death isolation reinfect createanxiety gatherreseources treat Countcontacts respeed checkICU traceme EssentialWorkerID hunt AccessPackage checkMask updatepersonalvirulence visitDestination HHContactsIso vaccinate_me ] ;; calculateIncomeperday earn financialstress
  ; *current excluded functions for reducing processing resources**
  ask medresources [ allocatebed ]
  ask resources [ deplete replenish resize spin ]
  ask packages [ absorbshock movepackages ]
  setupstages
  finished
  CruiseShip
  GlobalTreat
  Globalanxiety
  SuperSpread
  CountInfected
  CalculateDailyGrowth
  TriggerActionIsolation
  DeployStimulus
  ;;setInitialReserves
  CalculateAverageContacts
  ScaleUp
  ForwardTime
  Unlock
  setCaseFatalityRate
  countDailyCases
  calculatePopulationScale
  calculateICUBedsRequired
  calculateScaledBedCapacity
  calculateCurrentInfections
  calculateEliminationDate
  assesslinks
  calculatePotentialContacts
  countRed
  countBlue
  countYellow
  scaledownhatch
  calculateYesterdayInfected
  calculateTodayInfected
  calculateScaledPopulation
  calculateMeanR
  OSCase
  stopFade
  ;;seedCases
  avoid
  turnOnTracking
  countEWInfections
  countSchoolInfections
  finished
  calculateMeanDaysInfected
  ;;profilerstop
  traceadjust
  linearbehdecrease
  ;;visitDestination
  CovidPolicyTriggers
  calculateCasesInLastPeriod
  ;;calculateCashPosition
  calculateObjfunction
  updateoutside
  ;;updatestudentStatus
  incursion
  CalculateMeanIDTime
  VaccineBrand
  ask patches [ checkutilisation ]
 tick

end


to move ;; describes the circumstances under which people can move and infect one another
 if ticks > 1 [  let randombinary random 2 ;; this is assigned per agent so day and night are not aligned across people - this is deliberate

  ifelse randombinary = 1 [

  if color != red or color != black and spatial_Distance = false [ set heading heading + Contact_Radius + random 45 - random 45 fd random pace avoidICUs ] ;; contact radius defines how large the circle of contacts for the person is.

  ;;Infection transmission - inside

  if any? other simuls-here with [ color = red and asymptomaticFlag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 0 ] and color = 85 and [ pcolor ] of patch-here = black  [
    set color red set timenow 0 traceme ] ;; reduces capacity of asymptomatic people to pass on the virus by 1/3

  if any? other simuls-here with [ color = red and asymptomaticFlag = 0 and currentVirulence > random 100 and wearingMask = 0  ] and color = 85 and [ pcolor ] of patch-here = black  [
    set color red set timenow 0 traceme ] ;; people who are symptomatic pass on the virus at the rate of their personal virulence, which is drawn from population means

  if any? other simuls-here with [ color = red and asymptomaticFlag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 1 ] and color = 85 and random 100 > ownMaskEfficacy and [ pcolor ] of patch-here = black  [
    set color red set timenow 0 traceme ] ;; accounts for a % reduction in transfer through mask wearing

  if any? other simuls-here with [ color = red and asymptomaticFlag = 0 and currentVirulence > random 100 and wearingMask = 1 ] and color = 85 and random 100 > ownMaskEfficacy and [ pcolor ] of patch-here = black  [
    set color red set timenow 0 traceme ] ;; accounts for a % reduction in transfer through mask wearing

  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 1 and random 100 > ownMaskEfficacy and [ pcolor ] of patch-here = black
  [ set R R + 1 set GlobalR GlobalR + 1 ]  ;; asymptomatic and wearing mask
  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 0 and currentVirulence  > random 100 and wearingMask = 1 and random 100 >  ownMaskEfficacy and [ pcolor ] of patch-here = black
  [ set R R + 1 set GlobalR GlobalR + 1 ] ;; symptomatic and wearing mask

  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 0 and [ pcolor ] of patch-here = black
  [ set R R + 1 set GlobalR GlobalR + 1 ] ;; asymptomatic and not wearing mask
  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 0 and currentVirulence  > random 100 and wearingMask = 0 and [ pcolor ] of patch-here = black
  [ set R R + 1 set GlobalR GlobalR + 1 ] ;; symptomatic and not wearing mask

  ;; Infection transmission outside

  if any? other simuls-here with [ color = red and asymptomaticFlag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 0 ] and color = 85 and [ pcolor ] of patch-here = green and outsiderisk < random 100  [
    set color red set timenow 0 traceme ] ;; reduces capacity of asymptomatic people to pass on the virus by 1/3

  if any? other simuls-here with [ color = red and asymptomaticFlag = 0 and currentVirulence > random 100 and wearingMask = 0  ] and color = 85 and [ pcolor ] of patch-here = green and outsiderisk < random 100   [
    set color red set timenow 0 traceme ] ;; people who are symptomatic pass on the virus at the rate of their personal virulence, which is drawn from population means

  if any? other simuls-here with [ color = red and asymptomaticFlag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 1 ] and color = 85 and random 100 > ownMaskEfficacy and [ pcolor ] of patch-here = green and outsiderisk < random 100  [
    set color red set timenow 0 traceme ] ;; accounts for a % reduction in transfer through mask wearing

  if any? other simuls-here with [ color = red and asymptomaticFlag = 0 and currentVirulence > random 100 and wearingMask = 1 ] and color = 85 and random 100 > ownMaskEfficacy and [ pcolor ] of patch-here = green and outsiderisk < random 100  [
    set color red set timenow 0 traceme ] ;; accounts for a % reduction in transfer through mask wearing

  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 1 and random 100 > ownMaskEfficacy and [ pcolor ] of patch-here = green and outsiderisk < random 100
  [ set R R + 1 set GlobalR GlobalR + 1 ]  ;; asymptomatic and wearing mask
  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 0 and currentVirulence  > random 100 and wearingMask = 1 and random 100 >  ownMaskEfficacy and [ pcolor ] of patch-here = green and outsiderisk < random 100
  [ set R R + 1 set GlobalR GlobalR + 1 ] ;; symptomatic and wearing mask

  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 0 and [ pcolor ] of patch-here = green and outsiderisk < random 100
  [ set R R + 1 set GlobalR GlobalR + 1 ] ;; asymptomatic and not wearing mask
  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 0 and currentVirulence  > random 100 and wearingMask = 0 and [ pcolor ] of patch-here = green and outsiderisk < random 100
  [ set R R + 1 set GlobalR GlobalR + 1 ] ;; symptomatic and not wearing mask


    ;; these functions reflect those above but allow the Reff to be measured over the course of the simulation


  if color = red and Case_Isolation = false and ownCompliancewithIsolation * 100 < random 100 and health > random 100 [ set heading heading + random 90 - random 90 fd random pace ]  ;; non-compliant people continue to move around the environment unless they are very sick
  if color = red and Quarantine = false [ avoidICUs ] ;; steers people away from the hospital
  if color = black [ move-to one-of MedResources ] ;; hides deceased simuls from remaining simuls, preventing interaction
 ] ;; this considers how mobile people are

  [ move-to homeLocation  ]


   if any? other simuls-here with [ color = red and asymptomaticFlag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 0 ] and color = 85  [
    set color red set timenow 0 traceme ] ;; reduces capacity of asymptomatic people to pass on the virus by 1/3

  if any? other simuls-here with [ color = red and asymptomaticFlag = 0 and currentVirulence > random 100 and wearingMask = 0  ] and color = 85  [
    set color red set timenow 0 traceme ] ;; people who are symptomatic pass on the virus at the rate of their personal virulence, which is drawn from population means

  if any? other simuls-here with [ color = red and asymptomaticFlag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 1 ] and color = 85 and random 100 > ownMaskEfficacy  [
    set color red set timenow 0 traceme ] ;; accounts for a % reduction in transfer through mask wearing

  if any? other simuls-here with [ color = red and asymptomaticFlag = 0 and currentVirulence > random 100 and wearingMask = 1 ] and color = 85 and random 100 > ownMaskEfficacy  [
    set color red set timenow 0 traceme ] ;; accounts for a % reduction in transfer through mask wearing

  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 1 and random 100 > ownMaskEfficacy
  [ set R R + 1 set GlobalR GlobalR + 1 ]  ;; asymptomatic and wearing mask
  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 0 and currentVirulence  > random 100 and wearingMask = 1 and random 100 >  ownMaskEfficacy
  [ set R R + 1 set GlobalR GlobalR + 1 ] ;; symptomatic and wearing mask

  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 1 and ( currentVirulence * Asymptomatic_Trans ) > random 100 and wearingMask = 0
  [ set R R + 1 set GlobalR GlobalR + 1 ] ;; asymptomatic and not wearing mask
  if any? other simuls-here with [ color = 85 ] and color = red and Asymptomaticflag = 0 and currentVirulence  > random 100 and wearingMask = 0
  [ set R R + 1 set GlobalR GlobalR + 1 ] ;; symptomatic and not wearing mask

    ;; these functions reflect thos above but allow the Reff to be measured over the course of the simulation
  ]
end


to avoid ;; these are the circustances under which people will interact
ask simuls [
  (ifelse
      Spatial_Distance = true and (Proportion_People_Avoid + random-normal 0 3) > random 100 and (Proportion_Time_Avoid + random-normal 0 3) > random 100 and AgeRange > Age_Isolation and EssentialWorkerFlag = 0 [
        if any? other simuls-here with [ householdUnit != [ householdUnit ] of myself ]
        [ if any? neighbors with [ utilisation = 0  ] [ move-to one-of neighbors with [ utilisation = 0 ] ]]]
      ;; so, if the social distancing policies are on and you are distancing at this time and you are not part of an age-isolated group and you are not an essentialworker, then if there is anyone near you, move away if you can.
      ;; else...
      Spatial_Distance = true and (Proportion_People_Avoid + random-normal 0 3) > random 100 and (Proportion_Time_Avoid + random-normal 0 3) > random 100 and AgeRange > Age_Isolation and EssentialWorkerFlag = 1 [
        if any? other simuls-here with [ householdUnit != [ householdUnit ] of myself ]
        [ if any? neighbors with [ utilisation = 0  ] and Ess_W_Risk_Reduction > random 100  [ move-to one-of neighbors with [ utilisation = 0 ] ]]];;; if you are an essential worker, you can only reduce your
      ;;contacts when you are not at work assuming 8 hours work, 8 hours rest, 8 hours recreation - rest doesn't count for anyone, hence it is set at 50 on the input slider. People don't isolate from others in their household unit

      [ set heading heading + contact_Radius fd random pace avoidICUs move-to patch-here ])] ;; otherwise just move wherever you like

  if policyTriggerOn = true and freewheel = false and schoolsPolicy = true and ticks >= triggerday + SchoolReturnDate [ ask simuls with [ studentFlag = 1 ] [ ;; same thing but specifically targets the movement of students if the schools policy is turned on - that is
    ;;if students are expected to return to school ;; schoolspolicy = true means 'go to school = true
     ifelse Spatial_Distance = true and Proportion_People_Avoid + random-normal 0 3 > random 100 and Proportion_Time_Avoid + random-normal 0 3 > random 100 and AgeRange > Age_Isolation  [
      if any? other simuls-here with [ householdUnit != [ householdUnit ] of myself or studentFlag != 1 ]  [ ;; students don't isolate from each other or their household unit
        if any? neighbors with [ utilisation = 0 ] and Ess_W_Risk_Reduction > random 100 [ move-to one-of neighbors with [ utilisation = 0 ] ]]];;; if you are a student, you avoid everyone you can except for essential workers (i.e., teachers),  other students
   ;; and people from your own household
   ;;   [ set heading heading + contact_Radius fd pace avoidICUs move-to patch-here ] ;; just testing this to see if it creates more interaction among households and students
    [ move-to one-of simuls with [ essentialworkerflag = 1 or householdUnit = [ householdUnit ] of myself or studentFlag = 1 ]]
    ]
]

end

to finished
  if freewheel = true [ ;; stops the model if the following criteria are met - no more infected people in the simulation and it has run for at least 10 days
    if ticks > 100 and count simuls with [ color = red ] = 0  [ stop ]
   ]
end

to settime
  if color = red [ set timenow timenow + 1 PossiblyDie ] ;; asks simuls to start counting the days since they became infected and to also possibly die - dying this way currently not implemented but done at the end of the illness period, instead
end

to superSpread
  if count simuls with [ color = red and tracked = 0 ] > 1 and Case_Isolation = false [  if Superspreaders > random 100 [ ;; asks some people who are infected and not tracked to move to random new areas,
    ;;potentially among susceptible people if travel restrictions are not current
    ask n-of int (count simuls with [ color = red and tracked = 0  ] / Diffusion_Adjustment ) simuls with [ color = red and tracked = 0 ] [ fd world-width / 2 ]

    if count simuls with [ color = yellow ] >= Diffusion_Adjustment [ ask n-of int ( count simuls with [ color = yellow ] / Diffusion_Adjustment ) Simuls with [ color = yellow ] [fd world-width / 2]]]]
  ;; same as above but for recovered people to take into account immunity in the population

  if count simuls with [ color = red and timenow < ownIncubationPeriod and tracked = 0 ] > Diffusion_Adjustment and Case_Isolation = true [  if Superspreaders > random 100 [
    ask n-of int (count simuls with [ color = red and timenow < ownIncubationPeriod and tracked = 0 ] / Diffusion_Adjustment ) simuls with [ color = red and timenow < ownIncubationPeriod and tracked = 0 ] [fd world-width / 2]
    ;; only moves people who don't know they are sick yet

  if count simuls with [ color = yellow ] >= 1 [ ask n-of int (count simuls with [ color = yellow ] / Diffusion_Adjustment) simuls with [ color = yellow ]
      [ fd world-width / 2 ]]]] ;; this ensures that people with immunity also move to new areas, not just infected people
end

to recover
  if timenow > ownillnessperiod and color != black  [
    set color yellow set timenow 0 set health (100 - agerange ) set inICU 0 set requireICU 0  ] ;; if you are not dead at the end of your illness period, then you become recovered and turn yellow and don;t need hospital resources, anymore
end

to reinfect
  if color = yellow and ReinfectionRate > random 100 [ set color 85 ] ;; if you are recovered but suceptible again, you could become reinfected
end

to allocatebed
  if freewheel = true [ ask patches in-radius Bed_Capacity [ set pcolor white ] ] ;; this allow bed capacity to be altered dynamically mid simulation if desired
end

to avoidICUs
  if [ pcolor ] of patch-here = white and InICU = 0 [ move-to min-one-of patches with [ pcolor = black ]  [ distance myself ]  ] ;; makes sure that simulswho have not been sent to hospital stay outside
end


;;;;;*********RESOURCES********************

to gatherreseources
  if (anxiety * sensitivity) > random 100 and count resources > 0 and InICU = 0  [ face min-one-of resources with [ volume >= 0 ] [ distance myself ]  ]
  if any? resources-here with [ volume >= 0 ] and anxiety > 0 [ set anxiety mean [ anxietyfactor ] of neighbors move-to one-of patches with [ pcolor = black ] ]
end

to replenish
  if volume <= 10 and productionrate > random 100 [ ;; re-stocking resources at a rate set by the production rate
    set volume volume + 1 ]
end

to deplete
  if any? simuls in-radius 1 and volume > 0 [ ;; deplete resources if simuls are present to take them
    set volume volume - .1 ]
end

to resize
  set size volume * 2
  ifelse volume < 1 [ set color red ] [ set color white ]
end

to spin
  set heading heading + 5
end

;;;;;*********END OF RESOURCES********************


;;;*******************ANXIETY******************::::::::::::::::::

to createanxiety
  set anxiety ( anxiety + anxietyfactor ) * random-normal .9 .1 ;; a fairly unsophisticated (currently unused) means of allocating anxiety around COVID-19 to people - will be updated
  if anxiety < 0 [ set anxiety 0 ]
 ; if anxiety > 100 [ set anxiety 100 ]
end

to Globalanxiety  ;;
 let anxiouscohort (count simuls with [ color = red ] + count simuls with [ color = black ] - count simuls with [ color = yellow ] ) / Total_Population ;; levels of global anxiety are tied to knowledge of dead and infected
  ;;people multiplied by media exposure of dead and infected people

 if scalephase = 0 [  set anxietyFactor anxiouscohort * media_Exposure ]
 if scalephase = 1 [  set anxietyFactor anxiouscohort * 10  * media_Exposure ]
 if scalephase = 2 [  set anxietyFactor anxiouscohort * 100  * media_Exposure ]
 if scalephase = 3 [  set anxietyFactor anxiouscohort * 1000  * media_Exposure ]
 if scalephase = 4 [  set anxietyFactor anxiouscohort * 10000  * media_Exposure ]
end

to GlobalTreat ;; send people to quarantine if they have been identified
  let eligiblesimuls simuls with [ color = red and inICU = 0 and ownIncubationPeriod >= Incubation_Period and asymptom >= AsymptomaticPercentage and tracked = 1 ]
  if (count simuls with [ InICU = 1 ]) < (count patches with [ pcolor = white ]) and Quarantine = true and any? eligiblesimuls ;; only symptomatic cases are identified
    [ ask n-of ( count eligiblesimuls * Track_and_Trace_Efficiency )
      eligiblesimuls [
      move-to one-of patches with [ pcolor = white ] set inICU 1 ]]
end

to treat
     if inICU = 1 and color = red [ move-to one-of patches with [ pcolor = white]  ] ; keeps people withint he bunds of the hospital patches and overrides any other movement so they can;t interact with susceptible people
end

to PossiblyDie
  if InICU = 0 and Severity_of_illness / Illness_Period > random 100 [ set health health - Severity_of_Illness ] ;; determines whether people die on the basis of poor health (not currently active)
  if InICU = 1 and Severity_of_illness / Illness_Period > random 100 [ set health health - Severity_of_Illness / Treatment_Benefit ]
end

to TriggerActionIsolation ;; sets the date for social isolation and case isolation
  if PolicyTriggerOn = true and Freewheel = false  [
    ;;if triggerday - ticks < 14 and triggerday - ticks > 0 and Freewheel = false [ set Spatial_Distance true set case_Isolation true set Quarantine true ;; the 14 relates to 14 days. Could be an input but unlikely to change so hard-coded
       ;;set Proportion_People_Avoid 0 + (( PPA ) / (triggerday - ticks)) set Proportion_Time_Avoid 0 + (( PTA) / (triggerday - ticks)) ] ;;ramps up the avoidance 14 days out from implementation

    ;; this has been turned off to reflect immediate policy settings as of July 22

    if ticks >= Triggerday and Freewheel = false [ set Spatial_Distance true set Case_Isolation true set Quarantine true ]
  ]
end

to spend
  ifelse agerange < 18 [ set reserves reserves ] [ set reserves (income * random-normal Days_of_Cash_Reserves (Days_of_Cash_Reserves / 5) ) / 365 ];; allocates cash reserves of average of 3 weeks with tails
end

to Cruiseship
  if mouse-down? and cruise = true [ ;; lets loose a set of new infected people into the environment
    create-simuls random 50 [ setxy mouse-xcor mouse-ycor set size 2 set shape "dot" set color red set agerange one-of [ 0 10 20 30 40 50 60 70 80 90 ]
      set health ( 100 - Agerange )  set timenow 0 set InICU 0 set anxiety 0 set sensitivity random-float 1 set R 0 ;; resethealth resetincome calculateincomeperday calculateexpenditureperday
        set income random-exponential Mean_Individual_Income

        set ownIllnessPeriod ( exp random-normal M S ) ;; log transform of illness period
        set ownIncubationPeriod ( exp random-normal Minc Sinc ) ;;; log transform of incubation period


        set detectable random 100  ;;;; identifies whether the person is detectable or not
        set returntoschool random 100


        rngs:init ;; replacing previous log transform with beta distribution
        let stream_id random-float 999
        let seed random-float 999
        rngs:set-seed stream_id seed
        let dist rngs:rnd-beta  stream_id 450.3 23.7
        set ownComplianceWithIsolation dist
        let maskWearEfficacy rngs:rnd-beta stream_id 20 11
        set ownMaskEfficacy maskWearEfficacy * 100

      ]]
end

to CalculateDailyGrowth ;; calculated the growth in infectes per day
  set YesterdayInfections TodayInfections
  set TodayInfections ( count simuls with [ color = red  and timenow = 1 ] ) ;; this considers ALL cases - not just the reported ones
  if YesterdayInfections != 0 [set InfectionChange ( TodayInfections / YesterdayInfections ) ]
end

to countcontacts
  if color != red [
  set contacts7 contacts6
  set contacts6 contacts5
  set contacts5 contacts4
  set contacts4 contacts3
  set contacts3 contacts2
  set contacts2 contacts1
  set contacts1 (count other simuls-here with [ color != black and householdUnit != [ householdUnit ] of myself ]) ;; or alternatively add the following ## and householdUnit != [ householdUnit ] of myself

  set contacts ( contacts1 + contacts2 + contacts3 + contacts4 + contacts5 + contacts6 + contacts7 ) /  7
  ]
end

to death ;; calculates death for individuals and adds them to a total for the population - This should not be relied upon to esitmate deaths as it currently interacts with asymptomatic cases and undetected cases in the most recent version

  if Scalephase = 0 and color = red and timenow = int ownIllnessPeriod - 1 and RiskofDeath > random-float 1  [ set color black set pace 0 set RequireICU 0 set deathcount deathcount + 1 ]
  if Scalephase = 1 and color = red and timenow = int ownIllnessPeriod - 1 and RiskofDeath > random-float 1  [ set color black set pace 0 set RequireICU 0 set deathcount deathcount + 10 ]
  if Scalephase = 2 and color = red and timenow = int ownIllnessPeriod - 1 and RiskofDeath > random-float 1  [ set color black set pace 0 set RequireICU 0 set deathcount deathcount + 100 ]
  if Scalephase = 3 and color = red and timenow = int ownIllnessPeriod - 1 and RiskofDeath > random-float 1  [ set color black set pace 0 set RequireICU 0 set deathcount deathcount + 1000 ]
  if Scalephase = 4 and color = red and timenow = int ownIllnessPeriod - 1 and RiskofDeath > random-float 1  [ set color black set pace 0 set RequireICU 0 set deathcount deathcount + 10000 ]

end

to respeed
  if tracked != 1 [ set pace span ] ;; If people aren't tracked they can move as they wish
end

to checkutilisation
  ifelse any? simuls-here [ set utilisation 1 ] [ set utilisation 0 ] ;; records which patches are being occupied by simuls
end

to earn ;; people can earn money if they come into contact with other people who have money
  if ticks > 1 [
  if agerange < 18 [ set reserves reserves ]
  if agerange >= 70 [ set reserves reserves ]
  ifelse ticks > 0 and AverageFinancialContacts > 0 and color != black and any? other simuls-here with [ reserves > 0 ] and agerange >= 18 and agerange < 70 [
      set reserves reserves + ((income  / 365 ) / 5 * (1 / AverageFinancialContacts) - (( expenditure / 365) / 7 ) ) ]
    [ ifelse WFHCap < random WFH_Capacity and Spatial_Distance = true and AverageFinancialContacts > 0 and color != black and any? other simuls-here with [ reserves > 0 ] and agerange >= 18 and agerange < 70
      [ set reserves reserves + ((income  / 365 ) / 5 * (1 / AverageFinancialContacts)) -
      (( expenditure / 365) / 7 ) ] [
      set reserves reserves - (( expenditure / 365) / 7) * .5 ]  ] ;;; adjust here
  ]
end


to financialstress
  if reserves <= 0 and agerange > 18 and agerange < 70 [ set shape "star" ] ;; if simuls have negative financial reserves, this identifies them in the visualisation of the model
  if reserves > 0 [ set shape "dot" ] ;; reverts back to a dot shape if person has positive cash reserves
end

to DeployStimulus
  if mouse-down? and stimulus = true [ create-packages 1 [ setxy mouse-xcor mouse-ycor set shape "box" set value 0 set color orange set size 5  ] ] ;; deploys stimulus packagees into the environment
end

to absorbshock
  if any? simuls in-radius 1 with [ shape = "star" ] [ set value value - sum [ reserves ] of simuls in-radius 1 with [ shape = "star" ] ] ;; stimulus packages soak up the debt present in the simuls
end

to AccessPackage
  if any? Packages in-radius 10 and reserves < 0 [ set reserves 100 ] ;; enables people to access the support packages
end

;to setInitialReserves
;  if ticks = 1  [ set InitialReserves sum [ reserves ] of simuls ] ;; calculates total cash reserves in the population
;end

to CalculateAverageContacts ;; calculates average contacts for simuls and average financial contacts, which are contacts with people who have positive cash reserves
 ;; if ticks > 0 [ set AverageFinancialContacts mean [ contacts ] of simuls with [ agerange >= 18 and reserves > 0 and color != black ] ]
  if ticks > 0 [ set AverageContacts mean [ contacts ] of simuls with [ color != black ]  ]
end

to scaleup ;; this function scales up the simulation over 5 phases at base 10 to enable a small and large-scale understanding of dynamics. It enables the fine-grained analysis in early stages
  ;; that more closely resembles diffusion across a population similar to assumptions in SEIR models but as it scales up, recognises taht there are geographic constraints of movement of populations
  ifelse scale = true and ( count simuls with [ color = red ] )  >= 250 and scalePhase >= 0 and scalePhase < 4 and count simuls * 1000 < Total_Population and days > 0  [ ;;;+ ( count simuls with [ color = yellow ] )
    set scalephase scalephase + 1 ask n-of ( count simuls with [ color = red ] * .9 ) simuls with [ color = red ] [ set size 2 set shape "dot" set color 85 set detectable random 100  ;;;; identifies whether the person is detectable or not ;;resethealth calculateincomeperday calculateexpenditureperday
    set timenow 0 set InICU 0 set anxiety 0 set sensitivity random-float 1 set imported 0 set R 0 set ownIllnessPeriod ( exp random-normal M S ) ;; log transform of illness period
        set ownIncubationPeriod ( exp random-normal Minc Sinc )   ;; log transform of compliance with isolation
      set income ([ income ] of one-of other simuls )  move-to one-of patches with [ pcolor = black  ]
      resetlandingSimul set riskofdeath .01 set WFHCap random 100 set ageRange ([ageRange ] of one-of simuls) set requireICU random 100

        rngs:init ;; replacing previous log transform with beta distribution
        let stream_id random-float 999
        let seed random-float 999
        rngs:set-seed stream_id seed
        let dist rngs:rnd-beta  stream_id 450.3 23.7
        set ownComplianceWithIsolation dist
        let maskWearEfficacy rngs:rnd-beta stream_id 20 11
        set ownMaskEfficacy maskWearEfficacy * 100
        set returntoschool random 100
        set detectable random 100] ;;


     ask n-of ( count simuls with [ color = yellow ] * .9 ) simuls with [ color = yellow ] [ set size 2 set shape "dot" set color 85 set WFHCap random 100
      set ageRange ([ageRange ] of one-of simuls)  set imported 0 ;; resethealth
     set timenow 0 set InICU 0 set anxiety 0 set sensitivity random-float 1 set R 0 set ownIllnessPeriod ( exp random-normal M S ) ;; log transform of illness period
        set ownIncubationPeriod ( exp random-normal Minc Sinc )
       ;; log transform of compliance with isolation
      set income ([income ] of one-of other simuls)  move-to one-of patches with [ pcolor = black  ] ;;resetincome calculateincomeperday calculateexpenditureperday
      resetlandingSimul set riskofdeath [ riskOfDeath ] of one-of simuls with [ agerange = ([ agerange ] of myself )] set requireICU random 100


        rngs:init ;; replacing previous log transform with beta distribution
        let stream_id random-float 999
        let seed random-float 999
        rngs:set-seed stream_id seed
        let dist rngs:rnd-beta  stream_id 450.3 23.7
        set ownComplianceWithIsolation dist
        let maskWearEfficacy rngs:rnd-beta stream_id 20 11
        set ownMaskEfficacy maskWearEfficacy * 100
    ]


 set contact_Radius Contact_Radius + (90 / 4)
    Set days 0
         ] [scaledown ]

end

to scaledown ;; reverses the procedure above after the peak of the epidemic
  if scale = true and count simuls with [ color = red ] <= 25 and yellowcount > redcount and days > 0 and scalephase > 0 [ ask n-of (count simuls with [ color = red ] * .9 ) simuls with [ color = red ]
    [ hatch 10 move-to one-of patches with [ pcolor = black ] ]
  set contact_Radius Contact_radius - (90 / 4) set scalephase scalephase - 1  ]
end

to scaledownhatch ;; removes excess simuls fromt the scaled-down view
  if count simuls > Population [  ask n-of ( count simuls - Population ) simuls with [ color != red or color != black ] [ die ] ]
 ;; if count simuls > Population [ ask n-of ( count simuls - Population ) simuls with [ color = 85 ] [ die ] ]
end

to forwardTime
  set days days + 1 ;; counts days per tick, likely redundant at present as days are not used for anything right now.
end

To Unlock ;; reverses the initiation of social distancing and isolation policies over time. Recognises that the policies are interpreted and adherence is not binary.
  ;;Adherence to policies is associated with a negative exponential curve linked to the current day and the number of days until the policies are due to be relaxed at which point they are relaxed fully.
  if Complacency = true and PolicyTriggerOn = true and LockDown_Off = true and ticks >= Triggerday and int Proportion_People_Avoid > ResidualCautionPPA  [ ;;and ( timeLockdownOff - ticks ) > 0
    set PPA (PPA - 1 ) set Proportion_People_Avoid PPA ]

    ;;set Proportion_People_Avoid PPA - (( PPA - residualCautionPPA ) / ( timeLockdownOff - ticks )) ] ;; the residual caution variable leaves people with a sense that they should still avoid to some extent

  if Complacency = true and PolicyTriggerOn = true and LockDown_Off = true and ticks >= Triggerday and int Proportion_Time_Avoid > ResidualCautionPTA  [ ;;and ( timeLockdownOff - ticks ) > 0
    set PTA (PTA - 1 ) set Proportion_Time_Avoid PTA ]


    ;; set Proportion_Time_Avoid PTA - (( PTA - residualCautionPTA ) / ( timeLockdownOff - ticks )) ] ;; the residual caution variable leaves people with a sense that they should still avoid to some extent

  ;;the section above has been altered as on July 11th to produce a linear decay over time - original is commented out
  ;; if LockDown_Off = true and ticks >= timeLockDownOff [ set Case_Isolation false set Spatial_Distance false ]

end

to CountInfected ;; global infection count
  set numberinfected cumulativeInfected

end

to setCaseFatalityRate ;; calculates death rate per infected person over the course of the pandemic
  if Deathcount > 0 and numberinfected > 0 [ set casefatalityrate  ( Deathcount / numberInfected ) ]
end


to countDailyCases ;; sets the day for reporting new cases at 6 (adjustable) days after initial infection, scales up as the population scales

  ;; let casestoday count simuls with [ color = red and tracked = 1 and reported = 0 ] ;; use this if you want to adjust cases for those that go unreported at the peak
 ;;or

  let casestoday count simuls with [ color = red and unDetectedFlag = 0 and int timenow = int Case_reporting_delay ] ;; this now ONLY reports detected cases, not all infections - this flows through to daily cases

  if Scalephase = 0 [ set dailyCases casestoday ]
  if Scalephase = 1 [ set dailyCases casestoday * 10 ]
  if Scalephase = 2 [ set dailyCases casestoday * 100 ]
  if Scalephase = 3 [ set dailyCases casestoday * 1000 ]
  if Scalephase = 4 [ set dailyCases casestoday * 10000 ]

end

to calculatePopulationScale ;; population scaling function
  if scalephase = 0 [ set Scaled_Population ( count simuls ) ]
  if scalephase = 1 [ set Scaled_Population ( count simuls ) * 10 ]
  if scalephase = 2 [ set Scaled_Population ( count simuls ) * 100 ]
  if scalephase = 3 [ set Scaled_Population ( count simuls ) * 1000 ]
  if scalephase = 4 [ set Scaled_Population ( count simuls ) * 10000 ]
end

to checkICU
  if color = red and RequireICU < ICU_Required and timenow >= ownIncubationPeriod [ set requireICU 1 ] ;; estimates if someone needs and ICU bed
    if unDetectedFlag = 0 and reported = 0 [ set reported 1 ] ;; and updates their reported status - this needs to go after the last function as it wasn;t being counted properly
end

to CalculateICUBedsRequired ;; calculates the number of ICU beds required at any time
  let needsICU count simuls with [ color = red and requireICU = 1 ]

  if scalephase = 0 [ set ICUBedsRequired needsICU  ]
  if scalephase = 1 [ set ICUBedsRequired needsICU * 10 ]
  if scalephase = 2 [ set ICUBedsRequired needsICU * 100]
  if scalephase = 3 [ set ICUBedsRequired needsICU * 1000 ]
  if scalephase = 4 [ set ICUBedsRequired needsICU * 10000 ]

end

to calculateScaledBedCapacity ;; scales the number of patches in the environment that represents Australian bed capacity
   set scaled_Bed_Capacity ( Hospital_Beds_In_Australia / 2500 )
end

to calculateCurrentInfections ;; calculates the number of infected people in the population
   let infectedsimuls count simuls with [ color = red ]

   if Scalephase = 0 [ set currentInfections infectedsimuls ]
   if Scalephase = 1 [ set currentInfections infectedsimuls * 10 ]
   if Scalephase = 2 [ set currentInfections infectedsimuls * 100 ]
   if Scalephase = 3 [ set currentInfections infectedsimuls * 1000 ]
   if Scalephase = 4 [ set currentInfections infectedsimuls * 10000 ]

end

to movepackages
  set heading heading + 5 - 5 fd .5 ;; makes stimulus packages drift in the environment
end

to calculateEliminationDate
  if ticks > 1 and count simuls with [ color = red ] = 0 and eliminationDate = 0 [ set eliminationDate ticks ] ;; records the day that no infected people remain in the environment
end


;;;;;;;;;;;;;; *****TRACKING AND TRACING FUNCTIONS*********;;;;;;;;;


to traceme
  if tracked != 1 and tracking = true [ if color = red and track_and_trace_efficiency > random-float 1 and unDetectedFlag = 0 [ set tracked 1 set IDTime timenow ] ] ;; this represents the standard tracking and tracing regime - undetected people are not tracked
   if color != red and count my-in-links = 0 [ set hunted 0 set tracked 0 ] ;; this ensures that hunted people are tracked but that tracked people are not necessarily hunted
end


to isolation

if ownCompliancewithIsolation * 100 > random 100 [ ;; tracks people and isolates them even if they are pre incubation period
   move-to homelocation set pace 0 ]

;;    if color = red and ownCompliancewithIsolation * 100 > random 100 and tracked = 1 [ ;; tracks people and isolates them even if they are pre incubation period
;;     move-to homelocation set pace 0 ]

;; this function should enable the observer to track-down contacts of the infected person if that person is either infected or susceptible.
;; it enables the user to see how much difference an effective track and trace system might make to spread
end

to assesslinks ;; this represents the COVID-Safe or other tracing app function
  if link_switch = true and any? simuls with [ color = red and tracked = 1 and haveApp <= App_Uptake ] [ ask simuls with [ color = red and tracked = 1 and haveApp <= App_Uptake ]
    [ if any? other simuls-here and GoldStandard > random 100 [ create-links-with other simuls-here with [ haveapp <= App_Uptake ] ] ] ;; other person must also have the app installed
    ;; asks tracked simuls who have the app to make links to other simuls who also have the app they are in contact with
  ask simuls with [ haveApp <= App_Uptake and agerange > 10 ] [ ask my-out-links [ set color blue ] ] ;; Covid-safe app out-links  are set to blue
  ask simuls with [ haveApp > App_Uptake ] [ ask my-in-links [ set color red  ] ] ;; in-links red but if there is an out and in-link it will be grey

  ask simuls with [ color != red ] [ ask my-out-links [ die ] ] ;; asks all links coming from the infected agent to die
  ask simuls with [ color = yellow ] [ ask my-in-links [ die ] ] ;; asks all links going to the recovered agent to die
  ]
end

to hunt ;; this specifically uses the app to trace people
  if link_switch = true [
   ;; if Track_and_Trace_Efficiency * TTIncrease > random-float 1 and count my-links > 0 and haveApp <= App_Uptake [ set hunted 1 ]  ;; I need to only activate this if the index case is tracked
    if count my-links > 0 and haveApp <= App_Uptake [ set hunted 1 ]
  if hunted = 1 [ set tracked 1 ]
  ]  ;;
end


;;;;;;;;;;;;*********END OF TTI FUNCTIONS*******;;;;;;;;;;;;;


to calculateCarefactor ;; not currently implemented so can ignore
  set newv ( ( saliencyMessage * SaliencyExperience ) * (( vmax - initialassociationstrength ) * ( Careattitude * selfCapacity )))   ;; experience can be fear ;; we can analyse who got infected - vulnerable communities
  if newv > vmax [ set newv vmax ]
  if newv < vmin [ set newv vmin ]
  set newAssociationstrength ( initialAssociationstrength + newv )
  set vmax maxv set vmin minv
  set saliencyMessage PHWarnings set SaliencyExperience Saliency_of_Experience set CareAttitude Care_Attitude set selfCapacity Self_capacity
  if saliencyMessage > 1 [ set saliencymessage 1 ]
  if saliencyExperience > 1 [ set saliencyExperience 1 ]
end

to calculatePotentialContacts ;; counts the number of people tracked from infected people
   if Scalephase = 0 [ set PotentialContacts ( count links ) ]
   if Scalephase = 1 [ set PotentialContacts ( count links ) * 10 ]
   if Scalephase = 2 [ set PotentialContacts ( count links ) * 100 ]
   if Scalephase = 3 [ set PotentialContacts ( count links ) * 1000 ]
   if Scalephase = 4 [ set PotentialContacts ( count links ) * 10000 ]
end

to countred ;; as per code
  set redCount count simuls with [ color = red ]
end

to countblue ;; as per code
  set blueCount count simuls with [ color = 85 ]
end

to countyellow ;; as per code
  set yellowcount count simuls with [ color = yellow ]
end

to calculateTodayInfected ;; calculates the number of people infected and recorded today for use in conjunction with yesterday's estimate for calculation of daily growth (see below)
  set todayInfected dailycases ;; this only considers reported cases - must adjust undetected cases if you want to report all infections
end

to calculateYesterdayInfected ;; calculates the number of people infected and recorded today
  set cumulativeInfected cumulativeInfected + todayInfected
end

to calculateScaledPopulation ;; calculates the scaled population for working with smaller environments
  if scalephase = 0 [ set scaledPopulation Total_Population / 10000 ]
  if scalephase = 1 [ set scaledPopulation Total_Population / 1000 ]
  if scalephase = 2 [ set scaledPopulation Total_Population / 100 ]
  if scalephase = 3 [ set scaledPopulation Total_Population / 10 ]
  if scalephase = 4 [ set scaledPopulation Total_Population ]
end

to calculateMeanr
  ifelse any? simuls with [ color = red and timenow = int ownillnessperiod ] [ set meanR ( mean [ R ] of simuls with [ color = red and timenow = int ownillnessperiod ])] [ set MeanR MeanR ] ;; calculates mean Reff for the population
end

to OSCase
  if policytriggeron = true and count simuls with [ color = red and imported = 0 ] > 1 [
    let totallocal count simuls with [ color != 85 and imported = 0 ]
    let totalimported count simuls with [ imported = 1 ]
    let ratio ( totalimported  / (totallocal + totalimported) )

    if ticks <= triggerday and OS_Import_Switch = true and ratio < OS_Import_Proportion  [
      ask n-of ( count simuls with [ color = red ] * .10 ) simuls with [ color = 85 ]
      [ set color red set timenow int ownIncubationPeriod - random-normal 1 .5 set Essentialworker random 100 set imported 1 ] ] ;; contributes additional cases as a result of OS imports prior to lockdown

    if ticks <= triggerday and OS_Import_Switch = true  [
    ask n-of 1 simuls with [ color = 85 ]
      [ set color red set timenow int ownIncubationPeriod - random-normal 1 .5 set Essentialworker random 100 set imported 1 ] ] ;; creates steady stream of OS cases at beginning of pandemic

    if ticks > triggerday and OS_Import_Switch = true and ratio < OS_Import_Post_Proportion [
      ask n-of ( count simuls with [ color = red ] * .05 ) simuls with [ color = 85 ]
      [ set color red set timenow int ownIncubationPeriod - random-normal 1 .5 set Essentialworker random 100 set imported 1 set tracked 1 ] ] ;; contributes additional cases as a result of OS imports after lockdown

    ;; adds imported cases in the lead-up and immediate time after lockdown
      ]
end

to stopfade
 if freewheel != true [
  if ticks < Triggerday and count simuls with [ color = red ] < 3 [ ask n-of 1 simuls with [ color = 85 ]
      [ set color red set timenow int ownIncubationPeriod - 1 set Essentialworker random 100 ]]
    ;; prevents cases from dying out in the eraly stage of the trials when few numbers exist
  ]
end

to EssentialWorkerID
  ifelse EssentialWorker < Essential_Workers [ set EssentialWorkerFlag 1 ] [ set EssentialWorkerFlag 0 ] ;; identifies essential workers
end

to seedCases ;; set up to take the pre-intervention growth pre ******August 31th ********* and use it to seed new cases in the next week - must be updated each day 1_9_2020 =244.02*EXP(-0.09)^G55

;; Vic @ 90
    if ticks < seedticks and scalephase = 0 [ ask n-of  10 simuls with [ color = 85 ] [ set color red set timenow int Case_reporting_delay - 1 set Essentialworker random 100 set unDetectedFlag  0 ]]
    if ticks < seedticks and scalephase = 1 [ ask n-of  1 simuls with [ color = 85 ] [ set color red set timenow int Case_reporting_delay - 1 set Essentialworker random 100  set unDetectedFlag  0 ]]
    if ticks < seedticks and scalephase = 2 [ ask n-of int .1 simuls with [ color = 85 ] [ set color red set timenow int Case_reporting_delay - 1 set Essentialworker random 100  set unDetectedFlag  0 ]]

;    if ticks < seedticks and scalephase = 0 [ ask n-of int ((244 * (.914 ^ (ticks + 15))) )  simuls with [ color = 85 ] [ set color red set timenow int Case_reporting_delay - 1 set Essentialworker random 100 set unDetectedFlag  0 ]]
;    if ticks < seedticks and scalephase = 1 [ ask n-of int ((244 * (.914 ^ (ticks + 15))) / 10  ) simuls with [ color = 85 ] [ set color red set timenow int Case_reporting_delay - 1 set Essentialworker random 100  set unDetectedFlag  0 ]]
;    if ticks < seedticks and scalephase = 2 [ ask n-of int ((244 * (.914 ^ (ticks + 15))) / 100 ) simuls with [ color = 85 ] [ set color red set timenow int Case_reporting_delay - 1 set Essentialworker random 100  set unDetectedFlag  0 ]]
    ;; creates a steady stream of cases into the model in early stages for seeding - these need to be estimated are are unlikely to be exact due to errors and lags in real-world reporting
    ;; count simuls with [ color = red and unDetectedFlag = 0 and int timenow = int Case_reporting_delay ]

end

to turnOnTracking
  if freewheel != true [ ;; ensures that policies are enacted if their master switches are set to true at the time of the policy switch turning on
  if policyTriggerOn = true and ticks >= triggerday and schoolPolicyActive = true [
      set tracking true set SchoolsPolicy true ]

    if policyTriggerOn = true and ticks >= triggerday [
      set tracking true   ] ;; set link_switch true
  ]
end

to countEWInfections ;; counts infections among Essential workers
  let EWInfects (count simuls with [ color = red and EssentialWorkerFlag = 1 ] )
  if Scalephase = 0 [ set EWInfections EWInfects ]
  if Scalephase = 1 [ set EWInfections EWInfects  * 10 ]
  if Scalephase = 2 [ set EWInfections EWInfects  * 100 ]
  if Scalephase = 3 [ set EWInfections EWInfects  * 1000 ]
  if Scalephase = 4 [ set EWInfections EWInfects  * 10000 ]
end


to countSchoolInfections ;; counts infections among school students
   let studentInfects ( count simuls with [ color = red and StudentFlag = 1 ] )
   if Scalephase = 0 [ set studentInfections studentInfects ]
   if Scalephase = 1 [ set studentInfections studentInfects * 10 ]
   if Scalephase = 2 [ set studentInfections studentInfects * 100 ]
   if Scalephase = 3 [ set studentInfections studentInfects * 1000 ]
   if Scalephase = 4 [ set studentInfections studentInfects * 10000 ]
end

to checkMask ;; identifies people who waear a mask
  if maskPolicy = true [
    ifelse wearsMask <= mask_Wearing and patch-here != homelocation [ set wearingMask 1 ] [ set wearingMask 0 ] ]
end

to calculateMeanDaysInfected
  if any? simuls with [ color = red ] [ set meanDaysInfected ( mean [ timenow ] of simuls with [ color = red ] )]
end

to updatepersonalvirulence ;; creates a triangular distribution of virulence that peaks at the end of the incubation period
  if color = red and timenow <= ownIncubationPeriod [ set currentVirulence ( personalVirulence * ( timenow / ownIncubationPeriod )) ]
  if color = red and timenow > ownIncubationPeriod [ set currentVirulence ( personalVirulence  * ( ( ownIllnessPeriod - timenow ) / ( ownIllnessPeriod - ownIncubationPeriod ))) ]
end

;to profilerstop
;  if ticks = 25  [
;  profiler:stop          ;; stop profiling
;  print profiler:report  ;; view the results
;    profiler:reset  ]       ;; clear the data
;end

;to-report essentialworkerpercentage
;  if ticks > 1 [ report (count simuls with [ essentialWorkerflag = 1 and color != 85 ]) / (count simuls with [ essentialWorkerFlag = 1 ])]
;end

to-report nonesspercentage
  if count simuls with [ essentialworkerflag != 1 and color != 85 ] > 0 [  report (count simuls with [ essentialworkerflag != 1 and color != 85] ) / (count simuls with [ essentialWorkerFlag != 1 ]) ]
end

to traceadjust
  ifelse casesinperiod7 > 0 [ set track_and_trace_efficiency (0.63219 - (0.07213 * ln(casesinperiod7)))] [ set track_and_trace_efficiency .25 ] ;; fix this so it doesn't go negative

;  set track_and_trace_efficiency .25 ;; kept stable here for simplicity
;  if scalephase = 0 [ set track_and_trace_efficiency .25 ]
;  if scalephase = 1 [ set track_and_trace_efficiency .20 ]
;  if scalephase = 2 [ set track_and_trace_efficiency .15 ]
;  if scalephase = 3 [ set track_and_trace_efficiency .10 ]
;  if scalephase = 4 [ set track_and_trace_efficiency .05 ]
end

to linearbehdecrease
  if complacency = true [ if ticks > triggerday and ppa > ResidualCautionppa [ set ppa (ppa - 1) set pta ( pta - 1)]]
end


to visitDestination
  ;;; sets up destinations where people might gather and set off superspreader events
  if remainder random 7 Visit_Frequency = 0 and any? patches with [ destination = 1 ] in-radius (5 - stage) [ move-to one-of patches with [ destination = 1 ] ];; reduces large gatherings by stage
end
 ;; essential workers do not have the same capacity to reduce contact as non-esssential

to COVIDPolicyTriggers ;; used in idynamic model
    if selfgovern = true  [


    ;; Optimisation section
    ;;;********************************************************************************************************************************


;    if stage = 0 and casesinperiod14 >= zerotoone and ticks = resetdate [ set stage 1 set resetdate (ticks + JudgeDay1) ]
;    if stage = 1 and casesinperiod14 >= onetotwo and ticks = resetdate [ set stage 2 set resetdate (ticks + JudgeDay2) ]
;    if stage = 2 and casesinperiod14 >= twotothree and ticks = resetdate [ set stage 3 set resetdate (ticks + JudgeDay3) ]
;    if stage = 3 and casesinperiod14 >= threetofour and ticks = resetdate [ set stage 4 set resetdate (ticks + JudgeDay4_d) ]
;    if stage = 4 and casesinperiod14 <= fourtothree and ticks = resetdate [ set stage 3 set resetdate (ticks + JudgeDay3_d)]
;    if stage = 3 and casesinperiod14 <= threetotwo and ticks = resetdate [ set stage 2 set resetdate (ticks + JudgeDay2_d) ]
;    if stage = 2 and casesinperiod14 <= onetotwo and ticks = resetdate [ set stage 1 set resetdate (ticks + JudgeDay1_d) ]
;    if stage = 1 and casesinperiod14 <= zerotoone and ticks = resetdate [ set stage 0 ]
;    if ticks > 0 and ticks >= resetdate [ set resetdate (ticks + 7) ]



;    ;; regular section
;    if stage = 0 and casesinperiod7 >= zerotoone and ticks = resetdate [ set stage 1 set resetdate (ticks + JudgeDay1) ]
;    if stage = 1 and casesinperiod7 >= onetotwo and ticks = resetdate [ set stage 2 set resetdate (ticks + JudgeDay2) ]
;    if stage = 2 and casesinperiod7 >= twotothree and ticks = resetdate [ set stage 3 set resetdate (ticks + JudgeDay3) ]
;    if stage = 3 and casesinperiod7 >= threetofour and ticks = resetdate [ set stage 4 set resetdate (ticks + JudgeDay4_d) ]
;    if stage = 4 and casesinperiod7 <= fourtothree and ticks = resetdate [ set stage 3 set resetdate (ticks + JudgeDay3_d)]
;    if stage = 3 and casesinperiod7 <= threetotwo and ticks = resetdate [ set stage 2 set resetdate (ticks + JudgeDay2_d) ]
;    if stage = 2 and casesinperiod7 <= onetotwo and ticks = resetdate [ set stage 1 set resetdate (ticks + JudgeDay1_d) ]
;    if stage = 1 and casesinperiod7 <= zerotoone and ticks = resetdate [ set stage 0 ]
;    if ticks > 0 and ticks >= resetdate [ set resetdate (ticks + 7) ]
;

;;**********************************************************************************************************************************

   ;; Vic section

   ;; new section
;    if stage = 0 and casesinperiod14 >= zerotoone and ticks = resetdate [ set stage 1 set resetdate (ticks + JudgeDay1) ]
;    if stage = 1 and casesinperiod14 >= onetotwo and ticks = resetdate [ set stage 2 set resetdate (ticks + JudgeDay2) ]
;    if stage = 2 and casesinperiod14 >= twotothree and ticks = resetdate [ set stage 3.5 set resetdate (ticks + JudgeDay3) ]
;    if stage = 3.3 and casesinperiod14 >= threetofour and ticks = resetdate [ set stage 4 set resetdate (ticks + JudgeDay4) ] ;; these all jump back up to stage 4
;    if stage = 3.4 and casesinperiod14 >= threetofour and ticks = resetdate [ set stage 4 set resetdate (ticks + JudgeDay4) ] ;; these all jump back up to stage 4
;    if stage = 3.5 and casesinperiod14 >= threetofour and ticks = resetdate [ set stage 4 set resetdate (ticks + JudgeDay4) ] ;; these all jump back up to stage 4
;       ;;if stage = 4 and casesinperiod7 <= fourtothree and ticks = resetdate [ set stage 3 set resetdate (ticks + JudgeDay3)]
;    if stage = 4 and ticks = 14 [ set stage 3.9 set resetdate (ticks + JudgeDay3)] ; ramps down to 3.9 on September 15th
;    if stage = 4 and ticks > 14 and casesinperiod14 <= fourtothree and ticks = resetdate [ set stage 3.5 set resetdate (ticks + JudgeDay4) ]
;       ;; if stage = 3 and casesinperiod7 <= threetotwo and ticks = resetdate [ set stage 2 set resetdate (ticks + JudgeDay2) ]
;    if stage >= 0 and stage <= 3.5 and ticks = 34 [ set stage 3.4 ] ;; this sends 300000 students back on Oct 5th
;    if stage >= 0 and stage <= 3.5 and ticks = 41 [ set stage 3.3 ] ;; this sends another 100,000 students back on Oct 12th
;    if stage = 3.9 and ticks = 27 [ set stage 3.5 set resetdate (ticks + JudgeDay2) ]
;    if stage <= 3.5 and stage >= 3 and casesinperiod14 < threetotwo [ set stage 2 set resetdate (ticks + JudgeDay2) ]
;    if stage = 2 and casesinperiod14 <= onetotwo and ticks = resetdate [ set stage 1 set resetdate (ticks + JudgeDay1) ]
;    if stage = 1 and casesinperiod14 <= zerotoone and ticks = resetdate [ set stage 0 ]
;    if ticks > 0 and ticks >= resetdate [ set resetdate (ticks + 7) ]

 ;;************************************************************************************************************************************

 ;;   VIC Jan Section

   ;;up
 if ticks > 6 [

    if stage = 0 and casesinperiod7 >= zerotoone and ticks = resetdate and ( ticks - decisionDate) > Judgeday1 and MaxStage > 0 [ set stage 1 set resetdate (ticks + 1 ) set decisionDate ticks ]
    if stage <= 1 and casesinperiod7 >= onetotwo and ticks = resetdate and ( ticks - decisionDate) > Judgeday2 and MaxStage > 1 [ set stage 2 set resetdate (ticks + 1) set decisionDate ticks ]
    if stage <= 2 and casesinperiod7 >= twotothree and ticks = resetdate and ( ticks - decisionDate) > Judgeday3 and MaxStage > 2 [ set stage 3 set resetdate (ticks + 1) set decisionDate ticks ]
    if stage <= 3 and casesinperiod7 >= threetofour and ticks = resetdate and ( ticks - decisionDate) > Judgeday4 and MaxStage > 3 [ set stage 4 set resetdate (ticks + 1) set decisionDate ticks ] ;; these all jump back up to stage 4
  ;;  if stage <= 3 and casesinperiod7 >= onetotwo and ticks = resetdate and ( ticks - decisionDate) > Judgeday1 [ set stage stage + 1 set resetdate (ticks + 1) set decisionDate ticks ] ;; this tightens one stage if the other triggers are not met

  ;; down

    if stage = 4 and BaseStage < 4 and casesinPeriod7 < fourtothree [ set stage 3 set resetdate (ticks + 1) set decisionDate ticks ] ; ramps down to 3.9 on September 15th
    if stage = 3 and BaseStage < 3 and casesinperiod7 < threetotwo and ticks = resetdate and (ticks - decisionDate) > judgeday3_d [ set stage 2 set resetdate (ticks + 1) set decisionDate ticks ]
    if stage = 2 and BaseStage < 2 and casesinperiod7 < twotoone and ticks = resetdate and (ticks - decisionDate) > judgeday2_d [ set stage 1 set resetdate (ticks + 1 ) set decisionDate ticks ]
    if stage = 1 and BaseStage < 1 and casesinperiod7 < zerotoone and ticks = resetdate and (ticks - decisionDate) > judgeday1_d [ set stage 0 set resetdate (ticks + 1 ) set decisionDate ticks ]
    if ticks > 0 and ticks = resetdate [ set resetdate (ticks + 1 ) ]

    ]
;;Previous

    ;      ;;up
;
;    if stage = 0 and casesinperiod14 >= zerotoone and ticks = resetdate [ set stage 1 set resetdate (ticks + JudgeDay1) ]
;    if stage = 1 and casesinperiod14 >= onetotwo and ticks = resetdate [ set stage 2 set resetdate (ticks + JudgeDay2) ]
;    if stage = 2 and casesinperiod14 >= twotothree and ticks = resetdate [ set stage 3.5 set resetdate (ticks + JudgeDay3) ]
;    if stage = 3.3 and casesinperiod14 >= threetofour and ticks = resetdate [ set stage 4 set resetdate (ticks + JudgeDay4) ] ;; these all jump back up to stage 4
;    if stage = 3.4 and casesinperiod14 >= threetofour and ticks = resetdate [ set stage 4 set resetdate (ticks + JudgeDay4) ] ;; these all jump back up to stage 4
;    if stage = 3.5 and casesinperiod14 >= threetofour and ticks = resetdate [ set stage 4 set resetdate (ticks + JudgeDay4) ] ;; these all jump back up to stage 4
;
;  ;; down
;
;    if stage = 4 and ticks = 14 [ set stage 3.9 set resetdate (ticks + JudgeDay3)     ] ; ramps down to 3.9 on September 15th
;    if stage = 4 and ticks > 14 and casesinperiod14 <= fourtothree and ticks = resetdate [ set stage 3.5 set resetdate (ticks + JudgeDay4) ]
;
;    if stage <= 3.5 and stage >= 3 and casesinperiod14 < threetotwo [ set stage 2 set resetdate (ticks + JudgeDay2) ]
;    if stage = 2 and casesinperiod14 <= onetotwo and ticks = resetdate [ set stage 1 set resetdate (ticks + JudgeDay1 * 2) ]
;    if stage = 1 and casesinperiod14 <= zerotoone and ticks = resetdate [ set stage 0 ]
;    if ticks > 0 and ticks >= resetdate [ set resetdate (ticks + 7) ]


  ]

end
to setupstages

 if selfgovern = true   [

;; *****************************************************************************************************************************************************************************************************

 ;;   This section for 31_8_2020

    if stage = 0 and ticks = resetdate [ set span 30 set pta 0 set ppa 0 set spatial_distance false set age_isolation 0 set case_isolation false set schoolsPolicy true set quarantine true set schoolPolicyActive true
  set OS_Import_Proportion 0 set link_switch false set Essential_Workers 100 set maskPolicy true set mask_wearing 50 set tracking false set App_Uptake 100 set residualcautionPTA 0
      set residualcautionPPA 0 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true ask simuls [ if agerange = 5 and returntoschool <= 100 [ set studentFlag 1 ]] ask simuls [ if agerange = 15 and returntoschool < 100 [ set studentflag 1 ] set superspreaders 10 ]]

  if stage = 1 and ticks = resetdate [ set span 30 set pta 25 set ppa 25 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive true
  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 75 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 100 set residualcautionPTA 15
      set residualcautionPPA 15 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true ask simuls [ if agerange = 5 and returntoschool <= 100 [ set studentFlag 1 ]] ask simuls [ if agerange = 15 and returntoschool < 100 [ set studentflag 1 ] set superspreaders 10 ]]

  if stage = 2 and ticks = resetdate [ set span 15 set pta 65 set ppa 65 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive true
  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 50 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 100 set residualcautionPTA 52
      set residualcautionPPA 52 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true ask simuls [ if agerange = 5 and returntoschool <= 40 [ set studentFlag 1 ]] ask simuls [ if agerange = 15 and returntoschool < 15 [ set studentflag 1 ] set superspreaders 10 ]]

    if stage = 3.3 and ticks = resetdate [ set span 10 set pta 85 set ppa 85 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive false
  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 25 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 100 set residualcautionPTA 68 ;; this sends older children back
      set residualcautionPPA 68 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true  ask simuls [ if agerange = 5 and returntoschool <= 33 [ set studentFlag 1 ]] ask simuls [ if agerange = 15 and returntoschool < 15 [ set studentflag 1 ]
       if agerange = 5 and returntoschool > 50 [ set studentFlag 0 ]] ask simuls [ if agerange = 15 and returntoschool > 33 [ set studentflag 0 ]  set superspreaders 5 ]]

    if stage = 3.4 and ticks = resetdate [ set span 10 set pta 85 set ppa 85 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive false
  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 25 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 100 set residualcautionPTA 68 ;; this sends younger students back to school up to age 10
      set residualcautionPPA 68 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true ask simuls [ if agerange = 5 and returntoschool <= 33 [ set studentFlag 1 ]] ask simuls [ if agerange = 15 and returntoschool < 15 [ set studentflag 1 ]
       if agerange = 5 and returntoschool > 33 [ set studentFlag 0 ]] ask simuls [ if agerange = 15 and returntoschool > 20 [ set studentflag 0 ] set superspreaders 5 ]]

    if stage = 3 and ticks = resetdate [ set span 10 set pta 85 set ppa 85 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive false
  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 25 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 100 set residualcautionPTA 68 ;; 25% essentialworkers represents increase of ~150,000 FTE from 3.9
    set residualcautionPPA 68 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set superspreaders 5 ask simuls [ set studentFlag 0 ] ]

   if stage = 3.9 and ticks = resetdate [ set span 7 set pta 89 set ppa 89 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive false
  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 20 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 100 set residualcautionPTA 80
    set residualcautionPPA 80 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set superspreaders 3 ask simuls [ set studentFlag 0 ] ] ;; check st

  if stage = 4 and ticks = resetdate [ set span 5 set pta 90 set ppa 90 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive false
  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 20 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 100 set residualcautionPTA 81
      set residualcautionPPA 81 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set superspreaders 2 ask simuls [ set studentFlag 0 ] ]


  ]

 ;;; *******************************************************************************************************************************************************************************************************

 ;;  This section for 28-9-20


;    if stage = 0 [ set span 30 set pta 0 set ppa 0 set spatial_distance false set age_isolation 0 set case_isolation false set schoolsPolicy true set quarantine true set schoolPolicyActive true
;  set OS_Import_Proportion 0 set link_switch false set Essential_Workers 100 set maskPolicy true set mask_wearing 50 set tracking false set App_Uptake 20 set residualcautionPTA 0
;    set residualcautionPPA 0 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 18 set LowerStudentAge 3 set superspreaders 10 ]
;
;  if stage = 1 [ set span 30 set pta 15 set ppa 15 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive true
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 75 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 12
;    set residualcautionPPA 12 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 18 set LowerStudentAge 3 set superspreaders 10 ]
;
;  if stage = 2 [ set span 15 set pta 25 set ppa 25 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive true
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 50 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 15
;    set residualcautionPPA 15 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 18 set LowerStudentAge 3 set superspreaders 10 ]
;
;    if stage = 3.5 [ set span 10 set pta 85 set ppa 85 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy false set quarantine true set schoolPolicyActive false
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 30 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 68
;    set residualcautionPPA 68 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 18 set LowerStudentAge 4 set superspreaders 5 ]
;
;   if stage = 3.9 [ set span 7 set pta 89 set ppa 89 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy false set quarantine true set schoolPolicyActive false
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 20 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 80
;    set residualcautionPPA 80 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 18 set LowerStudentAge 0 set superspreaders 3 ] ;; check st
;
;  if stage = 4 [ set span 5 set pta 90 set ppa 90 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy false set quarantine true set schoolPolicyActive false
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 20 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 81
;    set residualcautionPPA 81 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 18 set LowerStudentAge 0 set superspreaders 2 ] ;;

;;**************************************************************************************************************************************************************************************************************


;    ;; this section for Tony
;
;    if stage = 0 [ set span 30 set pta 0 set ppa 0 set spatial_distance false set age_isolation 0 set case_isolation false set schoolsPolicy true set quarantine true set schoolPolicyActive true
;  set OS_Import_Proportion 0 set link_switch false set Essential_Workers 100 set maskPolicy true set mask_wearing 50 set tracking false set App_Uptake 20 set residualcautionPTA 0
;    set residualcautionPPA 0 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 18 set LowerStudentAge 3 set superspreaders 10 ]
;
;  if stage = 1 [ set span 30 set pta 15 set ppa 15 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive true
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 75 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 12
;    set residualcautionPPA 12 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 18 set LowerStudentAge 3 set superspreaders 10 ]
;
;  if stage = 2 [ set span 15 set pta 25 set ppa 25 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive true
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 50 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 15
;    set residualcautionPPA 15 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 18 set LowerStudentAge 3 set superspreaders 10 ]
;
;  if stage = 3 [ set span 10 set pta 80 set ppa 80 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy false set quarantine true set schoolPolicyActive false
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 30 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 64
;    set residualcautionPPA 64 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 16 set LowerStudentAge 3 set superspreaders 5 ]
;
;  if stage = 4 [ set span 5 set pta 90 set ppa 90 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy false set quarantine true set schoolPolicyActive false
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 20 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 81
;    set residualcautionPPA 81 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency true set upperStudentAge 18 set LowerStudentAge 0 set superspreaders 2 ] ;; check student age update
;
;
;;;************************************************************************************************************************************************************************************************************************

  ;; this section for Vic

;      if stage = 0 [ set span 30 set pta 0 set ppa 0 set spatial_distance false set age_isolation 0 set case_isolation false set schoolsPolicy true set quarantine true set schoolPolicyActive true
;  set OS_Import_Proportion 0 set link_switch false set Essential_Workers 100 set maskPolicy true set mask_wearing 50 set tracking false set App_Uptake 20 set residualcautionPTA 0
;    set residualcautionPPA 0 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency false set upperStudentAge 18 set LowerStudentAge 3 ]
;
;  if stage = 1 [ set span 30 set pta 15 set ppa 15 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy true set quarantine true set schoolPolicyActive true
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 75 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 15
;    set residualcautionPPA 15 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency false set upperStudentAge 18 set LowerStudentAge 3 ]
;
;  if stage = 2 [ set span 15 set pta 75 set ppa 75 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy false set quarantine true set schoolPolicyActive false
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 50 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 60
;    set residualcautionPPA 60 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency false set upperStudentAge 18 set LowerStudentAge 3 ]
;
;  if stage = 3 [ set span 10 set pta 85 set ppa 85 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy false set quarantine true set schoolPolicyActive false
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 30 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 68
;    set residualcautionPPA 68 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency false set upperStudentAge 18 set LowerStudentAge 3 ]
;
;  if stage = 4 [ set span 5 set pta 90 set ppa 90 set spatial_distance true set age_isolation 0 set case_isolation true set schoolsPolicy false set quarantine true set schoolPolicyActive false
;  set OS_Import_Proportion 0 set link_switch true set Essential_Workers 20 set maskPolicy true set mask_wearing 90 set tracking true set App_Uptake 30 set residualcautionPTA 81
;    set residualcautionPPA 81 set proportion_people_avoid ppa set proportion_time_avoid pta set complacency false set upperStudentAge 18 set LowerStudentAge 3 ] ;; check student age update

;;*************************************************************************************************************************************************************************************************************************

end

to calculateCasesInLastPeriod ;; counts cases in the last 14 days -
  ;; THIS ONLY COUNTS DETECTED CASES,  NOT ALL INFECTIONS - TOADJUST YOU MUST SET ASYMPTOMATIC TO ZERO



set	prior27	prior26
set	prior26	prior25
set	prior25	prior24
set	prior24	prior23
set	prior23	prior22
set	prior22	prior21
set	prior21	prior20
set	prior20	prior19
set	prior19	prior18
set	prior18	prior17
set	prior17	prior16
set	prior16	prior15
set	prior15	prior14
set	prior14	prior13
set prior13	prior12
set prior12	prior11
set prior11	prior10
set prior10	prior9
set prior9	prior8
set prior8	prior7
set prior7	prior6
set prior6	prior5
set prior5	prior4
set prior4	prior3
set prior3	prior2
set prior2	prior1
set prior1	prior0
set prior0 dailyCases	

  set casesinperiod14 (prior0 + prior1 + prior2 + prior3 + prior4 + prior5 + prior6 + prior7 + prior8 + prior9
    + prior10 + prior11 + prior12 + prior13 )

  set casesinperiod7 (prior0 + prior1 + prior2 + prior3 + prior4 + prior5 + prior6 )

  set casesinperiod28 (prior0 + prior1 + prior2 + prior3 + prior4 + prior5 + prior6 + prior7 + prior8 + prior9
    + prior10 + prior11 + prior12 + prior13 + prior14 + prior15 + prior16 + prior17 + prior18 + prior19 + prior20 + prior21
    + prior22 + prior23 + prior24 + prior25 + prior26 + prior27)


;print	prior13
;print	prior12
;print	prior11
;print	prior10
;print	prior9
;print	prior8
;print	prior7
;print	prior6
;print	prior5
;print	prior4
;print	prior3
;print	prior2
;print	prior1
;print	prior0
;print"****************************************************"

end

;to covidpolicytriggers
;
;  if ticks > 0 [ set stage 4 ] ;; used to set up initial stages for Victoria runs
;
;  ;;if ticks > 0 [ set stage 3 ] ;; used to set up initial stages for Victoria runs
;end


;to calculatecashPosition
;  set cashPosition ( mean [ reserves] of simuls with [ color != black ] )
;end

to calculateObjfunction
  ;; mobility
  ;; if ticks > 1 [ set objFunction (mean [ contacts ] of simuls ) ]

  ;; moderate
   if ticks > 1 and numberinfected != 0 [ set objFunction ( log numberInfected 10 ) + 1 * (1 - ( mean [ contacts ] of simuls ) )]

  ;; cases
  ;;if ticks > 1 [ set objFunction  ( numberinfected * currentinfections )]
end

to updateoutside ;; controls the amount of time that interactions happen outside
  if count patches with [ pcolor = green ] < ( Outside * (count patches) ) [ ask n-of random 10 patches with [ pcolor = black ] [ set pcolor green ] ]
  if count patches with [ pcolor = green ] > ( Outside * (count patches) ) [ ask n-of random 10 patches with [ pcolor = green ] [ set pcolor black ] ]
end

;to updateStudentStatus
;  ask simuls with [ agerange = 5 ] [ set studentFlag 1 ] ;;; students can only be young or older
;  ask simuls with [ agerange = 15 ] [ set studentFlag 1 ]
;end

to incursion
  if ticks > 0 and currentinfections = 0 and IncursionRate > random-float 100 [ ask one-of simuls with [ color = 85 ] [ set color red ]]
end

to HHContactsIso
  ifelse isolate = true and color = 85 and any? other simuls with [ householdunit = [ householdunit] of myself and tracked = 1 ] [ move-to homelocation set pace 0 set isolating 1 ] [ set isolating 0 ]
  if isolating = 1 and color = red [ set tracked 1 ] ;; this identifies people in the system earlier because they get a test straight away having been a close contact of someone in their house
end

to vaccinate_me
;;  if vaccine_Avail = true and vaccine_rate > random 1000 and vacc_Effective < VEffectiveness and color = 85  and ageRange > 60 and Essentialworkerflag = 1 [ set color yellow ]

if vaccine_Avail = true and vaccine_rate > random-float 1000 and vacc_Effective < Vaccine_Efficacy and color = 85 [ set shape "person" set vaccinated 1 set ownincubationperiod ( ownincubationperiod / 5 ) set ownillnessperiod (ownillnessperiod / 5 ) ]
  ;; identifies vaccinated people, compresses the incubation and illness period

end

to CalculateMeanIDTime
    set meanIDTime mean [ IDTime ] of simuls with [ color != 85 ]
end

to VaccineBrand
  if Vaccine_Type = "AstraZeneca" [ set Vaccine_Efficacy 70 ]
  if Vaccine_Type = "Pfizer/BioNTech" [ set Vaccine_Efficacy 95 ]
  if Vaccine_Type = "Moderna" [ set Vaccine_Efficacy 94 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
316
123
934
942
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-30
30
-40
40
0
0
1
ticks
30.0

BUTTON
205
176
269
210
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
169
220
233
254
Go
ifelse (count simuls ) = (count simuls with [ color = blue ])  [ stop ] [ Go ]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
175
348
293
382
Trace_Patterns
ask n-of 50 simuls with [ color != black ] [ pen-down ] 
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
1

BUTTON
175
396
293
430
UnTrace
ask turtles [ pen-up ]
NIL
1
T
OBSERVER
NIL
U
NIL
NIL
1

SWITCH
699
135
899
168
spatial_distance
spatial_distance
0
1
-1000

SLIDER
165
270
305
303
Population
Population
1000
2500
2500.0
500
1
NIL
HORIZONTAL

SLIDER
165
306
306
339
Span
Span
0
30
30.0
1
1
NIL
HORIZONTAL

PLOT
1396
122
1918
387
Susceptible, Infected and Recovered - 000's
Days from March 10th
Numbers of people
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Infected Proportion" 1.0 0 -2674135 true "" "plot count simuls with [ color = red ] * (Total_Population / 100 / count Simuls) "
"Susceptible" 1.0 0 -14070903 true "" "plot count simuls with [ color = 85 ] * (Total_Population / 100 / count Simuls)"
"Recovered" 1.0 0 -987046 true "" "plot count simuls with [ color = yellow ] * (Total_Population / 100 / count Simuls)"
"New Infections" 1.0 0 -11221820 true "" "plot count simuls with [ color = red and timenow = Incubation_Period ] * ( Total_Population / 100 / count Simuls )"

SLIDER
699
428
899
461
Illness_period
Illness_period
0
25
20.8
.1
1
NIL
HORIZONTAL

SWITCH
700
172
898
205
case_isolation
case_isolation
0
1
-1000

BUTTON
228
220
292
254
Go Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1936
569
2123
602
RestrictedMovement
RestrictedMovement
0
1
0.0
.01
1
NIL
HORIZONTAL

MONITOR
338
876
493
933
Deaths
Deathcount
0
1
14

MONITOR
963
133
1053
178
Time Count
ticks
0
1
11

SLIDER
699
465
899
498
ReInfectionRate
ReInfectionRate
0
100
0.0
1
1
NIL
HORIZONTAL

SWITCH
699
316
899
349
quarantine
quarantine
0
1
-1000

SLIDER
138
713
327
746
Available_Resources
Available_Resources
0
4
0.0
1
1
NIL
HORIZONTAL

PLOT
1929
272
2226
417
Resource Availability
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -5298144 true "" "if count resources > 0 [ plot mean [ volume ] of resources ]"

SLIDER
1933
493
2122
526
ProductionRate
ProductionRate
0
100
5.0
1
1
NIL
HORIZONTAL

MONITOR
965
310
1120
367
# simuls
count simuls * (Total_Population / population)
0
1
14

MONITOR
1400
934
1660
979
Bed Capacity Scaled for Australia at 65,000k
count patches with [ pcolor = white ]
0
1
11

MONITOR
335
685
493
742
Total # Infected
numberInfected
0
1
14

SLIDER
700
282
899
315
Track_and_Trace_Efficiency
Track_and_Trace_Efficiency
0
1
0.5529470956183693
.05
1
NIL
HORIZONTAL

PLOT
1155
343
1360
493
Fear & Action
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -2674135 true "" "plot mean [ anxiety ] of simuls"

SLIDER
1938
686
2125
719
Media_Exposure
Media_Exposure
1
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
335
748
494
805
Mean Days infected
meanDaysInfected
2
1
14

SLIDER
700
542
900
575
Superspreaders
Superspreaders
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
1938
646
2123
679
Severity_of_illness
Severity_of_illness
0
100
15.0
1
1
NIL
HORIZONTAL

MONITOR
338
815
491
872
% Total Infections
numberInfected / Total_Population * 100
2
1
14

MONITOR
1153
125
1283
170
Case Fatality Rate %
caseFatalityRate * 100
2
1
11

PLOT
1153
185
1353
335
Case Fatality Rate %
NIL
NIL
0.0
10.0
0.0
0.05
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "plot caseFatalityRate * 100"

SLIDER
700
209
898
242
Proportion_People_Avoid
Proportion_People_Avoid
0
100
24.0
.5
1
NIL
HORIZONTAL

SLIDER
699
245
898
278
Proportion_Time_Avoid
Proportion_Time_Avoid
0
100
24.0
.5
1
NIL
HORIZONTAL

SLIDER
1933
453
2123
486
Treatment_Benefit
Treatment_Benefit
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
1936
529
2123
562
FearTrigger
FearTrigger
0
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
955
630
1014
675
R0
mean [ R ] of simuls with [ color = red and timenow = int Illness_Period ]
2
1
11

SWITCH
158
586
302
619
policytriggeron
policytriggeron
0
1
-1000

SLIDER
1936
609
2121
642
Initial
Initial
0
100
1.0
1
1
NIL
HORIZONTAL

MONITOR
963
249
1118
306
Financial Reserves
mean [ reserves ] of simuls
1
1
14

PLOT
1398
390
1918
511
Estimated count of deceased across age ranges (not scaled)
NIL
NIL
0.0
100.0
0.0
50.0
true
false
"" ""
PENS
"default" 1.0 1 -2674135 true "" "Histogram [ agerange ] of simuls with [ color = black ] "

PLOT
1398
619
1918
769
Infection Proportional Growth Rate
Time
Growth rate
0.0
300.0
0.0
2.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 1 [ plot ( InfectionChange ) * 10 ]"

SLIDER
699
355
898
388
Compliance_with_Isolation
Compliance_with_Isolation
0
100
99.0
1
1
NIL
HORIZONTAL

MONITOR
1742
639
1874
684
Infection Growth %
infectionchange
2
1
11

INPUTBOX
158
443
314
504
current_cases
1.0
1
0
Number

INPUTBOX
158
508
314
569
total_population
2.5E7
1
0
Number

SLIDER
139
625
313
658
Triggerday
Triggerday
0
1000
1.0
1
1
NIL
HORIZONTAL

MONITOR
965
425
1120
470
Close contacts per day
AverageContacts
2
1
11

PLOT
965
506
1155
627
Close contacts and Mobility
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"Contacts" 1.0 0 -16777216 true "" "if ticks > 0 [ plot mean [ contacts ] of simuls with [ color != black  ] ] "

PLOT
951
678
1161
838
R0
Time
R
0.0
10.0
0.0
3.0
true
false
"" ""
PENS
"R" 1.0 0 -16777216 true "" "if count simuls with [ timenow = int ownIllnessPeriod ] > 0 [ plot MeanR ]"

PLOT
1160
503
1360
624
Population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count simuls"

SLIDER
699
505
901
538
Incubation_Period
Incubation_Period
0
10
5.1
.1
1
NIL
HORIZONTAL

PLOT
1931
123
2223
268
Age ranges
NIL
NIL
0.0
100.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ agerange ] of simuls"

PLOT
952
842
1368
1098
Active (red) and Total (blue) Infections ICU Beds (black)
NIL
NIL
0.0
10.0
0.0
200.0
true
false
"" "\n"
PENS
"Current Cases" 1.0 1 -7858858 true "" "plot currentInfections "
"Total Infected" 1.0 0 -13345367 true "" "plot NumberInfected "
"ICU Beds Required" 1.0 0 -16777216 true "" "plot ICUBedsRequired "

MONITOR
335
626
488
675
New Infections Today
DailyCases
0
1
12

PLOT
330
943
632
1098
New Infections Per Day
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "if Scalephase = 1 [ plot count simuls with [ color = red and int timenow = Case_Reporting_Delay ] * 10 ] \nif ScalePhase = 2 [ plot count simuls with [ color = red and int timenow = Case_Reporting_Delay ] * 100 ] \nif ScalePhase = 3 [ plot count simuls with [ color = red and int timenow = Case_Reporting_Delay ] * 1000 ]\nif ScalePhase = 4 [ plot count simuls with [ color = red and int timenow = Case_Reporting_Delay ] * 10000 ]"
PENS
"New Cases" 1.0 1 -5298144 true "" "if scalephase = 0 [ plot count simuls with [ color = red and timenow = Case_Reporting_Delay ] ]"

SLIDER
700
578
900
611
Diffusion_Adjustment
Diffusion_Adjustment
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
700
615
899
648
Age_Isolation
Age_Isolation
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
702
652
901
685
Contact_Radius
Contact_Radius
0
180
0.0
1
1
NIL
HORIZONTAL

PLOT
1400
772
1925
925
Cash_Reserves
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Financial_Reserves" 1.0 0 -16777216 true "" "plot mean [ reserves] of simuls with [ color != black ]"

SWITCH
173
753
277
786
stimulus
stimulus
1
1
-1000

SWITCH
173
796
277
829
cruise
cruise
0
1
-1000

MONITOR
963
370
1116
419
Stimulus
Sum [ value ] of packages * -1 * (Total_Population / Population )
0
1
12

MONITOR
1439
850
1514
907
Growth
objFunction
2
1
14

BUTTON
170
843
276
878
Stop Stimulus
ask packages [ die ] 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
963
183
1118
245
days_of_cash_reserves
30.0
1
0
Number

MONITOR
1400
983
1485
1028
Mean income
mean [ income ] of simuls with [ agerange > 18 and agerange < 70 and color != black ]
0
1
11

MONITOR
1493
983
1593
1028
Mean Expenses
mean [ expenditure ] of simuls with [ agerange >= 18 and agerange < 70 and color != black ]
0
1
11

MONITOR
52
885
191
930
Count red simuls (raw)
count simuls with [ color = red ]
0
1
11

SWITCH
178
952
283
985
scale
scale
0
1
-1000

MONITOR
1059
133
1117
178
NIL
Days
17
1
11

MONITOR
1160
687
1358
736
Scale Phase
scalePhase
17
1
12

MONITOR
1669
929
1924
978
Negative $ Reserves
count simuls with [ shape = \"star\" ] / count simuls
2
1
12

TEXTBOX
145
678
318
700
Day 1 - Dec 21st, 2020
12
15.0
1

TEXTBOX
1164
744
1379
837
0 - 2,500 Population\n1 - 25,000 \n2 - 250,000\n3 - 2,500,000\n4 - 25,000,000
12
0.0
1

INPUTBOX
530
216
609
284
ppa
23.0
1
0
Number

INPUTBOX
615
216
700
285
pta
23.0
1
0
Number

TEXTBOX
346
210
522
296
Manually enter the proportion of people who avoid (PPA) and time avoided (PTA) here when using the policy trigger switch
12
0.0
0

PLOT
1609
984
1924
1104
Trust in Govt
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot mean [ personalTrust ] of simuls with [ color != black ]"

SLIDER
700
858
903
891
WFH_Capacity
WFH_Capacity
0
100
30.0
.1
1
NIL
HORIZONTAL

SLIDER
140
1035
314
1068
TimeLockDownOff
TimeLockDownOff
0
300
28.0
1
1
NIL
HORIZONTAL

SWITCH
163
993
292
1026
lockdown_off
lockdown_off
0
1
-1000

SWITCH
189
130
298
163
freewheel
freewheel
1
1
-1000

TEXTBOX
143
80
358
118
Leave Freewheel to 'on' to manipulate policy on the fly
12
0.0
1

MONITOR
1292
128
1372
173
NIL
count simuls
17
1
11

SLIDER
700
898
904
931
ICU_Required
ICU_Required
0
100
5.0
1
1
NIL
HORIZONTAL

MONITOR
335
570
489
619
ICU Beds Needed
ICUBedsRequired
0
1
12

PLOT
630
942
949
1097
ICU Beds Available vs Required
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Required" 1.0 0 -16777216 true "" "plot ICUBedsRequired"
"Spare" 1.0 0 -5298144 true "" "plot ICU_Beds_in_Australia - ICUBedsRequired "

SLIDER
1027
635
1236
668
Mean_Individual_Income
Mean_Individual_Income
0
100000
55000.0
5000
1
NIL
HORIZONTAL

SLIDER
335
532
510
565
ICU_Beds_in_Australia
ICU_Beds_in_Australia
0
20000
7000.0
50
1
NIL
HORIZONTAL

SLIDER
700
819
905
852
Hospital_Beds_in_Australia
Hospital_Beds_in_Australia
0
200000
65000.0
5000
1
NIL
HORIZONTAL

SLIDER
1938
727
2128
760
Bed_Capacity
Bed_Capacity
0
20
4.0
1
1
NIL
HORIZONTAL

MONITOR
1530
1052
1594
1101
Links
count links / count simuls with [ color = red ]
0
1
12

SWITCH
1400
1033
1514
1066
link_switch
link_switch
0
1
-1000

INPUTBOX
1945
842
2100
902
maxv
1.0
1
0
Number

INPUTBOX
1945
912
2100
972
minv
0.0
1
0
Number

INPUTBOX
1947
977
2102
1037
phwarnings
0.8
1
0
Number

INPUTBOX
1949
1044
2104
1104
saliency_of_experience
1.0
1
0
Number

INPUTBOX
2104
774
2259
834
care_attitude
0.5
1
0
Number

INPUTBOX
2107
842
2262
902
self_capacity
0.8
1
0
Number

MONITOR
2142
448
2256
493
Potential contacts
PotentialContacts
0
1
11

MONITOR
999
946
1101
991
NIL
numberInfected
17
1
11

PLOT
2306
422
2641
545
Distribution of Illness pd
NIL
NIL
10.0
40.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ ownIllnessPeriod ] of simuls "

INPUTBOX
2139
503
2295
564
se_illnesspd
4.0
1
0
Number

INPUTBOX
2139
566
2295
627
se_incubation
2.25
1
0
Number

PLOT
2308
543
2646
665
Dist_Incubation_Pd
NIL
NIL
0.0
15.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ ownIncubationPeriod ] of simuls"

PLOT
2309
665
2469
786
Compliance
NIL
NIL
80.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ owncompliancewithisolation ] of simuls"

INPUTBOX
1942
775
2097
835
initialassociationstrength
0.0
1
0
Number

SLIDER
700
392
902
425
AsymptomaticPercentage
AsymptomaticPercentage
0
100
30.329707267192337
1
1
NIL
HORIZONTAL

MONITOR
1245
630
1310
675
Virulence
mean [ personalvirulence] of simuls
1
1
11

SLIDER
700
776
906
809
Global_Transmissability
Global_Transmissability
0
100
25.0
1
1
NIL
HORIZONTAL

MONITOR
1320
630
1376
675
A V
mean [ personalvirulence ] of simuls with [ asymptom < AsymptomaticPercentage ]
1
1
11

SLIDER
338
456
514
489
Essential_Workers
Essential_Workers
0
100
75.0
1
1
NIL
HORIZONTAL

SLIDER
140
1076
313
1109
SeedTicks
SeedTicks
0
100
7.0
1
1
NIL
HORIZONTAL

SLIDER
336
492
511
525
Ess_W_Risk_Reduction
Ess_W_Risk_Reduction
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
339
420
515
453
App_Uptake
App_Uptake
0
100
100.0
1
1
NIL
HORIZONTAL

SWITCH
342
172
447
205
tracking
tracking
0
1
-1000

SLIDER
461
305
573
338
Mask_Wearing
Mask_Wearing
0
100
90.0
1
1
NIL
HORIZONTAL

SWITCH
342
383
464
416
schoolsPolicy
schoolsPolicy
0
1
-1000

MONITOR
451
168
523
213
Household
mean [ householdunit ] of simuls
1
1
11

PLOT
2235
123
2515
271
Infections by age range
NIL
NIL
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "Histogram [ agerange ] of simuls with [ color != 85  ]"

SWITCH
503
898
631
931
AssignAppEss
AssignAppEss
1
1
-1000

SLIDER
503
859
631
892
eWAppUptake
eWAppUptake
0
1
0.0
.01
1
NIL
HORIZONTAL

SLIDER
343
132
506
165
TTIncrease
TTIncrease
0
5
2.0
.01
1
NIL
HORIZONTAL

MONITOR
1400
1070
1516
1115
Link Proportion
count links with [ color = blue ] / count links with [ color = red ]
1
1
11

MONITOR
2238
280
2370
325
EW Infection %
EWInfections / 2500
1
1
11

MONITOR
2239
330
2372
375
Student Infections %
studentInfections / 2500
1
1
11

SWITCH
469
383
621
416
SchoolPolicyActive
SchoolPolicyActive
0
1
-1000

SLIDER
520
420
652
453
SchoolReturnDate
SchoolReturnDate
0
100
0.0
1
1
NIL
HORIZONTAL

SWITCH
340
342
450
375
MaskPolicy
MaskPolicy
0
1
-1000

SLIDER
523
136
696
169
ResidualCautionPPA
ResidualCautionPPA
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
525
172
698
205
ResidualCautionPTA
ResidualCautionPTA
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
2109
911
2265
944
Case_Reporting_Delay
Case_Reporting_Delay
0
20
6.0
1
1
NIL
HORIZONTAL

PLOT
2113
953
2368
1103
R and Compliance Distributions 
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ R ] of simuls with [ color != 85 ] "
"Compliance" 1.0 0 -2674135 true "" "histogram [ ownCompliancewithIsolation * 10 ] of simuls "

MONITOR
2283
809
2341
854
R Sum
sum [ r ] of simuls with [ color != 85 ]
1
1
11

MONITOR
2445
810
2495
855
>3
sum [ r ] of simuls with [ color != 85  and R = 3]
17
1
11

MONITOR
2392
810
2442
855
=2
sum [ r ] of simuls with [ color != 85  and R = 2]
17
1
11

MONITOR
2496
810
2546
855
=4
sum [ r ] of simuls with [ color != 85  and R = 4]
17
1
11

MONITOR
2340
809
2390
854
=1
sum [ r ] of simuls with [ color != 85  and R = 1]
17
1
11

MONITOR
2548
810
2598
855
>4
sum [ r ] of simuls with [ color != 85  and R > 4]
17
1
11

MONITOR
2446
858
2496
903
C3
count simuls with [ color != 85 and R = 3]
17
1
11

MONITOR
2392
858
2442
903
C2
count simuls with [ color != 85 and R = 2]
17
1
11

MONITOR
2499
859
2549
904
c4
count simuls with [ color != 85 and R = 4]
17
1
11

MONITOR
2550
859
2600
904
C>4
count simuls with [ color != 85 and R > 4 ]
17
1
11

MONITOR
2339
858
2389
903
C1
count simuls with [ color != 85 and R = 1]
17
1
11

MONITOR
2283
858
2333
903
C0
count simuls with [ color != 85 and R = 0]
17
1
11

SLIDER
2378
282
2551
315
Visit_Frequency
Visit_Frequency
0
6
3.0
1
1
NIL
HORIZONTAL

SLIDER
2379
319
2552
352
Visit_Radius
Visit_Radius
0
10
4.0
1
1
NIL
HORIZONTAL

MONITOR
2510
925
2568
970
%>3
count simuls with [ color != 85 and R > 2] / count simuls with [ color != 85 and R > 0 ] * 100
2
1
11

MONITOR
2509
743
2567
788
% R
sum [ R ] of simuls with [ color != 85 and R > 2] / sum [ R ] of simuls with [ color != 85 and R > 0 ] * 100
2
1
11

SLIDER
703
695
905
728
Asymptomatic_Trans
Asymptomatic_Trans
0
1
0.2901105670124259
.01
1
NIL
HORIZONTAL

SWITCH
506
696
686
729
OS_Import_Switch
OS_Import_Switch
1
1
-1000

SLIDER
703
735
905
768
OS_Import_Proportion
OS_Import_Proportion
0
1
0.0
.01
1
NIL
HORIZONTAL

MONITOR
1000
889
1072
934
OS %
( count simuls with [  imported = 1 ] / count simuls with [ color != 85 ]) * 100
2
1
11

SLIDER
506
736
694
769
OS_Import_Post_Proportion
OS_Import_Post_Proportion
0
1
0.61
.01
1
NIL
HORIZONTAL

MONITOR
998
998
1106
1043
NIL
currentinfections
17
1
11

MONITOR
1078
890
1153
935
Illness time
mean [ timenow ] of simuls with [ color = red ]
1
1
11

MONITOR
898
1035
1003
1096
ICU Beds
ICUBedsRequired
0
1
15

SWITCH
462
347
587
380
Complacency
Complacency
0
1
-1000

CHOOSER
1270
763
1363
808
InitialScale
InitialScale
0 1 2 3 4
0

CHOOSER
506
776
694
821
Stage
Stage
0 1 2 3 3.3 3.4 3.5 3.9 4
1

PLOT
2378
981
2623
1103
New cases in last 7, 14, 28 days
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot casesinperiod14"
"pen-1" 1.0 0 -7500403 true "" "plot casesinperiod7"
"pen-2" 1.0 0 -2674135 true "" "plot casesinperiod28"

INPUTBOX
1425
133
1505
194
zerotoone
1.0
1
0
Number

INPUTBOX
1423
196
1503
257
onetotwo
35.0
1
0
Number

INPUTBOX
1423
258
1505
319
twotothree
70.0
1
0
Number

INPUTBOX
1423
320
1505
381
threetofour
210.0
1
0
Number

SWITCH
506
658
618
691
SelfGovern
SelfGovern
0
1
-1000

PLOT
1396
498
1921
619
Stages
NIL
NIL
0.0
10.0
0.0
4.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "plot stage"

MONITOR
2379
926
2494
971
Cases in period 7
casesinperiod7
0
1
11

INPUTBOX
1508
132
1590
193
JudgeDay1
2.0
1
0
Number

INPUTBOX
1508
198
1591
259
JudgeDay2
2.0
1
0
Number

INPUTBOX
1509
260
1591
321
JudgeDay3
2.0
1
0
Number

INPUTBOX
1509
322
1591
383
JudgeDay4
2.0
1
0
Number

MONITOR
1417
548
1527
593
Policy Reset Date
ResetDate
0
1
11

INPUTBOX
2140
632
2296
693
UpperStudentAge
18.0
1
0
Number

INPUTBOX
2142
693
2298
754
LowerStudentAge
4.0
1
0
Number

PLOT
512
493
692
643
Objective Function
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot Objfunction"

SLIDER
508
823
681
856
Outside
Outside
0
1
0.0
.01
1
NIL
HORIZONTAL

SLIDER
963
472
1136
505
outsideRisk
outsideRisk
0
100
33.0
1
1
NIL
HORIZONTAL

MONITOR
330
76
413
121
Green space
count patches with [ pcolor = green ]
0
1
11

INPUTBOX
1829
132
1902
193
onetozero
0.0
1
0
Number

INPUTBOX
1831
193
1903
254
twotoone
1.0
1
0
Number

INPUTBOX
1831
255
1901
316
threetotwo
35.0
1
0
Number

INPUTBOX
1831
316
1903
377
fourtothree
105.0
1
0
Number

MONITOR
229
888
311
933
Yellow (raw)
count simuls with [ color = yellow ]
0
1
11

MONITOR
1432
605
1550
650
NIL
StageHasChanged
0
1
11

INPUTBOX
1754
134
1824
194
JudgeDay1_d
1.0
1
0
Number

INPUTBOX
1754
195
1828
255
Judgeday2_d
1.0
1
0
Number

INPUTBOX
1754
257
1831
317
Judgeday3_d
1.0
1
0
Number

INPUTBOX
1754
320
1829
380
Judgeday4_d
1.0
1
0
Number

SLIDER
423
83
603
116
Undetected_Proportion
Undetected_Proportion
0
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
52
830
167
875
Undetected Cases
count simuls with [ color = red and undetectedFlag = 1 ]
0
1
11

MONITOR
340
922
412
967
NIL
Dailycases
0
1
11

SLIDER
756
86
929
119
Household_Attack
Household_Attack
0
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
80
335
153
380
Time = 1 
count simuls with [ timenow = 2 ]
0
1
11

MONITOR
1529
549
1594
594
Students
count simuls with [ studentFlag = 1 ]
0
1
11

SLIDER
616
86
735
119
IncursionRate
IncursionRate
0
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
1613
139
1728
184
Last Decision Date
DecisionDate
0
1
11

SWITCH
962
87
1066
120
Isolate
Isolate
0
1
-1000

SLIDER
1155
88
1343
121
Mask_Efficacy_Discount
Mask_Efficacy_Discount
0
1
0.33
.01
1
NIL
HORIZONTAL

SWITCH
1398
80
1524
113
Vaccine_Avail
Vaccine_Avail
0
1
-1000

SLIDER
1532
82
1705
115
Vaccine_Rate
Vaccine_Rate
0
700
2.73
1
1
NIL
HORIZONTAL

SLIDER
1710
82
1883
115
Vaccine_Efficacy
Vaccine_Efficacy
0
100
95.0
1
1
NIL
HORIZONTAL

CHOOSER
1893
72
2032
117
BaseStage
BaseStage
0 1 2 3 4
1

MONITOR
58
776
147
821
Mean ID Time
meanIDTime
1
1
11

SLIDER
2038
80
2211
113
GoldStandard
GoldStandard
0
100
100.0
1
1
NIL
HORIZONTAL

CHOOSER
2220
70
2359
115
MaxStage
MaxStage
0 1 2 3 4
4

MONITOR
1533
33
1623
79
Vaccinated %
( count simuls with [ shape = \"person\" ] / 2500 )* 100
2
1
11

CHOOSER
2363
72
2502
118
Vaccine_Type
Vaccine_Type
"AstraZeneca" "Moderna" "Pfizer/BioNTech" "Other"
0

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bed
false
15
Polygon -1 true true 45 150 45 150 90 210 240 105 195 75 45 150
Rectangle -1 true true 227 105 239 150
Rectangle -1 true true 90 195 106 250
Rectangle -1 true true 45 150 60 195
Polygon -1 true true 106 211 106 211 232 125 228 108 98 193 102 213

bog roll
true
0
Circle -1 true false 13 13 272
Circle -16777216 false false 75 75 150
Circle -16777216 true false 103 103 95
Circle -16777216 false false 59 59 182
Circle -16777216 false false 44 44 212
Circle -16777216 false false 29 29 242

bog roll2
true
0
Circle -1 true false 74 30 146
Rectangle -1 true false 75 102 220 204
Circle -1 true false 74 121 146
Circle -16777216 true false 125 75 44
Circle -16777216 false false 75 28 144

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

box 2
false
0
Polygon -7500403 true true 150 285 270 225 270 90 150 150
Polygon -13791810 true false 150 150 30 90 150 30 270 90
Polygon -13345367 true false 30 90 30 225 150 285 150 150

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

health care
false
15
Circle -1 true true 2 -2 302
Rectangle -2674135 true false 69 122 236 176
Rectangle -2674135 true false 127 66 181 233

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

worker1
true
15
Circle -16777216 true false 96 96 108
Circle -1 true true 108 108 85
Polygon -16777216 true false 120 180 135 195 121 245 107 246 125 190 125 190
Polygon -16777216 true false 181 182 166 197 180 247 194 248 176 192 176 192

worker2
true
15
Circle -16777216 true false 95 94 110
Circle -1 true true 108 107 85
Polygon -16777216 true false 130 197 148 197 149 258 129 258
Polygon -16777216 true false 155 258 174 258 169 191 152 196

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Australia" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="132"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="72"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Wuhan" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set current_cases current_cases + random-normal 20 10
set AsymptomaticPercentage AsymptomaticPercentage + random 10 - random 10
set PPA random 100
set PTA random 100</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>StudentInfections</metric>
    <metric>EWInfections</metric>
    <metric>count simuls with [ Asymptomaticflag = 1 ]</metric>
    <metric>PPA</metric>
    <metric>PTA</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="129"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="11000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="53"/>
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="86"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NZ new" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="5000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="39"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.45"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Australia Asymptomatic" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="132"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="72"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Wuhan new" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set current_cases current_cases + random-normal 20 10
set AsymptomaticPercentage AsymptomaticPercentage + random 10 - random 10
set PPA random 100
set PTA random 100</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>StudentInfections</metric>
    <metric>EWInfections</metric>
    <metric>count simuls with [ Asymptomaticflag = 1 ]</metric>
    <metric>PPA</metric>
    <metric>PTA</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="129"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="11000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="53"/>
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="86"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maskPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Victoria HE" repetitions="500" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>essentialworkerpercentage</metric>
    <metric>lasttransday</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="6400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="341"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Efficacy">
      <value value="80"/>
      <value value="70"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolpolicyactive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scalephase">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Victoria LE Masks Decay Test" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>essentialworkerpercentage</metric>
    <metric>lasttransday</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="6400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="70"/>
      <value value="50"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolpolicyactive">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Victoria LE Grattan 1" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup
set asymptomatic asymptomatic + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>essentialworkerpercentage</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="6400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Efficacy">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolpolicyactive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scalephase">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Victoria new MJA" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 2</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>essentialworkerpercentage</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="6400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="4200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Efficacy">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolpolicyactive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedticks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scalephase">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolreturndate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="R experiment" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>count simuls with [ color = red ] = 0</exitCondition>
    <metric>numberInfected / Total_Population * 100</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="2301"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="181"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="4.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="MJA stage 4 no complacency" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <metric>mean [ contacts ] of simuls</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="6400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="MJA stage 3 no complacency" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="150"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="0"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DHHS 24 August Balanced" repetitions="500" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <metric>objfunction</metric>
    <enumeratedValueSet variable="zerotoone">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="941"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="31"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DHHS 24 August Min Cases" repetitions="500" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <metric>objfunction</metric>
    <enumeratedValueSet variable="zerotoone">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="291"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="841"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1801"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DHHS 24 August Max Mobility" repetitions="500" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <metric>objfunction</metric>
    <enumeratedValueSet variable="zerotoone">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="271"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="701"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="4101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Elimination Aggressive" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="540"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="32.80452063214149"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Elimination Moderate" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="540"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>nonesspercentage</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="32.80452063214149"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Multiple JN" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="306"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="32.80452063214149"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JN experiment 28_8" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="306"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="14"/>
      <value value="28"/>
      <value value="42"/>
      <value value="56"/>
      <value value="70"/>
      <value value="84"/>
      <value value="98"/>
      <value value="112"/>
      <value value="126"/>
      <value value="140"/>
      <value value="210"/>
      <value value="280"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="31"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JN experiment 31_8 New" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set undetected_proportion undetected_proportion + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="306"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="14"/>
      <value value="28"/>
      <value value="42"/>
      <value value="70"/>
      <value value="140"/>
      <value value="210"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Tight Suppression" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="540"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="31.9786782754768"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.26642146168603675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Loose Suppression" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="540"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="32.80452063214149"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="31.9786782754768"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.26642146168603675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JN experiment 31_8 Testing for seedticks" repetitions="30" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set undetected_proportion undetected_proportion + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="35"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JN experiment 1_9 Evening Testing" repetitions="250" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set undetected_proportion undetected_proportion + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="303"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="14"/>
      <value value="42"/>
      <value value="70"/>
      <value value="98"/>
      <value value="140"/>
      <value value="210"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="JN experiment 1_9 Evening Testing High" repetitions="150" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set undetected_proportion undetected_proportion + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="120"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="42"/>
      <value value="70"/>
      <value value="140"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Final Schools back run" repetitions="500" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set undetected_proportion undetected_proportion + random-normal 0 3</setup>
    <go>go</go>
    <timeLimit steps="120"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="420"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="1400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="42"/>
      <value value="70"/>
      <value value="140"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Tony Aggressive" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="5"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="53"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Tony Moderate" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Tight Suppression" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="5"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="224"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="896"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="448"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="224"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Loose Suppression" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="560"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="5"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="560"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="3.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="4480"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="560"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="560"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1120"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Balanced Optimised" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.3786520078146838"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.93835399015626"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="100000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Case Optimised" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.3786520078146838"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.93835399015626"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Mobility Optimised" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.3786520078146838"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.93835399015626"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Loose Suppression Variation Test" repetitions="300" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="180"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="656"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="1312"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="656"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="5250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="656"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="7500000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="656"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="2625"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1312"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Aggressive Vic" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="180"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <metric>objFunction</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Unmitigated Vic" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <metric>ObjFunction</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jan Tests Vic" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
set App_uptake App_Uptake + random-normal 0 4
set stage BaseStage</setup>
    <go>go</go>
    <timeLimit steps="180"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <metric>objFunction</metric>
    <metric>meanIDTime</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BaseStage">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="56"/>
      <value value="70"/>
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Avail">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VEffectiveness">
      <value value="63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Rate">
      <value value="2.73"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Bumble Along" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
set asymptomaticPercentage asymptomaticPercentage + random-normal 0 3
set Asymptomatic_Trans Asymptomatic_Trans + random-normal 0 .06 
set Essential_Workers Essential_Workers + random-normal 0 2
set Superspreaders Superspreaders + random-normal 0 2
;;set App_uptake App_Uptake + random-normal 0 4
set stage BaseStage</setup>
    <go>go</go>
    <timeLimit steps="180"/>
    <metric>count turtles</metric>
    <metric>ticks</metric>
    <metric>numberInfected</metric>
    <metric>deathcount</metric>
    <metric>casefatalityrate</metric>
    <metric>ICUBedsRequired</metric>
    <metric>DailyCases</metric>
    <metric>CurrentInfections</metric>
    <metric>EliminationDate</metric>
    <metric>MeanR</metric>
    <metric>Essential_Workers</metric>
    <metric>scale</metric>
    <metric>stage</metric>
    <metric>averagecontacts</metric>
    <metric>CasesinPeriod7</metric>
    <metric>CasesinPeriod14</metric>
    <metric>CasesinPeriod28</metric>
    <metric>objFunction</metric>
    <metric>meanIDTime</metric>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="App_Uptake">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AssignAppEss">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Asymptomatic_Trans">
      <value value="0.35844673433467694"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AsymptomaticPercentage">
      <value value="33.70984742562481"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BaseStage">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care_attitude">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case_isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Reporting_Delay">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Complacency">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Compliance_with_Isolation">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="-45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="current_cases">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days_of_cash_reserves">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Diffusion_Adjustment">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ess_W_Risk_Reduction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Essential_Workers">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eWAppUptake">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourtothree">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="freewheel">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Global_Transmissability">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GoldStandard">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hospital_Beds_in_Australia">
      <value value="65000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Household_Attack">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Beds_in_Australia">
      <value value="7000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ICU_Required">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Illness_period">
      <value value="20.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IncursionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialassociationstrength">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialScale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolate">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay1_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay2">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday2_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay3">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday3_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="JudgeDay4">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Judgeday4_d">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link_switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown_off">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LowerStudentAge">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mask_Wearing">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaskPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaxStage">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mean_Individual_Income">
      <value value="55000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="onetozero">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Post_Proportion">
      <value value="0.61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS_Import_Switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outside">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outsideRisk">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phwarnings">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policytriggeron">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppa">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Time_Avoid">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pta">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPPA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ResidualCautionPTA">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saliency_of_experience">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolPolicyActive">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SchoolReturnDate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schoolsPolicy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_illnesspd">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se_incubation">
      <value value="2.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeedTicks">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="self_capacity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfGovern">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Span">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial_distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulus">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetofour">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threetotwo">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TimeLockDownOff">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track_and_Trace_Efficiency">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tracking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TTIncrease">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotoone">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="twotothree">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Undetected_Proportion">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UpperStudentAge">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Avail">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VEffectiveness">
      <value value="63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine_Rate">
      <value value="2.73"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Visit_Radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WFH_Capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zerotoone">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
