<cfscript>
    // Instantiate the Game component
    gameEngine = new components.Game();

    // Determine the current scene: URL param takes priority, fallback to session
    currentScene = structKeyExists(url, "scene") ? url.scene : (
        structKeyExists(session, "gameState") ? session.gameState.currentScene : "start"
    );

    // Reset session if "reset=true" in URL (for New Game)
    if (structKeyExists(url, "reset") AND url.reset EQ "true") {
        session.gameState = {
            currentScene = "start",
            inventory = []
        };
        currentScene = "start";
    }

    // Initialize session game state if not already
    if (!structKeyExists(session, "gameState")) {
        session.gameState = {
            currentScene = "start",
            inventory = []
        };
    }

    // Retrieve scene data from the game engine
    sceneData = gameEngine.getScene(currentScene);

    // Handle item pickup if there's an item in this scene
    itemPickedUp = false;
    if (structKeyExists(sceneData, "item") && len(trim(sceneData.item))) {
        if (!arrayContains(session.gameState.inventory, sceneData.item)) {
            arrayAppend(session.gameState.inventory, sceneData.item);
            itemPickedUp = true;
        }
    }

    // Update current scene in session
    session.gameState.currentScene = currentScene;

    // Prepare choices array
    choices = structKeyExists(sceneData, "choices") ? sceneData.choices : [];
    isEndOfStory = arrayLen(choices) EQ 0;
</cfscript>

<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>#sceneData.title# - Adventure Game</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <div class="center-container">
        <h1>#sceneData.title#</h1>

        <div class="story-box">
            <p>#sceneData.storyText#</p>
            <cfif itemPickedUp>
                <p class="inventory"><strong>You picked up:</strong> #sceneData.item#</p>
            </cfif>
        </div>

        <cfif NOT isEndOfStory>
            <ul>
                <cfloop array="#choices#" index="choice">
                    <li>
                        <a href="adventure.cfm?scene=#encodeForURL(choice.destination)#">
                            #choice.text#
                        </a>
                    </li>
                </cfloop>
            </ul>
        <cfelse>
            <p><strong>The End.</strong> <a class="end-link" href="adventure.cfm?scene=start">Start Over</a></p>
        </cfif>
    </div> <!-- end center-container -->

    <div class="game-buttons">
        <button onclick="saveGame()">Save Game</button>
        <button onclick="loadGame()">Load Game</button>
        <button onclick="newGame()">New Game</button>
        <!-- inline message -->
        <div id="statusMessage" style="margin-top:10px; color:green; font-weight:bold;"></div>
    </div>

    <!-- Inventory Bar -->
    <div class="inventory-bar">
        <strong>Inventory:</strong>
        <cfif arrayLen(session.gameState.inventory) GT 0>
            <cfloop array="#session.gameState.inventory#" index="item">
                <span class="item-badge">#item#</span>
            </cfloop>
        <cfelse>
            <span><em>Empty</em></span>
        </cfif>
    </div>

<script>
function showStatus(message, color = "green") {
    const statusDiv = document.getElementById("statusMessage");
    statusDiv.style.color = color;
    statusDiv.textContent = message;
    setTimeout(() => (statusDiv.textContent = ""), 3000);
}

// --- Save Game ---
async function saveGame() {
    const data = {
        scene: "#encodeForJavaScript(currentScene)#",
        inventory: #serializeJSON(session.gameState.inventory)#
    };
    const res = await fetch("api/state.cfm", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data)
    });
    const result = await res.json();
    showStatus(result.message || "Game saved successfully!");
}

// --- Load Game ---
async function loadGame() {
    const res = await fetch("api/state.cfm", { method: "GET" });
    const result = await res.json();
    if (result.success && result.scene) {
        showStatus(result.message || "Game loaded from saved data!");
        setTimeout(() => {
            window.location.href = "adventure.cfm?scene=" + encodeURIComponent(result.scene);
        }, 1000);
    } else {
        showStatus(result.message || "No saved game found.", "red");
    }
}

// --- New Game ---
async function newGame() {
    const res = await fetch("api/state.cfm", { method: "DELETE" });
    const result = await res.json();

    showStatus(result.message || "New game started!");

    setTimeout(() => {
        window.location.href = "adventure.cfm?scene=start&reset=true";
    }, 1000);
}
</script>

</body>
</html>
</cfoutput>
