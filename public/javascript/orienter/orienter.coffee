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
    @distance_el = $('#distance')

    @currentVal = 0
    @targetVal = 0

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
      @targetVal = data.value
      @target_el.text 'Target: ' + @targetVal
      @updateDistance()


    @twoEl = document.getElementById('anim');
    @two = new Two(fullscreen: true).appendTo(@twoEl)

    @c1 = @two.makeCircle(0, 0, Math.min(@two.width*0.3, @two.height*0.3))
    @c1.translation.set(@two.width/2, @two.height/2)
    @c1.fill = 'black'
    @c1.noStroke()
    @c1.opacity = 0.5
    @circle = @two.makeCircle(0, -Math.min(@two.width*0.3, @two.height*0.3), 10)
    @circle.fill = 'red'
    @circle.noStroke()
    @rotator = @two.makeGroup(@circle)
    @rotator.translation.set(@two.width/2, @two.height/2)

    # @two.bind 'update', @update
    @two.play()

  # update: (frameCount) =>


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
    @currentVal = Math.floor(event.alpha || 0)
    @current_el.text('Current: ' + @currentVal)
    @updateDistance()

  onDeviceAccel: (event) =>
    @server.emit 'accelerationData',
      rotationRate: event.rotationRate
      acceleration: event.acceleration
      accelerationIncludingGravity: event.accelerationIncludingGravity
    @acceleration_el.text('Acceleration: '+[event.accelerationIncludingGravity.x, event.accelerationIncludingGravity.y, event.accelerationIncludingGravity.z].join(', '))

  updateDistance: ->
    return if @currentVal == undefined || @targetVal == undefined
    @rotator.rotation = (@currentVal - @targetVal) / 180 * Math.PI
    a = @targetVal
    a = 180 - (@targetVal - 180) if @targetVal > 180
    b = @currentVal
    b = 180 - (@currentVal - 180) if @currentVal > 180
    dist = a-b
    @distance_el.text('Delta: ' + Math.abs(dist))
