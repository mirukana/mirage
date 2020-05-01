// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Button {
    id: button
    enabled: ! button.loading
    spacing: theme.spacing
    topPadding: padded ? spacing / (circle ? 1.75 : 2) : 0
    bottomPadding: topPadding
    leftPadding: padded ? spacing / (circle ? 1.5 : 1) : 0
    rightPadding: leftPadding

    icon.color: theme.icons.colorize

    // Must be explicitely set to display correctly on KDE
    implicitWidth: Math.max(
        implicitBackgroundWidth + leftInset + rightInset,
        implicitContentWidth + leftPadding + rightPadding
    )
    implicitHeight: Math.max(
        implicitBackgroundHeight + topInset + bottomInset,
        implicitContentHeight + topPadding + bottomPadding
    )

    // Prevent button from gaining focus and being highlighted on click
    focusPolicy: Qt.TabFocus

    background: HButtonBackground {
        button: button
        buttonTheme: theme.controls.button
        radius: circle ? height : enableRadius ? theme.radius : 0
        color: backgroundColor
    }

    contentItem: HButtonContent {
        id: contentItem
        button: button
        buttonTheme: theme.controls.button
    }


    readonly property alias iconItem: contentItem.icon
    readonly property alias label: contentItem.label

    property color backgroundColor: theme.controls.button.background
    property bool disableWhileLoading: true
    property bool loading: false
    property bool circle: false
    property bool padded: true
    property bool enableRadius: false

    property HToolTip toolTip: HToolTip {
        id: toolTip
        visible: text && hovered
    }


    Binding on enabled {
        when: disableWhileLoading && button.loading
        value: false
    }
}
