
class @OrienterAudio
  constructor: (opts) ->
    #
    # config
    #

    @options = opts || {}
    @track_urls = ['audio/drone.wav', 'audio/125bpm-drums.wav', 'audio/techno.wav'] # ['audio/125bpm-drums.wav', 'audio/125bpm-dj.wav', 'audio/125bpm-electro.wav', 'audio/harmonic-drone-repeat.wav']
    @volume = 0.6
    @freq = 700 # Hz
    @gainMultiplier = 1.0

    #
    # audio context
    #

    if typeof webkitAudioContext != "undefined"
      @context = new webkitAudioContext()
    else if typeof AudioContent != "undefined"
      @context = new AudioContext() 
    else
      console.log "AudioContext not supported"
      return

    #
    # gain node (to controle gain/volume)
    #

    @gain = @context.createGain()
    @gain.gain.value = @volume * @gainMultiplier
    @gain.connect @context.destination

    #
    # filters (effect)
    #

    @filter = @context.createBiquadFilter()
    @filter.connect @gain
    @filter.type = @filter.LOWPASS # 'lowpass'; # Low-pass filter. See BiquadFilterNode docs
    @filter.frequency.value = 5000; # Set cutoff to 440 HZ
    @filter.Q.value = 15
    # @filter.gain.value = 25;

    #
    # BufferSource (track)
    #
    bufferLoader = new BufferLoader @context, @track_urls, (bufferList) =>
      @bufferList = bufferList

    bufferLoader.load()

  applyTempo: (val) ->
    console.log 'apply tempo', val
    @source.playbackRate.value = val if @source

  applyGain: (val) ->
    @setGain val

  applyRadar: (val) ->
    @_radarTempo = val

  start: (trckidx) ->
    return if !@context

    if !@bufferList
      console.log 'no buffer list'
      return

    #
    # create and start 
    #

    @stop()
    console.log trckidx
    return if trckidx == false # just stop

    # no track specified; random mtrack
    trckidx = @_trackIdx || 0 if trckidx == undefined || trckidx == true
    buffer = @bufferList[trckidx]

    if !buffer
      console.log 'invalid buffer'
      return

    @source = @context.createBufferSource()
    @source.buffer = buffer
    @source.loop = true
    @source.connect @filter # @gain
    @source.start(@context.currentTime)

  stop: ->
    if @source
      @source.stop(@context.currentTime)
      @source.disconnect()
      @source = undefined

  isPlaying: ->
    @source != undefined

  setVolume: (vol) ->
    @volume = vol
    @gain.gain.value = vol * (1.0 - @fade) if @gain

  setGain: (g) ->
    @gainMultiplier = Math.max(Math.min(g, 1.0), 0.0)
    @gain.gain.value = @volume * @gainMultiplier if @gain

  update: (frameCount) ->
    if @_radarTempo
      if @_radarTempo == 0
        gain = 1
      else
        sinpos = new Date().getTime() * (1 / @_radarTempo)
        gain = Math.sin(sinpos) / 2 + 0.75

      @setGain(gain*gain)

  setTrack: (tracknumber) ->
    @_trackIdx = tracknumber - 1
    @start() if @isPlaying() # restart if playing

