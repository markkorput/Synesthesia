class @OrientModel extends Backbone.Model
  defaults:
    audioEnabled: false
    tempo: false
    gain: false
    blink: false
    radar: false
    targetOrientationValue: 0
    orientationValue: 0
    visualize: true

  initialize: ->
    @on 'change:targetOrientationValue', @_updateDistance
    @on 'change:orientationValue', @_updateDistance

    @on 'change:tempo', @_updateAudio
    @on 'change:gain', @_updateAudio

    @set(lastOrientationTime: new Date().getTime())

    @on 'change:orientation', (model, val, obj) ->
        model.set(lastOrientationTime: new Date().getTime())

  _updateDistance: =>
    target = @get('targetOrientationValue')
    current = @get('orientationValue')
    return if target == undefined || current == undefined
    target = 180 - (target - 180) if target > 180
    current= 180 - (current - 180) if current > 180
    dist = target-current
    # @log 'direction-delta', Math.abs(dist)
    @set(orientationDistance: dist)

  _updateAudio: =>
    audioEnabled = @get('tempo') == true || @get('gain') == true
    @set(audioEnabled: audioEnabled)
