// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "../../.."
import "../../../Base"

HColumnLayout {
    id: eventDelegate

    property string fetchProfilesFutureId: ""

    // Remember timeline goes from newest message at index 0 to oldest
    readonly property var previousModel: eventList.model.get(model.index + 1)
    readonly property var nextModel: eventList.model.get(model.index - 1)
    readonly property QtObject currentModel: model

    readonly property bool compact: window.settings.General.compact
    readonly property bool checked: model.id in eventList.checked
    readonly property bool isOwn: chat.userId === model.sender_id
    readonly property bool isRedacted: model.event_type === "RedactedEvent"
    readonly property bool onRight: ! eventList.ownEventsOnLeft && isOwn
    readonly property bool combine: eventList.canCombine(previousModel, model)
    readonly property bool asOneLine: eventList.renderEventAsOneLine(model)
    readonly property bool talkBreak:
        eventList.canTalkBreak(previousModel, model)
    readonly property bool dayBreak:
        eventList.canDayBreak(previousModel, model)

    readonly property int cursorShape:
        eventContent.hoveredLink ? Qt.PointingHandCursor :
        eventContent.hoveredSelectable ? Qt.IBeamCursor :
        Qt.ArrowCursor

    readonly property int separationSpacing: theme.spacing * (
        dayBreak  ? 4 :
        talkBreak ? 6 :
        combine && compact ? 0.25 :
        combine ? 0.5 :
        compact ? 1 :
        2
    )

    readonly property alias eventContent: eventContent


    function dict() {
        let event    = eventList.model.get(model.index)
        event        = JSON.parse(JSON.stringify(event))
        event.source = JSON.parse(event.source)
        return event
    }

    function openContextMenu() {
        eventList.contextMenu.spawn(
            model.index, eventDelegate, eventContent.hoveredLink,
        )
    }

    function toggleChecked() {
        eventList.toggleCheck(model.index)
    }


    width: eventList.width - eventList.leftMargin - eventList.rightMargin

    // Needed because of eventList's MouseArea which steals the
    // HSelectableLabel's MouseArea hover events
    onCursorShapeChanged: eventList.cursorShape = cursorShape

    Component.onCompleted: if (model.fetch_profile)
        fetchProfilesFutureId = py.callClientCoro(
            chat.userId,
            "get_event_profiles",
            [chat.roomId, model.id],
            // The if avoids segfault if eventDelegate is already destroyed
            () => { if (eventDelegate) fetchProfilesFutureId = "" }
        )

    Component.onDestruction:
        if (fetchProfilesFutureId) py.cancelCoro(fetchProfilesFutureId)

    ListView.onRemove: eventList.uncheck(model.id)

    DelegateTransitionFixer {}

    Item {
        Layout.fillWidth: true
        visible: model.event_type !== "RoomCreateEvent"
        Layout.preferredHeight: separationSpacing
    }

    Daybreak {
        visible: dayBreak

        Layout.fillWidth: true
        Layout.minimumWidth: parent.width
        Layout.bottomMargin: separationSpacing
    }

    EventContent {
        id: eventContent

        Layout.fillWidth: true
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        acceptedModifiers: Qt.NoModifier
        onTapped: toggleChecked()
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        acceptedModifiers: Qt.ShiftModifier
        onTapped: eventList.checkFromLastToHere(model.index)
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Pen
        onTapped: openContextMenu()
    }

    TapHandler {
        acceptedPointerTypes: PointerDevice.Finger | PointerDevice.Pen
        onLongPressed: openContextMenu()
    }
}
