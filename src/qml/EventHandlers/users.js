function onAccountUpdated(user_id) {
    accounts.append({"userId": user_id})
}

function onAccountDeleted(user_id) {
    accounts.popWhere({"userId": user_id}, 1)
}

// TODO: get updated from nio rooms
function onUserUpdated(user_id, display_name, avatar_url, status_message) {
    users.upsert({"userId": user_id}, {
        "userId":        user_id,
        "displayName":   display_name,
        "avatarUrl":     avatar_url,
        "statusMessage": status_message
    })
}

function onDeviceUpdated(user_id, device_id, ed25519_key, trust, display_name,
                         last_seen_ip, last_seen_date) {
}

function onDeviceDeleted(user_id, device_id) {
}
