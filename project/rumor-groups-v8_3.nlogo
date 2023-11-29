extensions [palette] ; Needed for coloring the turtles in gradients

; group-centres:  List[Patch] - list holding the patches which each respective group will base their movement on
; color-settings: String      - can be "groups", "rumors", or "belief". This represents how the agents are being colored
globals [group-centres color-setting]



turtles-own [
  group-id          ; Integer                   - connects each turtle to their group-centre patch in the `group-centres` list
  has-heard?        ; Boolean                   - checks whether the turtle has heard the rumor
  popularity        ; Float                     - in the range [0, 1]. Represents the popularity of this turtle amongst the entire `turtles` agentset
  familiarities     ; List[List[Turtle, Float]] - a list holding the relationships with all other turtles in the form of a list containing the agent and its respective familiarity
  rumor             ; Color / Number            - green or red (55 or 15). Green represents the true rumor, red represents the false rumor
  belief-confidence ; Float                     - represents how confident the turtle is that the rumor it believes is true
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;         SETUP        ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all

  ; GROUP STUFF
  set n-groups max list 1 min list 14 n-groups  ; clamping group size between 1 and 14 (14 being the size of the color list for the groups)
  create-groups
  assign-groups
  recolor
  set group-centres distributed-centres n-groups
  foreach group-centres [
    centre -> ask centre [set pcolor item (position centre group-centres) base-colors]
  ]
  setup-positions
  setup-familiarities

  ; RUMOR CREATION
  seed-rumors  ; Tell the rumor to a single turtle

  reset-ticks
end

to-report get-popularity
  let pop random-normal 0.5 0.2 ; Random distribution with mean 0.5 and standard deviation of 0.2
  set pop max list 0 pop
  set pop min list 1 pop
  report pop
end

to setup-familiarities
  ; This function wil calculate the familiarities of each turtle with the turtles next to it
  ; The calculation is performed as follows for each turtle:
  ; 1. Find the turtles within a parameter `search-distance`
  ; 2. Find the precise distance between each turtle and the original turtle
  ; 3. Normalise the distance with respect to the search distance (such that they are all between 0 and 1)
  ; 4. Invert the value (subtract them from 1) such that the familiarity increases as the turtles are closer
  ; 5. Add the familiarities to the list
  ask turtles [
    let my-familiarities []
    ask other turtles [
      let distance-to-other distance myself
      let normalised-distance distance-to-other / world-width
      let familiarity 1 - normalised-distance
      set my-familiarities lput (list self familiarity) my-familiarities
    ]
    set familiarities my-familiarities
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;        RUMORS        ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to seed-rumors
  ; The turtles chosen are effectively random as the groups will be randomly selected
  ask turtle 0 [  ; Asking the first turtle to hear the false rumor.
    hear-rumor red
  ]
  ask turtle 1 [ ; Asking the second turtle to hear the false rumor
   hear-rumor green
  ]
end

to hear-rumor [_rumor]  ; update the associated variable and color to represent the rumor
  set has-heard? true
  set rumor _rumor
end

to spread-rumor
  ; 1. Implicitly checking for other turtles on the same patch
  ; 2. Ask those turtles to find the convincing factor between the original turtle and itself
  ; 3. If the case that the original turtle makes for its belief is better than my current belief, change my mind to whichever rumor the original turtle has
  ask other turtles-here [
    let convincing-factor get-cf myself self
    if convincing-factor > belief-confidence [
      hear-rumor [rumor] of myself
      set belief-confidence min list 1.0 convincing-factor  ;  belief-confidence capped at 100%
    ]
  ]
end

to-report get-cf [original-turtle other-turtle] ; get-cf short for get-convincing-factor
  ; Find the other turtle's familiarity with the original turtle
  let familiarity-tuple filter [x -> first x = original-turtle] [familiarities] of other-turtle
  set familiarity-tuple item 0 familiarity-tuple
  let familiarity item 1 familiarity-tuple

  report calculate-probability [popularity] of original-turtle familiarity
end

to-report calculate-probability [pop fam]
  ; Calculate the weighted sum of the factors
  let weighted-pop pop * pop-weight
  let weighted-fam fam * fam-weight
  let total weighted-pop + weighted-fam

  let probability spread-chance + total / 2  ; adding the averaged probability from the factors to the base spread-chance

  ; Report the probability
  report probability
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;        GROUPS        ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to create-groups
  crt n-turtles [
    set shape "person"
    set has-heard? false           ; initialise turtles such that none have heard any rumor
    set belief-confidence 0
    set popularity get-popularity  ; initialise turtles' popularity between 0.0 and 1.0
    set familiarities []           ; initialise to empty list. Will later be populated by tuples containing another turtle and its familiarity to the original turtle
  ]
end

to-report distributed-centres [n-centres]  ; returns a list of patches acting as the group centres. Evenly distributed along the circumference of a circle
  let radius 14              ; semi-arbitrary number, works best from testing
  let theta 360 / n-centres  ; finding the angle between each group centre

  let centres []
  let index 0

  ; in case there is only one group, place them in the middle
  if n-centres = 1 [
    let centre patch 0 0
    set centres lput centre centres
    report centres
  ]

  while [index < n-centres] [   ; for each group centre
   let ang index * theta + 90   ; shifting by 90deg makes it look better
   ; x = rcos(theta), y = rsin(theta)
   let x radius * cos ang
   let y radius * sin ang

   ; adding the patch to the centres list
   let centre patch x y
   set centres lput centre centres

   set index index + 1
  ]

  report centres
end

to assign-groups
  let max-group-size floor (n-turtles / n-groups)  ; mostly equal number of turtles assigned to each group
  show max-group-size

  let current-group-id 0
  let current-group-size 0

  ask turtles [
    if current-group-size >= max-group-size [  ; once the group has been filled
      if current-group-id < n-groups - 1 [     ; important condition. If the group has filled up BUT there are no more groups left, continue to assign turtles to this last group
        set current-group-id current-group-id + 1
        set current-group-size 0
      ]
    ]
    set group-id current-group-id
    set current-group-size current-group-size + 1
  ]
end

to setup-positions  ; randomly placing turtles within their group's radius
  ask turtles [
    let respective-centre item group-id group-centres
    let r 12  ; another number which just works
    let x [pxcor] of respective-centre + (random-float r - r / 2)
    let y [pycor] of respective-centre + (random-float r - r / 2)

    set x max list min-pxcor (min list x max-pxcor)
    set y max list min-pycor (min list y max-pycor)

    setxy x y
  ]
end

to recolor
  ; in case the user has not chosen a color setting, default to groups
  if not is-string? color-setting [
   set color-setting "groups"
  ]

  if color-setting = "groups" [ ask turtles [set color item (group-id) base-colors] ]

  if color-setting = "belief" [
    ask turtles [
      ifelse rumor != 0 [
        let grad-index belief-confidence * belief-confidence * 100        ; squaring the belief confidence to make the color difference more visible
        if rumor = red [set grad-index -1 * grad-index]
        set color palette:scale-gradient [red green] grad-index -100 100  ; setting the color to a gradient between green and red based on the belief confidence (grad-index)
      ] [
        set color grey
      ]
    ]
  ]

  if color-setting = "rumors" [
    ask turtles [ifelse rumor != 0 [set color rumor] [set color grey] ]
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;       SIM LOOP       ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  recolor
  if all? turtles [rumor = green] [stop]
  if all? turtles [rumor = red] [stop]            ; Stop when all turtles have heard the rumor
  if ticks >= 1000 [stop]                         ; Stop after things stagnate
  move
  ask turtles [ update-familiarities ]            ; Increase the familiarity of turtles on the same patch
  ask turtles with [has-heard?] [ spread-rumor ]  ; Turtles who have heard the rumor try to spread it
  tick
end

to move
  ; Random Movement
  ask turtles [
      let respective-centre item group-id group-centres
      let dist-to-centre distance respective-centre
      rt random 360

      ; if we are out of our group, maybe go back towards it
      if random-float 1.0 <= group-tightness * group-tightness [  ; squaring group-tightness to give the slider more control
        face respective-centre
      ]
      fd 1
  ]
end

to update-familiarities
  ; 1. Check that there is a collision. If there isn't, no point in performing all the below calculations
  ; 2. Go thorugh each of the agents in the turtle's familiarities.
  ; 3-1. If the agent is not on the same patch, then add its current familiarity to the new familiarities list
  ; 3-2. If it is on the same patch, update the familiarity by adding the global familiarity increase var to its current familiarity. Add that value to the new list
  if count other turtles-here > 0 [
    let new-familiarities []

    foreach familiarities [ tuple ->
      let familiar-agent item 0 tuple
      if member? familiar-agent other turtles-here [
        set tuple replace-item 1 tuple min list 1 (item 1 tuple * (1 + random-float familiarity-inc))
      ]
      set new-familiarities lput tuple new-familiarities
    ]
    set familiarities new-familiarities
  ]

end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;      STATISTICS      ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report n-heard
  report count turtles with [has-heard?]
end

to-report f  ; list of familiarities
  let f-list []
  ask turtles [
    foreach familiarities [
     tuple -> set f-list lput item 1 tuple f-list
    ]
  ]
  report f-list
end

to-report rumors  ; list of rumor values (green or red in number form)
  let rumor-list []
  ask turtles [
    if has-heard? [set rumor-list lput rumor rumor-list]
  ]

  report rumor-list
end








@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
26
58
89
91
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
135
57
198
90
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
26
226
198
259
spread-chance
spread-chance
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
26
263
198
296
pop-weight
pop-weight
0
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
25
337
197
370
familiarity-inc
familiarity-inc
0
1
1.0
0.01
1
NIL
HORIZONTAL

PLOT
661
170
861
324
Turtles with a Rumor (%)
NIL
NIL
0.0
20.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (n-heard / count turtles) * 100"

PLOT
662
334
862
484
Familiarity
NIL
NIL
0.0
0.0
0.0
1.0
true
true
"" ""
PENS
"Mean" 1.0 0 -955883 true "" "plot mean f"
"Median" 1.0 0 -11221820 true "" "plot median f"

SLIDER
25
300
197
333
fam-weight
fam-weight
0
1
1.0
0.01
1
NIL
HORIZONTAL

PLOT
661
11
861
161
Average Rumor
NIL
NIL
0.0
0.0
50.0
50.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean rumors"

INPUTBOX
26
431
199
491
n-groups
9.0
1
0
Number

PLOT
865
10
1479
485
Number of Believing Turtles
NIL
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"False Rumor" 1.0 0 -2674135 true "" "plot count turtles with [rumor = red]"
"True Rumor" 1.0 0 -14439633 true "" "plot count turtles with [rumor = green]"

BUTTON
211
452
336
514
Group View
set color-setting \"groups\"\nrecolor
NIL
1
T
OBSERVER
NIL
1
NIL
NIL
1

BUTTON
365
451
491
516
Rumor View
set color-setting \"rumors\"\nrecolor
NIL
1
T
OBSERVER
NIL
2
NIL
NIL
1

BUTTON
521
451
647
516
Belief VIew
set color-setting \"belief\"\nrecolor
NIL
1
T
OBSERVER
NIL
3
NIL
NIL
1

SLIDER
25
537
201
570
group-tightness
group-tightness
0
1
0.35
0.01
1
NIL
HORIZONTAL

SLIDER
25
139
197
172
n-turtles
n-turtles
3
250
108.0
1
1
turtles
HORIZONTAL

TEXTBOX
76
118
155
136
TURTLES
14
0.0
1

TEXTBOX
57
208
207
226
RUMOR SPREAD
14
0.0
1

TEXTBOX
79
412
229
430
GROUPS
14
0.0
1

@#$#@#$#@
## WHAT IS IT?
This model explores the effect of popularity and familiarity on the belief of rumors amongst groups.

Two randomly selected turtles are told conflicting rumors which will spread until one wins or too much time passes.

Turtles will believe whichever rumor they are told first, and then will adopt different rumors (or the same rumor) if another turtle can convince it.


## HOW TO USE IT
1. Adjust the sliders and set the number of groups.
2. Click `setup`.
3. Click `go` to begin the simulation.
4. Click on any of the view buttons (hotkeys 1-3) to view different information about the turtles.
5. Watch the graphs on the right.


### PARAMETERS

#### TURTLES
- `n-turtles`: The number of turtles in the simulation.

#### RUMOR SPREAD
- `spread-chance`: The base rate for the probability of a rumor spreading.
- `pop-weight`: The importance of the turtle's popularity variable when calculating rumor spread chance.
- `fam-weight`: The importance of the turtle's familiarity variable when calculating rumor spread chance.
- `familiarity-inc`: The value added to the turtle's familiarity with the original turtle in the case the spread fails.

#### GROUPS
- `n-groups`: The number of groups. Minimum of **1**, maximum of **14**.
- `group-tightness`: Determines the radius of influence, where a value of 0 means turtles are unrestricted, and 100 means they remain exactly within radius.

#### VIEWS
1. Group View: Separates turtles by group, the color of the turtle matches its respective group centre patch.
2. Rumor View: Shows which turtles believe which rumor, where green turtles believe the true rumor, and red ones believe the false one.
3. Belief View: Similar to the Rumor View, but turtle colors are mapped to a gradient such that their confidence in their belief polarises the colors to a vibrant green or red, with murky colors in between.


## THINGS TO NOTICE
Although the stop criteria is for all turtles to believe a single rumor, this rarely happens.

Additionally, effects like the ingroup-outgroup bias are visible in certain contexts.

## THINGS TO TRY
1. Set the `group-tightness` to the maximum and let the groups with rumors spread completely. Switch to Rumor View, then gradually decrease the `group-tightness` until the groups occasionally make contact. Finally, increase the `group-tightness` a last time to see the effects on the groups.
2. Learn how different values in the Rumor Spread sliders alter the spread. Once an equilibrium is found, change the sliders to see what happens.

## EXTENDING THE MODEL
1. Sliders which create an imbalance between the conflicting rumors.
2. More parameters affecting belief
3. Creating a two-stage spread-belief system where spread factors only affect spread, and belief factors affect belief, meaning a bad rumor may not be accepted.
4. A variable number of rumors
5. Different systems for group centre locations (random, mouse presses, true equal distribution).

## RELATED MODELS
This model used the **Rumor Mill** model under the *Social Sciences* section in the models library as a starting point.
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

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="test1" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [rumor = green]</metric>
    <enumeratedValueSet variable="n-turtles">
      <value value="108"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pop-weight">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-groups">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="familiarity-inc">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="group-tightness">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fam-weight">
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
