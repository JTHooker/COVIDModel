;;extensions [ dist ]

globals [

  FearFactor
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
  Adjustment
  GlobalR
]


breed [ simuls simul ]
breed [ resources resource ]
breed [ medresources medresource ] ;; people living in the city
breed [ packages package ]

simuls-own [
  timenow
  health
  inICU
  fear
  sensitivity
  R
  income
  expenditure
  reserves
  agerange
  contacts
  IncubationPd
  DailyRisk
  RiskofDeath
  Pace
]

Packages-own [
  value
]


patches-own [
  utilisation
]

medresources-own [
  capacity
]

resources-own [
  volume
]


to setup
    ;;reset-ticks

    clear-all
  import-drawing "Background1.png"
  ask patches [ set pcolor black  ]
  ask n-of 1 patches [ sprout-medresources 1 ]
  ask medresources [ set color white set shape "Health care" set size 10 set capacity Bed_Capacity set xcor 20 set ycor -20 ]
  ask medresources [ ask patches in-radius Capacity [ set pcolor white ] ]
  ask n-of Available_Resources patches [ sprout-resources 1 ]
  ask resources [ set color white set shape "Bog Roll2" set size 5 set volume one-of [ 2.5 5 7.5 10 ]  resize set xcor -20 set ycor one-of [ -30 -10 10 30 ] resetlanding ]
  ask n-of Population patches with [ pcolor = black ]
    [ sprout-simuls 1
      [ set size 2 set shape "dot" set color 85 set agerange 95 resethealth set timenow 0 set IncubationPd Incubation_Period set InICU 0 set fear 0 set sensitivity random-float 1 set R 0
        set income random-exponential 55000  resetincome calculateincomeperday calculateexpenditureperday move-to one-of patches with [ pcolor = black  ] resetlandingSimul set riskofdeath .01 ]
    ]
  ask n-of (Current_Cases * (population / Total_Population)) simuls [ set xcor 0 set ycor 0 set color red set timenow Incubation_Period ]

  if count simuls with [ color = red ] < 1 [ ask n-of 1 simuls [ set xcor 0 set ycor 0 set color red set timenow Incubation_Period ]]

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

  matchages

  ask simuls [  set health ( 100 - Agerange + random-normal 0 2 ) calculateDailyrisk setdeathrisk spend CalculateIncomePerday ]

  set contact_radius 0
  set days 0
  set Send_to_Hospital false

  reset-ticks
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
 ;; ask n-of int ninetyfive simuls with [ agerange > 85 ] [ set agerange 95 ] ;;; fix this
end

to setdeathrisk
  if agerange = 5 [ set riskofDeath 0 ]
  if agerange = 15 [ set riskofDeath .002 ]
  if agerange = 25 [ set riskofDeath .002 ]
  if agerange = 35 [ set riskofDeath .002 ]
  if agerange = 45 [ set riskofDeath .004 ]
  if agerange = 55 [ set riskofDeath .013 ]
  if agerange = 65 [ set riskofDeath .036 ]
  if agerange = 75 [ set riskofDeath .08 ]
  if agerange = 85 [ set riskofDeath .148 ]
  if agerange = 95 [ set riskofDeath .148 ]
end

to resetlanding
  if any? other resources-here [ set ycor one-of [ -30 -10 10 30 ] resetlanding ]
end

to resetlandingSimul
  if any? other simuls-here [ move-to one-of patches with [ count simuls-here = 0 and pcolor = black ]]
end

to resetincome
  if agerange >= 18 and agerange < 70 and income < 10000 [
    set income random-exponential 55000 ]
end

to resethealth
  if health < 0 [
    set health (100 - agerange) + random-normal 0 5 ]
end

to calculateIncomeperday
  if agerange >= 18 and agerange < 70 [
    set income income ]
end

to calculateexpenditureperday
  set expenditure income
end

to calculatedailyrisk
  set dailyrisk ( riskofDeath / Illness_period )
end


to go
  ask simuls [ move avoid recover settime karkit isolation reinfect createfear gatherreseources treat Countcontacts respeed earn financialstress AccessPackage calculateIncomeperday ] ;
  ask medresources [ allocatebed ]
  ask resources [ deplete replenish resize spin ]
  ask packages [ absorbshock ]
  finished
  CruiseShip
  GlobalTreat
  GlobalFear
  SuperSpread
  CountInfected
  CalculateDailyGrowth
  TriggerActionIsolation
  DeployStimulus
  setInitialReserves
  CalculateAverageContacts
  ScaleUp
  ;;ScaleDown
  ForwardTime
  adjustExpenditure

  ask patches [ checkutilisation ]
  tick

 ;; TriggerActionDistance
 ;; TriggerActionICU

end

to move
  if color != red and color != black and spatialDistance = false [ set heading heading + Contact_Radius + random 45 - random 45 fd pace avoidICUs ] ;; contact radius defines how large the circle of contacts for the person is.
  if any? other simuls-here with [ color = red and timenow >= random-normal 4 1 ] and color = 85 and infectionRate > random 100 and ticks <= Incubation_period [ set color red set timenow Incubation_Period - ticks  ]
  if any? other simuls-here with [ color = red and timenow >= random-normal 4 1 ] and color = 85 and infectionRate > random 100 and ticks > Incubation_period [ set color red set timenow 0  ]
  if any? other simuls-here with [ color = 85 ] and color = red and infectionRate > random 100 [ set R R + 1 set GlobalR GlobalR + 1 ]
  if color = red and Case_Isolation = false and Proportion_Isolating < random 100 and health > random 100 [ set heading heading + random 90 - random 90 fd pace ]
  if color = red and Send_to_Hospital = false [ avoidICUs ]
  if color = black [ move-to one-of MedResources ] ;; hidden from remaining simuls
end

to isolation
  if Case_Isolation = true and color = red and Proportion_Isolating > random 100 and timenow > IncubationPD [
    move-to patch-here set pace 0 ]
end

to avoid
  ifelse SpatialDistance = true and Proportion_People_Avoid > random 100 and Proportion_Time_Avoid > random 100 and AgeRange > Age_Isolation
  [ if any? other simuls-here [ if any? neighbors with [ utilisation = 0  ] [ move-to one-of neighbors with [ utilisation = 0 ] ] ]]
  [ set heading heading + contact_Radius fd pace avoidICUs move-to patch-here ]
end

to finished
  if count simuls = (count simuls with [ color = red ]) [ stop ]
  if count simuls = (count simuls with [ color = 85 ]) [ stop ]
end

to settime
  if color = red [ set timenow timenow + 1 PossiblyDie ]
end

to superSpread
  if count simuls with [ color = red ] >= Diffusion_Adjustment and Case_Isolation = false [  if Superspreaders > random 100 [ ask n-of Diffusion_Adjustment simuls with [ color = red ] [move-to one-of patches with [ pcolor = black ]
    if count simuls with [ color = yellow ] >= Diffusion_Adjustment [ ask n-of Diffusion_Adjustment Simuls with [ color = yellow ]  [move-to one-of patches with [ pcolor = black ]]]]]]

  if count simuls with [ color = red and timenow < Incubation_Period ] >= Diffusion_Adjustment and Case_Isolation = true [  if Superspreaders > random 100 [ ask n-of Diffusion_Adjustment simuls with [ color = red and timenow < Incubation_Period ] [move-to one-of patches with [ pcolor = black ]
    if count simuls with [ color = yellow ] >= Diffusion_Adjustment [ ask n-of Diffusion_Adjustment Simuls with [ color = yellow ]  [move-to one-of patches with [ pcolor = black ]]]]]]
end

to recover
  if timenow > Illness_Period and color != black  [
    set color yellow set timenow 0 set health (100 - agerange ) set inICU 0  ]
end

to reinfect
  if color = yellow and ReinfectionRate > random 100 [ set color 85 ]
end

to allocatebed
  ask patches in-radius Bed_Capacity [ set pcolor white ]
end

to avoidICUs
  if [ pcolor ] of patch-here = white and InICU = 0 [ move-to min-one-of patches with [ pcolor = black ]  [ distance myself ]  ]
end

to replenish
  if volume <= 10 and productionrate > random 100 [
    set volume volume + 1 ]
end

to deplete
  if any? simuls in-radius 1 and volume > 0 [
    set volume volume - .1 ]
end

to createfear
  set fear fear + Fearfactor + random-normal -2 1
  if fear < 0 [ set fear 0 ]
 ; if fear > 100 [ set fear 100 ]
end

to GlobalFear
  set fearFactor (count simuls with [ color = red ]) / (count simuls) * media_Exposure
end

to gatherreseources
  if (fear * sensitivity) > random 100 and count resources > 0 and InICU = 0  [ face min-one-of resources with [ volume >= 0 ] [ distance myself ]  ]
  if any? resources-here with [ volume >= 0 ] and fear > 0 [ set fear mean [ fearfactor ] of neighbors move-to one-of patches with [ pcolor = black ] ]
end

to resize
  set size volume * 2
  ifelse volume < 1 [ set color red ] [ set color white ]
end

to spin
set heading heading + 5
end

to GlobalTreat
  if (count simuls with [ InICU = 1 ]) < (count patches with [ pcolor = white ]) and Send_to_Hospital = true and any? simuls with [ color = red and inICU = 0 ]
    [ ask n-of ( count simuls with [ color = red and inICU = 0 and IncubationPd >= Incubation_Period ] * ID_Rate ) simuls with [ color = red and inICU = 0 and IncubationPd >= Incubation_Period] [ move-to one-of patches with [ pcolor = white ] set inICU 1 ]]
end

to treat
;  if Send_to_ICU = true and inICU = 0 and [ pcolor ] of patch-here = black and color = red
;    [ move-to one-of patches with [ pcolor = white ] set inICU 1 ]
     if inICU = 1 and color = red [ move-to one-of patches with [ pcolor = white]  ]
end

to PossiblyDie
  if InICU = 0 and Severity_of_illness / Illness_Period > random 100 [ set health health - Severity_of_Illness ]
  if InICU = 1 and Severity_of_illness / Illness_Period > random 100 [ set health health - Severity_of_Illness / Treatment_Benefit ]
end

to CountInfected
  set numberinfected ( Population - count simuls ) + (count simuls with [ color != 85 ])
end

to TriggerActionIsolation
  ifelse PolicyTriggerOn = true [
    if triggerday - ticks < 7 and triggerday - ticks > 0 [ set SpatialDistance true set case_Isolation true set send_to_Hospital true
       set Proportion_People_Avoid 100 -  ((100 - PPA) / (triggerday - ticks)) set Proportion_Time_Avoid 100 - ((100 - PTA) / (triggerday - ticks)) ] ;;ramps up the avoidance 1 week out from implementation
    ifelse ticks >= triggerday [ set SpatialDistance true set Case_Isolation true set Send_to_Hospital true ] [ set SpatialDistance False set Case_Isolation False ]
  ] [ set SpatialDistance false set Case_Isolation false set Send_to_Hospital false ]


end

to spend
  ifelse agerange < 18 [ set reserves reserves ] [ set reserves (income * random-normal Days_of_Cash_Reserves (Days_of_Cash_Reserves / 5) ) / 365 ];; average of 3 weeks with tails
end

to Cruiseship
  if mouse-down?  and cruise = true [
    create-simuls random 50 [ setxy mouse-xcor mouse-ycor set size 2 set shape "dot" set color red set agerange one-of [ 0 10 20 30 40 50 60 70 80 90 ]
      set health ( 100 - Agerange ) resethealth set timenow 0 set InICU 0 set fear 0 set sensitivity random-float 1 set R 0
        set income random-exponential 55000 resetincome calculateincomeperday calculateexpenditureperday set IncubationPd Incubation_Period
  ]]
end

to CalculateDailyGrowth
  set YesterdayInfections TodayInfections
  set TodayInfections ( count simuls with [ color = red  and timenow = 1 ] )
  if YesterdayInfections != 0 [set InfectionChange ( TodayInfections / YesterdayInfections ) ]
end

to countcontacts
  if any? other simuls-here with [ color != black ] [
    set contacts ( contacts + count other simuls-here ) ]
end

to karkit
  if color = red and timenow = Illness_Period and RiskofDeath > random-float 1 [ set color black set pace 0 ]
end

to respeed
  set pace speed
end

to checkutilisation
  ifelse any? simuls-here [ set utilisation 1 ] [ set utilisation 0 ]
end

to earn
  if ticks > 1 [
  if agerange < 18 [ set reserves reserves ]
  if agerange >= 70 [ set reserves reserves ]
  ifelse ticks > 0 and AverageFinancialContacts > 0 and color != black and any? other simuls-here with [ reserves > 0 ] and agerange >= 18 and agerange < 70 [ set reserves reserves + ((income  / 365 ) * (1 / AverageFinancialContacts)  ) ]
    [ set reserves reserves - ( expenditure / 365) * ( 1 - AverageFinancialContacts) ] ;;; adjust here
  ]
end

to adjustExpenditure
  if Initialreserves > 0 [ set Adjustment sum [ reserves ] of simuls with [ color != black ]  / Initialreserves ]
end


to financialstress
  if reserves <= 0 and agerange > 18 and agerange < 70 [ set shape "star" ]
  if reserves > 0 [ set shape "dot" ]
end

to DeployStimulus
  if mouse-down? and stimulus = true [ create-packages 1 [ setxy mouse-xcor mouse-ycor set shape "box" set value 0 set color orange set size 5 ] ]
end

to absorbshock
  if any? simuls in-radius 1 with [ shape = "star" ] [ set value value - sum [ reserves ] of simuls in-radius 1 with [ shape = "star" ] ]
end

to AccessPackage
  if any? Packages in-radius 10 and reserves < 0 [ set reserves 100 ]
end

to setInitialReserves
  if ticks = 1  [ set InitialReserves sum [ reserves ] of simuls ]
end

to CalculateAverageContacts
  if ticks > 0 [ set AverageFinancialContacts mean [ contacts ] of simuls with [ agerange >= 18 and reserves > 0 and color != black ] / ticks ]
  if ticks > 0 [ set AverageContacts mean [ contacts ] of simuls with [ color != black and agerange >= 18 and agerange < 70 ] / ticks ]
end

to scaleup
  ifelse scale = true and count simuls with [ color = red ] >= 250 and scalePhase >= 0 and scalePhase < 5 and count simuls * 1000 < Total_Population and days > 0  [
    set scalephase scalephase + 1 ask n-of ( count simuls with [ color = red ] * .9 ) simuls with [ color = red ] [ set size 2 set shape "dot" set color 85 resethealth
    set timenow 0 set IncubationPd Incubation_Period set InICU 0 set fear 0 set sensitivity random-float 1 set R 0
      set income ([ income ] of one-of other simuls ) calculateincomeperday calculateexpenditureperday move-to one-of patches with [ pcolor = black  ] resetlandingSimul set riskofdeath .01 set ageRange ([ageRange ] of one-of simuls) ] ;;
     ask n-of ( count simuls with [ color = yellow ] * .9 ) simuls with [ color = yellow ] [ set size 2 set shape "dot" set color 85 set agerange 95 resethealth
    set timenow 0 set IncubationPd Incubation_Period set InICU 0 set fear 0 set sensitivity random-float 1 set R 0
      set income ([income ] of one-of other simuls) resetincome calculateincomeperday calculateexpenditureperday move-to one-of patches with [ pcolor = black  ] resetlandingSimul set riskofdeath .01  ]
 set contact_Radius Contact_Radius + (90 / 5)
    Set days 0
         ] [scaledown ]

end

to scaledown
;; if scale = true and scalephase > 0 and count simuls with [ color = red ] < 25 and count simuls with [ color = yellow ] > count simuls with [ color = red ] and days > 0 [
 ;;   set scalephase scalephase - 1 set contact_Radius Contact_radius - (90 / 5) ]

end

to forwardTime
  set days days + 1
end
@#$#@#$#@
GRAPHICS-WINDOW
328
124
945
941
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
196
168
260
202
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
163
215
227
249
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
166
340
284
374
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
166
388
284
422
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
142
899
175
SpatialDistance
SpatialDistance
1
1
-1000

SLIDER
156
262
296
295
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
156
298
297
331
Speed
Speed
0
5
1.0
.1
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
"Recovered Proportion" 1.0 0 -1184463 true "" "plot count simuls with [ color = 85 ] * (Total_Population / 100 / count Simuls)"
"Susceptible" 1.0 0 -14070903 true "" "plot count simuls with [ color = yellow ] * (Total_Population / 100 / count Simuls)"
"New Infections" 1.0 0 -11221820 true "" "plot count simuls with [ color = red and timenow = Incubation_Period ] * ( Total_Population / 100 / count Simuls )"

SLIDER
699
428
899
461
Illness_period
Illness_period
0
20
15.0
1
1
NIL
HORIZONTAL

SWITCH
699
178
897
211
Case_Isolation
Case_Isolation
1
1
-1000

BUTTON
231
215
295
249
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
Count simuls with [ color = black ] * (Total_Population / population )
0
1
14

MONITOR
965
126
1040
171
Time Count
ticks
0
1
11

SLIDER
699
392
901
425
InfectionRate
InfectionRate
0
100
50.0
1
1
NIL
HORIZONTAL

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

SLIDER
699
802
903
835
Bed_Capacity
Bed_Capacity
0
20
2.0
1
1
NIL
HORIZONTAL

SWITCH
699
316
899
349
Send_to_Hospital
Send_to_Hospital
1
1
-1000

SLIDER
130
705
319
738
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
2184
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
963
303
1101
360
# simuls
count simuls * (Total_Population / population)
0
1
14

MONITOR
1402
931
1662
976
Bed Capacity Scaled for Australia at 65,000k
count patches with [ pcolor = white ]
0
1
11

MONITOR
335
685
485
742
Total # Infected
count simuls with [ color = red ] * (Total_Population / population)
0
1
14

SLIDER
699
279
898
312
ID_Rate
ID_Rate
0
1
0.1
.01
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
"default" 1.0 1 -2674135 true "" "plot mean [ fear ] of simuls"

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
485
805
Mean Days infected
mean [ timenow ] of simuls with [ color = red ]
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
100.0
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
numberInfected / Population * 100
0
1
14

MONITOR
1153
125
1352
170
Case Fatality Rate %
(Population - Count Simuls) / numberInfected * 100
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
10.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "if count simuls with [ color = black ] > 1 [ plot (Population - Count Simuls) / numberInfected * 100 ]"

SLIDER
699
209
897
242
Proportion_People_Avoid
Proportion_People_Avoid
0
100
85.0
5
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
85.0
5
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
R
mean [ R ] of simuls with [ color = red and timenow = Illness_Period ]
3
1
11

SWITCH
152
668
296
701
PolicyTriggerOn
PolicyTriggerOn
1
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
241
1102
298
Financial Reserves
mean [ reserves ] of simuls
1
1
14

PLOT
1399
393
1919
608
Estimated count of deceased across age ranges
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
1399
613
1919
763
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
Proportion_Isolating
Proportion_Isolating
0
100
0.0
5
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
149
435
305
496
Current_Cases
5000.0
1
0
Number

INPUTBOX
149
499
305
560
Total_Population
2.5E7
1
0
Number

SLIDER
136
569
310
602
Triggerday
Triggerday
0
150
75.0
1
1
NIL
HORIZONTAL

MONITOR
961
438
1116
483
Close contacts per day
AverageContacts
2
1
11

PLOT
955
503
1155
624
Close contacts per day
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
"Contacts" 1.0 0 -16777216 true "" "if ticks > 0 [ plot mean [ contacts ] of simuls with [ color != black  ] / ticks ] "

PLOT
953
685
1142
835
R value
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
"R" 1.0 0 -16777216 true "" "Plot mean [ R ] of simuls with [ color = red and timenow = Illness_Period ]"

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
5.0
1
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
953
839
1368
1098
Total Active Infections
NIL
NIL
0.0
10.0
0.0
200.0
true
false
"" "if Scalephase = 1 [ plot count simuls with [ color = red ] * 10 ] \nif ScalePhase = 2 [ plot count simuls with [ color = red ] * 100 ] \nif ScalePhase = 3 [ plot count simuls with [ color = red ] * 1000 ]\nif ScalePhase = 4 [ plot count simuls with [ color = red ] * 10000 ]  "
PENS
"Current Cases" 1.0 1 -2674135 true "" "plot count simuls with [ color = red ] "

MONITOR
335
626
488
675
New Infections Today
count simuls with [ color = red and timenow = 10 ] * ( Total_Population / count Simuls )
0
1
12

PLOT
323
942
941
1097
New Infections Per Day
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
"Confirmed Cases" 1.0 1 -13345367 true "" "plot count simuls with [ color = red and timenow = 10 ]"

SLIDER
700
578
900
611
Diffusion_Adjustment
Diffusion_Adjustment
0
10
0.0
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
54.0
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
165
745
269
778
Stimulus
Stimulus
1
1
-1000

SWITCH
165
788
269
821
Cruise
Cruise
1
1
-1000

MONITOR
963
370
1082
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
sum [ reserves] of simuls with [ color != black ]  / Initialreserves
2
1
14

BUTTON
163
835
269
870
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
965
179
1121
240
Days_of_Cash_Reserves
60.0
1
0
Number

MONITOR
1402
979
1487
1024
Mean income
mean [ income ] of simuls with [ agerange > 18 and agerange < 70 and color != black ]
0
1
11

MONITOR
1496
981
1596
1026
Mean Expenses
mean [ expenditure ] of simuls with [ agerange >= 18 and agerange < 70 and color != black ]
0
1
11

MONITOR
142
889
281
934
Count red simuls (raw)
count simuls with [ color = red ]
0
1
11

SWITCH
170
943
275
976
Scale
Scale
0
1
-1000

MONITOR
1046
128
1104
173
NIL
Days
17
1
11

MONITOR
1163
680
1361
729
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
154
610
326
659
Days since approximately Jan 20 when first case appeared (Jan 25 reported)
12
15.0
1

TEXTBOX
350
15
2193
91
COVID-19 Policy Options and Impact Model for Australia
52
104.0
1

TEXTBOX
1166
738
1381
831
0 - 2,500 Population\n1 - 25,000 \n2 - 250,000\n3 - 2,500,000\n4 - 25,000,000
12
0.0
1

INPUTBOX
594
218
644
278
PPA
85.0
1
0
Number

INPUTBOX
648
218
698
278
PTA
85.0
1
0
Number

TEXTBOX
335
218
587
275
Manually enter the proportion of people who avoid (PPA) and time avoided (PTA) here when using the policy trigger switch
12
0.0
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
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>count simuls with [ color = red ] = 0</exitCondition>
    <metric>count simuls with [ color = red ]</metric>
    <metric>count simuls with [ color = blue ]</metric>
    <metric>count simuls with [color = black ]</metric>
    <metric>count simuls with [ color = yellow ]</metric>
    <metric>count simuls with [ color = black and agerange = 5 ]</metric>
    <metric>count simuls with [ color = black and agerange = 15 ]</metric>
    <metric>count simuls with [ color = black and agerange = 25 ]</metric>
    <metric>count simuls with [ color = black and agerange = 35 ]</metric>
    <metric>count simuls with [ color = black and agerange = 45 ]</metric>
    <metric>count simuls with [ color = black and agerange = 55 ]</metric>
    <metric>count simuls with [ color = black and agerange = 65 ]</metric>
    <metric>count simuls with [ color = black and agerange = 75 ]</metric>
    <metric>count simuls with [ color = black and agerange = 85 ]</metric>
    <metric>count simuls with [ color = black and agerange = 95 ]</metric>
    <metric>mean [ R ] of simuls with [ timenow = Illness_period ]</metric>
    <metric>mean [ contacts ] of simuls / ticks</metric>
    <metric>mean [ timenow ] of simuls with [ color = red ]</metric>
    <metric>count simuls with [ color = red and timenow = 10 ] * (Total_Population / 1000 / Population )</metric>
    <metric>sum [ reserves ] of simuls with [ color != black ]</metric>
    <enumeratedValueSet variable="Illness_period">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SpatialDistance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Isolating">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Total_Population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Current_Cases">
      <value value="4300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Send_to_Hospital">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ID_Rate">
      <value value="0.1"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PolicyTriggerOn">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="75"/>
      <value value="85"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="0"/>
      <value value="7"/>
      <value value="14"/>
      <value value="28"/>
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_time_Avoid">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfectionRate">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
      <value value="70"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="45"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Focused Policy" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>count simuls with [ color = red ] = 0</exitCondition>
    <metric>count simuls with [ color = red ]</metric>
    <metric>count simuls with [ color = 85 ]</metric>
    <metric>count simuls with [color = black ]</metric>
    <metric>count simuls with [ color = yellow ]</metric>
    <metric>count simuls with [ color = black and agerange = 5 ]</metric>
    <metric>count simuls with [ color = black and agerange = 15 ]</metric>
    <metric>count simuls with [ color = black and agerange = 25 ]</metric>
    <metric>count simuls with [ color = black and agerange = 35 ]</metric>
    <metric>count simuls with [ color = black and agerange = 45 ]</metric>
    <metric>count simuls with [ color = black and agerange = 55 ]</metric>
    <metric>count simuls with [ color = black and agerange = 65 ]</metric>
    <metric>count simuls with [ color = black and agerange = 75 ]</metric>
    <metric>count simuls with [ color = black and agerange = 85 ]</metric>
    <metric>count simuls with [ color = black and agerange = 95 ]</metric>
    <metric>mean [ R ] of simuls with [ timenow = Illness_period ]</metric>
    <metric>mean [ contacts ] of simuls / ticks</metric>
    <metric>mean [ timenow ] of simuls with [ color = red ]</metric>
    <metric>count simuls with [ color = red and timenow = Incubation_Period ]</metric>
    <metric>sum [ reserves ] of simuls with [ color != black ]</metric>
    <enumeratedValueSet variable="Illness_period">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SpatialDistance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Isolating">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Total_Population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Current_Cases">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Send_to_Hospital">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ID_Rate">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PolicyTriggerOn">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_time_Avoid">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfectionRate">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="45"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Containment Policy Scale" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>count simuls with [ color = red ] = 0</exitCondition>
    <metric>count simuls with [ color = red ]</metric>
    <metric>count simuls with [ color = 85 ]</metric>
    <metric>count simuls with [color = black ]</metric>
    <metric>count simuls with [ color = yellow ]</metric>
    <metric>count simuls with [ color = black and agerange = 5 ]</metric>
    <metric>count simuls with [ color = black and agerange = 15 ]</metric>
    <metric>count simuls with [ color = black and agerange = 25 ]</metric>
    <metric>count simuls with [ color = black and agerange = 35 ]</metric>
    <metric>count simuls with [ color = black and agerange = 45 ]</metric>
    <metric>count simuls with [ color = black and agerange = 55 ]</metric>
    <metric>count simuls with [ color = black and agerange = 65 ]</metric>
    <metric>count simuls with [ color = black and agerange = 75 ]</metric>
    <metric>count simuls with [ color = black and agerange = 85 ]</metric>
    <metric>count simuls with [ color = black and agerange = 95 ]</metric>
    <metric>mean [ R ] of simuls with [ timenow = Illness_period ]</metric>
    <metric>mean [ contacts ] of simuls / ticks</metric>
    <metric>mean [ timenow ] of simuls with [ color = red ]</metric>
    <metric>count simuls with [ color = red and timenow = Incubation_Period ]</metric>
    <metric>sum [ reserves ] of simuls with [ color != black ]</metric>
    <metric>scalePhase</metric>
    <enumeratedValueSet variable="Illness_period">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SpatialDistance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_Isolating">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Total_Population">
      <value value="25000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Available_Resources">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Current_Cases">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media_Exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bed_Capacity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReInfectionRate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RestrictedMovement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Superspreaders">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Severity_of_illness">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Send_to_Hospital">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProductionRate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incubation_Period">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Case_Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ID_Rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PolicyTriggerOn">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_People_Avoid">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Treatment_Benefit">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FearTrigger">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Triggerday">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Proportion_time_Avoid">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfectionRate">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Age_Isolation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Contact_Radius">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scale">
      <value value="true"/>
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
