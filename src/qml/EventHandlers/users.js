// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

"use strict"

function onAccountUpdated(userId) {
    accounts.append({userId})
}

function onAccountDeleted(userId) {
    accounts.popWhere({userId}, 1)
}

function onUserUpdated(userId, displayName, avatarUrl, statusMessage) {
    users.upsert({userId}, {userId, displayName, avatarUrl, statusMessage})
}

function onDeviceUpdated(userId, deviceId, ed25519Key, trust, displayName,
                         lastSeenIp, lastSeenDate) {
}

function onDeviceDeleted(userId, deviceId) {
}
