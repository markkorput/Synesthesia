class @OrientCms
    constructor: (opts) ->
        @options = opts || {}

        targetControlModel = new Backbone.Model(orientationValue: 0)
        @targetControlView = new OrientGlobalTargetControlView(model: targetControlModel)
        document.body.appendChild( @targetControlView.el );

        @view = new OrientCmsView(collection: opts.clients)
        document.body.appendChild( @view.el );

        opts.clients.on 'change:highlighted', (model, value, obj) ->
            if value == true
                # 'this' is the collection scope
                @each (m) ->
                    m.set(highlighted: false) if m.cid != model.cid


class OrientGlobalTargetControlView extends Backbone.View
    tgName: 'div'
    className: 'orient-global-target-control-view'

    events:
        # 'change #slider': 'sliderChanged'
        'mousemove #slider': 'sliderChanged'

    initialize: ->
        # create DOM elements
        @$el.append('<span id="display">0</span><input type="range" id="slider" value="0" min="0" max="360">')

        # initialize elements and create hooks to auto update on changes
        if @model
            @updateValues()
            @model.on 'change', @updateValues, this

    updateValues: ->
        return if !@model
        @$el.find('#slider').val(@model.get('orientationValue'))
        @$el.find('#display').text(@model.get('orientationValue'))

    sliderChanged: (event) ->
        return if !@model
        @model.set(orientationValue: $(event.target).val())

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
        @$el.append view.el

class OrientCmsItemView extends Backbone.View
    tagName: 'div'
    className: 'orient-cms-item-view'

    events:
        'mouseover': '_onHover'

    initialize: ->
        @$el.append('<p id="orientation"></p>')
        @$el.append('<p id="position"></p>')
        @updateValues()

        if @model
            @model.on 'change', @updateValues, this

    updateValues: ->
        return if !@model
        @$el.find('p#orientation').text 'Orientation: ' + _.map( @model.get('orientation').toArray(), (str) -> str.toString().substring(0, 5) ).join(', ')
        @$el.find('p#position').text 'Position: ' + _.map( @model.get('position').toArray(), (str) -> str.toString().substring(0, 5) ).join(', ')

        if @model.get('highlighted') == true
            @$el.addClass 'highlighted'
        else
            @$el.removeClass 'highlighted'

    _onHover: (evt) ->
        @model.set(highlighted: true)
