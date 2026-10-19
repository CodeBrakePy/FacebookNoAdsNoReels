import Foundation

enum ReelBlocker {
    /// Used by the native navigation delegate (full page loads).
    static func isReelPath(_ path: String) -> Bool {
        let p = path.lowercased()
        return p.hasPrefix("/reel/") || p.hasPrefix("/reels") ||
               p.hasPrefix("/share/r/") || p.hasPrefix("/watch/reels") ||
               p.range(of: #"^/[^/]+/reels(/|$)"#, options: .regularExpression) != nil
    }

    /// Injected into every page. Facebook is a single-page app, so this also
    /// handles in-page navigation (pushState), hides Reels links, and removes
    /// Reels posts and the "Reels and short videos" shelf from the feed.
    /// Selectors are fragile: Facebook changes its markup often.
    static let script = #"""
    (function () {
      if (window.__noReels) return;
      window.__noReels = true;

      function isReelPath(p) {
        return /^\/(reel|reels)(\/|$)/.test(p) || /^\/share\/r\//.test(p) ||
               /^\/watch\/reels/.test(p) || /^\/[^\/]+\/reels(\/|$)/.test(p);
      }
      function check() { if (isReelPath(location.pathname)) location.replace('/'); }
      check();

      // Catch in-app (SPA) navigation
      ['pushState', 'replaceState'].forEach(function (m) {
        var orig = history[m];
        history[m] = function () {
          var r = orig.apply(this, arguments);
          setTimeout(check, 0);
          return r;
        };
      });
      window.addEventListener('popstate', check);

      // Swallow taps on any Reels link
      document.addEventListener('click', function (e) {
        var a = e.target.closest && e.target.closest('a[href]');
        if (!a) return;
        try {
          var u = new URL(a.href, location.href);
          if (/facebook\.com$/.test(u.hostname) && isReelPath(u.pathname)) {
            e.preventDefault(); e.stopPropagation();
          }
        } catch (_) {}
      }, true);

      // Hide Reels links/tabs immediately via CSS
      var style = document.createElement('style');
      style.textContent =
        'a[href*="/reel/"], a[href*="/reels"], a[href*="/watch/reels"], a[href*="/share/r/"]' +
        '{ display: none !important; }';
      (document.head || document.documentElement).appendChild(style);

      var HEADING = /^reels( and short videos)?$/i;
      var POST = '[role="article"], [data-pagelet^="FeedUnit"], article';
      var AD_LABEL = /^(ad|sponsored|paid partnership)$/i;

      // Fallback when the post has no article-like wrapper: climb until we reach
      // an element that is one of several tall siblings (i.e. a card in the feed).
      function findCard(label) {
        var n = label;
        while (n.parentElement && n !== document.body) {
          var par = n.parentElement, tall = 0;
          for (var i = 0; i < par.children.length; i++) {
            if (par.children[i].offsetHeight > 150) tall++;
          }
          if (tall >= 3 && n.offsetHeight > 200) return n;
          n = par;
        }
        return null;
      }

      function hideAds() {
        // 1) Posts that carry Facebook's ad-info links
        document.querySelectorAll('a[href*="/ads/about"], a[href*="ad_id="], a[href*="/ads/preferences"]').forEach(function (a) {
          var post = a.closest(POST);
          if (post && post.style.display !== 'none') post.style.display = 'none';
        });
        // 2) Any text node that is exactly "Ad" / "Sponsored" near the top of a card
        var walker = document.createTreeWalker(document.documentElement, NodeFilter.SHOW_TEXT);
        var node;
        while ((node = walker.nextNode())) {
          var el = node.parentElement;
          if (!el || el.dataset.nrAd) continue;
          if (!AD_LABEL.test((node.nodeValue || '').trim())) continue;
          var card = el.closest(POST) || findCard(el);
          if (!card) continue;               // layout not ready yet, try again next sweep
          el.dataset.nrAd = '1';
          var gap = el.getBoundingClientRect().top - card.getBoundingClientRect().top;
          if (gap >= 0 && gap < 160) card.style.display = 'none';
        }
      }

      function sweep() {
        hideAds();
        // Feed posts that are Reels
        document.querySelectorAll('a[href*="/reel/"], a[href*="/reels/"]').forEach(function (a) {
          var post = a.closest('[role="article"], [data-pagelet^="FeedUnit"], [data-mcomponent="MContainer"]');
          if (post && post.style.display !== 'none') post.style.display = 'none';
        });
        // "Reels and short videos" shelf
        document.querySelectorAll('h2, h3, [role="heading"]').forEach(function (h) {
          if (HEADING.test((h.textContent || '').trim())) {
            var box = h.closest('[data-pagelet], [role="article"], section') ||
                      (h.parentElement && h.parentElement.parentElement &&
                       h.parentElement.parentElement.parentElement);
            if (box && box.style.display !== 'none') box.style.display = 'none';
          }
        });
      }

      var queued = false;
      function schedule() {
        if (queued) return;
        queued = true;
        requestAnimationFrame(function () { queued = false; sweep(); });
      }
      new MutationObserver(schedule).observe(document.documentElement,
        { childList: true, subtree: true });
      document.addEventListener('DOMContentLoaded', sweep);
    })();
    """#
}
