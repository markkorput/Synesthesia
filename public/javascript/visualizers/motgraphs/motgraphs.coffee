class @Motgraphs
  constructor: (opts) ->
    @options = opts
    server = io.connect('/motgraphs')

    server.on 'welcome', (data) ->
      console.log 'welcomed'

    server.on 'motionData', (data) =>
      # console.log 'motData:', data
      @update(data)

    server.on 'accelerationData', (data) =>
      @accelerationUpdate(data)

    server.on 'audio', (data) ->
      console.log "[warning] shouldn't be receiving audio"

    

    @alphas = []
    @betas = []
    @gammas = []
    @accelsX = []
    @accelsY = []
    @accelsZ = []

    @chart = new CanvasJS.Chart "chartContainer",
      title:
        text: "Orientation Data"
      data: [
        {type: "line", dataPoints: @alphas},
        {type: "line", dataPoints: @betas},
        {type: "line", dataPoints: @gammas},
      ]

    @chartAccel = new CanvasJS.Chart "accelContainer",
      title:
        text: "Acceleration Data"
      data: [
        {type: "line", dataPoints: @accelsX},
        {type: "line", dataPoints: @accelsY},
        {type: "line", dataPoints: @accelsZ},
      ]

    @startdate = new Date()
    setInterval @updateCharts, 100
    console.log '[debug] Motgraphs initialized'

  update: (data) ->
    console.log 'Motiondata:', data if !@lastData
    @lastData = data

  accelerationUpdate: (data) ->
    console.log 'Acceleration data:', data if !@lastAccelData
    @lastAccelData = data

  updateCharts: =>
    x = ((new Date().getTime()) - @startdate.getTime()) / 1000

    data = @lastData || {alpha: 0, beta: 0, gamma: 0}
    @alphas.push(x: x, y: data.alpha)
    @betas.push(x: x, y: data.beta)
    @gammas.push(x: x, y: data.gamma)

    @alphas.shift() while @alphas.length > 150
    @betas.shift() while @betas.length > 150
    @gammas.shift() while @gammas.length > 150

    @chart.render()


    data = @lastAccelData || {accelerationIncludingGravity: {x: 0, y: 0, z: 0}}
    @accelsX.push(x: x, y: data.accelerationIncludingGravity.x)
    @accelsY.push(x: x, y: data.accelerationIncludingGravity.y)
    @accelsZ.push(x: x, y: data.accelerationIncludingGravity.z)

    @accelsX.shift() while @accelsX.length > 150
    @accelsY.shift() while @accelsY.length > 150
    @accelsZ.shift() while @accelsZ.length > 150

    @chartAccel.render()



$(document).ready ->
  window.motgraphs = new Motgraphs()
