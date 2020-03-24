globals [

  FearFactor
  NumberInfected
  ]

breed [ simuls simul ]
breed [ resources resource ]
breed [ medresources medresource ] ;; people living in the city

simuls-own [
  timenow
  health
  pace
  inICU
  fear
  sensitivity
  R
  income
  expenditure
  reserves
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
  ask patches [ set pcolor black ]
  ask n-of 1 patches [ sprout-medresources 1 ]
  ask medresources [ set color white set shape "Health care" set size 10 set capacity Bed_Capacity moveaway set xcor 20 set ycor -40 ]
  ask medresources [ ask patches in-radius Capacity [ set pcolor white ] ]
  ask n-of Toilet_Rolls patches [ sprout-resources 1 ]
  ask resources [ set color white set shape "Bog Roll2" set size 5 set volume one-of [ 2.5 5 7.5 10 ]  moveaway resize set xcor -20 set ycor one-of [ -30 -10 10 30 ] resetlanding ]
  ask n-of Population patches with [ pcolor = black ]
    [ sprout-simuls 1
      [ set size 3 set shape "dot" set color 85 set health (random 100) set timenow 0 set pace Speed set InICU 0 set fear 0 set sensitivity random-float 1 fd random-float 1 set R 0
        set income random-normal 50000 30000 resetincome calculateincomeperday calculateexpenditureperday]
    ]
  ask n-of Initial simuls [ set xcor 0 set ycor 0 set color red ]
  reset-ticks

end

to resetlanding
  if any? other resources-here [ set ycor one-of [ -30 -10 10 30 ] resetlanding ]
end

to resetincome
  if income < 10000 [
    set income random-normal 50000 30000 ]
end

to calculateIncomeperday
  set income income / 365
end

to calculateexpenditureperday
  set expenditure income * .99
end

to go
  ask simuls [ move avoid set shape "dot" recover settime karkit move avoid isolation reinfect createfear gatherreseources treat Spend reSpeed ] ;
  ask medresources [ allocatebed ]
  ask resources [ deplete replenish resize spin ]
  finished
  GlobalTreat
  GlobalFear
  SuperSpread
  CountInfected
  TriggerActionIsolation

 ;; TriggerActionDistance
 ;; TriggerActionICU
  tick
end

to move
  if color != red [ set heading heading + random 5 - random 5 fd pace avoidICUs ]
  if any? other simuls-here with [ color = red ] and color = 85 and infectionRate > random 100 [ set color red set timenow 0  ]
  if any? other simuls-here with [ color = 85 ] and color = red and infectionRate > random 100 [ set R R + 1 ]
  if color = red and Isolate = false [ set heading heading + random 90 - random 90 fd (pace * ( health / 100 )) ]
  if color = red and Send_to_ICU = false [ avoidICUs ]
end

to isolation
  if Isolate = true and color = red [
    set pace RestrictedMovement fd pace ]
end

to avoid
  if SpatialDistance = true and Proportion_People_Avoid > random 100 and Proportion_time_Avoid > random 100 [
    ifelse any? other simuls-on patch-at-heading-and-distance heading forwarddistance [ set pace 0 fd pace set heading heading + random 180 - random 180  ]
  [ set pace (speed / 2) fd pace ] ]
end

to finished
  if count simuls = (count simuls with [ color = red ]) [ stop ]
  if count simuls = (count simuls with [ color = 85 ]) [ stop ]
end

to settime
  if color = red [ set timenow timenow + 1 PossiblyDie ]
end

to karkit
  if health < 0 [ set color black die ]
end

to recover
  if timenow > random-normal Infectious_Period ( Infectious_Period / 5) [
    set color yellow set timenow 0 set health random 100 set inICU 0  ]
end

to reinfect
  if color = yellow and ReinfectionRate > random 100 [ set color 85 ]
end

to allocatebed
  ask patches in-radius Bed_Capacity [ set pcolor white ]
end

to avoidICUs
  if [ pcolor ] of patch-here = white and InICU = 0 [ move-to min-one-of patches with [ pcolor = black ]  [ distance myself ] set heading heading - random 90 + random 90 ]
end

to moveaway
  if any? other turtles-here [ move-to one-of patches ]
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
  if (fear * sensitivity) > random 100 and count resources > 0 and InICU = 0  [ face min-one-of resources with [ volume >= 0 ] [ distance myself ]  fd pace ]
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
  if (count simuls with [ InICU = 1 ]) < (count patches with [ pcolor = white ]) and Send_to_ICU = true and any? simuls with [ color = red and inICU = 0 ]
    [ ask n-of ( count simuls with [ color = red and inICU = 0 ] * ID_Rate ) simuls with [ color = red and inICU = 0 ] [ move-to one-of patches with [ pcolor = white ] set inICU 1 ]]

end

to treat
;  if Send_to_ICU = true and inICU = 0 and [ pcolor ] of patch-here = black and color = red
;    [ move-to one-of patches with [ pcolor = white ] set inICU 1 ]
     if inICU = 1 [ move-to one-of patches with [ pcolor = white]  ]
end

to superSpread
  if count simuls with [ color = red ] > 0 and isolate = false [  if Superspreaders > random 100 [ ask one-of simuls with [ color = red ] [move-to one-of patches with [ pcolor = black ]]]]
end

to PossiblyDie
  if InICU = 0 and Seriousness_of_infection / Infectious_Period > random 100 [ set health health - Seriousness_of_Infection ]
  if InICU = 1 and Seriousness_of_infection / Infectious_Period > random 100 [ set health health - Seriousness_of_Infection / Treatment_Benefit ]
end

to CountInfected
  set numberinfected ( Population - count simuls ) + (count simuls with [ color != 85 ])
end

to TriggerActionIsolation
  if PolicyTriggerOn = true [

  ifelse mean [ fear ] of simuls > FearTrigger  [ set SpatialDistance true ] [ set SpatialDistance False ]
  ifelse mean [ fear ] of simuls > FearTrigger / 2 [ set isolate true ] [ set Isolate False ]
  ]
end

to spend
  set expenditure expenditure + (expenditure * (.025 / 365 ) )
  set reserves (income + income - expenditure )
end

to reSpeed
  set pace speed
end
@#$#@#$#@
GRAPHICS-WINDOW
501
49
1046
794
-1
-1
4.613
1
10
1
1
1
0
1
1
1
-40
40
-55
55
0
0
1
ticks
30.0

BUTTON
346
48
410
82
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
315
95
379
129
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
132
139
250
173
Trace_Patterns
ask one-of turtles with [ color = red ] [ pen-down ] 
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
132
185
250
219
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
840
62
1035
95
SpatialDistance
SpatialDistance
0
1
-1000

SLIDER
2232
413
2372
446
ForwardDistance
ForwardDistance
0
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
2232
451
2374
484
BackwardDistance
BackwardDistance
0
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
123
62
263
95
Population
Population
0
20000
2000.0
1000
1
NIL
HORIZONTAL

SLIDER
123
96
264
129
Speed
Speed
0
1
0.44
.01
1
NIL
HORIZONTAL

PLOT
1906
819
2188
978
Susceptible, Infected and Recovered as a % of Population
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"Infected Proportion" 1.0 0 -2674135 true "" "plot count simuls with [ color = red ] / count simuls * 100"
"Recovered Proportion" 1.0 0 -14070903 true "" "plot count simuls with [ color = 85 ] / count simuls * 100"
"Susceptible" 1.0 0 -1184463 true "" "plot count simuls with [ color = yellow ] / count simuls * 100"

SLIDER
125
233
274
266
Infectious_period
Infectious_period
0
100
15.0
5
1
NIL
HORIZONTAL

SWITCH
839
98
1037
131
Isolate
Isolate
1
1
-1000

PLOT
1931
472
2131
592
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

BUTTON
380
95
444
129
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
121
628
319
661
RestrictedMovement
RestrictedMovement
0
1
0.1
.01
1
NIL
HORIZONTAL

MONITOR
506
739
563
784
Deaths
Population - Count Simuls
0
1
11

MONITOR
1909
992
1984
1037
Time Count
ticks
0
1
11

SLIDER
121
662
319
695
InfectionRate
InfectionRate
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
123
269
273
302
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
119
348
308
381
Bed_Capacity
Bed_Capacity
0
100
15.0
1
1
NIL
HORIZONTAL

SWITCH
842
272
1037
305
Send_to_ICU
Send_to_ICU
1
1
-1000

SLIDER
122
442
311
475
Toilet_Rolls
Toilet_Rolls
0
4
0.0
1
1
NIL
HORIZONTAL

PLOT
1906
649
2186
808
Toilet Paper Reserves
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
"default" 1.0 1 -5298144 true "" "plot mean [ volume ] of resources"

SLIDER
119
478
315
511
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
2009
593
2068
638
# simuls
count simuls
0
1
11

MONITOR
2480
420
2698
465
NIL
count patches with [ pcolor = white ]
17
1
11

MONITOR
505
590
607
635
Total # Infected
count simuls with [ color = red ]
0
1
11

PLOT
705
533
1041
788
# of infections
NIL
NIL
0.0
10.0
0.0
200.0
true
false
"" ""
PENS
"default" 1.0 1 -2674135 true "" "plot count simuls with [ color = red ] "

SLIDER
840
200
1036
233
ID_Rate
ID_Rate
0
1
0.05
.01
1
NIL
HORIZONTAL

PLOT
1931
318
2131
468
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
122
308
272
341
Media_Exposure
Media_Exposure
1
100
53.0
1
1
NIL
HORIZONTAL

TEXTBOX
2235
129
2424
344
Media and knowledge link\n\nIf people are very ill, they won't move.\n\nToilet roll panic should also act independently of the virus panic\n\nI might have to isolate, so I need resources to get me through.\n\nOther people will probably try to get those resources because they will want to isolate, too, so I will panic-buy\n
11
0.0
1

MONITOR
506
639
630
684
Mean Days infected
mean [ timenow ] of simuls with [ color = red ]
2
1
11

SLIDER
840
236
1036
269
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
122
775
322
808
Seriousness_of_Infection
Seriousness_of_Infection
0
100
15.0
1
1
NIL
HORIZONTAL

MONITOR
506
689
624
734
% Total Infections
numberInfected / Population * 100
0
1
11

MONITOR
1925
99
2124
144
Case Fatality Rate %
(Population - Count Simuls) / numberInfected * 100
2
1
11

PLOT
1929
162
2129
312
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
"default" 1.0 0 -5298144 true "" "plot (Population - Count Simuls) / numberInfected * 100"

SLIDER
839
129
1037
162
Proportion_People_Avoid
Proportion_People_Avoid
0
100
50.0
10
1
NIL
HORIZONTAL

SLIDER
839
165
1038
198
Proportion_time_Avoid
Proportion_time_Avoid
0
100
50.0
10
1
NIL
HORIZONTAL

SLIDER
115
393
310
426
Treatment_Benefit
Treatment_Benefit
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
152
559
326
592
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
1926
593
1985
638
R
mean [ R ] of simuls with [ color != 85 ]
2
1
11

SWITCH
2236
493
2380
526
PolicyTriggerOn
PolicyTriggerOn
1
1
-1000

SLIDER
124
724
326
757
Initial
Initial
0
100
20.0
1
1
NIL
HORIZONTAL

MONITOR
1092
300
1217
346
Financial Researves
mean [ reserves ] of simuls
1
1
11

PLOT
1125
425
1497
621
Financial Reserves
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
"default" 1.0 1 -16777216 true "" "histogram [ income ] of simuls"

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
