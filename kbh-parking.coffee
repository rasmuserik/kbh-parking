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

  console.log lat, lng, tile2coord x+1, y+1
  ctx = canvas.getContext "2d"
  ctx.fillRect 1,0,10,10

  


canvasTiles.addTo map


###
heatmapLayer = L.TileLayer.heatMap
  radius: 20
  opacity: 0.8
  gradient:
    0.45: "rgb(0,0,255)"
    0.55: "rgb(0,255,255)"
    0.65: "rgb(0,255,0)"
  0.95: "yellow"
  1.0: "rgb(255,0,0)"
 
testData =
  max: 46,
  data: ({lat: 33 +Math.random() * Math.random(), lon: 117 + Math.random() * Math.random(), value: 1} for i in [1..100])

console.log testData


heatmapLayer.addData testData.data
 
overlayMaps = { 'Heatmap': heatmapLayer }
 
controls = L.control.layers(null, overlayMaps, {collapsed: false})
 
map = new L.Map('map',
  center: new L.LatLng(51.505, -0.09)
  zoom: 6
  layers: [baseLayer, heatmapLayer])
 
controls.addTo map
###