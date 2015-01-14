// Generated by CoffeeScript 1.6.3
(function() {
  var Orienter,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $(document).ready(function() {
    return window.orienter = new Orienter();
  });

  Orienter = (function() {
    function Orienter(opts) {
      this.onDeviceAccel = __bind(this.onDeviceAccel, this);
      this.onDeviceMotion = __bind(this.onDeviceMotion, this);
      var _this = this;
      this.options = opts || {};
      this.server = io.connect('/orienter');
      this.currentVal = 0;
      this.targetVal = 0;
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
        if (data.targetOrientationValue) {
          _this.targetVal = data.targetOrientationValue;
          _this.log('target-direction', _this.targetVal);
          return _this.updateDistance();
        }
      });
      this.twoEl = document.getElementById('anim');
      this.two = new Two({
        fullscreen: true
      }).appendTo(this.twoEl);
      this.c1 = this.two.makeCircle(0, 0, Math.min(this.two.width * 0.3, this.two.height * 0.3));
      this.c1.translation.set(this.two.width / 2, this.two.height / 2);
      this.c1.noFill();
      this.c1.stroke = 'white';
      this.c1.opacity = 0.5;
      this.c1.linewidth = 2;
      this.circle = this.two.makeCircle(0, -Math.min(this.two.width * 0.3, this.two.height * 0.3), 10);
      this.circle.fill = 'red';
      this.circle.noStroke();
      this.rotator = this.two.makeGroup(this.circle);
      this.rotator.translation.set(this.two.width / 2, this.two.height / 2);
      this.two.play();
    }

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
        return Math.floor(val / Math.PI * 180);
      }).join(', '));
      this.currentVal = Math.floor(event.alpha || 0);
      this.log('current-value', this.currentVal);
      return this.updateDistance();
    };

    Orienter.prototype.onDeviceAccel = function(event) {
      this.server.emit('accelerationData', {
        rotationRate: event.rotationRate,
        acceleration: event.acceleration,
        accelerationIncludingGravity: event.accelerationIncludingGravity
      });
      return this.log('acceleration', _.map([event.accelerationIncludingGravity.x, event.accelerationIncludingGravity.y, event.accelerationIncludingGravity.z], function(val) {
        return Math.floor(val / Math.PI * 180);
      }).join(', '));
    };

    Orienter.prototype.updateDistance = function() {
      var a, b, dist;
      if (this.currentVal === void 0 || this.targetVal === void 0) {
        return;
      }
      this.rotator.rotation = (this.currentVal - this.targetVal) / 180 * Math.PI;
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
