import Foundation

enum BackgroundPlay {
    // Makes the page believe it is always visible so YouTube Music doesn't pause
    // itself when the app is minimized, and exposes remember/resume helpers
    // that the native side calls around backgrounding.
    static let script = """
    (function () {
      if (window.__moBg) return;
      window.__moBg = true;

      try {
        var def = function (name, value) {
          Object.defineProperty(document, name, { configurable: true, get: function () { return value; } });
        };
        def('hidden', false);
        def('webkitHidden', false);
        def('visibilityState', 'visible');
        def('webkitVisibilityState', 'visible');
      } catch (e) {}

      ['visibilitychange', 'webkitvisibilitychange'].forEach(function (ev) {
        document.addEventListener(ev, function (e) { e.stopImmediatePropagation(); }, true);
        window.addEventListener(ev, function (e) { e.stopImmediatePropagation(); }, true);
      });

      var wasPlaying = false;
      window.__moRemember = function () {
        var v = document.querySelector('video');
        wasPlaying = !!(v && !v.paused);
      };
      window.__moResume = function () {
        var v = document.querySelector('video');
        if (wasPlaying && v && v.paused) {
          var p = v.play();
          if (p && p.catch) p.catch(function () {});
        }
      };
    })();
    """
}
