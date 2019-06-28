import QtQuick 2.7
import QtQuick.Controls 2.2
import io.thp.pyotherside 1.5
import "EventHandlers/includes.js" as EventHandlers

Python {
    id: py

    property bool ready: false
    property var pendingCoroutines: ({})

    property bool loadingAccounts: false

    function callCoro(name, args, kwargs, callback) {
        call("APP.call_backend_coro", [name, args, kwargs], function(uuid){
            pendingCoroutines[uuid] = callback || function() {}
        })
    }

    function callClientCoro(account_id, name, args, kwargs, callback) {
        var args = [account_id, name, args, kwargs]

        call("APP.call_client_coro", args, function(uuid){
            pendingCoroutines[uuid] = callback || function() {}
        })
    }

    Component.onCompleted: {
        for (var func in EventHandlers) {
            if (EventHandlers.hasOwnProperty(func)) {
                setHandler(func.replace(/^on/, ""), EventHandlers[func])
            }
        }

        addImportPath("../..")
        importNames("src", ["APP"], function() {
            call("APP.start", [Qt.application.arguments], function(debug_on) {
                window.debug = debug_on

                callCoro("has_saved_accounts", [], {}, function(has) {
                    loadingAccounts = has
                    py.ready = true

                    if (has) {
                        py.callCoro("load_saved_accounts", [], {}, function() {
                            loadingAccounts = false
                        })
                    }
                })
            })
        })
    }
}
