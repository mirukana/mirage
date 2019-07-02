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

        addImportPath("src")
        addImportPath("qrc:/")
        importNames("python", ["APP"], function() {
            call("APP.is_debug_on", [Qt.application.arguments], function(on) {
                window.debug = on

                callCoro("has_saved_accounts", [], {}, function(has) {
                    py.ready = true
                    willLoadAccounts(has)

                    if (has) {
                        py.loadingAccounts = true
                        py.callCoro("load_saved_accounts", [], {}, function() {
                            py.loadingAccounts = false
                        })
                    }
                })
            })
        })
    }
}
