class @Motgraphs
  constructor: (opts) ->
    @options = opts
    server = io.connect('/motgraphs')

    server.on 'welcome', (data) ->
      console.log 'welcomed'

    server.on 'motionData', (data) =>
      # console.log 'motData:', data
      @update(data)

    server.on 'audio', (data) ->
      console.log "[warning] shouldn't be receiving audio"

    

    @alphas = []
    @betas = []
    @gammas = []

    @chart = new CanvasJS.Chart "chartContainer",
      title:
        text: "Motion Data"
      data: [
        {type: "line", dataPoints: @alphas},
        {type: "line", dataPoints: @betas},
        {type: "line", dataPoints: @gammas},
      ]

    @startdate = new Date()
    # @updateChart()
    setInterval @updateChart, 100
    console.log '[debug] Motgraphs initialized'

  update: (data) ->
    console.log 'Motiondata:', data if !@lastData
    @lastData = data

  updateChart: =>
    x = ((new Date().getTime()) - @startdate.getTime()) / 1000

    data = @lastData || {alpha: 0, beta: 0, gamma: 0}
    @alphas.push(x: x, y: data.alpha)
    @betas.push(x: x, y: data.beta)
    @gammas.push(x: x, y: data.gamma)

    @alphas.shift() while @alphas.length > 150
    @betas.shift() while @betas.length > 150
    @gammas.shift() while @gammas.length > 150

    @chart.render()






$(document).ready ->
  window.motgraphs = new Motgraphs()
