$(document).ready ->
  window.orients = new Orients()

class Orients
    constructor: (opts) ->
        @options = opts || {}

        @server = io.connect '/orients'
        @server.on 'welcome', (data) =>
            console.log "Orients welcomed", data

        @server.on 'motionData', (data) =>
            @processMotionData(data)

        @clients = new Backbone.Collection()

        @initScene()
        @animate()

        # @processMotionData(cid: 100, alpha: Math.random()*360, beta: Math.random()*360, gamma: Math.random()*360)
        # @processMotionData(cid: 101, alpha: Math.random()*360, beta: Math.random()*360, gamma: Math.random()*360)
        # @processMotionData(cid: 102, alpha: Math.random()*360, beta: Math.random()*360, gamma: Math.random()*360)

        @clients.on 'change:highlighted', (model, value, obj) =>
            if model.clientOrient
                if value == true
                    model.clientOrient.mesh.material.color.setHex(0xBBBBFF)
                else
                    model.clientOrient.mesh.material.color.setHex(0xFF0000)

        @cms = new OrientCms(clients: @clients, server: @server)
        @initGlobalTarget()

    initScene: ->
        # @camera = new THREE.PerspectiveCamera(75, window.innerWidth/window.innerHeight, 0.1, 10000);
        @camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 1, 1000)
        @renderer = new THREE.WebGLRenderer();
        # @renderer.setClearColor(0x000000);
        # @clock = new THREE.Clock();

        @_resize()
        $(window).resize @_resize

        document.body.appendChild( @renderer.domElement );

        @scene = new THREE.Scene()

        @camera.position.set(0, 300, 0)
        @camera.lookAt @scene.position
        @camera.rotation.z = Math.PI

        @light = new THREE.PointLight(0xFFFFFF)
        @light.position.copy @camera.position
        @light.position.x += 3
        @light.position.y += 3
        @scene.add( @light )

    initGlobalTarget: ->
        @globalTargetRotator = new THREE.Object3D()
        @globalTargetRotator.position.set(0,0,0)

        geometry = new THREE.SphereGeometry 10
        material = new THREE.MeshLambertMaterial(color: 0x00FF00)
        @globalTargetMesh = new THREE.Mesh(geometry, material)
        @globalTargetMesh.position.set(0, 0, 80)
        @globalTargetRotator.add @globalTargetMesh
        @scene.add @globalTargetRotator

        @cms.targetControlView.model.on 'change:orientationValue', (model, value, obj) =>
            @globalTargetRotator.rotation.y = value / 180 * Math.PI

    updateGlobalTarget: ->
        return if !@cms || !@cms.targetControlView || !@cms.targetControlView.model

    _resize: (event) ->
        if @camera
            @camera.aspect = window.innerWidth / window.innerHeight
            @camera.updateProjectionMatrix()

        if @renderer
            @renderer.setSize( window.innerWidth, window.innerHeight * 0.7 )

    animate: ->
        requestAnimationFrame =>
            @animate()

        # @update(0.032) # 30fps
        @draw()

    # update: (dt) ->

    draw: ->
        @renderer.render @scene, @camera

    processMotionData: (data) ->
        vec3 = new THREE.Vector3(data.beta / 180 * Math.PI, data.alpha / 180 * Math.PI, -data.gamma / 180 * Math.PI)

        if model = @clients.get(data.cid)
            model.set(orientation: vec3)
        else
            pos = new THREE.Vector3(-50+Math.random()*100,-50+Math.random()*100,0)
            model = new Backbone.Model(id: data.cid, orientation: vec3, position: pos)
            @clients.add model
            clientOrient = new ClientOrient(model: model)
            model.clientOrient = clientOrient
            @scene.add clientOrient.mesh


class ClientOrient
    constructor: (opts) ->
        @options = opts || {}

        geometry = new THREE.CubeGeometry 10, 2, 20
        material = new THREE.MeshLambertMaterial(color: 0xFF0000)

        @mesh = new THREE.Mesh( geometry, material )
        @model = opts.model

        subgeometry = new THREE.CubeGeometry 2, 2, 10
        @submesh = new THREE.Mesh( subgeometry, material )
        @submesh.position.set(0, 0, 10)
        @mesh.add @submesh

        if @model
            @model.on 'change:orientation', @update, this
            @update()

    update: ->
        if @model
            if value = @model.get('orientation')
                @mesh.rotation.fromArray value.toArray()

            if value = @model.get('position')
                @mesh.position.fromArray value.toArray()
