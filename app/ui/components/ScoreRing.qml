import QtQuick
import "../theme"

Item {
    id: ring
    property real score: 0
    property string classification: "Waiting"
    property color tone: Theme.accent
    property real displayedScore: score
    implicitWidth: 240
    implicitHeight: 250
    Behavior on displayedScore {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
    onDisplayedScoreChanged: canvas.requestPaint()
    onToneChanged: canvas.requestPaint()
    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var x = width / 2, y = height / 2 - 12, r = Math.min(width / 2 - 14, height / 2 - 35);
            ctx.lineWidth = 8;
            ctx.strokeStyle = Theme.border;
            ctx.beginPath();
            ctx.arc(x, y, r, 0, Math.PI * 2);
            ctx.stroke();
            ctx.strokeStyle = ring.tone;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(x, y, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0, ring.displayedScore) / 100);
            ctx.stroke();
        }
    }
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -12
        spacing: 4
        AppText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(ring.displayedScore)
            font.pixelSize: 55
            font.weight: Font.DemiBold
        }
        AppText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "OUT OF 100"
            color: Theme.muted
            font.pixelSize: 10
            font.letterSpacing: 1.3
        }
    }
    AppText {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: ring.classification.toUpperCase()
        color: ring.tone
        font.weight: Font.DemiBold
        font.pixelSize: 12
        font.letterSpacing: 1
    }
}
