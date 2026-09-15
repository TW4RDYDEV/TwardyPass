import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../components"

WorkbenchPage {
    id: page
    property var generated: ({})
    property bool phraseMode: false
    function preset() {
        var p = bridge.generatorPreset(presets.currentText);
        if (!p.length)
            return;
        length.value = p.length;
        upper.checked = p.uppercase;
        lower.checked = p.lowercase;
        digits.checked = p.digits;
        symbols.checked = p.symbols;
        ambiguous.checked = p.exclude_ambiguous;
        excluded.text = "";
    }
    function generate() {
        generated = phraseMode ? bridge.generatePassphrase({
            words: words.value,
            separator: separator.currentText,
            capitalization: capitalization.currentText,
            number: number.checked,
            symbol: symbol.checked
        }) : bridge.generatePassword({
            length: length.value,
            uppercase: upper.checked,
            lowercase: lower.checked,
            digits: digits.checked,
            symbols: symbols.checked,
            exclude_ambiguous: ambiguous.checked,
            excluded: excluded.text
        });
        output.text = generated.password || "";
    }
    function custom() {
        presets.currentIndex = 4;
    }
    Connections {
        target: bridge
        function onSensitiveCleared() {
            page.generated = ({});
            output.clear();
            excluded.clear();
        }
    }
    AppCard {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            SectionHeader {
                text: "Generate with confidence"
                Layout.fillWidth: true
            }
            StatusBadge {
                text: "CRYPTOGRAPHIC RANDOMNESS"
            }
        }
        PasswordField {
            id: output
            objectName: "generatedPassword"
            Layout.fillWidth: true
            readOnly: true
            placeholderText: "Generate a new password or passphrase"
        }
        RowLayout {
            Layout.fillWidth: true
            AppButton {
                objectName: "generateButton"
                text: "Generate"
                primary: true
                onClicked: page.generate()
            }
            AppButton {
                text: "Copy securely"
                enabled: output.text.length > 0
                onClicked: bridge.copySecure(output.text)
            }
            Item {
                Layout.fillWidth: true
            }
            AppText {
                text: (page.generated.entropy || 0) + " bits · actual generator space"
                color: Theme.muted
                font.pixelSize: 12
            }
        }
    }
    RowLayout {
        AppButton {
            text: "Random password"
            primary: !page.phraseMode
            onClicked: page.phraseMode = false
        }
        AppButton {
            text: "Memorable passphrase"
            primary: page.phraseMode
            onClicked: page.phraseMode = true
        }
    }
    AppCard {
        Layout.fillWidth: true
        visible: !page.phraseMode
        SectionHeader {
            text: "Password configuration"
        }
        AppComboBox {
            id: presets
            objectName: "generatorPreset"
            Layout.fillWidth: true
            model: ["BALANCED", "MAXIMUM SECURITY", "WEBSITE COMPATIBLE", "EASY TO TYPE", "CUSTOM"]
            onActivated: page.preset()
        }
        RowLayout {
            AppText {
                text: "Length"
                Layout.preferredWidth: 90
            }
            SpinBox {
                id: length
                from: 4
                to: 128
                value: 20
                editable: true
                onValueModified: page.custom()
            }
            Repeater {
                model: [16, 20, 24, 32, 48, 64]
                AppButton {
                    required property int modelData
                    text: modelData
                    primary: length.value === modelData
                    onClicked: {
                        length.value = modelData;
                        page.custom();
                    }
                }
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 40
            AppCheckBox {
                id: upper
                text: "Uppercase A–Z"
                checked: true
                onClicked: page.custom()
            }
            AppCheckBox {
                id: lower
                text: "Lowercase a–z"
                checked: true
                onClicked: page.custom()
            }
            AppCheckBox {
                id: digits
                text: "Numbers 0–9"
                checked: true
                onClicked: page.custom()
            }
            AppCheckBox {
                id: symbols
                text: "Symbols"
                checked: true
                onClicked: page.custom()
            }
            AppCheckBox {
                id: ambiguous
                text: "Exclude ambiguous characters"
                checked: true
                onClicked: page.custom()
            }
        }
        AppTextField {
            id: excluded
            Layout.fillWidth: true
            placeholderText: "Custom excluded characters"
            maximumLength: 256
            onTextEdited: page.custom()
        }
        AppText {
            Layout.fillWidth: true
            text: "Every selected category is represented. Impossible exclusions produce an error instead of silently weakening your settings."
            color: Theme.muted
            font.pixelSize: 12
        }
    }
    AppCard {
        Layout.fillWidth: true
        visible: page.phraseMode
        SectionHeader {
            text: "Passphrase configuration"
        }
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            columnSpacing: 24
            rowSpacing: 12
            AppText {
                text: "Word tokens (adjective + noun)"
            }
            SpinBox {
                id: words
                from: 4
                to: 12
                value: 6
                editable: true
            }
            AppText {
                text: "Separator"
            }
            AppComboBox {
                id: separator
                model: ["-", ".", "_", " ", "/"]
                Layout.fillWidth: true
            }
            AppText {
                text: "Capitalization"
            }
            AppComboBox {
                id: capitalization
                model: ["lower", "title", "upper"]
                Layout.fillWidth: true
            }
        }
        RowLayout {
            AppCheckBox {
                id: number
                text: "Append random two-digit number"
            }
            AppCheckBox {
                id: symbol
                text: "Append random symbol"
            }
        }
        AppText {
            Layout.fillWidth: true
            text: "Each token combines two securely selected words from the bundled lists. Capitalization and a fixed separator do not add entropy. More tokens increase the output space."
            color: Theme.muted
        }
    }
    AppCard {
        Layout.fillWidth: true
        SectionHeader {
            text: "Clipboard protection"
        }
        AppText {
            Layout.fillWidth: true
            text: "Auto-clear is currently " + bridge.clipboardSeconds + " seconds (0 = off). Change this in Privacy Center. Clearing only removes a clipboard value if it still matches the value copied here."
            color: Theme.muted
        }
    }
}
