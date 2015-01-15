class @OrientCms
    constructor: (opts) ->
        @options = opts || {}

        @server = opts.server

        globalModel = new Backbone.Model(orientationValue: 0, visualize: true, blink: false, tempo: false, global: true)
        
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
        globalModel.on 'change:visualize', (model, val, obj) => @_pushGlobalBool('visualize', val)
        globalModel.on 'change:blink', (model, val, obj) => @_pushGlobalBool('blink', val)
        globalModel.on 'change:tempo', (model, val, obj) => @_pushGlobalBool('tempo', val)

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
                tempo: globalModel.get('tempo')

        _.each ['visualize', 'blink', 'tempo'], (prop) =>
            @view.collection.on 'change:'+prop+'CustomValue', (model, val, obj) =>
                if val != true
                    model.set(prop, globalModel.get(prop))

            @view.collection.on 'change:'+prop, (model, val, obj) =>
                data = sessionId: model.id
                data[prop] = val
                @server.emit 'orient-config', data

        # when a client's (actual) target value changes, emit a message to notify the client
        @view.collection.on 'change:targetOrientationValue', (model, value, obj) =>
            @server.emit('orient-config', sessionId: model.id, targetOrientationValue: value)


    _pushGlobalBool: (prop, val) =>
        @view.collection.each (clientModel) =>
            if clientModel.get(prop+'CustomValue') != true
                clientModel.set(prop, val)

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
        'change #visualize select': '_onBoolControlChange'
        'change #blink select': '_onBoolControlChange'
        'change #tempo select': '_onBoolControlChange'

    initialize: ->
        @$el.append('<p id="orientation"></p>')
        @$el.append('<p id="position"></p>')
        @$el.append('<p id="target"><span id="display">0</span><input type="range" value="0" min="0" max="360" /><a href="#" id="reset">reset</a></p>')

        @_appendBoolControl('visualize')
        @_appendBoolControl('blink')
        @_appendBoolControl('tempo')

        @updateValues()

        if @model
            @model.on 'change', @updateValues, this

    _appendBoolControl: (propName) ->
        if @model && @model.get('global')
            global_option = ''
        else
            global_option = '<option value="global">Use Global</option>'

        @$el.append('<p id="'+propName+'">'+propName+': <select>'+global_option+'<option value="1">On</option><option value="0">Off</option></select></p>')

    _updateBoolControl: (propName) ->
        lineEl = @$el.find('#'+propName)

        if @model.get(propName) == true
            lineEl.addClass('enabled').removeClass('disabled')
        else
            lineEl.addClass('disabled').removeClass('enabled')

        resetEl = lineEl.find('#reset')

        if @model.get('global') != true && resetEl.length > 0
            if @model.get(propName+'CustomValue') == true
                resetEl.show()
            else
                resetEl.hide()

    updateValues: ->
        return if !@model

        if val = @model.get('orientation')
            @$el.find('p#orientation').text 'Orientation: ' + _.map( val.toArray(), (angle) -> Math.floor(angle/Math.PI*180) ).join(', ')

        if val = @model.get('position')
            @$el.find('p#position').text 'Position: ' + _.map( val.toArray(), (str) -> str.toString().substring(0, 5) ).join(', ')

        targetVal = @model.get('targetOrientationValue') || 0
        @$el.find('p#target #display').text 'targetOrientationValue: ' + targetVal
        @$el.find('p#target input').val targetVal

        @_updateBoolControl('blink')
        @_updateBoolControl('visualize')
        @_updateBoolControl('tempo')

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

    _onBoolControlChange: (evt) ->
        el = $(evt.target)
        id = el.parent().prop('id')
        val = el.val()
        @model.set(id+'CustomValue', val != 'global')
        if val != 'global'
            @model.set(id, val == '1')
