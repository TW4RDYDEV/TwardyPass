pragma Singleton
import QtQuick

QtObject {
    readonly property color background: "#070A0F"
    readonly property color sidebar: "#090E15"
    readonly property color surface: "#0C1118"
    readonly property color raised: "#111822"
    readonly property color border: "#1A2533"
    readonly property color text: "#F5F7FA"
    readonly property color muted: "#9AA7B8"
    readonly property color accent: "#41C8FF"
    readonly property color secondary: "#7C5CFF"
    readonly property color success: "#53E6A0"
    readonly property color warning: "#FFBE55"
    readonly property color danger: "#FF5F6D"
    function severity(value) {
        return value === "danger" ? danger : value === "warning" ? warning : value === "good" ? success : muted;
    }
}
