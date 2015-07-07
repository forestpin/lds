TDS = require './tds'

Point = TDS.Struct "Point",
 {key: "x", type: TDS.Types.Int32}
 {key: "y", type: TDS.Types.Int32}

Line = TDS.Struct "Line",
 {key: "a", type: TDS.Types.Float32}
 {key: "b", type: TDS.Types.Float32}
 {key: "c", type: TDS.Types.Float32}

p = new Point x: 1, y: 3
l = new Line a: 10, b: 20, c: 30.5

console.log p.get()
console.log l.get()
console.log p.get()

p2 = new Point
p2.copyFrom p

console.log p.getX()
console.log p.getY()
p.setX 12
p.setY 13
console.log p.get()
console.log p2.get()


console.log 'Test Arrays'

n = 10000000
points = new TDS.Array Point, n

console.time 'arr'

p = points.get 0
p.copyFrom p2
pl = points.get 0


for i in [1...n]
 p.next()

 p.setX pl.getX() + i
 p.setY pl.getY() + 2

 #p.copyFrom pl
 #p.setX p.getX() + i

 pl.next()

###
p = points.get 0
for i in [0...n]
 console.log p.get()
 p.next()
###

console.log (points.get 1).get()
console.log p.get()

console.timeEnd 'arr'


console.time 'arr2'
points.setObject 0, x: 1, y: 3
for i in [1...n]
 points.setX i, (points.getX i-1) + i
 points.setY i, (points.getY i-1) + 2

#console.log (points.getX n-1), points.getY n-1
console.log points.getObject 1
console.log points.getObject n-1

console.timeEnd 'arr2'

console.time 'ArrayBuffer'

buffer1 = new ArrayBuffer n * 4
buffer2 = new ArrayBuffer n * 4
x = new Int32Array buffer1
y = new Int32Array buffer2

x[0] = 1
y[0] = 3
for i in [1...n]
 x[i] = x[i-1] + i
 y[i] = y[i-1] + 2

console.log x[1], y[1]
console.log x[n-1], y[n-1]
console.timeEnd 'ArrayBuffer'

console.time 'js'
x = new Array n
y = new Array n

x[0] = 1
y[0] = 3

for i in [1...n]
 x[i] = x[i-1] + i
 y[i] = y[i-1] + 2

console.log x[1], y[1]
console.log x[n-1], y[n-1]

console.timeEnd 'js'