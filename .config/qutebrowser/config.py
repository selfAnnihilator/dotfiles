"""
qutebrowser config — Noctalia theme integration

Themed with Noctalia, a matugen-based dynamic color scheme for the Niri compositor.
Noctalia extracts a Material You palette from the current wallpaper and writes it to
~/.config/noctalia/colors.json. This config reads that file on startup and applies
the palette to the completion popup, statusbar, tabs, and hints.

The startPage (startup.html) is themed separately via startPage/colors.css, which
noctalia generates from its own template (see ~/.config/noctalia/user-templates.toml).

To re-apply colors after a wallpaper change: run :config-source inside qutebrowser.
"""

config.load_autoconfig(False)

import json
import os

noctalia_colors_path = os.path.expanduser("~/.config/noctalia/colors.json")

if os.path.exists(noctalia_colors_path):
    with open(noctalia_colors_path) as f:
        n = json.load(f)

    c.colors.completion.fg = n["mOnSurface"]
    c.colors.completion.odd.bg = n["mSurface"]
    c.colors.completion.even.bg = n["mSurface"]
    c.colors.completion.category.bg = n["mSurfaceVariant"]
    c.colors.completion.category.fg = n["mPrimary"]
    c.colors.completion.item.selected.bg = n["mPrimary"]
    c.colors.completion.item.selected.fg = n["mOnPrimary"]
    c.colors.completion.match.fg = n["mTertiary"]

    c.colors.statusbar.normal.bg = n["mSurface"]
    c.colors.statusbar.normal.fg = n["mOnSurface"]
    c.colors.statusbar.insert.bg = n["mSecondary"]
    c.colors.statusbar.insert.fg = n["mOnSecondary"]
    c.colors.statusbar.command.bg = n["mSurfaceVariant"]
    c.colors.statusbar.command.fg = n["mOnSurface"]

    c.colors.tabs.bar.bg = n["mSurface"]
    c.colors.tabs.even.bg = n["mSurface"]
    c.colors.tabs.odd.bg = n["mSurface"]
    c.colors.tabs.even.fg = n["mOnSurfaceVariant"]
    c.colors.tabs.odd.fg = n["mOnSurfaceVariant"]
    c.colors.tabs.selected.even.bg = n["mPrimary"]
    c.colors.tabs.selected.odd.bg = n["mPrimary"]
    c.colors.tabs.selected.even.fg = n["mOnPrimary"]
    c.colors.tabs.selected.odd.fg = n["mOnPrimary"]

    c.colors.hints.bg = n["mSurfaceVariant"]
    c.colors.hints.fg = n["mOnSurface"]
    c.colors.hints.match.fg = n["mPrimary"]
    c.hints.border = "1px solid " + n["mPrimary"]


# set Dark-Mode
# config.set("colors.webpage.darkmode.enabled", True)

# Which cookies to accept. With QtWebEngine, this setting also controls
# other features with tracking capabilities similar to those of cookies;
# including IndexedDB, DOM storage, filesystem API, service workers, and
# AppCache. Note that with QtWebKit, only `all` and `never` are
# supported as per-domain values. Setting `no-3rdparty` or `no-
# unknown-3rdparty` per-domain on QtWebKit will have the same effect as
# `all`. If this setting is used with URL patterns, the pattern gets
# applied to the origin/first party URL of the page making the request,
# not the request URL. With QtWebEngine 5.15.0+, paths will be stripped
# from URLs, so URL patterns using paths will not match. With
# QtWebEngine 5.15.2+, subdomains are additionally stripped as well, so
# you will typically need to set this setting for `example.com` when the
# cookie is set on `somesubdomain.example.com` for it to work properly.
# To debug issues with this setting, start qutebrowser with `--debug
# --logfilter network --debug-flag log-cookies` which will show all
# cookies being set.
# Type: String
# Valid values:
#   - all: Accept all cookies.
#   - no-3rdparty: Accept cookies from the same origin only. This is known to break some sites, such as GMail.
#   - no-unknown-3rdparty: Accept cookies from the same origin only, unless a cookie is already set for the domain. On QtWebEngine, this is the same as no-3rdparty.
#   - never: Don't accept cookies at all.
config.set('content.cookies.accept', 'all', 'chrome-devtools://*')

# Which cookies to accept. With QtWebEngine, this setting also controls
# other features with tracking capabilities similar to those of cookies;
# including IndexedDB, DOM storage, filesystem API, service workers, and
# AppCache. Note that with QtWebKit, only `all` and `never` are
# supported as per-domain values. Setting `no-3rdparty` or `no-
# unknown-3rdparty` per-domain on QtWebKit will have the same effect as
# `all`. If this setting is used with URL patterns, the pattern gets
# applied to the origin/first party URL of the page making the request,
# not the request URL. With QtWebEngine 5.15.0+, paths will be stripped
# from URLs, so URL patterns using paths will not match. With
# QtWebEngine 5.15.2+, subdomains are additionally stripped as well, so
# you will typically need to set this setting for `example.com` when the
# cookie is set on `somesubdomain.example.com` for it to work properly.
# To debug issues with this setting, start qutebrowser with `--debug
# --logfilter network --debug-flag log-cookies` which will show all
# cookies being set.
# Type: String
# Valid values:
#   - all: Accept all cookies.
#   - no-3rdparty: Accept cookies from the same origin only. This is known to break some sites, such as GMail.
#   - no-unknown-3rdparty: Accept cookies from the same origin only, unless a cookie is already set for the domain. On QtWebEngine, this is the same as no-3rdparty.
#   - never: Don't accept cookies at all.
config.set('content.cookies.accept', 'all', 'devtools://*')

# Value to send in the `Accept-Language` header. Note that the value
# read from JavaScript is always the global value.
# Type: String
config.set('content.headers.accept_language', '', 'https://matchmaker.krunker.io/*')

# User agent to send.  The following placeholders are defined:  *
# `{os_info}`: Something like "X11; Linux x86_64". * `{webkit_version}`:
# The underlying WebKit version (set to a fixed value   with
# QtWebEngine). * `{qt_key}`: "Qt" for QtWebKit, "QtWebEngine" for
# QtWebEngine. * `{qt_version}`: The underlying Qt version. *
# `{upstream_browser_key}`: "Version" for QtWebKit, "Chrome" for
# QtWebEngine. * `{upstream_browser_version}`: The corresponding
# Safari/Chrome version. * `{upstream_browser_version_short}`: The
# corresponding Safari/Chrome   version, but only with its major
# version. * `{qutebrowser_version}`: The currently running qutebrowser
# version.  The default value is equal to the default user agent of
# QtWebKit/QtWebEngine, but with the `QtWebEngine/...` part removed for
# increased compatibility.  Note that the value read from JavaScript is
# always the global value.
# Type: FormatString
config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}; rv:145.0) Gecko/20100101 Firefox/145.0', 'https://accounts.google.com/*')

# User agent to send.  The following placeholders are defined:  *
# `{os_info}`: Something like "X11; Linux x86_64". * `{webkit_version}`:
# The underlying WebKit version (set to a fixed value   with
# QtWebEngine). * `{qt_key}`: "Qt" for QtWebKit, "QtWebEngine" for
# QtWebEngine. * `{qt_version}`: The underlying Qt version. *
# `{upstream_browser_key}`: "Version" for QtWebKit, "Chrome" for
# QtWebEngine. * `{upstream_browser_version}`: The corresponding
# Safari/Chrome version. * `{upstream_browser_version_short}`: The
# corresponding Safari/Chrome   version, but only with its major
# version. * `{qutebrowser_version}`: The currently running qutebrowser
# version.  The default value is equal to the default user agent of
# QtWebKit/QtWebEngine, but with the `QtWebEngine/...` part removed for
# increased compatibility.  Note that the value read from JavaScript is
# always the global value.
# Type: FormatString
# config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} (KHTML, like Gecko) {qt_key}/{qt_version} {upstream_browser_key}/{upstream_browser_version_short} Safari/{webkit_version}', 'https://gitlab.gnome.org/*')

# Load images automatically in web pages.
# Type: Bool
config.set('content.images', True, 'chrome-devtools://*')

# Load images automatically in web pages.
# Type: Bool
config.set('content.images', True, 'devtools://*')

# Enable JavaScript.
# Type: Bool
config.set('content.javascript.enabled', True, 'chrome-devtools://*')

# Enable JavaScript.
# Type: Bool
config.set('content.javascript.enabled', True, 'devtools://*')

# Enable JavaScript.
# Type: Bool
config.set('content.javascript.enabled', True, 'chrome://*/*')

# Enable JavaScript.
# Type: Bool
config.set('content.javascript.enabled', True, 'qute://*/*')

# Allow locally loaded documents to access remote URLs.
# Type: Bool
config.set('content.local_content_can_access_remote_urls', True, 'file:///home/abhi/.local/share/qutebrowser/userscripts/*')

# Allow locally loaded documents to access other local URLs.
# Type: Bool
config.set('content.local_content_can_access_file_urls', False, 'file:///home/abhi/.local/share/qutebrowser/userscripts/*')

# Allow websites to show notifications.
# Type: BoolAsk
# Valid values:
#   - true
#   - false
#   - ask
config.set('content.notifications.enabled', True, 'https://www.reddit.com')

# Allow websites to show notifications.
# Type: BoolAsk
# Valid values:
#   - true
#   - false
#   - ask
config.set('content.notifications.enabled', True, 'https://www.youtube.com')

# Directory to save downloads to. If unset, a sensible OS-specific
# default is used.
# Type: Directory
c.downloads.location.directory = '~/Downloads'



# Allow websites to show notifications.
# Type: BoolAsk
# Valid values:
#   - true
#   - false
#   - ask
config.set('content.notifications.enabled', True, 'https://www.reddit.com')

# Allow websites to show notifications.
# Type: BoolAsk
# Valid values:
#   - true
#   - false
#   - ask
config.set('content.notifications.enabled', True, 'https://www.youtube.com')

# Directory to save downloads to. If unset, a sensible OS-specific
# default is used.
# Type: Directory
c.downloads.location.directory = '~/Downloads'

#Startup Page
startpage = "file:///home/abhi/.config/qutebrowser/startPage/startup.html"
c.url.start_pages = [startpage]
c.url.default_page = startpage

c.tabs.title.format = "{audio}{current_title}"
c.fonts.web.size.default = 14

# tabs and statusbar default visibility
c.tabs.show = "never"
c.statusbar.show = "never"

c.url.searchengines = {
    'DEFAULT': 'https://duckduckgo.com/?q={}', 
    '!am': 'https://www.amazon.com/s?k={}', 
    '!aw': 'https://wiki.archlinux.org/?search={}', 
    '!goog': 'https://www.google.com/search?q={}', 
    '!hoog': 'https://hoogle.haskell.org/?hoogle={}', 
    '!re': 'https://www.reddit.com/r/{}', 
    '!ub': 'https://www.urbandictionary.com/define.php?term={}', 
    '!wiki': 'https://en.wikipedia.org/wiki/{}', 
    '!yt': 'https://www.youtube.com/results?search_query={}',
    '!git': 'https://www.github.com/results?search_query={}'
}

c.completion.open_categories = ['searchengines', 'quickmarks', 'bookmarks', 'history', 'filesystem']

# config.load_autoconfig(F) # load settings done via the gui

c.auto_save.session = False # save tabs on quit/restart
c.session.lazy_restore = True

# hint configuration
c.hints.chars = "arstneio"
c.hints.min_chars = 1

c.hints.padding = {"top": 2, "bottom": 2, "left": 4, "right": 4}

c.hints.scatter = True
c.hints.auto_follow = "unique-match"
# c.hints.selectors = {
#     "all": [
#         "a[href]",          # links only
#         "button",           # buttons
#         "input:not([type=hidden])",  # visible inputs
#         "textarea",
#         "select"
#     ]
# }

# keybinding changes
config.bind('=', 'cmd-set-text -s :open')
# config.bind('h', 'history')
config.bind('cc', 'hint images spawn sh -c "cliphist link {hint-url}"')
config.bind('cs', 'cmd-set-text -s :config-source')
config.bind('M', 'hint links spawn mpv {hint-url}')
config.bind('Z', 'hint links spawn st -e youtube-dl {hint-url}')
config.bind('t', 'cmd-set-text -s :open -t')
config.bind('xb', 'config-cycle statusbar.show always never')
config.bind('xt', 'config-cycle tabs.show always never')
config.bind('xx', 'config-cycle statusbar.show always never;; config-cycle tabs.show always never')
config.bind('T', 'hint links tab')
config.bind('pP', 'open -- {primary}')
config.bind('pp', 'open -- {clipboard}')
config.bind('pt', 'open -t -- {clipboard}')
config.bind('qm', 'macro-record')
config.bind('<ctrl-y>', 'spawn --userscript ytdl.sh')
config.bind('tT', 'config-cycle tabs.position top left')
config.bind('gJ', 'tab-move +')
config.bind('gK', 'tab-move -')
config.bind('gm', 'tab-move')
config.bind(',p', 'spawn --userscript pass-type-password')
config.bind(',u', 'spawn --userscript pass-type-username')
config.bind(',t', 'spawn --userscript translate')
config.bind(',h', 'history')
config.bind(',ba', 'bookmark-add')

# unbind
# config.unbind('h')

# dark mode setup
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = 'lightness-cielab'
c.colors.webpage.darkmode.policy.images = 'never'
config.set('colors.webpage.darkmode.enabled', False, 'file://*')

# styles, cosmetics
# c.content.user_stylesheets = ["~/.config/qutebrowser/styles/youtube-tweaks.css"]
c.tabs.padding = {'top': 5, 'bottom': 5, 'left': 9, 'right': 9}
c.tabs.indicator.width = 0 # no tab indicators
# c.window.transparent = True # apparently not needed
c.tabs.width = '7%'

# fonts
c.fonts.default_family = []
c.fonts.default_size = '13pt'
c.fonts.web.family.fixed = 'monospace'
c.fonts.web.family.sans_serif = 'monospace'
c.fonts.web.family.serif = 'monospace'
c.fonts.web.family.standard = 'monospace'


# privacy - adjust these settings based on your preference
# config.set("completion.cmd_history_max_items", 0)
# config.set("content.private_browsing", True)
config.set("content.webgl", False, "*")
config.set("content.canvas_reading", False)
config.set("content.geolocation", False)
config.set("content.webrtc_ip_handling_policy", "default-public-interface-only")
config.set("content.cookies.accept", "all")
config.set("content.cookies.store", True)
# config.set("content.javascript.enabled", False) # tsh keybind to toggle
c.content.local_content_can_access_remote_urls = True

# Adblocking info -->
# For yt ads: place the greasemonkey script yt-ads.js in your greasemonkey folder (~/.config/qutebrowser/greasemonkey).
# The script skips through the entire ad, so all you have to do is click the skip button.
# Yeah it's not ublock origin, but if you want a minimal browser, this is a solution for the tradeoff.
# You can also watch yt vids directly in mpv, see qutebrowser FAQ for how to do that.
# If you want additional blocklists, you can get the python-adblock package, or you can uncomment the ublock lists here.
c.content.blocking.enabled = True
c.content.blocking.method = 'adblock' # uncomment this if you install python-adblock
# c.content.blocking.adblock.lists = [
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2022.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2023.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2024.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-cookies.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-others.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt"]

# Reduce disk cache overhead
c.qt.args = ["--disable-logging", "--disable-extensions"]

# Enable GPU acceleration
c.qt.args += ["--enable-gpu-rasterization", "--ignore-gpu-blocklist"]

c.messages.timeout = 5000
c.downloads.remove_finished = 5000
