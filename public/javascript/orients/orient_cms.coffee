class @OrientCms
    constructor: (opts) ->
        @options = opts || {}

        @server = opts.server

        globalModel = new Backbone.Model(orientationValue: 0, visualize: true, blink: false, global: true)
        
        @view = new OrientCmsView(collection: opts.clients)
        document.body.appendChild( @view.el );

        @globalItemView = new OrientCmsItemView(model: globalModel)
        # document.body.appendChild( @globalItemView.el );

        @view.$el.prepend(@globalItemView.el)
        $(@globalItemView.el).addClass('global')


        # when a client gets highlighted, "UNhighlight" all others
        opts.clients.on 'change:highlighted', (model, value, obj) ->
            if value == true
                # 'this' is the collection scope
                @each (m) ->
                    m.set(highlighted: false) if m.cid != model.cid

        # when global target control model's value changes, propagate this change to all client models
        globalModel.on 'change:targetOrientationValue', (model, val, obj) =>
            @view.collection.each (clientModel) =>
                clientModel.set(globalTargetOrientationValue: val)

        # when global target control model's value changes, propagate this change to all client models
        globalModel.on 'change:visualize', @_pushVisualize
        globalModel.on 'change:blink', @_pushBlink

        # each client gets the 'globalTargetOrientationValue', but only for the ones that don't have a custom target value,
        # this global value will be applied as actual target value
        @view.collection.on 'change:globalTargetOrientationValue', (model, val, obj) ->
            return if model.get('customTargetOrientationValue') == true # skip clients who have a custom setting
            model.set(targetOrientationValue: val)

        # create visual elements for every new connecting client
        @view.collection.on 'add', (model) =>
            model.set(targetOrientationValue: globalModel.get('orientationValue'))
            model.set
                blink: globalModel.get('blink')
                visualize: globalModel.get('visualize')


        @view.collection.on 'change:customVisualizeValue', (model, val, obj) =>
            if val != true
                model.set(visualize: globalModel.get('visualize'))

        @view.collection.on 'change:customBlinkValue', (model, val, obj) =>
            if val != true
                model.set(blink: globalModel.get('blink'))

        # when a client's (actual) target value changes, emit a message to notify the client
        @view.collection.on 'change:targetOrientationValue', (model, value, obj) =>
            @server.emit('orient-config', sessionId: model.id, targetOrientationValue: value)

        @view.collection.on 'change:visualize', (model, value, obj) =>
            @server.emit('orient-config', sessionId: model.id, visualize: value)

        @view.collection.on 'change:blink', (model, value, obj) =>
            @server.emit('orient-config', sessionId: model.id, blink: value)

    _pushVisualize: (model, val, obj) =>
        @view.collection.each (clientModel) =>
            if clientModel.get('customVisualizeValue') != true
                clientModel.set(visualize: val)

    _pushBlink: (model, val, obj) =>
        @view.collection.each (clientModel) =>
            if clientModel.get('customBlinkValue') != true
                clientModel.set(blink: val)

class OrientCmsView extends Backbone.View
    tagName: 'div'
    className: 'orient-cms-view'

    initialize: ->
        # create item view for each item in collection

        if @collection
            @collection.each (model) =>
                @_addItemView(model)

            @collection.on 'add', (model) =>
                @_addItemView(model)

    _addItemView: (model) ->
        view = new OrientCmsItemView(model: model)
        model.cmsView = view
        $(view.el).addClass('client')
        @$el.append view.el



class OrientCmsItemView extends Backbone.View
    tagName: 'div'
    className: 'orient-cms-item-view'

    events:
        'mouseover': '_onHover'
        'mousedown #target input': '_onCustomTarget'
        'mousemove #target input': '_onCustomTargetUpdate'
        'click #target #reset': '_onResetCustomTarget'
        'change #visualize select': '_onVisualizeChange'
        'change #blink select': '_onBlinkChange'


    initialize: ->
        @$el.append('<p id="orientation"></p>')
        @$el.append('<p id="position"></p>')
        @$el.append('<p id="target"><span id="display">0</span><input type="range" value="0" min="0" max="360" /><a href="#" id="reset">reset</a></p>')

        if @model.get('global')
            global_option = ''
        else
            global_option = '<option value="global">Use Global</option>'

        @$el.append('<p id="visualize">Visualization enabled: <select>'+global_option+'<option value="1">Enabled</option><option value="0">Disabled</option></select></p>')

        @$el.append('<p id="blink">Blink enabled: <select>'+global_option+'<option value="1">Enabled</option><option value="0">Disabled</option></select></p>')

        @updateValues()

        if @model
            @model.on 'change', @updateValues, this

    updateValues: ->
        return if !@model
        if val = @model.get('orientation')
            @$el.find('p#orientation').text 'Orientation: ' + _.map( val.toArray(), (angle) -> Math.floor(angle/Math.PI*180) ).join(', ')

        if val = @model.get('position')
            @$el.find('p#position').text 'Position: ' + _.map( val.toArray(), (str) -> str.toString().substring(0, 5) ).join(', ')

        targetVal = @model.get('targetOrientationValue') || 0
        @$el.find('p#target #display').text 'targetOrientationValue: ' + targetVal
        @$el.find('p#target input').val targetVal

        resetEl = @$el.find('p#target #reset')
        if @model.get('customTargetOrientationValue')
            resetEl.show()
        else
            resetEl.hide()

        if @model.get('visualize') == true
            @$el.find('#visualize').addClass('enabled').removeClass('disabled')
        else
            @$el.find('#visualize').addClass('disabled').removeClass('enabled')

        if @model.get('blink') == true
            @$el.find('#blink').addClass('enabled').removeClass('disabled')
        else
            @$el.find('#blink').addClass('disabled').removeClass('enabled')

        if @model.get('highlighted') == true
            @$el.addClass 'highlighted'
        else
            @$el.removeClass 'highlighted'



    _onHover: (evt) ->
        @model.set(highlighted: true)

    _onCustomTarget: (evt) ->
        @model.set(customTargetOrientationValue: true)

    _onCustomTargetUpdate: (evt) ->
        return if @model.get('customTargetOrientationValue') != true
        @model.set(targetOrientationValue: $(event.target).val())

    _onResetCustomTarget: (evt) ->
        @model.set(customTargetOrientationValue: false)
        @model.set(targetOrientationValue: @model.get('globalTargetOrientationValue'))

    _onVisualizeChange: (evt) ->
        val = $(evt.target).val()
        if val == 'global'
            @model.set(customVisualizeValue: false)
        else
            @model.set(customVisualizeValue: true, visualize: val == '1')

    _onBlinkChange: (evt) ->
        val = $(evt.target).val()
        if val == 'global'
            @model.set(customBlinkValue: false)
        else
            @model.set(customBlinkValue: true, blink: val == '1')
