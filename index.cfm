<cfscript>
savedScene = "start";
if (structKeyExists(session, "gameState") && isStruct(session.gameState)) {
    savedScene = session.gameState.currentScene;
}
</cfscript>

<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Adventure Game</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>

    <div class="container" style="text-align: center;">
        <h1>Adventure Game</h1>
        <p>Welcome, adventurer! Your journey awaits.</p>

        <div class="menu">
            <a class="menu-btn" href="adventure.cfm?scene=start">Start New Adventure</a>
            <a class="menu-btn" href="adventure.cfm?scene=#savedScene#">Continue Saved Game</a>
        </div>
    </div>

</body>
</html>
</cfoutput>
