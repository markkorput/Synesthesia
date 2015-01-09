class @OrientCms
    constructor: (opts) ->
        @options = opts || {}
        @view = new OrientCmsView(collection: opts.clients)
        document.body.appendChild( @view.el );

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


