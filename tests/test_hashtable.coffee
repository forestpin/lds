LDS = null
ind = []
Person = p2 = null


test_lds = (n) ->
 console.time 'time_lds_add'
 map = LDS.HashtableBase n, LDS.Types.Int32

 #map.set "key-0", 3
 #map.set "key-1", 4
 #console.log map.get "key-1"
 #return

 for i in [0...n]
  map.set "key-#{i}", i
  #console.log "#{i} -> #{map.get "#{i}"}"
  #console.log i, map.get "key-#{i}"
 console.timeEnd 'time_lds_add'

 console.time 'time_lds_get'
 s = 0
 for i in [0...n]
  p = ind[i]
  v = map.get "key-#{p}"
  #console.log "#{p} -> #{v}"
  s += v
  #console.log p, v
 console.timeEnd 'time_lds_get'
 console.log s

 map.summarize()
 LDS.cleanup()

test_js = (n) ->
 console.time 'time_js_add'
 map = {}
 for i in [0...n]
  map["key-#{i}"] = i
 console.timeEnd 'time_js_add'

 console.time 'time_js_get'
 s = 0
 for i in [0...n]
  p = ind[i]
  v = map["key-#{p}"]
  #console.log p, v
  s += v
 console.timeEnd 'time_js_get'
 console.log s


test_js_obj = (n) ->
 console.time 'time_js_obj'
 class JSPeople
  constructor: ->
   @name = "asdf"
   @age = 23
   @values = [1, 2, 3, 0, 0]
   @address = ["No. 123", "Street 1", "Street 2", '', null]

 people = {}
 for i in [0...n]
  p = new JSPeople
  people["#{i}"] = p
  for j in [0...5]
   p.address[j] = "#{i}-#{j}"
 console.timeEnd 'time_js_obj'

 console.log 'created'

 for i in [0...20]
  p = (Math.floor Math.random()*n*2) % (n*2)
  console.log p, people["#{p}"]?.address


test_lds_obj = (n) ->
 console.time 'time_hashtable'
 arr = new Array 5
 people = LDS.Hashtable n, Person
 instance = null
 for i in [0...n]
  instance = people.get "#{i}", instance
  instance.copyFrom p2

  for j in [0...5]
   #arr[j] = "#{i}-#{j}"
   instance.setAddress "#{i}-#{j}", j
  #instance.setAddress arr
 console.timeEnd 'time_hashtable'

 console.log 'created'

 for i in [0...20]
  p = (Math.floor Math.random()*n*2) % (2*n)
  if not people.check "#{p}"
   console.log p, null
  else
   console.log p, (people.get "#{p}", instance).getAddress()

run = (n) ->
 Person = LDS.Struct "Person",
  {property: 'name', type: LDS.Types.String, length: 1}
  {property: 'age', type: LDS.Types.Int16}
  {property: 'values', type: LDS.Types.Int32, length: 5}
  {property: 'address', type: LDS.Types.String, length: 5}

 p = new Person
 p.setName 'asdf'
 p.setAge 23
 p.setValues [1, 2, 3]
 p.setAddress ["No. 123", "Street 1", "Street 2", ""]
 p.setAddress "3 - thrid", 3
 str = new LDS.String "4-fourth"
 p.setAddress str, 4, on
 str.release()

 p2 = new Person
 p2.copyFrom p



 for i in [0...n]
  p = (Math.floor Math.random()*n) % n
  ind.push p

 test_js n
 test_lds n

 console.log "Test Hashtable - Object"
 console.log "------------------------"
 test_js_obj n
 test_lds_obj n

 #itest_lds n
 #LDS.cleanup()


if GLOBAL?
 LDS = require './lds'
else
 LDS = window.LDS

run 1000
