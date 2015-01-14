class @OrientCms
    constructor: (opts) ->
        @options = opts || {}

        @server = opts.server

        targetControlModel = new Backbone.Model(orientationValue: 0)
        
        @view = new OrientCmsView(collection: opts.clients)
        document.body.appendChild( @view.el );

        @globalItemView = new OrientCmsItemView(model: targetControlModel)
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
        targetControlModel.on 'change:targetOrientationValue', (model, val, obj) =>
            @view.collection.each (clientModel) =>
                clientModel.set(globalTargetOrientationValue: val)

        # each client gets the 'globalTargetOrientationValue', but only for the ones that don't have a custom target value,
        # this global value will be applied as actual target value
        @view.collection.on 'change:globalTargetOrientationValue', (model, val, obj) ->
            return if model.get('customTargetOrientationValue') == true # skip clients who have a custom setting
            model.set(targetOrientationValue: val)

        # create visual elements for every new connecting client
        @view.collection.on 'add', (model) =>
            model.set(targetOrientationValue: targetControlModel.get('orientationValue'))

        # when a client's (actual) target value changes, emit a message to notify the client
        @view.collection.on 'change:targetOrientationValue', (model, value, obj) =>
            console.log 'emit'
            @server.emit('orient-config', sessionId: model.id, targetOrientationValue: value)


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


    initialize: ->
        @$el.append('<p id="orientation"></p>')
        @$el.append('<p id="position"></p>')
        @$el.append('<p id="target"><span id="display">0</span><input type="range" value="0" min="0" max="360" /><a href="#" id="reset">reset</a></p>')
        @$el.append('<p id="visualize">Visualization enabled: <select><option value="global">Use Global</option><option value="1">Enabled</option><option value="0">Disabled</option></select></p>')


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
