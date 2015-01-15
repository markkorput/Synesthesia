$(document).ready ->
  window.orienter = new Orienter()


class OrientModel extends Backbone.Model
  initialize: ->
    @on 'change:targetOrientationValue', @_updateDistance
    @on 'change:orientationValue', @_updateDistance

  _updateDistance: =>
    target = @get('targetOrientationValue')
    current = @get('orientationValue')
    return if target == undefined || current == undefined
    target = 180 - (target - 180) if target > 180
    current= 180 - (current - 180) if current > 180
    dist = target-current
    # @log 'direction-delta', Math.abs(dist)
    @set(orientationDistance: dist)



class Blinker
  constructor: (opts) ->
    # @options = opts || {}
    @two = opts.two
    @enabled = false
    @timeout = 180
    @lastBlinkFrame = 0
    @visible = false

  enable: (_enable) ->
    @enabled = _enable
    @showBlinker(_enable)

  update: (frameCount) ->
    return if !@enabled
    nextBlink = @lastBlinkFrame + @timeout
    # console.log nextBlink, frameCount
    if frameCount >= nextBlink
      @lastBlinkFrame = frameCount
      @showBlinker(!@visible)

  showBlinker: (_show) ->
    # show or hide the blinker circle
    if _show
      if !@blinkCircle
        @blinkCircle ||= @two.makeCircle(@two.width/2, @two.height/2, 50)
        @blinkCircle.noStroke()
        @blinkCircle.fill = 'white'
      @blinkCircle.opacity = 0.5
    else
      @blinkCircle.opacity = 0.0 if @blinkCircle

    @visible = _show


class Orienter
  constructor: (opts) ->
    @options = opts || {}

    @server = io.connect '/orienter'

    @model = new OrientModel(targetOrientationValue: 0, blink: false, visualize: true)

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
      @model.set(data)
  
    @model.on 'change:targetOrientationValue', (model, val, obj) =>
      @log 'target-direction', val
      @_updateVisualizerRotation()

    @model.on 'change:orientationValue', (model,val,obj) =>
      @log 'current-direction', val
      @_updateVisualizerRotation()

    @model.on 'change:visualize', (model,val,obj) =>
      if val == true
        @loadVisualizer()
      else
        @loadVisualizer(false)

    @model.on 'change:blink', (model,val,obj) =>
      @blinker.enable(val)

    @model.on 'change:tempo', (model,val,obj) =>
      @orienterAudio.start(val)

    @model.on 'change:orientationDistance', (model,val,obj) =>
      @log 'direction-delta', Math.abs(val)
      @blinker.timeout = val if @blinker
      @orienterAudio.apply(1.0 + val * 0.03) if @orienterAudio

    @twoEl = document.getElementById('anim');
    @two = new Two(fullscreen: true).appendTo(@twoEl)

    @two.bind 'update', @update

    @orienterAudio = new OrienterAudio()

    $('#start a').click (evt) =>
      evt.preventDefault()
      $('#start').hide()
      @start()

  start: ->
    @loadVisualizer()
    @blinker = new Blinker(two: @two)
    
    @orienterAudio.start()
    @two.play()


  update: (frameCount) =>
    @blinker.update(frameCount) if @blinker

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


  _updateVisualizerRotation: ->
    return if !@rotator || !@model
    @rotator.rotation = ((@model.get('orientationValue') || 0) - (@model.get('targetOrientationValue') || 0)) / 180 * Math.PI


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
    @log 'orientation', _.map([event.alpha, event.beta, event.gamma], (val) -> Math.floor(val)).join(', ')
    @model.set(orientationValue: Math.floor(event.alpha || 0))


  onDeviceAccel: (event) =>
    @server.emit 'accelerationData',
      rotationRate: event.rotationRate
      acceleration: event.acceleration
      accelerationIncludingGravity: event.accelerationIncludingGravity
    @log 'acceleration', _.map([event.accelerationIncludingGravity.x, event.accelerationIncludingGravity.y, event.accelerationIncludingGravity.z], (val) -> Math.floor(val)).join(', ')


  updateDistance: ->
    return if @currentVal == undefined || @targetVal == undefined
    @rotator.rotation = (@currentVal - @targetVal) / 180 * Math.PI if @rotator
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

