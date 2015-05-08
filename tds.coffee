nTypes = 6
Types =
 Uint8: 0
 Int32: 1
 Int16: 2
 Float32: 3
 Float64: 4
 String: 5

TypeArrays = [
 [Uint8Array, 1]
 [Int32Array, 1]
 [Int16Array, 1]
 [Float32Array, 1]
 [Float64Array, 1]
 [Int32Array, 2]
]



TypeLenghts = [
 1
 4
 2
 4
 8
 8
]

names = {}
namesCnt = 1
STRING_ID = 0

INT_SIZE = 16
MAX_SIZE = 1<<26
MAX_BYTES = 1<<29


Strings =
 INVALID_STRING_REF: "Invalid String reference"
 NO_PROPERTIES: (name) ->
  "No properties in the struct #{name}"
 INVALID_STRING: "Invalid String"


StringAlloc = ->
 chars = []
 charLens = []
 lastChar = null
 i_lChar = i_lCharPos = 0
 lastCharLen = 0

 views = []
 viewLens = []
 lastView = null
 i_lView = i_lViewPos = 0
 lastViewLen = 0

 view = viewPos = 0

 size = INT_SIZE
 buffer = new ArrayBuffer size << 1
 chars.push new Int16Array buffer
 charLens.push size
 lastChar = chars[0]
 lastCharLen = size

 buffer = new ArrayBuffer size * 16
 views.push new Array 4
 for i in [0...4]
  views[0][i] = new Int32Array buffer, size*i*4, size
 viewLens.push size
 lastView = views[0]
 lastViewLen = size

 views[0][0][0] = -1
 i_lViewPos = 1

 create = (str) ->
  if i_lViewPos is lastViewLen
   addView()
  if i_lCharPos is lastCharLen
   addChar()

  len = str.length
  lastView[0][i_lViewPos] = len
  lastView[1][i_lViewPos] = i_lChar
  lastView[2][i_lViewPos] = i_lCharPos
  lastView[3][i_lViewPos] = 1
  for i in [0...len]
   if i_lCharPos is lastCharLen
    addChar()
   lastChar[i_lCharPos++] = str.charCodeAt i
  view = i_lView
  viewPos = i_lViewPos
  i_lViewPos++

 addView = ->
  size = lastViewLen
  while size * 16 * 2 <= MAX_BYTES
   size = size << 1
  buffer = new ArrayBuffer size * 16
  lastView = new Array 4
  views.push lastView
  for i in [0...4]
   lastView[i] = new Int32Array buffer, size*i*4, size
  viewLens.push size
  lastViewLen = size
  i_lViewPos = 0
  i_lView++

 addChar = ->
  size = lastCharLen
  while size * 2 * 2 <= MAX_BYTES
   size = size << 1

  buffer = new ArrayBuffer size << 1
  lastChar = new Int16Array buffer
  chars.push lastChar
  charLens.push size
  lastCharLen = size

  i_lCharPos = 0
  i_lChar++

 retain = (x, y) ->
  views[x][3][y]++

 release = (x, y) ->
  views[x][3][y]--

 class StringClass
  constructor: (str, x, y) ->
   @x = @y = -1
   if str?
    create str
    @x = view
    @y = viewPos
   else
    ###
    if x < 0 or x > i_lView or y < 0 or y >= viewLens[x] or
    (x is i_lView and y >= i_lViewPos)
     throw new Error Strings.INVALID_STRING_REF
    ###
    @x = x
    @y = y
    retain x, y

  release: ->
   release @x, @y

  retain: ->
   retain @x, @y

  hash: ->

  toString: ->
   len = views[@x][0][@y]
   if len is -1
    return null
   c = views[@x][1][@y]
   p = views[@x][2][@y]
   char = chars[c]
   clen = charLens[c]
   str = ""
   for i in [0...len]
    str += String.fromCharCode char[p]
    p++
    if p is clen
     c++
     char = chars[c]
     clen = charLens[c]
     p = 0
   str

 RES =
  retain: retain
  release: release
  String: StringClass
 RES

StringAlloc = StringAlloc()
StringClass = StringAlloc.String


###
e.g.

Person = TDS.Struct "Person",
 {property: "name", type: TDS.Types.String}
 {property: "address", type: TDS.Types.String, length: 3}

p = new Person()
console.log p.get()
###

Struct = ->
 id = null
 name = null
 properties = []
 titleCasePropperties = []
 types = []
 lengths = []
 offsets = []
 n = 0
 bytes = 0

 if typeof arguments[0] isnt 'string' or arguments[0].length is 0
  throw new Error 'No name for the struct'
 name = arguments[0]
 if names[name]?
  throw new Error "An Struct already defined with name: #{name}"
 names[name] = namesCnt
 id = namesCnt++

 for k, v of arguments
  if v?.property? and v?.type? and
  (typeof v.property is 'string') and (typeof v.type is 'number') and
  v.type >= 0 and v.type < nTypes and (v.type is parseInt v.type)
   properties.push v.property
   types.push v.type
   offsets.push bytes

   if v.length? and (typeof v.length is 'number') and
   (v.length > 0) and (v.length is parseInt v.length)
    lengths.push v.length
    bytes += TypeLenghts[v.type] * v.length
   else
    lengths.push 1
    bytes += TypeLenghts[v.type]
   n++

 if n is 0
  throw new Error Strings.NO_PROPERTIES name

 class RawObject
  constructor: ->
   for k, i in properties
    if lengths[i] is 1
     this[k] = null
    else
     this[k] = new Array lengths[i]

 class StructClass
  constructor: (obj, views, pos, viewLen) ->
   @id = id
   if views?
    @views = views
    @pos = pos
    @viewLen = viewLen
   else
    @pos = 0
    @views = []
    @viewLen = 1
    for t, i in types
     buffer = new ArrayBuffer TypeLenghts[t] * lengths[i]
     @views.push new TypeArrays[t][0] buffer
   if obj?
    @set obj

  set: (obj) ->
   if obj?
    for k, i in properties
     if obj[k]?
      @set_prop i, obj[k]
   return

  get: ->
   o = new RawObject()
   for k, i in properties
    o[k] = @get_prop i
   o

  set_prop: (v, i, j, string_ref) ->
   if types[i] is Types.String
    if lengths[i] is 1
     if string_ref is on
      s = v
      s.retain()
     else
      s = new StringClass v
     @views[i][@pos*2] = s.x
     @views[i][@pos*2+1] = s.y
    else
     k1 = @pos*lengths[i]*2
     if j?
      if string_ref is on
       s = v
       s.retain()
      else
       s = new StringClass v
      @views[i][k1 + j*2] = s.x
      @views[i][k1 + j*2 + 1] = s.y
     else
      l = Math.min lengths[i], v.length
      for j in [0...l]
       if string_ref is on
        s = v
        s.retain()
       else
        s = new StringClass v[j]
       @views[i][k1 + j*2] = s.x
       @views[i][k1 + j*2 + 1] = s.y
   else
    if lengths[i] is 1
     @views[i][@pos] = v
    else
     k1 = @pos*lengths[i]
     if j?
      @views[i][k1 + j] = v
     else
      l = Math.min lengths[i], v.length
      for j in [0...l]
       @views[i][k1 + j] = v[j]
   return

  get_prop: (i, j, string_ref) ->
   res = null
   if lengths[i] is 1
    if types[i] is Types.String
     s = new StringClass null, @views[i][@pos*2], @views[i][@pos*2+1]
     if string_ref is on
      res = s
     else
      res = s.toString()
      s.release()
    else
     res = @views[i][@pos]
   else
    if j?
     if types[i] is Types.String
      k1 = @pos*lengths[i]*2
      s = new StringClass null, @views[i][k1 + j*2], @views[i][k1 + j*2 + 1]
      if string_ref is on
       res = s
      else
       res = s.toString()
       s.release()
     else
      k1 = @pos * lengths[i]
      res = @views[i][k1 + j]
    else
     res = new Array lengths[i]
     if types[i] is Types.String
      k1 = @pos*lengths[i]*2
      for j in [0...lengths[i]]
       s = new StringClass null, @views[i][k1 + j*2], @views[i][k1 + j*2 + 1]
       if string_ref is on
        res[j] = s
       else
        res[j] = s.toString()
        s.release()
     else
      k1 = @pos*lengths[i]
      for j in [0...lengths[i]]
       res[j] = @views[i][k1 + j]
   res

  copyFrom: (struct) ->
   if @id isnt struct.id
    return off
   for t, i in types
    k1 = lengths[i] * TypeArrays[t][1]
    k2 = TypeArrays[t][1]
    for j in [0...lengths[i]]
     p = @pos * k1 + j * k2
     for k in [0...k2]
      @views[i][p+k] = struct.views[i][struct.pos*k1 + j*k2 + k]
     if t is Types.String
      StringAlloc.retain @views[i][p], @views[i][p+1]
   return true

  next: ->
   if @pos < @viewLen-1
    @pos++
    return on
   else
    return off

  prev: ->
   if @pos > 0
    @pos--
    return on
   else
    return off

 for k, i in properties
  StructClass[k.toUpperCase()] = i
  code = k.charCodeAt 0
  tcase = k
  if code <= 122 and code >= 97
   tcase = (k.substr 0, 1).toUpperCase() + k.substr 1
  titleCasePropperties.push tcase
  do (i) ->
   StructClass.prototype["set#{tcase}"] = (val, j, string_ref) ->
    @set_prop val, i, j, string_ref

   StructClass.prototype["get#{tcase}"] = (j, string_ref) ->
    @get_prop i, j, string_ref

 StructClass.id = id
 StructClass.name = name
 StructClass.properties = properties
 StructClass.titleCasePropperties = titleCasePropperties
 StructClass.types = types
 StructClass.lengths = lengths
 StructClass.offsets = offsets
 StructClass.n = n
 StructClass.bytes = bytes
 StructClass.Object = RawObject
 StructClass


TDSArray = (struct, length) ->
 views = null

 class ArrayClass
  constructor: ->
   @struct = struct
   @length = length
   views = []
   for t, i in struct.types
    buffer = new ArrayBuffer TypeLenghts[t] * struct.lengths[i] * length
    views.push new TypeArrays[t][0] buffer

  get: (i, structIns) ->
   if structIns?
    structIns.views = views
    structIns.pos = i
   else
    structIns = new struct null, views, i, length
   structIns

  getViews: -> views

 new ArrayClass


ArrayList = (struct, start_size, capacity) ->
 arrays = null
 length = 0
 lastArr = null
 i_lArr = i_lArrPos = 0

 class ArrayListClass
  constructor: ->
   arrays = @arrays = []
   @struct = struct

   length = 0
   while true
    lastArr = TDSArray struct, capacity
    arrays.push lastArr
    if length + capacity >= start_size
     i_lArrPos = start_size - length
     length = @length = start_size
     break
    else
     i_lArr++
     length += capacity

  get: (p, structIns) ->
   if p < 0 or p >= length
    return null
   x = parseInt p / capacity
   y = p % capacity
   return arrays[x].get y, structIns

  add: (structIns) ->
   if i_lArrPos is capacity
    @addArray()

   @length++
   length++
   return lastArr.get i_lArrPos++, structIns

  addArray: ->
   lastArr = TDS.Array struct, capacity
   arrays.push lastArr
   i_lArr++
   i_lArrPos = 0

 new ArrayListClass


TDS =
 Types: Types
 Struct: Struct
 String: StringClass
 Array: TDSArray
 ArrayList: ArrayList

if GLOBAL?
 module.exports = TDS
else
 window.TDS = TDS

