import QtQuick
import "../theme"

Canvas {
    id: radar
    property var dna: ({})
    property string breachState: "idle"
    implicitWidth: 240
    implicitHeight: 240
    onDnaChanged: requestPaint()
    onBreachStateChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        var c = getContext("2d");
        c.reset();
        var x = width / 2, y = height / 2, r = Math.min(width, height) / 2 - 30;
        var vals = [dna.length || 0, dna.unpredictability || 0, dna.patternSafety || 0, dna.characterMix || 0, breachState === "clear" ? 100 : 0];
        var known = breachState === "clear" || breachState === "compromised";
        function point(i, scale) {
            var a = -Math.PI / 2 + i * Math.PI * 2 / 5;
            return [x + Math.cos(a) * r * scale, y + Math.sin(a) * r * scale];
        }
        c.lineWidth = 1;
        c.strokeStyle = Theme.border;
        for (var k = 1; k <= 4; k++) {
            c.beginPath();
            for (var j = 0; j < 5; j++) {
                var p = point(j, k / 4);
                if (j === 0)
                    c.moveTo(p[0], p[1]);
                else
                    c.lineTo(p[0], p[1]);
            }
            c.closePath();
            c.stroke();
        }
        for (var i = 0; i < 5; i++) {
            var edge = point(i, 1);
            c.beginPath();
            c.moveTo(x, y);
            c.lineTo(edge[0], edge[1]);
            c.stroke();
            var label = point(i, 1.2);
            c.fillStyle = Theme.muted;
            c.font = '11px "Segoe UI"';
            c.textAlign = "center";
            c.fillText(String(i + 1), label[0], label[1] + 4);
        }
        c.strokeStyle = Theme.accent;
        c.fillStyle = Qt.rgba(0.25, 0.78, 1, 0.12);
        c.lineWidth = 2;
        c.beginPath();
        for (var n = 0; n < (known ? 5 : 4); n++) {
            var p2 = point(n, vals[n] / 100);
            if (n === 0)
                c.moveTo(p2[0], p2[1]);
            else
                c.lineTo(p2[0], p2[1]);
        }
        if (known) {
            c.closePath();
            c.fill();
        }
        c.stroke();
        if (!known) {
            var u = point(4, 1);
            c.fillStyle = Theme.warning;
            c.font = 'bold 16px "Segoe UI"';
            c.fillText("?", u[0], u[1] + 5);
        }
    }
}
