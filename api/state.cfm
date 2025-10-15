<cfscript>
    cfheader(name="Content-Type", value="application/json");

    // Ensure session is initialized
    if (!structKeyExists(session, "gameState")) {
        session.gameState = {
            "currentScene": "start",
            "inventory": [],
            "savedAt": now()
        };
    }

    // --- File-based save setup ---
    dataDir = expandPath("../data");
    if (!directoryExists(dataDir)) {
        directoryCreate(dataDir);
    }
    saveFile = dataDir & "/saves.json";

    // --- Utility to safely load saves ---
    function loadSaves() {
        if (fileExists(saveFile)) {
            try {
                return deserializeJSON(fileRead(saveFile));
            } catch (any e) {
                // If corrupted file, start fresh
                return {};
            }
        } else {
            return {};
        }
    }

    // --- Utility to write saves ---
    function saveSaves(struct saves) {
        fileWrite(saveFile, serializeJSON(saves));
    }

    // --- Determine request method ---
    httpMethod = uCase(trim(cgi.request_method));

    // --- Prepare response ---
    response = {
        "success": false,
        "message": "",
        "scene": session.gameState.currentScene,
        "data": {}
    };

    try {
        switch (httpMethod) {

            // =======================================================
            // 🔹 POST — Save Game
            // =======================================================
            case "POST":
                requestBody = trim(getHttpRequestData().content);
                if (!len(requestBody)) {
                    response.message = "No data provided to save.";
                    break;
                }

                requestData = deserializeJSON(requestBody);

                // Validate input
                if (structKeyExists(requestData, "scene") && NOT isSimpleValue(requestData.scene)) {
                    throw(type="InvalidInput", message="Scene must be a string.");
                }
                if (structKeyExists(requestData, "inventory") && NOT isArray(requestData.inventory)) {
                    throw(type="InvalidInput", message="Inventory must be an array.");
                }

                // Update session
                if (structKeyExists(requestData, "scene")) {
                    session.gameState.currentScene = requestData.scene;
                }
                if (structKeyExists(requestData, "inventory")) {
                    session.gameState.inventory = requestData.inventory;
                }
                session.gameState.savedAt = now();

                // Persist to file
                savedGames = loadSaves();
                savedGames[session.sessionID] = session.gameState;
                saveSaves(savedGames);

                // Success response
                response.success = true;
                response.message = "Game saved successfully!";
                response.data = {
                    "scene": session.gameState.currentScene,
                    "inventoryCount": arrayLen(session.gameState.inventory),
                    "savedAt": dateTimeFormat(session.gameState.savedAt, "yyyy-mm-dd HH:nn:ss")
                };
                break;

            // =======================================================
            // 🔹 GET — Load Game
            // =======================================================
            case "GET":
                savedGames = loadSaves();
                if (structKeyExists(savedGames, session.sessionID)) {
                    session.gameState = savedGames[session.sessionID];
                    response.message = "Game loaded from saved data.";
                } else {
                    response.message = "No saved game found; starting new game.";
                }

                response.success = true;
                response.scene = session.gameState.currentScene;
                response.data = {
                    "scene": session.gameState.currentScene,
                    "inventory": session.gameState.inventory,
                    "savedAt": structKeyExists(session.gameState, "savedAt") ?
                            dateTimeFormat(session.gameState.savedAt, "yyyy-mm-dd HH:nn:ss") :
                            "Unknown"
                };
                break;

            // =======================================================
            // 🔹 DELETE — New Game (reset)
            // =======================================================
            case "DELETE":
                session.gameState = {
                    "currentScene": "start",
                    "inventory": [],
                    "savedAt": now()
                };

                // Remove save from file
                savedGames = loadSaves();
                if (structKeyExists(savedGames, session.sessionID)) {
                    structDelete(savedGames, session.sessionID);
                    saveSaves(savedGames);
                }

                response.success = true;
                response.message = "Saved game deleted. Starting new game.";
                response.scene = "start";
                response.data = session.gameState;
                break;

            // =======================================================
            // 🔸 Unsupported HTTP Method
            // =======================================================
            default:
                cfheader(statuscode="405", statustext="Method Not Allowed");
                response.message = "HTTP method #httpMethod# not supported. Use GET, POST, or DELETE.";
                break;
        }

    } catch (any e) {
        cfheader(statuscode="500", statustext="Internal Server Error");
        response.success = false;
        response.message = "An error occurred: #e.message#";
        response.data = { "type": e.type, "detail": e.detail };
        writeLog(type="error", file="adventureGameAPI", text="Error in #httpMethod#: #e.message# - #e.detail#");
    }

    // --- Output final JSON ---
    writeOutput(serializeJSON(response));
</cfscript>
