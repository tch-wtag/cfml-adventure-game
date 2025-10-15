component {

    this.name = "AdventureGame";
    this.applicationTimeout = createTimeSpan(0,2,0,0);
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0,0,30,0);

    public void function onSessionStart() {
        if (!structKeyExists(session, "gameState") || !isStruct(session.gameState)) {
            session.gameState = {
                "currentScene": "start",
                "inventory": [],
                "savedAt": now()
            };
        }
    }

    public void function onError(required any exception, required string eventName) {
        writeOutput("<h2>Oops! Something went wrong</h2>");
        writeOutput("<p>#encodeForHTML(exception.message)#</p>");
        writeOutput("<p><a href='index.cfm'>Return to Start</a></p>");
    }
}
