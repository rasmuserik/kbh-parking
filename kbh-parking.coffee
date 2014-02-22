#{{{1 Code during iot hackathon
#
# hackathon code in progress
#
#{{{1 setup

desc.style.fontSize =  window.innerHeight*.03 + "px"

map = L.map('mapElem')
L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map)

navigator.geolocation.getCurrentPosition (pos) ->
  L.marker([pos.coords.latitude, pos.coords.longitude]).addTo(map)

map.setView [55.690, 12.5655300], 12
#{{{1 utility
sinh = (x) -> (Math.pow(Math.E,x) - Math.pow(Math.E, -x))/2

tile2coordZoom = (zoom) -> (x, y) ->
  scale = Math.pow 0.5, zoom
  return [
    x * scale * 360.0 - 180.0
    180 / Math.PI * Math.atan sinh(Math.PI * (1 - 2 * y * scale))
  ]

#{{{1 drawtile
canvasTiles = L.tileLayer.canvas()
canvasTiles.drawTile = (canvas, tilePoint, zoom) ->
  tile2coord = tile2coordZoom zoom

  if false
    ctx = canvas.getContext "2d"
    im = ctx.getImageData 0,0,255,255
    w = im.width
    for y in [0..255] by 8
      for x in [0..255] by 8
        [lng, lat] = tile2coord tilePoint.x + x/256, tilePoint.y + y/256
        d = 0
        maxDist = 10000
        parkomat = undefined
        for _, obj of points
          dlng = obj.lng - lng
          dlng *= dlng
          dlat = obj.lat - lat
          dlat *= dlat
          if dlat+dlng < maxDist
            maxDist = dlat+dlng
            parkomat = obj

        for dx in [0..7]
          for dy in [0..7]
            if maxDist < 0.01
              im.data[4*(x+dx+(y+dy)*w)] = parkomat.sampling*256/40000
              im.data[4*(x+dx+(y+dy)*w)+1] = parkomat.sampling*256/40000
              im.data[4*(x+dx+(y+dy)*w)+2] = parkomat.sampling*256/40000
              im.data[4*(x+dx+(y+dy)*w)+3] = 100
    console.log im, maxDist
    ctx.putImageData im, 0, 0



  #console.log lat, lng, tile2coord x+1, y+1
  ###
  ctx = canvas.getContext "2d"
  setInterval (->
    ctx.fillRect Math.random() * 256, Math.random() * 256,3,3
  ), 1000
  ###

  
canvasTiles.addTo map
#{{{1 talk with server

parkomatGet = (offset, limit, fn) ->
  $.ajax
    url: 'http://data.kk.dk/api/action/datastore_search'
    data:
      resource_id: '660e19fa-8838-4a5c-9495-0d7f94fab51e'
      offset: offset
      limit: limit
    dataType: 'jsonp'
    success: (data) ->
      fn(data.result?.records)

###
parkomatGet = (offset, limit, fn) ->
  $.ajax
    url: "sample100000latest.json"
    success: (data) ->
      console.log data
      fn(data.result?.records)
###

parkomatCount = (fn) -> #{{{2
  $.ajax
    url: 'http://data.kk.dk/api/action/datastore_search_sql'
    data:
      sql: 'SELECT COUNT (*) from "660e19fa-8838-4a5c-9495-0d7f94fab51e"'
    dataType: 'jsonp'
    success: (data) ->
      fn +data.result.records[0].count

loadRecent = (fn) -> #{{{2
  parkomatCount (n) ->
    console.log "count", n
    # TODO: should probably be closer to 100000
    parkomatGet n - 70000, 70000, (result) ->
      console.log "got n", result.length
      fn result

now = undefined
parkomats = undefined
minLat = 1000
minLng = 1000
maxLat = 0
maxLng = 0

#{{{1 draw overlay
updatePoints = (fn) ->
  for _, parkomat of points
    parkomat.used = 0
  loadRecent (events) ->
    console.log events[0]
    latest = events.reduce ((a, b)->
      if a.tlPayDateTime > b.tlExpDateTime then a else b
    ), {tlPayDateTime: ""}
    now = latest.tlPayDateTime

    missing = 0
    current = (events.filter (e) -> e.tlPayDateTime < now < e.tlExpDateTime)
    for event in current
      parkomat = points[event.tlPDM]
      if parkomat
        ++parkomat.used
      else
        ++missing

    console.log "missing out of", missing, current.length

    parkomats = []
    for _, parkomat of points
      minLat = Math.min minLat, parkomat.lat
      maxLat = Math.max maxLat, parkomat.lat
      minLng = Math.min minLng, parkomat.lng
      maxLng = Math.max maxLng, parkomat.lng
      parkomat.weight = parkomat.used / parkomat.sampling
      parkomats.push parkomat

    parkomats.sort (a,b) ->
      a.weight - b.weight

    console.log parkomats
    console.log minLat, maxLat, minLng, maxLng

    fn()


render = (fn) ->
  stats =  []
  res = 70

  ctx = canvas.getContext "2d"

  ctx.width = ctx.height = canvas.width = canvas.height = res
  for parkomat in parkomats
    x = (parkomat.lng - minLng) / (maxLng - minLng)
    y = (maxLat - parkomat.lat) / (maxLat - minLat)
    x = x * res >>> 0
    y = y * res >>> 0
    obj = stats[x+y*res] ||
      weight: 0
      used: 0
    obj.weight += parkomat.sampling
    obj.used += parkomat.used
    stats[x+y*res] = obj
  console.log stats
  max = 0
  min = 1000000
  for stat in stats
    if stat && stat.weight
      stat.val = stat.used/stat.weight
      max = Math.max(max, stat.val)
      min = Math.min(min, stat.val)

  for stat in stats
    if stat
      stat.val = (stat.val - min) / (max - min)
  sorted = stats.filter (a) -> a
  sorted.sort (a,b) ->
    return a.val  - b.val
  for i in [0..sorted.length-1]
    sorted[i].val = i/sorted.length*256

  im = ctx.getImageData 0,0,res,res
  for y in [0..res-1]
    for x in [0..res-1]
      val = 0
      stat = stats[x+y*res]
      if stat
        val = stat.val
        im.data[4*(x+y*res)+0] = val
        im.data[4*(x+y*res)+1] = 255 - val
        im.data[4*(x+y*res)+2] = 0
        im.data[4*(x+y*res)+3] = 150
  ctx.putImageData im, 0, 0
  console.log maxLat, minLat, maxLng, minLng
  fn()


$ ->
  updatePoints ->
    console.log "B"
    render ->
      console.log canvas.toDataURL()
      L.imageOverlay(canvas.toDataURL(), [[minLat, minLng], [maxLat, maxLng]]).addTo(map);
      desc.style.opacity = 0
      desc.style.zIndex = 0
