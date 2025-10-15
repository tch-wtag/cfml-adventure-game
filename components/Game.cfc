<cfcomponent displayname="Game" output="false">

    <!--- Constructor: read the story JSON --->
    <cffunction name="init" access="public" returntype="any" output="false">
        <cfset variables.story = {}>

        <!--- Robust path to story.json --->
        <cfset var filePath = expandPath(getDirectoryFromPath(getCurrentTemplatePath()) & "../story.json")>

        <!--- Check if file exists --->
        <cfif NOT fileExists(filePath)>
            <cfthrow message="story.json not found at #filePath#">
        </cfif>

        <!--- Read and deserialize JSON --->
        <cfset var jsonData = fileRead(filePath)>
        <cfset variables.story = deserializeJSON(jsonData)>

        <cfreturn this>
    </cffunction>

    <!--- Get a scene by name --->
    <cffunction name="getScene" access="public" returntype="struct" output="false">
        <cfargument name="sceneName" type="string" required="true">

        <cfif structKeyExists(variables.story, arguments.sceneName)>
            <cfreturn variables.story[arguments.sceneName]>
        <cfelse>
            <cfreturn { "title": "Unknown", "storyText": "This scene does not exist.", "choices": [] }>
        </cfif>
    </cffunction>

</cfcomponent>
