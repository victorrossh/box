#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <json>
#include <celltrie>

new giTypeColors[32][3];
new gszTypeClass[32][32];
new giTypes = -1;

new Trie:gTypes; 

Types_LoadList()
{
	gTypes = TrieCreate();
	
	new dp = open_dir(gszConfigFile, gszConfigFile[giConfigFile], charsmax(gszConfigFile));
	
	if(!dp) return;
	
	Types_LoadFromFile(gszConfigFile);
 
	while(next_file(dp, gszConfigFile[giConfigFile], charsmax(gszConfigFile)))
	{   
		Types_LoadFromFile(gszConfigFile);
	}
	close_dir(dp);
}

Types_LoadFromFile(const szFile[])
{
	if(szFile[giConfigFile] == '.') return;
	
	Types_Load(szFile)
}

Types_Load(const filePath[])
{
	// Open the JSON file
	new JSON:jTypeFile = json_parse(filePath, true, true);

	// Check if the JSON object is valid
	if (json_is_object(jTypeFile))
	{
		// Variables to hold the data
		new JSON:jColor, szType[32];
		new r, g, b;
		
		giTypes++;

		json_object_get_string(jTypeFile, "type", szType, charsmax(szType));
		if (g_bDebugMode)
			log_to_file("json_debug.log", "Type value: %s", szType);

		format(gszTypeClass[giTypes], charsmax(gszTypeClass[]), szType);
		TrieSetCell(gTypes, gszTypeClass[giTypes], giTypes );

		// Get the color object
		jColor = json_object_get_value(jTypeFile, "color");
		if (json_is_object(jColor))
		{
			// Retrieve color values
			r = json_object_get_number(jColor, "r");
			g = json_object_get_number(jColor, "g");
			b = json_object_get_number(jColor, "b");

			giTypeColors[giTypes][0] = r;
			giTypeColors[giTypes][1] = g;
			giTypeColors[giTypes][2] = b;

			if (g_bDebugMode)
			{
				// Log color values
				log_to_file("json_debug.log", "Color R: %d", r);
				log_to_file("json_debug.log", "Color G: %d", g);
				log_to_file("json_debug.log", "Color B: %d", b);
			}
		}
		else
		{
			if (g_bDebugMode)
				log_to_file("json_debug.log", "Failed to retrieve color data for %s", szType);
		}
		if (g_bDebugMode)
			log_to_file("json_debug.log", "---------------------------");

		// Free the JSON object memory
		json_free(jTypeFile);
	}
	else
	{
		if (g_bDebugMode)
			log_to_file("json_debug.log", "Failed to parse JSON file or file is not an object.");
	}
}

getTypeId(const szNetName[])
{
	new iType = -1;
	TrieGetCell(gTypes, szNetName, iType);
	
	return iType;
}

getTypeColor(ent, iColor[3])
{
	if(!pev_valid(ent)) return 0;
		
	new szNetName[32];
	pev(ent, PEV_TYPE, szNetName, 31);
	
	new iType;
	if(TrieGetCell(gTypes, szNetName, iType))
	{
		iColor[0] = giTypeColors[iType][0];
		iColor[1] = giTypeColors[iType][1];
		iColor[2] = giTypeColors[iType][2];
	}
	else
	{
		iColor[0] = 50;
		iColor[1] = 255;
		iColor[2] = 50;
	}
	return 1;
}