pragma Singleton
import QtQuick
import Quickshell.Services.Pam

QtObject {
    id: root

    signal unlocked
    signal failed(string errorMessage)

    property PamContext pam: PamContext {
        id: pamContext
        config: "login"

        onPamMessage: {
            console.log("PAM MSG:", pamContext.message, "| error:", pamContext.messageIsError);
            if (pamContext.messageIsError)
                root.failed(pamContext.message);
        }

        onError: err => {
            console.log("PAM ERROR:", err);
            root.failed("Authentication error");
            pamContext.abort();
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked();
            } else if (result === PamResult.Failed) {
                root.failed("Wrong password");
                pamContext.abort();
                pamContext.start();
            } else if (result === PamResult.MaxTries) {
                root.failed("Too many failed attempts");
                pamContext.abort();
            } else if (result === PamResult.Error) {
                root.failed("An authentication error occurred");
                pamContext.abort();
            }
        }
    }

    function start() {
        if (!pamContext.active)
            pamContext.start();
    }

    function stop() {
        if (pamContext.active)
            pamContext.abort();
    }

    // Μόνο respond — το start() γίνεται ήδη στο lock
    function authenticate(password) {
        if (pamContext.responseRequired)
            pamContext.respond(password);
        else
            console.warn("PAM not ready (responseRequired=false)");
    }
}
