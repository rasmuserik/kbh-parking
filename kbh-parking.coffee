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
  map.setView [pos.coords.latitude, pos.coords.longitude], 13

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
  x = tilePoint.x
  y = tilePoint.y
  [lat, lng] = tile2coord x, y

  #console.log lat, lng, tile2coord x+1, y+1
  ###
  ctx = canvas.getContext "2d"
  setInterval (->
    ctx.fillRect Math.random() * 256, Math.random() * 256,3,3
  ), 1000
  ###

  
canvasTiles.addTo map
#{{{1 experiment

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

parkomatCount (n) ->
  console.log "count", n
  parkomatGet n - 3*24000, 3*24000, (result) ->
    console.log "got n", result.length
