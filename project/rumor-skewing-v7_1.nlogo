globals [og-rumor]

turtles-own [
  has-heard?     ; Boolean
  popularity     ; Float
  familiarities  ; List[List[Turtle, Float]] - a list holding the relationships with all other turtles in the form of a list containing the agent and its respective familiarity
  rumor          ; Integer
]

to seed-rumor [original-rumor]
  ask turtle 0 [  ; Asking the first turtle to hear the rumor
    hear-rumor original-rumor
  ]
end

to hear-rumor [original-rumor]  ; update the associated variable and colour to represent knowing the rumor
  set has-heard? true
  set rumor skew-rumor original-rumor
  set color red
end

to setup
  clear-all

  crt 100 [
    setxy random-xcor random-ycor  ; Go to random position
    set shape "person"
    set has-heard? false           ; Initialise turtles such that none have heard the rumor
    set color green                ; Green colour to represent turtles not having heard rumor
    set popularity get-popularity  ; Initialise turtles' popularity between 0.0 and 1.0
    set familiarities []           ; Initialise to empty list. Will later be populated by tuples containing another turtle and its familiarity to the original turtle
  ]

  set og-rumor generate-rumor
  seed-rumor og-rumor              ; Tell the rumor to a single turtle

  setup-familiarities

  reset-ticks
end

to-report generate-rumor
  report random 100
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

to go
  if all? turtles [has-heard?] [stop]             ; Stop when all turtles have heard the rumor
  move
  ask turtles [ update-familiarities ]            ; Increase the familiarity of turtles on the same patch
  ask turtles with [has-heard?] [ spread-rumor ]  ; Turtles who have heard the rumor try to spread it
  tick
end

to move
  ; Random Movement
  ask turtles [
    rt random 360  ; turn right by a random angle
    fd 1           ; move forward 1 step
  ]
end

to spread-rumor
  ifelse count turtles-here > 1 [
    ask other turtles-here [
      ifelse valid-spread? myself self [
        hear-rumor [rumor] of myself
      ] [
        if not has-heard? [ ; In the case where a turtle is told the rumor but doesn't believe it, it turns yellow
          set color yellow
        ]
      ]
    ]
  ]
  [
    ; This is currently for performance reasons but we can handle this case if needed
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
        set tuple replace-item 1 tuple min list 1 (item 1 tuple * (1 + familiarity-inc))
      ]
      set new-familiarities lput tuple new-familiarities
    ]
    set familiarities new-familiarities
  ]

end

to-report valid-spread? [original-turtle other-turtle]
  let familiarity-tuple filter [x -> first x = original-turtle] [familiarities] of other-turtle
  set familiarity-tuple item 0 familiarity-tuple
  let familiarity item 1 familiarity-tuple

  report random-float 1 <= calculate-probability [popularity] of original-turtle familiarity
end

to-report calculate-probability [pop fam]
  ; Calculate the weighted sum of factors
  let weighted-pop pop * pop-weight
  let weighted-fam fam * fam-weight
  let total weighted-pop + weighted-fam

  ; Calculate the probability using the logistic function
  let probability spread-chance + total / 2

  ; Report the probability
  report probability
end

;;;;;;;;;;;;; New for v7 ;;;;;;;;;;;;;;;

to-report skew-rumor [original-rumor]
  let abs-chaos random-float rumor-chaos
  let direction 0
  ifelse random-float 1 < skew-effectiveness [set direction random-float rumor-skew] [set direction random-float -1 * rumor-skew]
  let directed-chaos abs-chaos * direction
  let new-rumor original-rumor + directed-chaos
  report new-rumor
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;      STATISTICS      ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report n-heard
  report count turtles with [has-heard?]
end

to-report f
  let f-list []
  ask turtles [
    foreach familiarities [
     tuple -> set f-list lput item 1 tuple f-list
    ]
  ]
  report f-list
end

to-report rumors
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
27
58
90
91
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
NIL
NIL
NIL
1

SLIDER
26
95
198
128
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
132
198
165
pop-weight
pop-weight
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
25
207
197
240
familiarity-inc
familiarity-inc
0
1
0.5
0.01
1
NIL
HORIZONTAL

PLOT
661
170
861
324
% turtles heard
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
Mean Familiarity
NIL
NIL
0.0
0.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean f"

SLIDER
26
244
198
277
fam-weight
fam-weight
0
1
0.5
0.01
1
NIL
HORIZONTAL

MONITOR
870
385
1063
430
NIL
mean f
17
1
11

MONITOR
870
335
1063
380
NIL
median f
17
1
11

SLIDER
26
293
198
326
rumor-chaos
rumor-chaos
0
10
1.1
0.1
1
NIL
HORIZONTAL

MONITOR
867
12
934
57
NIL
og-rumor
17
1
11

PLOT
661
11
861
161
Average Rumor
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
"default" 1.0 0 -16777216 true "" "plot mean rumors"

SLIDER
26
330
198
363
rumor-skew
rumor-skew
-1
1
-0.59
0.01
1
NIL
HORIZONTAL

SLIDER
26
367
198
400
skew-effectiveness
skew-effectiveness
0
1
0.7
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT DO THE SLIDERS DO?
#### Spread Chance
Affects the probability that a given agent will spread the rumor.

#### Popularity Bias:
Changes how much popularity boosts the probability of spreading.

Values between 0 and 1 simply affect the importance of popularity.

Values above 1 boost the popularity itself, with very large values leading to 100% spread for any popularity.

## What's new in v6?
1. Refactored the `has-heard` variable such that it is in line with NetLogo's style guide by adding a ?: `has-heard?`.
2. Added the familiarity stuff.
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
