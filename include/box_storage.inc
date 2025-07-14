#include <amxmodx>
#include <fakemeta>
#include <json>

BOX_Save()
{
	if (giZonesP == 0) return;

	new szValue[32];
	new szID[32];
	new Float:fOrigin[3];

	// Create a JSON array to hold the boxes
	new JSON:jConfigsFile = json_init_array();

	// Iterate over the array of boxes
	for (new i = 0; i < giZonesP; i++)
	{
		new ent = giZones[i];
		
		pev(ent, PEV_TYPE, szValue, 31);
		pev(ent, PEV_ID, szID, 31);
		pev(ent, pev_origin, fOrigin);

		// Create a JSON object for each box
		new JSON:jBoxObject = json_init_object();

		// Add "Type" and "Id" to the box object
		json_object_set_string(jBoxObject, "Type", szValue); // Type
		json_object_set_string(jBoxObject, "Id", szID);	  // Id

		// Add "Origin" to the box object
		new JSON:jOrigin = json_init_object();
		json_object_set_real(jOrigin, "X", fOrigin[0]);  // Origin X
		json_object_set_real(jOrigin, "Y", fOrigin[1]);  // Origin Y
		json_object_set_real(jOrigin, "Z", fOrigin[2]);  // Origin Z
		json_object_set_value(jBoxObject, "Origin", jOrigin);  // Add Origin to box object

		pev(ent, pev_mins, fOrigin);

		// Add "Mins" to the box object
		new JSON:jMins = json_init_object();
		json_object_set_real(jMins, "X", fOrigin[0]);  // Mins X
		json_object_set_real(jMins, "Y", fOrigin[1]);  // Mins Y
		json_object_set_real(jMins, "Z", fOrigin[2]);  // Mins Z
		json_object_set_value(jBoxObject, "Mins", jMins);  // Add Mins to box object

		pev(ent, pev_maxs, fOrigin);

		// Add "Maxs" to the box object
		new JSON:jMaxs = json_init_object();
		json_object_set_real(jMaxs, "X", fOrigin[0]);  // Maxs X
		json_object_set_real(jMaxs, "Y", fOrigin[1]);  // Maxs Y
		json_object_set_real(jMaxs, "Z", fOrigin[2]);  // Maxs Z
		json_object_set_value(jBoxObject, "Maxs", jMaxs);  // Add Maxs to box object

		// Add the box object to the array
		json_array_append_value(jConfigsFile, jBoxObject);

		if (g_bDebugMode)
		{
			log_to_file("json_debug.log", "Box %d saved with Type: %s, Id: %s", i, szValue, szID);
			log_to_file("json_debug.log", "Origin: X: %.2f, Y: %.2f, Z: %.2f", fOrigin[0], fOrigin[1], fOrigin[2]);
			log_to_file("json_debug.log", "Mins: X: %.2f, Y: %.2f, Z: %.2f", fOrigin[0], fOrigin[1], fOrigin[2]);
			log_to_file("json_debug.log", "Maxs: X: %.2f, Y: %.2f, Z: %.2f", fOrigin[0], fOrigin[1], fOrigin[2]);
		}
	}

	// Save the JSON array to the file
	json_serial_to_file(jConfigsFile, gszConfigDirPerMap, true);
	
	// Free the JSON object memory
	json_free(jConfigsFile);
}

BOX_Load()
{
	// Opening the JSON file
	new JSON:jConfigsFile = json_parse(gszConfigDirPerMap, true, true);
	new Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3];
	
	// Check if the JSON data is an array
	if (json_is_array(jConfigsFile))
	{
		// Loop through each object in the JSON array
		new size = json_array_get_count(jConfigsFile);
		for (new i = 0; i < size; i++)
		{
			// Get the JSON object at position i in the array
			new JSON:iBoxObject = json_array_get_value(jConfigsFile, i);
			
			// Retrieve and log the "Type" value
			new szType[32];
			json_object_get_string(iBoxObject, "Type", szType, charsmax(szType));

			if (g_bDebugMode)
				log_to_file("json_debug.log", "Box %d loaded with Type: %s", i, szType);

			// Retrieve and log the "Id" value
			new szId[32];
			json_object_get_string(iBoxObject, "Id", szId, charsmax(szId));
			
			if (g_bDebugMode)
				log_to_file("json_debug.log", "Id value: %s", szId);
			
			// Retrieve and log the "Origin" values
			new JSON:jOrigin = json_object_get_value(iBoxObject, "Origin");
			if (json_is_object(jOrigin))
			{
				fOrigin[0] = json_object_get_real(jOrigin, "X");
				fOrigin[1] = json_object_get_real(jOrigin, "Y");
				fOrigin[2] = json_object_get_real(jOrigin, "Z");

				if (g_bDebugMode)
				{
					log_to_file("json_debug.log", "Origin X: %.2f", fOrigin[0]);
					log_to_file("json_debug.log", "Origin Y: %.2f", fOrigin[1]);
					log_to_file("json_debug.log", "Origin Z: %.2f", fOrigin[2]);
				}
			}
			
			// Retrieve and log the "Mins" values
			new JSON:jMins = json_object_get_value(iBoxObject, "Mins");
			if (json_is_object(jMins))
			{
				fMins[0] = json_object_get_real(jMins, "X");
				fMins[1] = json_object_get_real(jMins, "Y");
				fMins[2] = json_object_get_real(jMins, "Z");

				if (g_bDebugMode)
				{
					log_to_file("json_debug.log", "Mins X: %.2f", fMins[0]);
					log_to_file("json_debug.log", "Mins Y: %.2f", fMins[1]);
					log_to_file("json_debug.log", "Mins Z: %.2f", fMins[2]);
				}
			}
			
			// Retrieve and log the "Maxs" values
			new JSON:jMaxs = json_object_get_value(iBoxObject, "Maxs");
			if (json_is_object(jMaxs))
			{
				fMaxs[0] = json_object_get_real(jMaxs, "X");
				fMaxs[1] = json_object_get_real(jMaxs, "Y");
				fMaxs[2] = json_object_get_real(jMaxs, "Z");

				if (g_bDebugMode)
				{
					log_to_file("json_debug.log", "Maxs X: %.2f", fMaxs[0]);
					log_to_file("json_debug.log", "Maxs Y: %.2f", fMaxs[1]);
					log_to_file("json_debug.log", "Maxs Z: %.2f", fMaxs[2]);
				}
			}
			
			if (g_bDebugMode)
				log_to_file("json_debug.log", "---------------------------");
			
			// Create the box using the loaded data
			BOX_Create(szType, szId, fOrigin, fMins, fMaxs);
		}
		
		// Free the memory for the main JSON array
		json_free(jConfigsFile);
	}
	else
	{
		if (g_bDebugMode)
			log_to_file("json_debug.log", "Failed to parse JSON file or file is not an array.");
	}
}