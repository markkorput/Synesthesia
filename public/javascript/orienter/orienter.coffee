$(document).ready ->
  window.orienter = new Orienter()

class Orienter
  constructor: (opts) ->
    @options = opts || {}

    @server = io.connect '/orienter'
    @$h1 = $('h1')
    @session_el = $('#session_id')
    @orientation_el = $('#orientation')
    @acceleration_el = $('#acceleration')
    @target_el = $('#target')
    @current_el = $('#current')

    @server.on 'sessionId', (data) =>
      @session_id = data
      @session_el.text('Session ID: ' + data)

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

    @server.on 'targetOrientationValue', (data) =>
      return if data.sessionId != @session_id # not for us
      @target_el.text 'Target: '+data.value

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
    @current_el.text('Current: ' + Math.floor(event.alpha))

  onDeviceAccel: (event) =>
    @server.emit 'accelerationData',
      rotationRate: event.rotationRate
      acceleration: event.acceleration
      accelerationIncludingGravity: event.accelerationIncludingGravity
    @acceleration_el.text('Acceleration: '+[event.accelerationIncludingGravity.x, event.accelerationIncludingGravity.y, event.accelerationIncludingGravity.z].join(', '))

