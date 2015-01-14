$(document).ready ->
  window.orienter = new Orienter()

class Orienter
  constructor: (opts) ->
    @options = opts || {}

    @server = io.connect '/orienter'

    @currentVal = 0
    @targetVal = 0

    @server.on 'sessionId', (data) =>
      @sessionId = data
      @log 'SessionID', data

    @server.on 'welcome', (data) =>
      if data.tracking
        @setupTracking()
      else
        @log 'status', 'Connected. Motion tracking off.'

    @server.on 'reset', =>
      @setupTracking(false)

    @server.on 'toggleMotion', (data) =>
      if data.motion
        @setupTracking()
      else
        @setupTracking(false)

    @server.on 'orient-config', (data) =>
      return if data.sessionId != @sessionId # not for us

      if data.targetOrientationValue
        @targetVal = data.targetOrientationValue
        @log 'target-direction', @targetVal
        @updateDistance()

      if data.visualize != undefined
        console.log data.visualize
        if data.visualize == true
          @loadVisualizer()
        else
          @loadVisualizer(false)
  

    @twoEl = document.getElementById('anim');
    @two = new Two(fullscreen: true).appendTo(@twoEl)

    @loadVisualizer()



    # @two.bind 'update', @update
    @two.play()

  loadVisualizer: (_load) ->
    if _load == false
      @two.remove(@rotator, @c1) # @c2 is nested inside rotator and will thus be removed
      @rotator = undefined
      @c1 = undefined
      @c2 = undefined
    else
      @c1 ||= @two.makeCircle(0, 0, Math.min(@two.width*0.3, @two.height*0.3))
      @c1.translation.set(@two.width/2, @two.height/2)
      @c1.noFill()
      @c1.stroke = 'white'
      @c1.opacity = 0.5
      @c1.linewidth = 2
      @c2 ||= @two.makeCircle(0, -Math.min(@two.width*0.3, @two.height*0.3), 10)
      @c2.fill = 'red'
      @c2.noStroke()
      @rotator ||= @two.makeGroup(@c2)
      @rotator.translation.set(@two.width/2, @two.height/2)

  # update: (frameCount) =>


  setupTracking: (_setup) ->
    @setupMotionListener(_setup)
    @setupAccelListener(_setup)

    if _setup == true || _setup == undefined
      @log 'status', 'Now tracking motion.'
    else
      @log 'status', 'Motion tracking off.'

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
    @log 'orientation', _.map([event.alpha, event.beta, event.gamma], (val) -> Math.floor(val / Math.PI * 180)).join(', ')

    @currentVal = Math.floor(event.alpha || 0)
    @log 'current-value', @currentVal
    @updateDistance()

  onDeviceAccel: (event) =>
    @server.emit 'accelerationData',
      rotationRate: event.rotationRate
      acceleration: event.acceleration
      accelerationIncludingGravity: event.accelerationIncludingGravity
    @log 'acceleration', _.map([event.accelerationIncludingGravity.x, event.accelerationIncludingGravity.y, event.accelerationIncludingGravity.z], (val) -> Math.floor(val / Math.PI * 180)).join(', ')

  updateDistance: ->
    return if @currentVal == undefined || @targetVal == undefined
    @rotator.rotation = (@currentVal - @targetVal) / 180 * Math.PI
    a = @targetVal
    a = 180 - (@targetVal - 180) if @targetVal > 180
    b = @currentVal
    b = 180 - (@currentVal - 180) if @currentVal > 180
    dist = a-b
    @log 'direction-delta', Math.abs(dist)


  #
  # LOGGING
  #

  _logsContainer: ->
    @$_logsContainerEl ||= $('#logs')
    if @$_logsContainerEl.length == 0
      $('body').append('<div id="logs"></div>')
      @$_logsContainerEl = $('#logs')

    return @$_logsContainerEl

  _logValueElFor: (subject) ->
    logsContainer = @_logsContainer()
    logField = logsContainer.find('#'+subject) # creates if necessary
    if logField.length == 0
      logsContainer.append('<p id="'+subject+'"><span class="label">'+subject+'</span><span class="value"></span></p>');
      logField = logsContainer.find('#'+subject)

    # lbl = logField.find('.label')
    return logField.find('.value')

  log: (subject, message) -> 
    if message == undefined
      message = subject
      subject = undefined

    if subject == undefined
      console.log message
      return

    el = @_logValueElFor(subject)
    el.text(message)

