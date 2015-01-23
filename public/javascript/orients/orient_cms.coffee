class @OrientCms
    constructor: (opts) ->
        @options = opts || {}

        @server = opts.server

        globalModel = new OrientModel(global: true)
        
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


        @view.collection.on 'change:target_source', (model, val, obj) =>
            target = false
            if val.indexOf('target-') == 0
                v = val.replace('target-', '')
                target = true
            else
                v = val

            # find leader
            leader = @view.collection.get(v) # get the model with the specified cid
            leader ||= @globalItemView.model if @globalItemView.model.cid == v
            # only set the actual effective targetLeaderCid property if the current target_source value specifies a valid model
            if leader
                if target
                    model.set targetLeaderCid: v
                else
                    model.set dirLeaderCid: v

        # create visual elements for every new connecting client
        @view.collection.on 'add', (model) =>
            model.set
                target: globalModel.get('target')
                blink: globalModel.get('blink')
                visualize: globalModel.get('visualize')
                tempo: globalModel.get('tempo')
                gain: globalModel.get('gain')

            model.on 'change:targetLeaderCid', (model, val, obj) =>
                # remove previous listener
                if model.targetLeader
                    model.targetLeader.off 'change:target', model.onTargetLeaderTargetChange
                    model.targetLeader = undefined

                # find leader
                leader = @view.collection.get(val) # get the model with the specified cid
                leader ||= @globalItemView.model if @globalItemView.model.cid == val

                # abort if not found (maybe val == undefined?)
                if leader == undefined
                    return

                # make sure any conflicting dirLeaderCid is unset
                model.unset('dirLeaderCid')

                # bind listener
                leader.on 'change:target', model.onTargetLeaderTargetChange
                model.targetLeader = leader
                model.set(target: leader.get('target'))

            model.on 'change:dirLeaderCid', (model, val, obj) =>
                # remove previous listener
                if model.dirLeader
                    model.dirLeader.off 'change:orientation', model.onDirLeaderOrientationChange
                    model.dirLeader = undefined

                # find leader
                leader = @view.collection.get(val) # get the model with the specified cid
                leader ||= @globalItemView.model if @globalItemView.model.cid == val

                # abort if not found (maybe val == undefined?)
                if leader == undefined
                    console.log "Couldn't find dir leader model using cid: " + val
                    return

                # make sure any conflicting targetLeaderCid is unset
                model.unset('targetLeaderCid')

                # bind listener
                leader.on 'change:orientation', model.onDirLeaderOrientationChange
                model.dirLeader = leader
                # model.set(target: leader.get('target'))

            # by default every new connected client binds to the global model's target
            # model.set targetLeaderCid: @globalItemView.model.cid
            model.set target_source: 'target-'+@globalItemView.model.cid


        # every time a client model's target property changes, make sure we notify them
        @view.collection.on 'change:target', (model, val, obj) =>
            @server.emit 'orient-config', sessionId: model.id, target: val

        # automate the control and notification for these properties
        _.each ['visualize', 'blink', 'tempo', 'gain', 'radar', 'audio_track'], (prop) =>

            # when global target control model's value changes, propagate this change to all client models
            globalModel.on 'change:'+prop, (model, val, obj) => @_pushGlobalBool(prop, val)

            @view.collection.on 'change:'+prop+'CustomValue', (model, val, obj) =>
                if val != true
                    model.set(prop, globalModel.get(prop))

            @view.collection.on 'change:'+prop, (model, val, obj) =>
                data = sessionId: model.id
                data[prop] = val
                @server.emit 'orient-config', data



    _pushGlobalBool: (prop, val) =>
        @view.collection.each (clientModel) =>
            if clientModel.get(prop+'CustomValue') != true
                clientModel.set(prop, val)


class OrientCmsView extends Backbone.View
    tagName: 'ul'
    className: 'orient-cms-view'

    initialize: ->
        # create item view for each item in collection

        if @collection
            @collection.each (model) =>
                @_addItemView(model)

            @collection.on 'add', (model) =>
                @_addItemView(model)

            @collection.on 'remove', (model) ->
                if model.cmsView
                    model.cmsView.remove()

    _addItemView: (model) ->
        view = new OrientCmsItemView(model: model)
        model.cmsView = view
        $(view.el).addClass('client')
        @$el.append view.el



class OrientCmsItemView extends Backbone.View
    tagName: 'li'
    className: 'orient-cms-item-view'

    events:
        'mouseover': '_onHover'

        'mousedown #target input': '_onCustomTarget'
        'mousemove #target input': '_onCustomTargetUpdate'
        'click #target #reset': '_onResetCustomTarget'

        'mousedown #audio_track input': '_onCustomTrack'
        'mousemove #audio_track input': '_onCustomTrackUpdate'
        'click #audio_track #reset': '_onResetTrack'
        
        'change #visualize select': '_onBoolControlChange'
        'change #blink select': '_onBoolControlChange'
        'change #tempo select': '_onBoolControlChange'
        'change #gain select': '_onBoolControlChange'
        'change #radar select': '_onBoolControlChange'

        'keyup #target_source': '_onStringControlChange'

    initialize: ->
        @$el.append('<p id="cid">'+@model.cid+'</p>')
        @$el.append('<p id="orientation"></p>')
        @$el.append('<p id="position"></p>')

        @_appendStringControl('target_source')
        @_appendRangeControl('target', 0, 360, {reset: false})

        @_appendBoolControl('visualize')
        @_appendBoolControl('blink')

        @_appendRangeControl('audio_track', 1, 3)

        @_appendBoolControl('tempo')
        @_appendBoolControl('gain')
        @_appendBoolControl('radar')

        @updateValues()

        if @model
            @model.on 'change', @updateValues, this

    _appendBoolControl: (propName) ->
        if @model && @model.get('global')
            global_option = ''
        else
            global_option = '<option value="global">Use Global</option>'

        @$el.append('<p id="'+propName+'"><select>'+global_option+'<option value="1">On</option><option value="0">Off</option></select></p>')

    _appendRangeControl: (propName, min, max, opts) ->
        opts ||= {}

        if @model.get('global') == true || opts.reset == false
            resetHtml = ''
        else
            resetHtml = '<a href="#" id="reset">reset</a>'

        @$el.append('<p id="'+propName+'"><span id="display">0</span><input type="range" value="0" min="'+(min || 0)+'" max="'+(max || 100)+'" />'+resetHtml+'</p>')

    _appendStringControl: (propName) ->
        if @model.get('global') == true
            resetHtml = ''
        else
            resetHtml = '<a href="#" id="reset">reset</a>'

        @$el.append('<p id="'+propName+'"><input type="text" />'+resetHtml+'</p>')


    _updateBoolControl: (propName) ->
        lineEl = @$el.find('#'+propName)

        if @model.get(propName) == true
            lineEl.addClass('enabled').removeClass('disabled')
        else
            lineEl.addClass('disabled').removeClass('enabled')

        if inputEl = lineEl.find('select')
            useGlobal = (@model.get('global') != true && @model.get(propName+'CustomValue') != true)
            if useGlobal
                inputEl.val('global')
            else if @model.get(propName) == true
                inputEl.val('1')
            else
                inputEl.val('0')

    _updateRangeControl: (propName) ->
        val = @model.get(propName) || 0
        @$el.find('p#'+propName+' #display').text val
        @$el.find('p#'+propName+' input').val val

        lineEl = @$el.find('#'+propName)
        resetEl = lineEl.find('#reset')

        if @model.get('global') != true && @model.get(propName+'CustomValue') == true
            resetEl.show()
        else
            resetEl.hide()

    _updateStringControl: (propName) ->
        @$el.find('p#'+propName+' input').val @model.get(propName)

        resetEl = $('p#'+propName+' #reset')
        if @model.get('global') != true && @model.get(propName+'CustomValue') == true
            resetEl.show()
        else
            resetEl.hide()

    updateValues: ->
        return if !@model

        if val = @model.get('orientation')
            @$el.find('p#orientation').text _.map( val.toArray(), (angle) -> Math.floor(angle/Math.PI*180) ).join(', ')

        if val = @model.get('position')
            @$el.find('p#position').text _.map( val.toArray(), (str) -> str.toString().substring(0, 5) ).join(', ')

        targetVal = @model.get('targetOrientationValue') || 0
        @$el.find('p#target #display').text targetVal
        @$el.find('p#target input').val targetVal

        @_updateRangeControl('target')
        @_updateRangeControl('audio_track')

        @_updateBoolControl('blink')
        @_updateBoolControl('visualize')
        @_updateBoolControl('tempo')
        @_updateBoolControl('gain')
        @_updateBoolControl('radar')

        # @_updateStringControl('target_source')

        if @model.get('highlighted') == true
            @$el.addClass 'highlighted'
        else
            @$el.removeClass 'highlighted'

    _onHover: (evt) ->
        @model.set(highlighted: true)


    _onCustomTarget: (evt) ->
        @model.set(target_source: 'target-'+@model.cid) # @model.set(targetCustomValue: true) if @model.get('global') != true
        @_updateStringControl('target_source')

    _onCustomTargetUpdate: (evt) ->
        return if @model.get('target_source') != 'target-'+@model.cid && @model.get('global') != true
        @model.set(target: $(event.target).val())

    _onResetCustomTarget: (evt) ->
        evt.preventDefault()
        @model.set(targetCustomValue: false)

    _onCustomTrack: (evt) ->
        @model.set(audio_trackCustomValue: true) if @model.get('global') != true

    _onCustomTrackUpdate: (evt) ->
        return if @model.get('audio_trackCustomValue') != true && @model.get('global') != true
        @model.set(audio_track: $(event.target).val())

    _onResetTrack: (evt) ->
        evt.preventDefault()
        @model.set(audio_trackCustomValue: false)

    _onBoolControlChange: (evt) ->
        el = $(evt.target)
        id = el.parent().prop('id')
        val = el.val()
        @model.set(id+'CustomValue', val != 'global')
        if val != 'global'
            @model.set(id, val == '1')

    _onStringControlChange: (evt) ->
        el = $(evt.target)
        id = el.parent().prop('id')
        val = el.val()
        @model.set(id, val)



