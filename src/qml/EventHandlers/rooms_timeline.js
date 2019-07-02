function onHtmlMessageReceived(type, room_id, event_id, sender_id, date,
                               is_local_echo, content) {
    models.timelines.upsert({"eventId": event_id}, {
        "type":        type,
        "roomId":      room_id,
        "eventId":     event_id,
        "senderId":    sender_id,
        "date":        date,
        "isLocalEcho": is_local_echo,
        "content":     content,
    }, true, 1000)
}
