var server = io.connect('/dancer');
var $h1 = $('h1');

server.on('welcome', function(data) {
  if (data.tracking) {
    startTrack();
  } else {
    $h1.text('Connected. Motion tracking off.');
  }
});

server.on('reset', function() {
  stopTrack();
});

server.on('toggleMotion', function(data) {
  if (data.motion) {
    startTrack();
  } else {
    stopTrack();
  }
});

var startTrack = function() {
  $h1.text('Now tracking motion.');
  initMotionListener();
  initAccelListener();
};

var stopTrack = function() {
  $h1.text('Motion tracking off.');
  removeMotionListener();
  removeAccelListener();
};

var initMotionListener = function() {
  window.addEventListener('deviceorientation', boundDeviceMotion);
};

var removeMotionListener = function() {
  window.removeEventListener('deviceorientation', boundDeviceMotion);
};

var onDeviceMotion = function(event) {
  server.emit('motionData', {alpha: event.alpha, beta: event.beta, gamma: event.gamma,});
};

var boundDeviceMotion = onDeviceMotion.bind(this);

var initAccelListener = function(){
  window.addEventListener('devicemotion', boundOnAccel);
}

var removeAccelListener = function(){
  window.removeEventListener('devicemotion', boundOnAccel);
}

var onAccel = function(data){
  server.emit('accelerationData', {
    rotationRate: data.rotationRate,
    acceleration: data.acceleration,
    accelerationIncludingGravity: data.accelerationIncludingGravity
  });
}

var boundOnAccel = onAccel.bind(this);


