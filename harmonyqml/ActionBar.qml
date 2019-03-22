import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Row {
    id: "root"
    width: parent.width
    height: 31
    spacing: 0

    ActionButton {
        iconName: "home";
        tooltip: "Home page"
        targetPage: "HomePage"
    }

    ActionButton {
        iconName: "add_account";
        tooltip: "Add new account"
        targetPage: "AddAccountPage"
    }
    ActionButton {
        iconName: "add_room";
        tooltip: "Create or join chat room"
        targetPage: "AddRoomPage"
    }
    ActionButton {
        iconName: "set_status";
        tooltip: "Set status for all accounts"
    }
    ActionButton {
        iconName: "settings";
        tooltip: "Settings"
        targetPage: "SettingsPage"
    }
}
