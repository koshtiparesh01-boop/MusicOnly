import Foundation

enum AdBlock {

    // Network-level rules (WKContentRuleList). Blocks ad servers and YouTube's ad endpoints.
    static let rulesJSON = """
    [
      { "trigger": { "url-filter": "doubleclick\\\\.net" },            "action": { "type": "block" } },
      { "trigger": { "url-filter": "googlesyndication\\\\.com" },      "action": { "type": "block" } },
      { "trigger": { "url-filter": "googleadservices\\\\.com" },       "action": { "type": "block" } },
      { "trigger": { "url-filter": "google-analytics\\\\.com" },       "action": { "type": "block" } },
      { "trigger": { "url-filter": "adservice\\\\.google\\\\." },       "action": { "type": "block" } },
      { "trigger": { "url-filter": "youtube\\\\.com/pagead/" },        "action": { "type": "block" } },
      { "trigger": { "url-filter": "youtube\\\\.com/api/stats/ads" },  "action": { "type": "block" } },
      { "trigger": { "url-filter": "youtube\\\\.com/ptracking" },       "action": { "type": "block" } },
      { "trigger": { "url-filter": "youtube\\\\.com/get_midroll_info" },"action": { "type": "block" } },
      { "trigger": { "url-filter": "youtube\\\\.com/youtubei/v1/player/ad_break" }, "action": { "type": "block" } },
      { "trigger": { "url-filter": "static\\\\.doubleclick\\\\.net" },  "action": { "type": "block" } }
    ]
    """

    // Page-level script: hides ad UI, auto-clicks "Skip", and fast-forwards any ad
    // that is served inline with the music stream.
    static let script = """
    (function () {
      if (window.__musicOnlyAdBlock) return;
      window.__musicOnlyAdBlock = true;

      // Hide promo / ad containers.
      var style = document.createElement('style');
      style.textContent = [
        'ytmusic-mealbar-promo-renderer',
        'ytmusic-statement-banner-renderer',
        'ytmusic-popup-container ytmusic-upsell-dialog-renderer',
        '.ytp-ad-module', '.ytp-ad-overlay-container',
        '.video-ads', '#player-ads', 'ytd-ad-slot-renderer',
        'ytmusic-player-bar .ad-badge', '.ad-interrupting'
      ].join(',') + '{display:none !important;}';
      (document.head || document.documentElement).appendChild(style);

      function clickSkip() {
        var sels = ['.ytp-ad-skip-button', '.ytp-skip-ad-button',
                    '.ytp-ad-skip-button-modern', 'button[aria-label^="Skip"]'];
        sels.forEach(function (s) {
          document.querySelectorAll(s).forEach(function (b) { try { b.click(); } catch (e) {} });
        });
      }

      function isAdPlaying() {
        return !!(document.querySelector('.ad-showing, .ad-interrupting, #movie_player.ad-showing') ||
                  document.querySelector('ytmusic-player-bar .ad-badge'));
      }

      function handleAd() {
        clickSkip();
        if (!isAdPlaying()) return;
        var v = document.querySelector('video');
        if (v && isFinite(v.duration) && v.duration > 0) {
          v.muted = true;
          v.currentTime = v.duration;   // jump to the end of the ad
          v.playbackRate = 16;
        }
      }

      function restoreIfNeeded() {
        if (isAdPlaying()) return;
        var v = document.querySelector('video');
        if (v && v.playbackRate === 16) { v.playbackRate = 1; v.muted = false; }
      }

      setInterval(function () { handleAd(); restoreIfNeeded(); }, 300);
      new MutationObserver(handleAd).observe(document.documentElement,
        { childList: true, subtree: true, attributes: true, attributeFilter: ['class'] });
    })();
    """
}
