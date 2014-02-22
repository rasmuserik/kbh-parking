#{{{1 Code during iot hackathon
#
# hackathon code in progress
#
#{{{1 setup
mapElem.style.width = window.innerWidth + "px"
mapElem.style.height = window.innerHeight + "px"
mapElem.style.display = "inline-block"
mapElem.style.position = "absolute"
mapElem.style.top = mapElem.style.left = "0px"

map = L.map('mapElem')
L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map)

navigator.geolocation.getCurrentPosition (pos) ->
  map.setView [pos.coords.latitude, pos.coords.longitude], 10

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
    for y in [0..255] by 2
      for x in [0..255] by 2
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

        for dx in [0..1]
          for dy in [0..1]
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

parkomatCount = (fn) ->
  $.ajax
    url: 'http://data.kk.dk/api/action/datastore_search_sql'
    data:
      sql: 'SELECT COUNT (*) from "660e19fa-8838-4a5c-9495-0d7f94fab51e"'
    dataType: 'jsonp'
    success: (data) ->
      fn +data.result.records[0].count

loadRecent = (fn) ->
  parkomatCount (n) ->
    console.log "count", n
    # TODO: should probably be closer to 100000
    parkomatGet n - 70000, 70000, (result) ->
      console.log "got n", result.length
      fn result

now = undefined
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
    fn()


$ ->
    updatePoints ->
      undefined
