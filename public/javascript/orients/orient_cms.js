// Generated by CoffeeScript 1.6.3
(function() {
  var OrientCmsItemView, OrientCmsView, _ref, _ref1,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  this.OrientCms = (function() {
    function OrientCms(opts) {
      this._pushGlobalBool = __bind(this._pushGlobalBool, this);
      var globalModel,
        _this = this;
      this.options = opts || {};
      this.server = opts.server;
      globalModel = new Backbone.Model({
        orientationValue: 0,
        visualize: true,
        blink: false,
        tempo: false,
        gain: false,
        global: true
      });
      this.view = new OrientCmsView({
        collection: opts.clients
      });
      document.body.appendChild(this.view.el);
      this.globalItemView = new OrientCmsItemView({
        model: globalModel
      });
      this.view.$el.prepend(this.globalItemView.el);
      $(this.globalItemView.el).addClass('global');
      opts.clients.on('change:highlighted', function(model, value, obj) {
        if (value === true) {
          return this.each(function(m) {
            if (m.cid !== model.cid) {
              return m.set({
                highlighted: false
              });
            }
          });
        }
      });
      globalModel.on('change:targetOrientationValue', function(model, val, obj) {
        return _this.view.collection.each(function(clientModel) {
          return clientModel.set({
            globalTargetOrientationValue: val
          });
        });
      });
      this.view.collection.on('change:globalTargetOrientationValue', function(model, val, obj) {
        if (model.get('customTargetOrientationValue') === true) {
          return;
        }
        return model.set({
          targetOrientationValue: val
        });
      });
      this.view.collection.on('add', function(model) {
        model.set({
          targetOrientationValue: globalModel.get('orientationValue')
        });
        return model.set({
          blink: globalModel.get('blink'),
          visualize: globalModel.get('visualize'),
          tempo: globalModel.get('tempo'),
          gain: globalModel.get('gain')
        });
      });
      _.each(['visualize', 'blink', 'tempo', 'gain'], function(prop) {
        globalModel.on('change:' + prop, function(model, val, obj) {
          return _this._pushGlobalBool(prop, val);
        });
        _this.view.collection.on('change:' + prop + 'CustomValue', function(model, val, obj) {
          if (val !== true) {
            return model.set(prop, globalModel.get(prop));
          }
        });
        return _this.view.collection.on('change:' + prop, function(model, val, obj) {
          var data;
          data = {
            sessionId: model.id
          };
          data[prop] = val;
          return _this.server.emit('orient-config', data);
        });
      });
      this.view.collection.on('change:targetOrientationValue', function(model, value, obj) {
        return _this.server.emit('orient-config', {
          sessionId: model.id,
          targetOrientationValue: value
        });
      });
    }

    OrientCms.prototype._pushGlobalBool = function(prop, val) {
      var _this = this;
      return this.view.collection.each(function(clientModel) {
        if (clientModel.get(prop + 'CustomValue') !== true) {
          return clientModel.set(prop, val);
        }
      });
    };

    return OrientCms;

  })();

  OrientCmsView = (function(_super) {
    __extends(OrientCmsView, _super);

    function OrientCmsView() {
      _ref = OrientCmsView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    OrientCmsView.prototype.tagName = 'ul';

    OrientCmsView.prototype.className = 'orient-cms-view';

    OrientCmsView.prototype.initialize = function() {
      var _this = this;
      if (this.collection) {
        this.collection.each(function(model) {
          return _this._addItemView(model);
        });
        this.collection.on('add', function(model) {
          return _this._addItemView(model);
        });
        return this.collection.on('remove', function(model) {
          if (model.cmsView) {
            return model.cmsView.remove();
          }
        });
      }
    };

    OrientCmsView.prototype._addItemView = function(model) {
      var view;
      view = new OrientCmsItemView({
        model: model
      });
      model.cmsView = view;
      $(view.el).addClass('client');
      return this.$el.append(view.el);
    };

    return OrientCmsView;

  })(Backbone.View);

  OrientCmsItemView = (function(_super) {
    __extends(OrientCmsItemView, _super);

    function OrientCmsItemView() {
      _ref1 = OrientCmsItemView.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    OrientCmsItemView.prototype.tagName = 'li';

    OrientCmsItemView.prototype.className = 'orient-cms-item-view';

    OrientCmsItemView.prototype.events = {
      'mouseover': '_onHover',
      'mousedown #target input': '_onCustomTarget',
      'mousemove #target input': '_onCustomTargetUpdate',
      'click #target #reset': '_onResetCustomTarget',
      'change #visualize select': '_onBoolControlChange',
      'change #blink select': '_onBoolControlChange',
      'change #tempo select': '_onBoolControlChange',
      'change #gain select': '_onBoolControlChange'
    };

    OrientCmsItemView.prototype.initialize = function() {
      var resetHtml;
      this.$el.append('<p id="orientation"></p>');
      this.$el.append('<p id="position"></p>');
      if (this.model.get('global') === true) {
        resetHtml = '';
      } else {
        resetHtml = '<a href="#" id="reset">reset</a>';
      }
      this.$el.append('<p id="target"><span id="display">0</span><input type="range" value="0" min="0" max="360" />' + resetHtml + '</p>');
      this._appendBoolControl('visualize');
      this._appendBoolControl('blink');
      this._appendBoolControl('tempo');
      this._appendBoolControl('gain');
      this.updateValues();
      if (this.model) {
        return this.model.on('change', this.updateValues, this);
      }
    };

    OrientCmsItemView.prototype._appendBoolControl = function(propName) {
      var global_option;
      if (this.model && this.model.get('global')) {
        global_option = '';
      } else {
        global_option = '<option value="global">Use Global</option>';
      }
      return this.$el.append('<p id="' + propName + '"><select>' + global_option + '<option value="1">On</option><option value="0">Off</option></select></p>');
    };

    OrientCmsItemView.prototype._updateBoolControl = function(propName) {
      var lineEl, resetEl;
      lineEl = this.$el.find('#' + propName);
      if (this.model.get(propName) === true) {
        lineEl.addClass('enabled').removeClass('disabled');
      } else {
        lineEl.addClass('disabled').removeClass('enabled');
      }
      resetEl = lineEl.find('#reset');
      if (this.model.get('global') !== true && resetEl.length > 0) {
        if (this.model.get(propName + 'CustomValue') === true) {
          return resetEl.show();
        } else {
          return resetEl.hide();
        }
      }
    };

    OrientCmsItemView.prototype.updateValues = function() {
      var targetVal, val;
      if (!this.model) {
        return;
      }
      if (val = this.model.get('orientation')) {
        this.$el.find('p#orientation').text(_.map(val.toArray(), function(angle) {
          return Math.floor(angle / Math.PI * 180);
        }).join(', '));
      }
      if (val = this.model.get('position')) {
        this.$el.find('p#position').text(_.map(val.toArray(), function(str) {
          return str.toString().substring(0, 5);
        }).join(', '));
      }
      targetVal = this.model.get('targetOrientationValue') || 0;
      this.$el.find('p#target #display').text(targetVal);
      this.$el.find('p#target input').val(targetVal);
      this._updateBoolControl('blink');
      this._updateBoolControl('visualize');
      this._updateBoolControl('tempo');
      this._updateBoolControl('gain');
      if (this.model.get('highlighted') === true) {
        return this.$el.addClass('highlighted');
      } else {
        return this.$el.removeClass('highlighted');
      }
    };

    OrientCmsItemView.prototype._onHover = function(evt) {
      return this.model.set({
        highlighted: true
      });
    };

    OrientCmsItemView.prototype._onCustomTarget = function(evt) {
      return this.model.set({
        customTargetOrientationValue: true
      });
    };

    OrientCmsItemView.prototype._onCustomTargetUpdate = function(evt) {
      if (this.model.get('customTargetOrientationValue') !== true) {
        return;
      }
      return this.model.set({
        targetOrientationValue: $(event.target).val()
      });
    };

    OrientCmsItemView.prototype._onResetCustomTarget = function(evt) {
      evt.preventDefault();
      this.model.set({
        customTargetOrientationValue: false
      });
      return this.model.set({
        targetOrientationValue: this.model.get('globalTargetOrientationValue')
      });
    };

    OrientCmsItemView.prototype._onBoolControlChange = function(evt) {
      var el, id, val;
      el = $(evt.target);
      id = el.parent().prop('id');
      val = el.val();
      this.model.set(id + 'CustomValue', val !== 'global');
      if (val !== 'global') {
        return this.model.set(id, val === '1');
      }
    };

    return OrientCmsItemView;

  })(Backbone.View);

}).call(this);
