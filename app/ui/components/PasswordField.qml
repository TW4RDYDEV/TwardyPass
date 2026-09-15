import QtQuick
import QtQuick.Controls
import "../theme"

Rectangle {
    id: shell

    property alias text: input.text
    readonly property int characterCount: (text.match(/[\uD800-\uDBFF][\uDC00-\uDFFF]|[\s\S]/g) || []).length
    property string placeholderText: ""
    property bool reveal: !bridge.maskByDefault
    property bool passwordMode: true
    property bool readOnly: false
    property int maximumLength: 8192

    implicitHeight: 58
    radius: 13
    color: Theme.background
    border.width: input.activeFocus ? 1.5 : 1
    border.color: input.activeFocus ? Theme.accent : Theme.border
    clip: true

    Behavior on border.color {
        ColorAnimation {
            duration: 120
        }
    }

    function clear() {
        input.text = "";
        viewport.contentX = 0;
        input.deselect();
        reveal = false;
    }

    function ensureCursorVisible() {
        if (readOnly || viewport.width <= 0)
            return;
        var cursorX = input.x + input.cursorRectangle.x + input.cursorRectangle.width;
        var leftEdge = viewport.contentX + 14;
        var rightEdge = viewport.contentX + viewport.width - 14;
        var maxX = Math.max(0, viewport.contentWidth - viewport.width);

        if (cursorX > rightEdge)
            viewport.contentX = Math.min(maxX, cursorX - viewport.width + 14);
        else if (cursorX < leftEdge)
            viewport.contentX = Math.max(0, cursorX - 14);
    }

    Flickable {
        id: viewport
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 82
        anchors.topMargin: 3
        anchors.bottomMargin: 7
        clip: true
        interactive: contentWidth > width
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: Math.max(width, input.width + 20)
        contentHeight: height

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -2
            visible: input.text.length === 0
            text: shell.placeholderText
            color: Theme.muted
            font.pixelSize: 14
        }

        TextInput {
            id: input
            objectName: shell.objectName + "Input"
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -2
            width: Math.max(viewport.width - 24, contentWidth + 4)
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: "#041018"
            font.pixelSize: 14
            font.family: shell.readOnly ? "Consolas" : "Segoe UI"
            maximumLength: shell.maximumLength * 2
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            onTextEdited: bridge.touchActivity()
            readOnly: shell.readOnly
            selectByMouse: true
            echoMode: shell.passwordMode && !shell.reveal ? TextInput.Password : TextInput.Normal
            onCursorRectangleChanged: shell.ensureCursorVisible()
            onTextChanged: {
                var points = text.match(/[\uD800-\uDBFF][\uDC00-\uDFFF]|[\s\S]/g) || [];
                if (points.length > shell.maximumLength)
                    text = points.slice(0, shell.maximumLength).join("");
                var maxX = Math.max(0, viewport.contentWidth - viewport.width);
                if (viewport.contentX > maxX)
                    viewport.contentX = maxX;
                shell.ensureCursorVisible();
            }
        }

        ScrollBar.horizontal: ScrollBar {
            id: horizontalBar
            policy: viewport.contentWidth > viewport.width + 1 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            height: 6
            contentItem: Rectangle {
                implicitHeight: 6
                radius: 3
                color: horizontalBar.pressed ? Theme.accent : "#3A536C"
            }
            background: Rectangle {
                implicitHeight: 6
                radius: 3
                color: "#142232"
            }
        }
    }

    AppButton {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 68
        text: shell.reveal ? "Hide" : "Show"
        onClicked: {
            shell.reveal = !shell.reveal;
            bridge.touchActivity();
        }
    }
    Connections {
        target: bridge
        function onSettingsChanged() {
            shell.reveal = !bridge.maskByDefault;
        }
        function onSensitiveCleared() {
            shell.clear();
        }
    }
}
