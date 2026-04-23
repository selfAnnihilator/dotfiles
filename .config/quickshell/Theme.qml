pragma Singleton
import QtQuick

QtObject {
    // ── Active theme name ──────────────────────────────────────────────────
    property string currentTheme: "gruvbox"

    function setTheme(name) {
        currentTheme = name
    }

    function nextTheme() {
        var names = themes.map(t => t.name)
        var idx = names.indexOf(currentTheme)
        currentTheme = names[(idx + 1) % names.length]
    }

    // ── Theme list (for the picker) ────────────────────────────────────────
    readonly property var themes: [
        {
            name: "gruvbox",
            label: "Gruvbox",
            background:   "#282828",
            surface:      "#3c3836",
            surfaceHover: "#504945",
            highlight:    "#665c54",
            accent:       "#d79921",
            accentAlt:    "#b57614",
            text:         "#ebdbb2",
            subtext:      "#a89984",
            danger:       "#cc241d",
            dangerBg:     "#3c1c1c",
            dangerHover:  "#4e2020",
            border:       "#44a89984"
        },
        {
            name: "catppuccin",
            label: "Catppuccin",
            background:   "#1e1e2e",
            surface:      "#313244",
            surfaceHover: "#45475a",
            highlight:    "#585b70",
            accent:       "#cba6f7",
            accentAlt:    "#89b4fa",
            text:         "#cdd6f4",
            subtext:      "#a6adc8",
            danger:       "#f38ba8",
            dangerBg:     "#2c1e2e",
            dangerHover:  "#3d2040",
            border:       "#44a6adc8"
        },
        {
            name: "tokyonight",
            label: "Tokyo Night",
            background:   "#1a1b26",
            surface:      "#24283b",
            surfaceHover: "#2e3248",
            highlight:    "#3b4261",
            accent:       "#7aa2f7",
            accentAlt:    "#bb9af7",
            text:         "#c0caf5",
            subtext:      "#565f89",
            danger:       "#f7768e",
            dangerBg:     "#2a1520",
            dangerHover:  "#3d1e2e",
            border:       "#44565f89"
        },
        {
            name: "nord",
            label: "Nord",
            background:   "#2e3440",
            surface:      "#3b4252",
            surfaceHover: "#434c5e",
            highlight:    "#4c566a",
            accent:       "#88c0d0",
            accentAlt:    "#81a1c1",
            text:         "#eceff4",
            subtext:      "#d8dee9",
            danger:       "#bf616a",
            dangerBg:     "#2d1f22",
            dangerHover:  "#3d2528",
            border:       "#444c566a"
        },
        {
            name: "rosepine",
            label: "Rosé Pine",
            background:   "#191724",
            surface:      "#1f1d2e",
            surfaceHover: "#26233a",
            highlight:    "#403d52",
            accent:       "#eb6f92",
            accentAlt:    "#f6c177",
            text:         "#e0def4",
            subtext:      "#6e6a86",
            danger:       "#eb6f92",
            dangerBg:     "#2a1020",
            dangerHover:  "#3d1530",
            border:       "#446e6a86"
        },
        {
            name: "everforest",
            label: "Everforest",
            background:   "#272e33",
            surface:      "#2e383c",
            surfaceHover: "#374145",
            highlight:    "#414b50",
            accent:       "#a7c080",
            accentAlt:    "#83c092",
            text:         "#d3c6aa",
            subtext:      "#859289",
            danger:       "#e67e80",
            dangerBg:     "#2c1e1e",
            dangerHover:  "#3d2828",
            border:       "#44859289"
        }
    ]

    // ── Resolved colors (read these everywhere in the UI) ──────────────────
    readonly property var _t: {
        for (var i = 0; i < themes.length; i++) {
            if (themes[i].name === currentTheme) return themes[i]
        }
        return themes[0]
    }

    readonly property color background:   _t.background
    readonly property color surface:      _t.surface
    readonly property color surfaceHover: _t.surfaceHover
    readonly property color highlight:    _t.highlight
    readonly property color accent:       _t.accent
    readonly property color accentAlt:    _t.accentAlt
    readonly property color text:         _t.text
    readonly property color subtext:      _t.subtext
    readonly property color danger:       _t.danger
    readonly property color dangerBg:     _t.dangerBg
    readonly property color dangerHover:  _t.dangerHover
    readonly property color border:       _t.border
}
