import QtQuick
import QtQuick.Effects
import SddmComponents 2.0

// Dynamic Bubble
// Author: L4ZY404

Rectangle {
    id: container

    // SDDM creates one QQuickView per monitor and resizes the root object to it.
    // The primaryScreen context property is supplied by SDDM for each view.
    width: 1920
    height: 1080
    color: backgroundColor
    focus: primaryScreen

    function configString(key, fallbackValue) {
        var value = config.stringValue(key)
        return value === "" ? fallbackValue : value
    }

    function scaled(value) {
        return Math.round(value * uiScale)
    }

    readonly property real uiScale: Math.max(0.72, Math.min(1.65, Math.min(width / 1920.0, height / 1080.0)))
    readonly property bool primaryOnly: config.boolValue("primaryOnly")
    readonly property bool showInteractiveUi: !primaryOnly || primaryScreen

    readonly property color backgroundColor: configString("background_color", "#1a1b26")
    readonly property color foregroundColor: configString("foreground", "#ffffff")
    readonly property color errorColor: configString("color1", "#f38ba8")
    readonly property color warningColor: configString("color3", "#f9e2af")
    readonly property color mutedColor: configString("color8", "#6c7086")
    readonly property color successColor: configString("color10", "#a6e3a1")
    readonly property color accentColor: configString("color11", "#8caaee")
    readonly property color infoColor: configString("color12", "#89b4fa")
    readonly property string wallpaperSource: configString("background", "background.jpg")

    FontLoader {
        id: themeFont
        source: "fonts/JetBrainsMonoNerdFont-Regular.ttf"
    }

    // Authentication state.
    property int userIndex: Math.max(0, userModel.lastIndex)
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)
    property bool isAuthenticating: false
    property bool showMessage: false
    property string sysMessage: ""
    property color messageColor: "transparent"

    function nextUser() {
        if (userModel.count > 1 && !isAuthenticating) {
            userIndex = (userIndex + 1) % userModel.count
            passwordInput.forceActiveFocus()
        }
    }

    function getCurrentUser() {
        var name = userModel.data(userModel.index(userIndex, 0), Qt.UserRole + 1)
        return name ? name : userModel.lastUser
    }

    function nextSession() {
        if (sessionModel.count > 1 && !isAuthenticating) {
            sessionIndex = (sessionIndex + 1) % sessionModel.count
            passwordInput.forceActiveFocus()
        }
    }

    function getCurrentSession() {
        var sessionName = sessionModel.data(sessionModel.index(sessionIndex, 0), Qt.UserRole + 4)
        return sessionName ? sessionName : "Desktop"
    }

    function beginLogin() {
        if (isAuthenticating || getCurrentUser() === "")
            return

        isAuthenticating = true
        showMessage = false
        sddm.login(getCurrentUser(), passwordInput.text, sessionIndex)
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            isAuthenticating = false
            sysMessage = "  Incorrect password"
            messageColor = errorColor
            showMessage = true
            statusTimer.restart()
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        }

        function onErrorMessage(message) {
            isAuthenticating = false
            sysMessage = "  " + message
            messageColor = warningColor
            showMessage = true
            statusTimer.restart()
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        }

        function onInformationMessage(message) {
            isAuthenticating = false
            sysMessage = "  " + message
            messageColor = infoColor
            showMessage = true
            statusTimer.restart()
        }

        function onLoginSucceeded() {
            isAuthenticating = true
        }
    }

    Timer {
        id: statusTimer
        interval: 4000
        onTriggered: showMessage = false
    }

    // The wallpaper is rendered only where the full theme UI is enabled.
    // Secondary monitors use the Pywal background color when primaryOnly=true.
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: wallpaperSource
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
        cache: true
    }

    MultiEffect {
        anchors.fill: parent
        source: backgroundImage
        visible: showInteractiveUi
        blurEnabled: true
        blur: 0.34
        blurMax: 24
    }

    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        opacity: showInteractiveUi ? (hoverDetector.containsMouse ? 0.52 : 0.24) : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 420 }
        }
    }

    // Power controls are intentionally restricted to the active theme monitor.
    Row {
        visible: showInteractiveUi
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: scaled(25)
        spacing: scaled(15)
        z: 100

        Rectangle {
            width: scaled(50)
            height: scaled(50)
            radius: width / 2
            color: powerOffArea.containsMouse ? errorColor : Qt.rgba(0, 0, 0, 0.5)
            border.color: accentColor
            border.width: Math.max(1, scaled(1))

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: themeFont.name
                font.pixelSize: scaled(20)
                color: foregroundColor
            }

            MouseArea {
                id: powerOffArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.powerOff()
            }
        }

        Rectangle {
            width: scaled(50)
            height: scaled(50)
            radius: width / 2
            color: rebootArea.containsMouse ? warningColor : Qt.rgba(0, 0, 0, 0.5)
            border.color: accentColor
            border.width: Math.max(1, scaled(1))

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: themeFont.name
                font.pixelSize: scaled(20)
                color: foregroundColor
            }

            MouseArea {
                id: rebootArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.reboot()
            }
        }
    }

    MouseArea {
        id: hoverDetector
        visible: showInteractiveUi
        enabled: showInteractiveUi
        height: Math.min(parent.height, scaled(600))
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        hoverEnabled: true
        z: 0
    }

    Rectangle {
        id: loginPanel
        visible: showInteractiveUi
        width: Math.min(parent.width * 0.88, scaled(480))
        height: Math.min(parent.height * 0.76, scaled(460))
        anchors.centerIn: parent
        anchors.verticalCenterOffset: hoverDetector.containsMouse ? 0 : scaled(500)
        z: 10

        color: backgroundColor
        radius: scaled(35)
        border.color: accentColor
        border.width: Math.max(1, scaled(2))

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: scaled(30)
            spacing: scaled(15)

            Rectangle {
                width: parent.width - scaled(40)
                height: scaled(45)
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.06)
                radius: height / 2
                border.color: accentColor
                border.width: Math.max(1, scaled(1))

                Text {
                    anchors.centerIn: parent
                    text: "Welcome back, " + (configString("username", "") !== "" ? configString("username", "") : getCurrentUser()) + "!"
                    color: foregroundColor
                    font.family: themeFont.name
                    font.pixelSize: scaled(15)
                    font.bold: true
                }
            }

            Text {
                id: timeText
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(), "hh:mm")
                color: foregroundColor
                font.family: themeFont.name
                font.pixelSize: scaled(85)
                font.bold: true

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            Column {
                width: parent.width
                spacing: scaled(15)
                opacity: hoverDetector.containsMouse ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 400 }
                }

                Rectangle {
                    width: scaled(160)
                    height: scaled(35)
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.10)
                    radius: height / 2

                    Text {
                        anchors.centerIn: parent
                        text: "  " + getCurrentUser()
                        color: foregroundColor
                        font.family: themeFont.name
                        font.pixelSize: scaled(14)
                        opacity: isAuthenticating ? 0.5 : 1.0
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !isAuthenticating
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: nextUser()
                    }
                }

                Rectangle {
                    id: statusPill
                    width: parent.width - scaled(80)
                    anchors.horizontalCenter: parent.horizontalCenter
                    property bool isActive: isAuthenticating || showMessage
                    height: isActive ? scaled(35) : 0
                    opacity: isActive ? 1.0 : 0.0
                    clip: true
                    radius: Math.max(1, height / 2)
                    color: isAuthenticating
                        ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)
                        : Qt.rgba(messageColor.r, messageColor.g, messageColor.b, 0.15)
                    border.color: showMessage ? messageColor : (isAuthenticating ? accentColor : "transparent")
                    border.width: Math.max(1, scaled(1))

                    Behavior on height {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 220 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: isAuthenticating ? "  Authenticating..." : sysMessage
                        color: isAuthenticating ? accentColor : messageColor
                        font.family: themeFont.name
                        font.pixelSize: scaled(13)
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width - scaled(40)
                    height: scaled(55)
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(0, 0, 0, 0.40)
                    radius: height / 2
                    clip: true
                    border.color: showMessage ? messageColor : (passwordInput.activeFocus ? accentColor : mutedColor)
                    border.width: passwordInput.activeFocus ? Math.max(1, scaled(2)) : Math.max(1, scaled(1))

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: scaled(25)
                        anchors.rightMargin: scaled(50)
                        color: foregroundColor
                        selectionColor: accentColor
                        selectedTextColor: backgroundColor
                        font.family: themeFont.name
                        font.pixelSize: scaled(18)
                        focus: showInteractiveUi
                        echoMode: TextInput.Password
                        verticalAlignment: TextInput.AlignVCenter
                        readOnly: isAuthenticating
                        onAccepted: beginLogin()

                        Text {
                            anchors.fill: parent
                            text: "Password..."
                            color: foregroundColor
                            opacity: 0.30
                            font.family: themeFont.name
                            font.pixelSize: scaled(16)
                            verticalAlignment: Text.AlignVCenter
                            visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: scaled(18)
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        color: warningColor
                        font.family: themeFont.name
                        font.pixelSize: scaled(18)
                        visible: keyboard.capsLock
                    }
                }

                Rectangle {
                    width: scaled(220)
                    height: scaled(35)
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(0, 0, 0, 0.20)
                    radius: height / 2
                    border.color: accentColor
                    border.width: Math.max(1, scaled(1))

                    Text {
                        anchors.centerIn: parent
                        text: "  " + getCurrentSession()
                        color: foregroundColor
                        font.family: themeFont.name
                        font.pixelSize: scaled(13)
                        opacity: isAuthenticating ? 0.5 : 0.82
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !isAuthenticating
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: nextSession()
                    }
                }
            }
        }
    }
}
