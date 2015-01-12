$(document).ready ->
  window.orienter = new Orienter()

class Orienter
  constructor: (opts) ->
    @options = opts || {}

    @server = io.connect '/dancer'
    @$h1 = $('h1')
    @orientation_el = $('#orientation')
    @acceleration_el = $('#acceleration')

    @server.on 'welcome', (data) =>
      if data.tracking
        @setupTracking()
      else
        @$h1.text 'Connected. Motion tracking off.'

    @server.on 'reset', =>
      @setupTracking(false)

    @server.on 'toggleMotion', (data) =>
      if data.motion
        @setupTracking()
      else
        @setupTracking(false)

  setupTracking: (_setup) ->
    @setupMotionListener(_setup)
    @setupAccelListener(_setup)

    if _setup == true || _setup == undefined
      @$h1.text 'Now tracking motion.'
    else
      @$h1.text 'Motion tracking off.'

  setupMotionListener: (_setup) ->
    if _setup == true || _setup == undefined
      window.addEventListener 'deviceorientation', @onDeviceMotion
    else
      window.removeEventListener 'deviceorientation', @onDeviceMotion

  setupAccelListener: (_setup) ->
    if _setup == true || _setup == undefined
      window.addEventListener 'devicemotion', @onDeviceAccel
    else
      window.removeEventListener 'devicemotion', @onDeviceAccel

  onDeviceMotion: (event) =>
    @server.emit('motionData', {alpha: event.alpha, beta: event.beta, gamma: event.gamma,});
    @orientation_el.text('Orientation: '+[event.alpha, event.beta, event.gamma].join(', '))

  onDeviceAccel: (event) =>
    @server.emit 'accelerationData',
      rotationRate: event.rotationRate
      acceleration: event.acceleration
      accelerationIncludingGravity: event.accelerationIncludingGravity
    @acceleration_el.text('Acceleration: '+[event.accelerationIncludingGravity.x, event.accelerationIncludingGravity.y, event.accelerationIncludingGravity.z].join(', '))




# var server = io.connect('/dancer');
# var $h1 = $('h1');
# 
# server.on('welcome', function(data) {
#   if (data.tracking) {
#     startTrack();
#   } else {
#     $h1.text('Connected. Motion tracking off.');
#   }
# });
# 
# server.on('reset', function() {
#   stopTrack();
# });
# 
# server.on('toggleMotion', function(data) {
#   if (data.motion) {
#     startTrack();
#   } else {
#     stopTrack();
#   }
# });
# 
# var startTrack = function() {
#   $h1.text('Now tracking motion.');
#   initMotionListener();
#   initAccelListener();
# };
# 
# var stopTrack = function() {
#   $h1.text('Motion tracking off.');
#   removeMotionListener();
#   removeAccelListener();
# };
# 
# var initMotionListener = function() {
#   window.addEventListener('deviceorientation', boundDeviceMotion);
# };
# 
# var removeMotionListener = function() {
#   window.removeEventListener('deviceorientation', boundDeviceMotion);
# };
# 
# var onDeviceMotion = function(event) {
#   server.emit('motionData', {alpha: event.alpha, beta: event.beta, gamma: event.gamma,});
# };
# 
# var boundDeviceMotion = onDeviceMotion.bind(this);
# 
# var initAccelListener = function(){
#   window.addEventListener('devicemotion', boundOnAccel);
# }
# 
# var removeAccelListener = function(){
#   window.removeEventListener('devicemotion', boundOnAccel);
# }
# 
# var onAccel = function(data){
#   server.emit('accelerationData', {
#     rotationRate: data.rotationRate,
#     acceleration: data.acceleration,
#     accelerationIncludingGravity: data.accelerationIncludingGravity
#   });
# }
# 
# var boundOnAccel = onAccel.bind(this);


