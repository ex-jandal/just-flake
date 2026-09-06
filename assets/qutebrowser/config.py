# import dracula.draw
# from theme import tampilan
# tampilan(c)

# dracula.draw.blood(c, {
#     'spacing': {
#         'vertical': 1,
#         'horizontal': 2
#     }
# })
#


c.auto_save.session = True
c.session.lazy_restore = True
c.completion.shrink = True
c.completion.use_best_match = True
c.content.notifications.presenter = "libnotify"
c.content.fullscreen.window = True
c.content.geolocation = False
c.content.autoplay = False


# adblock
c.content.blocking.enabled = True
c.content.blocking.hosts.block_subdomains = True
c.content.blocking.method = "both"
c.content.tls.certificate_errors = "block"

c.content.blocking.hosts.lists = [
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
    # 'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=1&mimetype=plaintext&_=223428',
    "https://adaway.org/hosts.txt",
    # 'https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts',
]
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2021.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/legacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt",
    "https://raw.githubusercontent.com/brave/adblock-lists/master/brave-lists/brave-social.txt",
    "https://raw.githubusercontent.com/reek/anti-adblock-killer/master/anti-adblock-killer-filters.txt",
]

# download manager
c.downloads.position = "bottom"
c.downloads.location.remember = True
c.downloads.location.suggestion = "both"
c.downloads.remove_finished = 30000


#  ╭──────────────────────────────────────────────────────────╮
#  │ Useragent for mobile view and desktop                    │
#  ╰──────────────────────────────────────────────────────────╯
desktop_ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; Xbox; Xbox One) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36 Edge/167D0DCEF5E2D"

# mobile_ua = "Mozilla/5.0 (Android 4.4; Mobile; rv:109.0) Gecko/109.0 Firefox/109.0"
mobile_ua = "Mozilla/5.0 (Linux; Android 13; SM-S901B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36"
# config.set('content.headers.user_agent', old_chrome_ua, 'steamdb.info')
# config.set('content.headers.user_agent', old_chrome_ua, 'www.nginx.com')
# config.set('content.headers.user_agent', old_chrome_ua, 'gitlab.com/users/sign_in')

mobile_url = [
    "facebook.com",
    "x.facebook.com",
    "www.facebook.com",
    "m.facebook.com",
]
# for url in mobile_url:
# config.set("content.headers.user_agent", mobile_ua, url)
config.set("content.headers.user_agent", desktop_ua, "global")

config.set("content.images", True, "chrome-devtools://*")
config.set("content.cookies.accept", "all", "chrome-devtools://*")
config.set("content.images", True, "devtools://*")


c.content.pdfjs = True


c.editor.command = ["alacritty", "-e", "nvim", "{file}"]
c.fileselect.single_file.command = [
    "alacritty",
    "-e",
    "ranger",
    "--choosefile={}",
]
c.fileselect.multiple_files.command = [
    "alacritty",
    "-e",
    "ranger",
    "--choosefiles={}",
]
c.fileselect.folder.command = ["alacritty", "-e", "ranger", "--choosedir={}"]
c.input.insert_mode.auto_load = False
c.scrolling.smooth = True


c.statusbar.show = "always"
c.statusbar.position = "bottom"
c.statusbar.widgets = [
    "progress",
    "keypress",
    "url",
    "scroll",
    "history",
    "tabs",
]
c.tabs.favicons.show = "always"
c.tabs.background = True
c.tabs.last_close = "ignore"
c.tabs.position = "top"
c.tabs.show = "multiple"
c.tabs.favicons.scale = 1
c.tabs.indicator.width = 10


c.url.start_pages = str("qute://start")

# Dark Mode
c.colors.webpage.preferred_color_scheme = "dark"
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = "never"


c.fonts.default_family = "JetBrainsMono Nerd Font"
c.fonts.default_size = "11pt"
c.url.default_page = c.url.start_pages

# Search Enginge
c.url.searchengines = {
    "DEFAULT": "https://google.com/search?q={}",
    "a": "https://wiki.archlinux.org/?search={}",
    "g": "http://www.google.com/search?hl=en&source=hp&ie=ISO-8859-l&q={}",
    "y": "https://invidious.snopyta.org/search?q={}",
    "gh": "https://github.com/search?q={}",
    "gf": "https://greasyfork.org/en/scripts?filter_locale=0&q={}",
    "red": "https://libreddit.spike.codes/r/popular/search?q={}&restrict_sr=on",
    "aur": "https://aur.archlinux.org/packages?O=0&K={}",
    "d": "https://duckduckgo.com/?q={}&hps=1",
    "npm": "https://www.npmjs.com/search?q={}",
    "npms": "https://npms.io/search?q={}",
    "pa": "https://packagist.org/?query={}",
    "fdroid": "https://search.f-droid.org/?q={}",
    "apkmirror": "https://www.apkmirror.com/?s={}",
    "tliden": "https://translate.google.com/?sl=id&tl=en&text={}&op=translate",
    "tlenid": "https://translate.google.com/?sl=en&tl=id&text={}&op=translate",
}


c.qt.environ = {"NODE_PATH": "/home/deve/.local/share/pnpm/global/5/node_modules"}

# Spawn with URL
config.bind("C", "spawn --userscript container-open")
config.bind("<Alt-c>", "set-cmd-text -s :spawn --userscript container-open")
config.bind("<Alt-f>", "hint links userscript container-open")
# config.bind("<Alt-b>", "spawn --userscript qute-bitwarden")

config.bind(
    "<Alt-Shift-u>",
    "spawn --userscript qute-keepassxc --key ABC1234",
    mode="insert",
)
config.bind("pw", "spawn --userscript qute-keepassxc --key ABC1234", mode="normal")
config.bind("X", "spawn --userscript add-nextcloud-bookmarks")
config.bind(",dark", "spawn --userscript dark-toogle")


config.bind(
    "<Alt-Shift-u>",
    "spawn --userscript qute-keepassxc --key 5AF6D616CE6A96E0071D5D94F8A9C4E5735C3E59",
    mode="insert",
)
config.bind(
    "pw",
    "spawn --userscript qute-keepassxc --key 5AF6D616CE6A96E0071D5D94F8A9C4E5735C3E59",
    mode="normal",
)


# alias
c.aliases = {
    "q": "close",
    "qa": "quit",
    "w": "session-save",
    "wq": "quit --save",
    "wqa": "quit --save",
    "bitwarden": "spawn --userscript qute-bitwarden",
    "container-open": "spawn --userscript container-open",
    "container-ls": "spawn --userscript container-ls",
    "container-add": "spawn --userscript container-add",
    "container-rm": "spawn --userscript container-rm",
    "nextcloud-bookmarks-import": "spawn --userscript import-nextcloud-bookmarks",
}

c.bindings.commands = {
    "normal": {
        "d": "scroll page-down",
        "u": "scroll page-up",
        "<Ctrl-D>": "tab-close",
        "<Ctrl-U>": "undo",
    }
}

config.source("gruvbox.py")

config.load_autoconfig()
