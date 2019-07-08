// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import QtQuick.Controls 2.2
import io.thp.pyotherside 1.5
import "EventHandlers/includes.js" as EventHandlers

Python {
    id: py

    property bool ready: false
    property var pendingCoroutines: ({})

    signal willLoadAccounts(bool will)
    property bool loadingAccounts: false

    function callSync(name, args) {
        return call_sync("APP.backend." + name, args)
    }

    function callCoro(name, args, callback) {
        var uuid = Math.random() + "." + name

        pendingCoroutines[uuid] = callback || function() {}
        call("APP.call_backend_coro", [name, uuid, args])
    }

    function callClientCoro(account_id, name, args, callback) {
        var uuid = Math.random() + "." + name

        pendingCoroutines[uuid] = callback || function() {}
        call("APP.call_client_coro", [account_id, name, uuid, args])
    }

    Component.onCompleted: {
        for (var func in EventHandlers) {
            if (EventHandlers.hasOwnProperty(func)) {
                setHandler(func.replace(/^on/, ""), EventHandlers[func])
            }
        }

        addImportPath("src")
        addImportPath("qrc:/")
        importNames("python", ["APP"], function() {
            call("APP.is_debug_on", [Qt.application.arguments], function(on) {
                window.debug = on

                callCoro("has_saved_accounts", [], function(has) {
                    py.ready = true
                    willLoadAccounts(has)

                    if (has) {
                        py.loadingAccounts = true
                        py.callCoro("load_saved_accounts", [], function() {
                            py.loadingAccounts = false
                        })
                    }
                })
            })
        })
    }
}
