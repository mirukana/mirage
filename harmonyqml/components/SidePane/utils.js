.import "../Chat/utils.js" as ChatJS


function getLastRoomEventText(roomId, accountId) {
    var eventsModel = Backend.roomEvents.get(roomId)
    if (eventsModel.count < 1) { return "" }
    var ev = eventsModel.get(0)

    var name = Backend.users.get(ev.dict.sender).displayName.value

    var undecryptable = ev.type === "OlmEvent" || ev.type === "MegolmEvent"

    if (undecryptable || ev.type.startsWith("RoomMessage")) {
        var color = Qt.hsla(Backend.hueFromString(name), 0.32, 0.3, 1)

        return "<font color='" + color + "'>" +
               name +
               ":</font> " +
               (undecryptable ?
                "<font color='darkred'>" + qsTr("Undecryptable") + "<font>" :
                ev.dict.body)
   } else {
       return "<font color='" + (undecryptable ? "darkred" : "#444") + "'>" +
              name +
              " " +
              ChatJS.getEventText(ev.type, ev.dict) +
              "</font>"
   }
}
