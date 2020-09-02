// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "../../.."
import "../../../Base"
import "../../../PythonBridge"

HColumnLayout {
    id: eventDelegate

    property var fetchProfilesFuture: null

    // Remember timeline goes from newest message at index 0 to oldest
    readonly property var previousModel: eventList.model.get(model.index + 1)
    readonly property var nextModel: eventList.model.get(model.index - 1)
    readonly property QtObject currentModel: model

    readonly property bool compact: window.settings.compactMode
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

    readonly property int separationSpacing:
        dayBreak  ? theme.spacing * 4 :
        talkBreak ? theme.spacing * 6 :
        combine   ? theme.spacing / (compact ? 4 : 2) :
        theme.spacing * (compact ? 1 : 2)

    readonly property alias eventContent: eventContent

    function json() {
        let event    = ModelStore.get(chat.userId, chat.roomId, "events")
                                 .get(model.index)
        event        = JSON.parse(JSON.stringify(event))
        event.source = JSON.parse(event.source)
        return JSON.stringify(event, null, 4)
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
        fetchProfilesFuture = py.callClientCoro(
            chat.userId,
            "get_event_profiles",
            [chat.roomId, model.id],
            () => { fetchProfilesFuture = null }
        )

    Component.onDestruction:
        if (fetchProfilesFuture) fetchProfilesFuture.cancel()

    ListView.onRemove: eventList.uncheck(model.id)

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

        Behavior on x { HNumberAnimation {} }
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
