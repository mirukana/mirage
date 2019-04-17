.import "../chat/utils.js" as ChatJS


function get_last_room_event_text(room_id) {
    var eventsModel = Backend.models.roomEvents.get(room_id)

    for (var i = 0; i < eventsModel.count; i++) {
        var ev = eventsModel.get(i)

        if (ev.type !== "RoomMemberEvent") {
            var found = true
            break
        }
    }

    if (! found) { return "" }

    var name          = Backend.getUser(ev.dict.sender).display_name
    var undecryptable = ev.type === "OlmEvent" || ev.type === "MegolmEvent"

    if (undecryptable || ev.type.startsWith("RoomMessage")) {
        var color = ev.dict.sender === roomList.for_user_id ?
                    "darkblue" : "purple"

        return "<font color='" +
               color +
               "'>" +
               name +
               ":</font> " +
               (undecryptable ?
                "<font color='darkred'>Undecryptable<font>" :
                ev.dict.body)
   } else {
       return "<font color='" +
              (undecryptable ? "darkred" : "#444") +
              "'>" +
              name +
              " " +
              ChatJS.get_event_text(ev.type, ev.dict) +
              "</font>"
   }
}
