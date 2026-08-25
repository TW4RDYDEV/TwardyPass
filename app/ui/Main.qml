// TwardyPass UI build: 2026-08-24-fixed-compare-overflow
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    width: 1440
    height: 900
    minimumWidth: 1180
    minimumHeight: 720
    visible: true
    title: "TwardyPass — Password Security Workbench"
    color: "#070B11"

    property color bg: "#070B11"
    property color sidebar: "#090E15"
    property color card: "#0E1622"
    property color card2: "#111C2A"
    property color border: "#1D2A39"
    property color textMain: "#F5F7FA"
    property color textMuted: "#8D9AAA"
    property color accent: "#35C2FF"
    property color accent2: "#7B61FF"
    property color good: "#54E6A0"
    property color warning: "#FFBF5B"
    property color danger: "#FF5F6D"

    property int currentPage: 0
    property int score: 0
    property string classification: "Waiting"
    property string scoreColor: "#8D9AAA"
    property real entropy: 0
    property int passwordLength: 0
    property real guessesLog10: 0
    property var findings: []
    property var recommendations: []
    property var dna: ({"length":0,"unpredictability":0,"patternSafety":0,"characterMix":0})
    property var attack: ({"onlineThrottled":"—","onlineUnthrottled":"—","offlineSlow":"—","offlineFast":"—"})
    property string breachState: "idle"
    property string breachMessage: "Not checked"
    property int breachCount: 0

    property string generatedValue: ""
    property real generatedEntropy: 0
    property bool passphraseMode: false
    property int clipboardSeconds: 30

    function analyzeNow() {
        var result = bridge.analyzePassword(passwordInput.text, contextInput.text)
        score = result.score
        classification = result.classification
        scoreColor = result.color
        entropy = result.entropy
        passwordLength = result.length
        guessesLog10 = result.guesses_log10
        findings = result.findings
        recommendations = result.recommendations
        dna = result.dna
        attack = result.attack
        breachState = "idle"
        breachMessage = "Not checked"
        breachCount = 0
    }

    function generateNow() {
        if (passphraseMode) {
            var p = bridge.generatePassphrase(passphraseWords.value, separatorBox.currentText)
            generatedValue = p.password
            generatedEntropy = p.entropy
        } else {
            var r = bridge.generatePassword(
                        passwordSize.value,
                        upperCheck.checked,
                        lowerCheck.checked,
                        digitCheck.checked,
                        symbolCheck.checked,
                        ambiguousCheck.checked)
            generatedValue = r.password
            generatedEntropy = r.entropy
        }
    }

    function analyzeAllComparisons() {
        compareCardA.analyze()
        compareCardB.analyze()
        compareCardC.analyze()
    }

    function clearCompare() {
        compareCardA.clear()
        compareCardB.clear()
        compareCardC.clear()
        compareRevealAll.checked = false
    }

    function bestCompareScore() {
        return Math.max(compareCardA.result.score || 0,
                        compareCardB.result.score || 0,
                        compareCardC.result.score || 0)
    }

    function bestCompareText() {
        var best = bestCompareScore()
        if (!compareCardA.analyzed && !compareCardB.analyzed && !compareCardC.analyzed)
            return "Analyze candidates to compare them"

        var winners = []
        if (compareCardA.analyzed && (compareCardA.result.score || 0) === best)
            winners.push("A")
        if (compareCardB.analyzed && (compareCardB.result.score || 0) === best)
            winners.push("B")
        if (compareCardC.analyzed && (compareCardC.result.score || 0) === best)
            winners.push("C")

        return winners.length === 1
                ? "Candidate " + winners[0] + " currently scores highest"
                : "Top score tied: " + winners.join(", ")
    }

    function panicClear() {
        passwordInput.clear()
        contextInput.clear()
        root.clearCompare()
        generatedValue = ""
        generatedEntropy = 0
        score = 0
        classification = "Waiting"
        scoreColor = textMuted
        findings = []
        recommendations = []
        breachState = "idle"
        breachMessage = "Not checked"
        bridge.clearSensitiveClipboard()
        showToast("Sensitive data cleared", "Analyzer, comparison fields, generator output and matching clipboard content were cleared.")
    }

    function showToast(title, message) {
        toastTitle.text = title
        toastMessage.text = message
        toast.opacity = 1
        toastTimer.restart()
    }

    Shortcut {
        sequence: "Ctrl+Shift+X"
        onActivated: root.panicClear()
    }

    Timer {
        id: analysisTimer
        interval: 180
        repeat: false
        onTriggered: root.analyzeNow()
    }

    Timer {
        id: toastTimer
        interval: 3200
        repeat: false
        onTriggered: toast.opacity = 0
    }

    Connections {
        target: bridge
        function onBreachStarted() {
            breachState = "checking"
            breachMessage = "Checking anonymized hash range…"
        }
        function onBreachFinished(result) {
            breachState = result.status
            breachMessage = result.message
            breachCount = result.count
        }
        function onToastRequested(title, message) {
            root.showToast(title, message)
        }
    }

    component Panel: Rectangle {
        color: root.card
        radius: 18
        border.width: 1
        border.color: root.border
    }

    component SectionTitle: Text {
        color: root.textMain
        font.pixelSize: 16
        font.weight: Font.DemiBold
    }

    component MutedText: Text {
        color: root.textMuted
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }

    component StyledButton: Button {
        id: control
        property bool primary: false
        property color buttonColor: primary ? root.accent : root.card2
        implicitHeight: 44
        leftPadding: 18
        rightPadding: 18
        font.pixelSize: 13
        font.weight: Font.DemiBold
        contentItem: Text {
            text: control.text
            color: control.primary ? "#041018" : root.textMain
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font: control.font
        }
        background: Rectangle {
            radius: 12
            color: control.down ? Qt.darker(control.buttonColor, 1.12)
                                : control.hovered ? Qt.lighter(control.buttonColor, 1.08)
                                                  : control.buttonColor
            border.width: control.primary ? 0 : 1
            border.color: root.border
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    component ToggleCheck: Item {
        id: toggle

        property string text: ""
        property bool checked: false

        implicitWidth: indicatorBox.width + 10 + labelText.implicitWidth
        implicitHeight: Math.max(24, labelText.implicitHeight)

        Rectangle {
            id: indicatorBox
            width: 20
            height: 20
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            radius: 6
            color: toggle.checked ? root.accent : (toggleMouse.containsMouse ? "#17283A" : root.card2)
            border.width: 1
            border.color: toggle.checked ? root.accent : (toggleMouse.containsMouse ? "#36536D" : root.border)

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: "✓"
                visible: toggle.checked
                color: "#041018"
                font.pixelSize: 13
                font.bold: true
            }
        }

        Text {
            id: labelText
            anchors.left: indicatorBox.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: toggle.text
            color: root.textMain
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggle.checked = !toggle.checked
        }
    }

    component StyledField: TextField {
        id: field
        color: root.textMain
        placeholderTextColor: "#586779"
        selectionColor: root.accent
        selectedTextColor: "#041018"
        font.pixelSize: 15
        leftPadding: 16
        rightPadding: 16
        implicitHeight: 50
        background: Rectangle {
            radius: 13
            color: "#0A121C"
            border.width: field.activeFocus ? 1.5 : 1
            border.color: field.activeFocus ? root.accent : root.border
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }
    }


    component ScrollablePasswordField: Rectangle {
        id: shell

        property alias text: input.text
        property string placeholderText: ""
        property bool reveal: false
        property bool passwordMode: true
        property bool readOnly: false
        property int maximumLength: 128

        implicitHeight: 58
        radius: 13
        color: "#0A121C"
        border.width: input.activeFocus ? 1.5 : 1
        border.color: input.activeFocus ? root.accent : root.border
        clip: true

        Behavior on border.color { ColorAnimation { duration: 120 } }

        function ensureCursorVisible() {
            if (readOnly || viewport.width <= 0)
                return

            var cursorX = input.x + input.cursorRectangle.x + input.cursorRectangle.width
            var leftEdge = viewport.contentX + 14
            var rightEdge = viewport.contentX + viewport.width - 14
            var maxX = Math.max(0, viewport.contentWidth - viewport.width)

            if (cursorX > rightEdge)
                viewport.contentX = Math.min(maxX, cursorX - viewport.width + 14)
            else if (cursorX < leftEdge)
                viewport.contentX = Math.max(0, cursorX - 14)
        }

        Flickable {
            id: viewport
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
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
                color: "#586779"
                font.pixelSize: 14
            }

            TextInput {
                id: input
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -2
                width: Math.max(viewport.width - 24, contentWidth + 4)
                color: root.textMain
                selectionColor: root.accent
                selectedTextColor: "#041018"
                font.pixelSize: 14
                font.family: shell.readOnly ? "Consolas" : "Segoe UI"
                maximumLength: shell.maximumLength
                readOnly: shell.readOnly
                selectByMouse: true
                echoMode: shell.passwordMode && !shell.reveal ? TextInput.Password : TextInput.Normal
                onCursorRectangleChanged: shell.ensureCursorVisible()
                onTextChanged: {
                    var maxX = Math.max(0, viewport.contentWidth - viewport.width)
                    if (viewport.contentX > maxX)
                        viewport.contentX = maxX
                    shell.ensureCursorVisible()
                }
            }

            ScrollBar.horizontal: ScrollBar {
                id: horizontalBar
                policy: viewport.contentWidth > viewport.width + 1 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                height: 6
                contentItem: Rectangle {
                    implicitHeight: 6
                    radius: 3
                    color: horizontalBar.pressed ? root.accent : "#3A536C"
                }
                background: Rectangle {
                    implicitHeight: 6
                    radius: 3
                    color: "#142232"
                }
            }
        }
    }

    component CompareCandidate: Column {
        id: candidate

        property string candidateName: "A"
        property var result: ({})
        property bool globalReveal: false
        property bool localReveal: false
        property bool analyzed: false

        spacing: 10

        function analyze() {
            if (!candidateInput.text.length) {
                result = ({})
                return
            }
            result = bridge.analyzePassword(candidateInput.text, "")
            analyzed = true
        }

        function clear() {
            candidateInput.text = ""
            result = ({})
            localReveal = false
            analyzed = false
        }

        Text {
            width: parent.width
            text: "CANDIDATE " + candidate.candidateName
            color: root.textMuted
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1
        }

        Row {
            width: parent.width
            height: 58
            spacing: 8

            ScrollablePasswordField {
                id: candidateInput
                width: parent.width - revealButton.width - parent.spacing
                height: parent.height
                placeholderText: "Candidate " + candidate.candidateName
                passwordMode: true
                reveal: candidate.globalReveal || candidate.localReveal
                maximumLength: 128
                onTextChanged: {
                    candidate.result = ({})
                    candidate.analyzed = false
                }
            }

            StyledButton {
                id: revealButton
                width: 74
                height: parent.height
                text: candidate.globalReveal ? "Shown" : (candidate.localReveal ? "Hide" : "Show")
                enabled: !candidate.globalReveal
                onClicked: candidate.localReveal = !candidate.localReveal
            }
        }

        Row {
            spacing: 8

            StyledButton {
                text: "Analyze " + candidate.candidateName
                primary: true
                enabled: candidateInput.text.length > 0
                onClicked: candidate.analyze()
            }

            StyledButton {
                text: "Clear"
                enabled: candidateInput.text.length > 0
                onClicked: candidate.clear()
            }
        }

        Panel {
            width: parent.width
            height: compareResultContent.implicitHeight + 36

            ColumnLayout {
                id: compareResultContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: candidate.result.classification || "Waiting"
                        color: candidate.result.color || root.textMuted
                        font.pixelSize: 16
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        visible: candidate.analyzed && (candidate.result.score || 0) === root.bestCompareScore()
                        implicitWidth: 72
                        implicitHeight: 24
                        radius: 12
                        color: "#10263A"
                        border.width: 1
                        border.color: "#1D506D"
                        Text {
                            anchors.centerIn: parent
                            text: "TOP SCORE"
                            color: root.accent
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                Text {
                    text: (candidate.result.score || 0) + "/100"
                    color: root.textMain
                    font.pixelSize: 36
                    font.bold: true
                }

                Metric {
                    label: "LENGTH"
                    value: (candidate.result.length || 0) + " chars"
                }

                Metric {
                    label: "ENTROPY"
                    value: (candidate.result.entropy || 0) + " bits"
                }
            }
        }
    }

    component Metric: Rectangle {
        property string label: "Metric"
        property string value: "—"
        Layout.fillWidth: true
        implicitHeight: 88
        radius: 14
        color: root.card2
        border.width: 1
        border.color: root.border
        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
            Text { text: parent.parent.label; color: root.textMuted; font.pixelSize: 11; font.letterSpacing: 0.8 }
            Text { text: parent.parent.value; color: root.textMain; font.pixelSize: 20; font.weight: Font.DemiBold; elide: Text.ElideRight; width: parent.width }
        }
    }

    component DnaRow: Column {
        property string label: "Metric"
        property int value: 0
        spacing: 7
        RowLayout {
            width: parent.width
            Text { text: parent.parent.label; color: root.textMuted; font.pixelSize: 12; Layout.fillWidth: true }
            Text { text: parent.parent.value; color: root.textMain; font.pixelSize: 12; font.weight: Font.DemiBold }
        }
        Rectangle {
            width: parent.width
            height: 7
            radius: 4
            color: "#162333"
            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, parent.parent.value)) / 100
                height: parent.height
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: root.accent2 }
                    GradientStop { position: 1; color: root.accent }
                }
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.bg

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 230
            color: root.sidebar
            border.width: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 34
                    spacing: 12
                    Rectangle {
                        width: 42
                        height: 42
                        radius: 13
                        gradient: Gradient {
                            GradientStop { position: 0; color: root.accent }
                            GradientStop { position: 1; color: root.accent2 }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "T"
                            color: "white"
                            font.pixelSize: 22
                            font.bold: true
                        }
                    }
                    Column {
                        Layout.fillWidth: true
                        Text { text: "TwardyPass"; color: root.textMain; font.pixelSize: 18; font.weight: Font.DemiBold }
                        Text { text: "SECURITY WORKBENCH"; color: root.textMuted; font.pixelSize: 9; font.letterSpacing: 1.1 }
                    }
                }

                Repeater {
                    model: ["Analyzer", "Generator", "Compare Lab", "Privacy"]
                    delegate: Button {
                        required property int index
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        Layout.bottomMargin: 8
                        leftPadding: 16
                        contentItem: Text {
                            text: modelData
                            color: root.currentPage === index ? root.textMain : root.textMuted
                            font.pixelSize: 13
                            font.weight: root.currentPage === index ? Font.DemiBold : Font.Normal
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 12
                            color: root.currentPage === index ? "#112333" : (parent.hovered ? "#0E1722" : "transparent")
                            border.width: root.currentPage === index ? 1 : 0
                            border.color: "#18384B"
                            Rectangle {
                                width: 3
                                height: 22
                                radius: 2
                                anchors.left: parent.left
                                anchors.leftMargin: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.accent
                                visible: root.currentPage === index
                            }
                        }
                        onClicked: root.currentPage = index
                    }
                }

                Item { Layout.fillHeight: true }

                Panel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 116
                    color: "#0B151F"
                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8
                        Row {
                            spacing: 8
                            Rectangle { width: 8; height: 8; radius: 4; color: root.good; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "LOCAL ANALYSIS"; color: root.good; font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
                        }
                        Text { text: "Passwords are not stored or logged."; color: root.textMuted; font.pixelSize: 11; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "Panic clear: Ctrl + Shift + X"; color: root.textMain; font.pixelSize: 10 }
                    }
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 230
            anchors.right: parent.right
            anchors.top: parent.top
            height: 76
            color: root.bg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 30
                anchors.rightMargin: 30
                Text {
                    text: root.currentPage === 0 ? "Password Security Analyzer"
                         : root.currentPage === 1 ? "Secure Generator"
                         : root.currentPage === 2 ? "Compare Lab"
                         : "Privacy Center"
                    color: root.textMain
                    font.pixelSize: 21
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: 152
                    implicitHeight: 32
                    radius: 16
                    color: "#0C1D18"
                    border.width: 1
                    border.color: "#17392E"
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle { width: 7; height: 7; radius: 4; color: root.good; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "PRIVACY ACTIVE"; color: root.good; font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
                    }
                }
            }
        }

        StackLayout {
            anchors.left: parent.left
            anchors.leftMargin: 230
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 76
            anchors.bottom: parent.bottom
            currentIndex: root.currentPage

            // ANALYZER
            ScrollView {
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: parent.width - 60
                    x: 30
                    spacing: 18

                    Panel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 166
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#101B29" }
                            GradientStop { position: 1; color: "#0D1520" }
                        }
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 10
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "ANALYZE A PASSWORD"; color: root.textMuted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.2; Layout.fillWidth: true }
                                Text { text: "100% local until you request a breach check"; color: root.textMuted; font.pixelSize: 11 }
                            }
                            StyledField {
                                id: passwordInput
                                Layout.fillWidth: true
                                placeholderText: "Enter a password to analyze"
                                maximumLength: 128
                                echoMode: revealPassword.checked ? TextInput.Normal : TextInput.Password
                                onTextChanged: analysisTimer.restart()
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                StyledField {
                                    id: contextInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    placeholderText: "Personal info to avoid (optional): name, username, company, year"
                                    font.pixelSize: 12
                                    onTextChanged: analysisTimer.restart()
                                }
                                ToggleCheck { id: revealPassword; text: "Show password" }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 18
                        rowSpacing: 18

                        Panel {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 330
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 22
                                spacing: 18
                                SectionTitle { text: "Overall Security" }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 172
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 156
                                        height: 156
                                        radius: 78
                                        color: "transparent"
                                        border.width: 10
                                        border.color: "#172434"
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 130
                                            height: 130
                                            radius: 65
                                            color: "#0B131D"
                                            border.width: 2
                                            border.color: root.scoreColor
                                            Behavior on border.color { ColorAnimation { duration: 250 } }
                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 2
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.score; color: root.textMain; font.pixelSize: 42; font.weight: Font.Bold }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "/ 100"; color: root.textMuted; font.pixelSize: 11 }
                                            }
                                        }
                                    }
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; text: root.classification.toUpperCase(); color: root.scoreColor; font.pixelSize: 15; font.bold: true; font.letterSpacing: 1.2 }
                                MutedText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "Pattern-aware scoring combines zxcvbn estimates with local structural checks." }
                            }
                        }

                        Panel {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 330
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 22
                                spacing: 18
                                RowLayout {
                                    Layout.fillWidth: true
                                    SectionTitle { text: "Security DNA"; Layout.fillWidth: true }
                                    Text { text: "LIVE"; color: root.accent; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1 }
                                }
                                DnaRow { Layout.fillWidth: true; label: "Length"; value: root.dna.length || 0 }
                                DnaRow { Layout.fillWidth: true; label: "Unpredictability"; value: root.dna.unpredictability || 0 }
                                DnaRow { Layout.fillWidth: true; label: "Pattern Safety"; value: root.dna.patternSafety || 0 }
                                DnaRow { Layout.fillWidth: true; label: "Character Mix"; value: root.dna.characterMix || 0 }
                                Item { Layout.fillHeight: true }
                                MutedText { Layout.fillWidth: true; text: "These are explanatory indicators, not guarantees of account security." }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        Metric { label: "LENGTH"; value: root.passwordLength + " chars" }
                        Metric { label: "ENTROPY EST."; value: root.entropy.toFixed(1) + " bits" }
                        Metric { label: "GUESS SPACE"; value: root.guessesLog10 > 0 ? "10^" + root.guessesLog10.toFixed(1) : "—" }
                        Metric { label: "BREACH STATUS"; value: breachState === "compromised" ? "FOUND" : breachState === "clear" ? "NOT FOUND" : breachState === "checking" ? "CHECKING…" : "NOT CHECKED" }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 18
                        rowSpacing: 18

                        Panel {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 315
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 12
                                RowLayout {
                                    Layout.fillWidth: true
                                    SectionTitle { text: "Findings"; Layout.fillWidth: true }
                                    Text { text: root.findings.length + " signals"; color: root.textMuted; font.pixelSize: 11 }
                                }
                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    spacing: 8
                                    model: root.findings
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: ListView.view.width
                                        height: 64
                                        radius: 12
                                        color: "#0A121C"
                                        border.width: 1
                                        border.color: modelData.severity === "danger" ? "#48232A" : modelData.severity === "warning" ? "#493A1F" : "#193B31"
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 10
                                            Rectangle {
                                                width: 8; height: 8; radius: 4
                                                color: modelData.severity === "danger" ? root.danger : modelData.severity === "warning" ? root.warning : root.good
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Text { text: modelData.title; color: root.textMain; font.pixelSize: 12; font.weight: Font.DemiBold }
                                                Text { text: modelData.detail; color: root.textMuted; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                            }
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: root.findings.length === 0
                                        text: "Start typing to populate findings"
                                        color: root.textMuted
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        Panel {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 315
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 12
                                SectionTitle { text: "Attack Resistance" }
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: 10
                                    rowSpacing: 10
                                    Metric { label: "ONLINE / LIMITED"; value: root.attack.onlineThrottled || "—" }
                                    Metric { label: "ONLINE / 10 SEC"; value: root.attack.onlineUnthrottled || "—" }
                                    Metric { label: "OFFLINE / SLOW HASH"; value: root.attack.offlineSlow || "—" }
                                    Metric { label: "OFFLINE / FAST HASH"; value: root.attack.offlineFast || "—" }
                                }
                                MutedText { Layout.fillWidth: true; text: "These are scenario estimates. Real cracking cost depends on hashing, rate limits, attacker hardware, and password reuse." }
                            }
                        }
                    }

                    Panel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 210
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                SectionTitle { text: "Breach Intelligence"; Layout.fillWidth: true }
                                Rectangle {
                                    implicitWidth: 98
                                    implicitHeight: 26
                                    radius: 13
                                    color: breachState === "compromised" ? "#2D151A" : breachState === "clear" ? "#0C2019" : "#111A25"
                                    Text {
                                        anchors.centerIn: parent
                                        text: breachState === "compromised" ? "COMPROMISED" : breachState === "clear" ? "NO MATCH" : breachState === "checking" ? "CHECKING" : "MANUAL"
                                        color: breachState === "compromised" ? root.danger : breachState === "clear" ? root.good : root.textMuted
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                            }
                            MutedText {
                                Layout.fillWidth: true
                                text: "HIBP Pwned Passwords check. Only the first 5 SHA-1 hash characters are sent; the full hash comparison happens locally."
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.breachMessage
                                color: breachState === "compromised" ? root.danger : breachState === "clear" ? root.good : root.textMain
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                wrapMode: Text.WordWrap
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                StyledButton {
                                    text: breachState === "checking" ? "Checking…" : "Check Breach Exposure"
                                    primary: true
                                    enabled: passwordInput.text.length > 0 && breachState !== "checking"
                                    onClicked: bridge.checkBreach(passwordInput.text)
                                }
                                StyledButton {
                                    text: "Clear Sensitive Data"
                                    onClicked: root.panicClear()
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }

                    Panel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: recommendationsContent.implicitHeight + 40

                        ColumnLayout {
                            id: recommendationsContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 20
                            spacing: 10

                            SectionTitle { text: "Recommendations" }

                            Repeater {
                                model: root.recommendations

                                delegate: Item {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(18, recommendationText.implicitHeight)

                                    Text {
                                        id: recommendationBullet
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        text: "•"
                                        color: root.accent
                                        font.pixelSize: 18
                                    }

                                    Text {
                                        id: recommendationText
                                        anchors.left: recommendationBullet.right
                                        anchors.leftMargin: 10
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        text: modelData
                                        color: root.textMuted
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            MutedText {
                                visible: root.recommendations.length === 0
                                Layout.fillWidth: true
                                text: "Recommendations will appear after a password is analyzed."
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 28 }
                }
            }

            // GENERATOR
            ScrollView {
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: parent.width - 60
                    x: 30
                    spacing: 18

                    Panel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#111C2C" }
                            GradientStop { position: 1; color: "#0D1520" }
                        }
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 22
                            spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                SectionTitle { text: passphraseMode ? "Generated Passphrase" : "Generated Password"; Layout.fillWidth: true }
                                Text { text: generatedEntropy.toFixed(1) + " bits estimated entropy"; color: root.accent; font.pixelSize: 11; font.bold: true }
                            }
                            ScrollablePasswordField {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 62
                                text: root.generatedValue
                                placeholderText: "Generate a new secure value"
                                passwordMode: false
                                reveal: true
                                readOnly: true
                                maximumLength: 512
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                StyledButton { text: "Generate"; primary: true; onClicked: root.generateNow() }
                                StyledButton { text: "Copy Securely"; enabled: generatedValue.length > 0; onClicked: bridge.copySecure(generatedValue, root.clipboardSeconds) }
                                Item { Layout.fillWidth: true }
                                Text { text: "Cryptographic randomness via Python secrets"; color: root.textMuted; font.pixelSize: 10 }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 18
                        rowSpacing: 18

                        Panel {
                            Layout.fillWidth: true
                            // Content-aware height prevents checkbox/control overflow on
                            // Windows display scaling and different Qt font metrics.
                            Layout.preferredHeight: Math.max(468, generatorModeContent.implicitHeight + 44)
                            ColumnLayout {
                                id: generatorModeContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 22
                                height: implicitHeight
                                spacing: 16
                                SectionTitle { text: "Generator Mode" }
                                RowLayout {
                                    Layout.fillWidth: true
                                    StyledButton { text: "Random Password"; primary: !passphraseMode; onClicked: { passphraseMode = false; generateNow() } }
                                    StyledButton { text: "Memorable Phrase"; primary: passphraseMode; onClicked: { passphraseMode = true; generateNow() } }
                                }

                                Item { Layout.preferredHeight: 4 }
                                ColumnLayout {
                                    visible: !passphraseMode
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: "Length: " + Math.round(passwordSize.value); color: root.textMain; font.pixelSize: 13 }
                                    Slider { id: passwordSize; Layout.fillWidth: true; from: 8; to: 64; value: 22; stepSize: 1; onMoved: if (!passphraseMode) root.generateNow() }
                                    ToggleCheck { id: upperCheck; text: "Uppercase A–Z"; checked: true }
                                    ToggleCheck { id: lowerCheck; text: "Lowercase a–z"; checked: true }
                                    ToggleCheck { id: digitCheck; text: "Numbers 0–9"; checked: true }
                                    ToggleCheck { id: symbolCheck; text: "Symbols"; checked: true }
                                    ToggleCheck { id: ambiguousCheck; text: "Exclude ambiguous characters (I, l, 1, O, 0)"; checked: true }
                                }

                                ColumnLayout {
                                    visible: passphraseMode
                                    Layout.fillWidth: true
                                    spacing: 14
                                    Text { text: "Tokens: " + Math.round(passphraseWords.value); color: root.textMain; font.pixelSize: 13 }
                                    Slider { id: passphraseWords; Layout.fillWidth: true; from: 4; to: 10; value: 7; stepSize: 1; onMoved: if (passphraseMode) root.generateNow() }
                                    Text { text: "Separator"; color: root.textMuted; font.pixelSize: 12 }
                                    ComboBox {
                                        id: separatorBox
                                        Layout.fillWidth: true
                                        model: ["-", ".", "_", " ", "/"]
                                        onActivated: if (passphraseMode) root.generateNow()
                                    }
                                    MutedText { Layout.fillWidth: true; text: "Memorable mode combines cryptographically selected adjective+noun tokens. The displayed entropy is based on the actual local token space." }
                                }
                            }
                        }

                        Panel {
                            Layout.fillWidth: true
                            // Keep both generator cards aligned at the same height.
                            Layout.preferredHeight: 468
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 22
                                spacing: 16
                                SectionTitle { text: "Clipboard Protection" }
                                MutedText { Layout.fillWidth: true; text: "TwardyPass can remove a generated password from the clipboard after a short delay, but only if the clipboard still contains that same value." }
                                Text { text: "Auto-clear after"; color: root.textMain; font.pixelSize: 13 }
                                RowLayout {
                                    spacing: 8
                                    Repeater {
                                        model: [15, 30, 60, 120]
                                        delegate: StyledButton {
                                            required property int modelData
                                            text: modelData + "s"
                                            primary: root.clipboardSeconds === modelData
                                            onClicked: root.clipboardSeconds = modelData
                                        }
                                    }
                                }
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.border }
                                SectionTitle { text: "Generator Principles" }
                                MutedText { Layout.fillWidth: true; text: "• Uses the operating system's cryptographically secure random source\n• Ensures every selected character category is represented\n• Does not mutate or derive output from a user's existing password\n• Does not save generated values" }
                                Item { Layout.fillHeight: true }
                            }
                        }
                    }
                    Item { Layout.preferredHeight: 28 }
                }
            }

            // COMPARE
            ScrollView {
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: parent.width - 60
                    x: 30
                    spacing: 18

                    Panel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 145

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                SectionTitle {
                                    text: "Compare candidates locally"
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    implicitWidth: 96
                                    implicitHeight: 26
                                    radius: 13
                                    color: "#0C211C"
                                    border.width: 1
                                    border.color: "#1A493C"

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: root.good
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "NO NETWORK"
                                            color: root.good
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }
                                }
                            }

                            MutedText {
                                Layout.fillWidth: true
                                text: "Use this lab to compare alternatives before choosing one: for example, a familiar password, an improved version, and a generated password. Scores are local and breach lookups are intentionally not automatic here."
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        StyledButton {
                            text: "Analyze All"
                            primary: true
                            onClicked: root.analyzeAllComparisons()
                        }

                        StyledButton {
                            text: "Clear Compare"
                            onClicked: root.clearCompare()
                        }

                        ToggleCheck {
                            id: compareRevealAll
                            text: "Show all passwords"
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.bestCompareText()
                            color: root.bestCompareScore() > 0 ? root.accent : root.textMuted
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Row {
                        id: compareRow
                        Layout.fillWidth: true
                        spacing: 16

                        property real candidateWidth: Math.max(0, (width - spacing * 2) / 3)

                        CompareCandidate {
                            id: compareCardA
                            width: compareRow.candidateWidth
                            candidateName: "A"
                            globalReveal: compareRevealAll.checked
                        }

                        CompareCandidate {
                            id: compareCardB
                            width: compareRow.candidateWidth
                            candidateName: "B"
                            globalReveal: compareRevealAll.checked
                        }

                        CompareCandidate {
                            id: compareCardC
                            width: compareRow.candidateWidth
                            candidateName: "C"
                            globalReveal: compareRevealAll.checked
                        }
                    }

                    Item { Layout.preferredHeight: 28 }
                }
            }

            // PRIVACY
            ScrollView {
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: parent.width - 60
                    x: 30
                    spacing: 18

                    Panel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 178
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#0E211D" }
                            GradientStop { position: 1; color: "#0D1520" }
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 22
                            Rectangle {
                                width: 86; height: 86; radius: 43
                                color: "#0D2A22"; border.width: 1; border.color: "#1C5747"
                                Text { anchors.centerIn: parent; text: "✓"; color: root.good; font.pixelSize: 36; font.bold: true }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Privacy-first by design"; color: root.textMain; font.pixelSize: 23; font.weight: Font.DemiBold }
                                MutedText { Layout.fillWidth: true; text: "Local analysis, no password history, no telemetry, no password logging, and manual-only breach lookups." }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 18
                        rowSpacing: 18

                        Panel {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 310
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 22; spacing: 14
                                SectionTitle { text: "Data Handling" }
                                MutedText { Layout.fillWidth: true; text: "Analyzer input" }
                                Text { text: "Memory only — never written to disk"; color: root.good; font.pixelSize: 13 }
                                MutedText { Layout.fillWidth: true; text: "Generated passwords" }
                                Text { text: "Memory only — never written to disk"; color: root.good; font.pixelSize: 13 }
                                MutedText { Layout.fillWidth: true; text: "Personal context" }
                                Text { text: "Used locally for analysis only"; color: root.good; font.pixelSize: 13 }
                                MutedText { Layout.fillWidth: true; text: "Telemetry" }
                                Text { text: "Disabled / not implemented"; color: root.good; font.pixelSize: 13 }
                            }
                        }

                        Panel {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 310
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 22; spacing: 14
                                SectionTitle { text: "Breach Lookup Privacy" }
                                MutedText { Layout.fillWidth: true; text: "When explicitly requested, TwardyPass hashes the password locally with SHA-1, sends only the first 5 hexadecimal characters to the HIBP Pwned Passwords range API, then compares returned suffixes locally." }
                                MutedText { Layout.fillWidth: true; text: "The request also asks HIBP for padded responses to make response-size inference less useful." }
                                Text { text: "No full password or full hash is transmitted."; color: root.good; font.pixelSize: 13; font.bold: true }
                            }
                        }
                    }

                    Panel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 160
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 22; spacing: 18
                            ColumnLayout {
                                Layout.fillWidth: true
                                SectionTitle { text: "Emergency Clear" }
                                MutedText { Layout.fillWidth: true; text: "Immediately clear analyzer input, comparison candidates, generated output, personal context, and matching clipboard content." }
                                Text { text: "Keyboard shortcut: Ctrl + Shift + X"; color: root.accent; font.pixelSize: 12; font.bold: true }
                            }
                            StyledButton { text: "CLEAR SENSITIVE DATA"; buttonColor: root.danger; onClicked: root.panicClear() }
                        }
                    }
                    Item { Layout.preferredHeight: 28 }
                }
            }
        }

        Rectangle {
            id: toast
            width: 390
            height: 92
            radius: 16
            color: "#111B28"
            border.width: 1
            border.color: "#274058"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 28
            anchors.bottomMargin: 28
            opacity: 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 7
                Text { id: toastTitle; color: root.textMain; font.pixelSize: 13; font.bold: true }
                Text { id: toastMessage; width: parent.width; color: root.textMuted; font.pixelSize: 11; wrapMode: Text.WordWrap }
            }
        }
    }

    Component.onCompleted: root.generateNow()
}
