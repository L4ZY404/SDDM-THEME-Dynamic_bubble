import QtQuick 2.15
import SddmComponents 2.0
import QtGraphicalEffects 1.15

Rectangle {
    // --- LOCAL FONT LOADER ---
    // Loads the included Nerd Font to guarantee icons render correctly on any system
    FontLoader {
        id: themeFont
        source: "fonts/JetBrainsMonoNerdFont-Regular.ttf"
    }
    
    id: container
    width: 1920
    height: 1080
    color: "black"

    // --- 1. USER AUTHENTICATION LOGIC ---
    property int userIndex: Math.max(0, userModel.lastIndex)
    
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
    
    // --- 2. DYNAMIC STATUS & SYSTEM MESSAGES (PAM) ---
    property bool isAuthenticating: false
    property bool showMessage: false
    property string sysMessage: "" 
    property string messageColor: "transparent"
    property string messageBg: "transparent"
    
    Connections {
        target: sddm
        
        // Signal: Triggered on incorrect password
        function onLoginFailed() {
            isAuthenticating = false
            sysMessage = "❌ Incorrect Password!"
            messageColor = "#f38ba8" 
            messageBg = Qt.rgba(243/255, 139/255, 168/255, 0.15)
            showMessage = true
            statusTimer.restart()
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        }
        
        // Signal: Triggered on system errors (e.g., Account Locked by faillock)
        function onErrorMessage(message) {
            isAuthenticating = false
            sysMessage = "⚠️ " + message 
            messageColor = "#fab387" 
            messageBg = Qt.rgba(250/255, 179/255, 135/255, 0.15)
            showMessage = true
            statusTimer.restart()
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        }

        // Signal: Informational messages from PAM
        function onInformationMessage(message) {
            isAuthenticating = false
            sysMessage = "🛑 " + message
            messageColor = "#f9e2af"
            messageBg = Qt.rgba(249/255, 226/255, 175/255, 0.15)
            showMessage = true
            statusTimer.restart()
        }
        
        function onLoginSucceeded() { isAuthenticating = true }
    }
    
    // Timer to hide the status pill after 4 seconds
    Timer { 
        id: statusTimer
        interval: 4000 
        onTriggered: showMessage = false
    }

    // --- 3. THEME MODE & SESSION LOGIC ---
    readonly property bool isPro: config.mode === "pro"
    readonly property string finalWallpaper: isPro ? "file:///var/cache/sddm-theme/current_wallpaper.jpg" : config.background

    property int sessionIndex: Math.max(0, sessionModel.lastIndex)
    function nextSession() {
        if (sessionModel.count > 1 && !isAuthenticating) {
            sessionIndex = (sessionIndex + 1) % sessionModel.count
            passwordInput.forceActiveFocus()
        }
    }
    
    function getCurrentSession() {
        var sName = sessionModel.data(sessionModel.index(sessionIndex, 0), Qt.UserRole + 4)
        return sName ? sName : "Desktop"
    }

    // --- 4. DYNAMIC BACKGROUND ---
    Image { id: bgImage; anchors.fill: parent; source: finalWallpaper; fillMode: Image.PreserveAspectCrop; visible: false }
    FastBlur { anchors.fill: bgImage; source: bgImage; radius: 10 }
    
    Rectangle {
        anchors.fill: parent; color: config.background_color || "black"
        opacity: hoverDetector.containsMouse ? 0.5 : 0.2
        Behavior on opacity { NumberAnimation { duration: 500 } }
    }

    // --- 5. POWER CONTROLS ---
    Row {
        anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 25; spacing: 15; z: 100
        Rectangle {
            width: 50; height: 50; radius: 25; color: pwr1.containsMouse ? "#f38ba8" : Qt.rgba(0,0,0,0.5)
            border.color: config.color11 || "#ffffff"; border.width: 1
            Text { text: ""; anchors.centerIn: parent; font.family: themeFont.name; font.pixelSize: 20; color: "white" }
            MouseArea { id: pwr1; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.powerOff() }
        }
        Rectangle {
            width: 50; height: 50; radius: 25; color: pwr2.containsMouse ? "#f9e2af" : Qt.rgba(0,0,0,0.5)
            border.color: config.color11 || "#ffffff"; border.width: 1
            Text { text: ""; anchors.centerIn: parent; font.family: themeFont.name; font.pixelSize: 20; color: "white" }
            MouseArea { id: pwr2; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.reboot() }
        }
    }

    MouseArea { id: hoverDetector; height: 600; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; hoverEnabled: true; z: 0 }

    // --- 6. MAIN LOGIN BUBBLE ---
    Rectangle {
        id: loginPanel; width: 480; height: 460; anchors.centerIn: parent
        anchors.verticalCenterOffset: hoverDetector.containsMouse ? 0 : 500
        z: 10

        color: config.background_color || "#1a1b26"; radius: 35
        border.color: config.color11 || "#8caaee"; border.width: 2
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

        Column {
            anchors.fill: parent; anchors.margins: 30; spacing: 15

            // GREETING PILL
            Rectangle {
                width: parent.width - 40; height: 45; anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.rgba(1, 1, 1, 0.05); radius: 22.5
                border.color: config.color11 || "#8caaee"; border.width: 1
                Text { 
                    anchors.centerIn: parent
                    text: "Welcome back, " + ((config.username && config.username !== "") ? config.username : getCurrentUser()) + "!" 
                    color: "white"; font.family: themeFont.name; font.pixelSize: 15; font.bold: true 
                }
            }

            // CLOCK
            Text {
                id: timeText; anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(), "hh:mm")
                color: "white"; font.family: themeFont.name; font.pixelSize: 85; font.bold: true
                Timer { interval: 1000; running: true; repeat: true; onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm") }
            }

            // LOGIN INTERFACE
            Column {
                width: parent.width; spacing: 15
                opacity: hoverDetector.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 400 } }

                // USER SELECTOR
                Rectangle {
                    width: 160; height: 35; anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(1, 1, 1, 0.1); radius: 17.5
                    Text { anchors.centerIn: parent; text: "  " + getCurrentUser(); color: "white"; font.family: themeFont.name; font.pixelSize: 14; opacity: isAuthenticating ? 0.5 : 1.0 }
                    MouseArea { anchors.fill: parent; onClicked: nextUser(); cursorShape: isAuthenticating ? Qt.ArrowCursor : Qt.PointingHandCursor }
                }

                // STATUS PILL (DYNAMIC)
                Rectangle {
                    id: statusPill
                    width: parent.width - 80; anchors.horizontalCenter: parent.horizontalCenter
                    property bool isActive: isAuthenticating || showMessage
                    height: isActive ? 35 : 0; opacity: isActive ? 1.0 : 0.0; clip: true; radius: 17.5
                    color: isAuthenticating ? Qt.rgba(1, 1, 1, 0.1) : messageBg
                    border.color: showMessage ? messageColor : (isAuthenticating ? (config.color11 || "#8caaee") : "transparent")
                    border.width: 1
                    Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    Text { anchors.centerIn: parent; text: isAuthenticating ? "⏳ Authenticating..." : sysMessage; color: isAuthenticating ? (config.color11 || "#8caaee") : messageColor; font.family: themeFont.name; font.pixelSize: 13; font.bold: true }
                }

                // PASSWORD BOX
                Rectangle {
                    width: parent.width - 40; height: 55; anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(0, 0, 0, 0.4); radius: 25; clip: true
                    border.color: showMessage ? messageColor : (passwordInput.focus ? (config.color11 || "#8caaee") : "transparent")
                    TextInput {
                        id: passwordInput; anchors.fill: parent; anchors.leftMargin: 25; anchors.rightMargin: 50
                        color: "white"; font.family: themeFont.name; font.pixelSize: 18; focus: true
                        echoMode: TextInput.Password; verticalAlignment: TextInput.AlignVCenter
                        readOnly: isAuthenticating
                        onAccepted: { if (!isAuthenticating && getCurrentUser() !== "") { isAuthenticating = true; showMessage = false; sddm.login(getCurrentUser(), passwordInput.text, sessionIndex); } }
                        Text { anchors.fill: parent; text: "Password..."; color: "white"; opacity: 0.3; font.family: themeFont.name; font.pixelSize: 16; verticalAlignment: Text.AlignVCenter; visible: !passwordInput.text && !passwordInput.focus }
                    }
                    Text { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: ""; color: "#f9e2af"; font.family: themeFont.name; font.pixelSize: 18; visible: keyboard.capsLock }
                }

                // SESSION SELECTOR
                Rectangle {
                    width: 220; height: 35; anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(0, 0, 0, 0.2); radius: 17.5; border.color: config.color11 || "#8caaee"; border.width: 0.5
                    Text { anchors.centerIn: parent; text: "  " + getCurrentSession(); color: "white"; font.family: themeFont.name; font.pixelSize: 13; opacity: isAuthenticating ? 0.5 : 0.8 }
                    MouseArea { anchors.fill: parent; onClicked: nextSession(); cursorShape: isAuthenticating ? Qt.ArrowCursor : Qt.PointingHandCursor }
                }
            }
        }
    }
}