// Generated by CoffeeScript 1.6.3
(function() {
  var Blinker, OrientModel, Orienter, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(document).ready(function() {
    return window.orienter = new Orienter();
  });

  OrientModel = (function(_super) {
    __extends(OrientModel, _super);

    function OrientModel() {
      this._updateAudio = __bind(this._updateAudio, this);
      this._updateDistance = __bind(this._updateDistance, this);
      _ref = OrientModel.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    OrientModel.prototype.initialize = function() {
      this.on('change:targetOrientationValue', this._updateDistance);
      this.on('change:orientationValue', this._updateDistance);
      this.on('change:tempo', this._updateAudio);
      return this.on('change:gain', this._updateAudio);
    };

    OrientModel.prototype._updateDistance = function() {
      var current, dist, target;
      target = this.get('targetOrientationValue');
      current = this.get('orientationValue');
      if (target === void 0 || current === void 0) {
        return;
      }
      if (target > 180) {
        target = 180 - (target - 180);
      }
      if (current > 180) {
        current = 180 - (current - 180);
      }
      dist = target - current;
      return this.set({
        orientationDistance: dist
      });
    };

    OrientModel.prototype._updateAudio = function() {
      var audioEnabled;
      audioEnabled = this.get('tempo') === true || this.get('gain') === true;
      return this.set({
        audioEnabled: audioEnabled
      });
    };

    return OrientModel;

  })(Backbone.Model);

  Blinker = (function() {
    function Blinker(opts) {
      this.two = opts.two;
      this.enabled = false;
      this.timeout = 180;
      this.lastBlinkFrame = 0;
      this.visible = false;
    }

    Blinker.prototype.enable = function(_enable) {
      this.enabled = _enable;
      return this.showBlinker(_enable);
    };

    Blinker.prototype.update = function(frameCount) {
      var nextBlink;
      if (!this.enabled) {
        return;
      }
      nextBlink = this.lastBlinkFrame + this.timeout;
      if (frameCount >= nextBlink) {
        this.lastBlinkFrame = frameCount;
        return this.showBlinker(!this.visible);
      }
    };

    Blinker.prototype.showBlinker = function(_show) {
      if (_show) {
        if (!this.blinkCircle) {
          this.blinkCircle || (this.blinkCircle = this.two.makeCircle(this.two.width / 2, this.two.height / 2, 50));
          this.blinkCircle.noStroke();
          this.blinkCircle.fill = 'white';
        }
        this.blinkCircle.opacity = 0.5;
      } else {
        if (this.blinkCircle) {
          this.blinkCircle.opacity = 0.0;
        }
      }
      return this.visible = _show;
    };

    return Blinker;

  })();

  Orienter = (function() {
    function Orienter(opts) {
      this.onDeviceAccel = __bind(this.onDeviceAccel, this);
      this.onDeviceMotion = __bind(this.onDeviceMotion, this);
      this.update = __bind(this.update, this);
      var _this = this;
      this.options = opts || {};
      this.server = io.connect('/orienter');
      this.model = new OrientModel({
        targetOrientationValue: 0,
        blink: false,
        visualize: true
      });
      this.server.on('sessionId', function(data) {
        _this.sessionId = data;
        return _this.log('SessionID', data);
      });
      this.server.on('welcome', function(data) {
        if (data.tracking) {
          return _this.setupTracking();
        } else {
          return _this.log('status', 'Connected. Motion tracking off.');
        }
      });
      this.server.on('reset', function() {
        return _this.setupTracking(false);
      });
      this.server.on('toggleMotion', function(data) {
        if (data.motion) {
          return _this.setupTracking();
        } else {
          return _this.setupTracking(false);
        }
      });
      this.server.on('orient-config', function(data) {
        if (data.sessionId !== _this.sessionId) {
          return;
        }
        return _this.model.set(data);
      });
      this.model.on('change:targetOrientationValue', function(model, val, obj) {
        _this.log('target-direction', val);
        return _this._updateVisualizerRotation();
      });
      this.model.on('change:orientationValue', function(model, val, obj) {
        _this.log('current-direction', val);
        return _this._updateVisualizerRotation();
      });
      this.model.on('change:visualize', function(model, val, obj) {
        if (val === true) {
          return _this.loadVisualizer();
        } else {
          return _this.loadVisualizer(false);
        }
      });
      this.model.on('change:blink', function(model, val, obj) {
        if (_this.blinker) {
          return _this.blinker.enable(val);
        }
      });
      this.model.on('change:orientationDistance', function(model, val, obj) {
        _this.log('direction-delta', Math.abs(val));
        if (_this.blinker) {
          _this.blinker.timeout = val;
        }
        if (_this.orienterAudio && _this.model.get('tempo') === true) {
          _this.orienterAudio.applyTempo(1.0 + val * 0.03);
        }
        if (_this.orienterAudio && _this.model.get('gain') === true) {
          return _this.orienterAudio.applyGain(1.0 - val / 180);
        }
      });
      this.model.on('change:gain', function(model, val, obj) {
        if (_this.orienterAudio) {
          if (val === true) {
            return _this.orienterAudio.applyGain(1.0 - model.get('orientationDistance') / 180);
          } else {
            return _this.orienterAudio.applyGain(1.0);
          }
        }
      });
      this.model.on('change:audioEnabled', function(model, val, obj) {
        _this.orienterAudio || (_this.orienterAudio = _this.orienterAudio());
        return _this.orienterAudio.start(val);
      });
      this.twoEl = document.getElementById('anim');
      this.two = new Two({
        fullscreen: true
      }).appendTo(this.twoEl);
      this.two.bind('update', this.update);
      this.orienterAudio = new OrienterAudio();
      $('#start a').click(function(evt) {
        evt.preventDefault();
        $('#start').hide();
        return _this.start();
      });
    }

    Orienter.prototype.start = function() {
      this.loadVisualizer();
      this.blinker = new Blinker({
        two: this.two
      });
      this.orienterAudio.start();
      return this.two.play();
    };

    Orienter.prototype.update = function(frameCount) {
      if (this.blinker) {
        return this.blinker.update(frameCount);
      }
    };

    Orienter.prototype.loadVisualizer = function(_load) {
      if (_load === false) {
        this.two.remove(this.rotator, this.c1);
        this.rotator = void 0;
        this.c1 = void 0;
        return this.c2 = void 0;
      } else {
        this.c1 || (this.c1 = this.two.makeCircle(0, 0, Math.min(this.two.width * 0.3, this.two.height * 0.3)));
        this.c1.translation.set(this.two.width / 2, this.two.height / 2);
        this.c1.noFill();
        this.c1.stroke = 'white';
        this.c1.opacity = 0.5;
        this.c1.linewidth = 2;
        this.c2 || (this.c2 = this.two.makeCircle(0, -Math.min(this.two.width * 0.3, this.two.height * 0.3), 10));
        this.c2.fill = 'red';
        this.c2.noStroke();
        this.rotator || (this.rotator = this.two.makeGroup(this.c2));
        return this.rotator.translation.set(this.two.width / 2, this.two.height / 2);
      }
    };

    Orienter.prototype._updateVisualizerRotation = function() {
      if (!this.rotator || !this.model) {
        return;
      }
      return this.rotator.rotation = ((this.model.get('orientationValue') || 0) - (this.model.get('targetOrientationValue') || 0)) / 180 * Math.PI;
    };

    Orienter.prototype.setupTracking = function(_setup) {
      this.setupMotionListener(_setup);
      this.setupAccelListener(_setup);
      if (_setup === true || _setup === void 0) {
        return this.log('status', 'Now tracking motion.');
      } else {
        return this.log('status', 'Motion tracking off.');
      }
    };

    Orienter.prototype.setupMotionListener = function(_setup) {
      if (_setup === true || _setup === void 0) {
        return window.addEventListener('deviceorientation', this.onDeviceMotion);
      } else {
        return window.removeEventListener('deviceorientation', this.onDeviceMotion);
      }
    };

    Orienter.prototype.setupAccelListener = function(_setup) {
      if (_setup === true || _setup === void 0) {
        return window.addEventListener('devicemotion', this.onDeviceAccel);
      } else {
        return window.removeEventListener('devicemotion', this.onDeviceAccel);
      }
    };

    Orienter.prototype.onDeviceMotion = function(event) {
      this.server.emit('motionData', {
        alpha: event.alpha,
        beta: event.beta,
        gamma: event.gamma
      });
      this.log('orientation', _.map([event.alpha, event.beta, event.gamma], function(val) {
        return Math.floor(val);
      }).join(', '));
      return this.model.set({
        orientationValue: Math.floor(event.alpha || 0)
      });
    };

    Orienter.prototype.onDeviceAccel = function(event) {
      this.server.emit('accelerationData', {
        rotationRate: event.rotationRate,
        acceleration: event.acceleration,
        accelerationIncludingGravity: event.accelerationIncludingGravity
      });
      return this.log('acceleration', _.map([event.accelerationIncludingGravity.x, event.accelerationIncludingGravity.y, event.accelerationIncludingGravity.z], function(val) {
        return Math.floor(val);
      }).join(', '));
    };

    Orienter.prototype.updateDistance = function() {
      var a, b, dist;
      if (this.currentVal === void 0 || this.targetVal === void 0) {
        return;
      }
      if (this.rotator) {
        this.rotator.rotation = (this.currentVal - this.targetVal) / 180 * Math.PI;
      }
      a = this.targetVal;
      if (this.targetVal > 180) {
        a = 180 - (this.targetVal - 180);
      }
      b = this.currentVal;
      if (this.currentVal > 180) {
        b = 180 - (this.currentVal - 180);
      }
      dist = a - b;
      return this.log('direction-delta', Math.abs(dist));
    };

    Orienter.prototype._logsContainer = function() {
      this.$_logsContainerEl || (this.$_logsContainerEl = $('#logs'));
      if (this.$_logsContainerEl.length === 0) {
        $('body').append('<div id="logs"></div>');
        this.$_logsContainerEl = $('#logs');
      }
      return this.$_logsContainerEl;
    };

    Orienter.prototype._logValueElFor = function(subject) {
      var logField, logsContainer;
      logsContainer = this._logsContainer();
      logField = logsContainer.find('#' + subject);
      if (logField.length === 0) {
        logsContainer.append('<p id="' + subject + '"><span class="label">' + subject + '</span><span class="value"></span></p>');
        logField = logsContainer.find('#' + subject);
      }
      return logField.find('.value');
    };

    Orienter.prototype.log = function(subject, message) {
      var el;
      if (message === void 0) {
        message = subject;
        subject = void 0;
      }
      if (subject === void 0) {
        console.log(message);
        return;
      }
      el = this._logValueElFor(subject);
      return el.text(message);
    };

    return Orienter;

  })();

}).call(this);
