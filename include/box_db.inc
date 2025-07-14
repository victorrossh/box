public mysql_init() {
	if (g_bDebugMode)
		log_amx("Attempting to create DbTuple with host: %s, user: %s, db: %s", g_eSettings[SQL_HOST], g_eSettings[SQL_USER], g_eSettings[SQL_DATABASE]);
	g_iSqlTuple = SQL_MakeDbTuple(g_eSettings[SQL_HOST], g_eSettings[SQL_USER], g_eSettings[SQL_PASSWORD], g_eSettings[SQL_DATABASE]);
	if (g_iSqlTuple == Empty_Handle) {
		if (g_bDebugMode)
			log_amx("Failed to create DbTuple. Check SQL_HOST, SQL_USER, SQL_PASSWORD, and SQL_DATABASE in box.cfg.");
		return;
	}
	SQL_SetAffinity(g_eSettings[SQL_TYPE]);

	new iErrorCode, szSqlError[128], Handle:iSqlConnection = SQL_Connect(g_iSqlTuple, iErrorCode, szSqlError, charsmax(szSqlError));
	if (iSqlConnection == Empty_Handle) {
		if (g_bDebugMode)
			log_amx("Connection failed (%i): %s", iErrorCode, szSqlError);
		g_iSqlTuple = Empty_Handle;
		return;
	} else {
		if (g_bDebugMode)
			log_amx("Connection successful.");
		SQL_FreeHandle(iSqlConnection);
	}
}

public DB_LoadMapConfig(const szMapName[]) {
	if (g_iSqlTuple == Empty_Handle) {
		if (g_bDebugMode)
			log_amx("Cannot load from database: Invalid SQL tuple handle. Check database connection.");
		static iReturn;
		ExecuteForward(g_fwdDBLoaded, iReturn);
		return;
	}

	new szQuery[256];
	formatex(szQuery, charsmax(szQuery),
		"SELECT type, box_id, origin_x, origin_y, origin_z, mins_x, mins_y, mins_z, maxs_x, maxs_y, maxs_z \
		 FROM box WHERE map = '%s'", szMapName);
	SQL_ThreadQuery(g_iSqlTuple, "QueryLoadMapConfigHandler", szQuery);
}

public QueryLoadMapConfigHandler(iFailState, Handle:iQuery, szError[], iErrorCode) {
	if (iFailState) {
		if (g_bDebugMode)
			check_and_log_query_error(iFailState, szError, iErrorCode);
		return;
	}

	new Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3];
	new szType[32], szId[32];

	while (SQL_MoreResults(iQuery)) {
		SQL_ReadResult(iQuery, 0, szType, charsmax(szType));
		SQL_ReadResult(iQuery, 1, szId, charsmax(szId));
		SQL_ReadResult(iQuery, 2, fOrigin[0]);
		SQL_ReadResult(iQuery, 3, fOrigin[1]);
		SQL_ReadResult(iQuery, 4, fOrigin[2]);
		SQL_ReadResult(iQuery, 5, fMins[0]);
		SQL_ReadResult(iQuery, 6, fMins[1]);
		SQL_ReadResult(iQuery, 7, fMins[2]);
		SQL_ReadResult(iQuery, 8, fMaxs[0]);
		SQL_ReadResult(iQuery, 9, fMaxs[1]);
		SQL_ReadResult(iQuery, 10, fMaxs[2]);

		BOX_Create(szType, szId, fOrigin, fMins, fMaxs);

		if (g_bDebugMode)
			log_amx("Box loaded: Type=%s, Id=%s, Origin=(%.2f, %.2f, %.2f), Mins=(%.2f, %.2f, %.2f), Maxs=(%.2f, %.2f, %.2f)",
				szType, szId, fOrigin[0], fOrigin[1], fOrigin[2], fMins[0], fMins[1], fMins[2], fMaxs[0], fMaxs[1], fMaxs[2]);
		SQL_NextRow(iQuery);
	}

	static iReturn;
	ExecuteForward(g_fwdDBLoaded, iReturn);
}

public DB_SaveMapConfig() {
	if (g_iSqlTuple == Empty_Handle) {
		if (g_bDebugMode)
			log_amx("Cannot save to database: Invalid SQL tuple handle. Check database connection.");
		return;
	}

	new szQuery[512];
	new szMapName[32];
	get_mapname(szMapName, charsmax(szMapName));
	strtolower(szMapName);

	if (g_bDebugMode)
		log_amx("Saving map '%s' with %d zones to database.", szMapName, giZonesP);

	if (giZonesP > 0) {
		formatex(szQuery, charsmax(szQuery), "DELETE FROM box WHERE map = '%s'", szMapName);
		if (g_bDebugMode)
			log_amx("Executing query: %s", szQuery);
		SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery);

		new szType[32], szId[32], Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3];
		for (new i = 0; i < giZonesP; i++) {
			new ent = giZones[i];
			if (!pev_valid(ent)) {
				if (g_bDebugMode)
					log_amx("Invalid entity at index %d, skipping.", i);
				continue;
			}

			pev(ent, PEV_TYPE, szType, charsmax(szType));
			pev(ent, PEV_ID, szId, charsmax(szId));
			pev(ent, pev_origin, fOrigin);
			pev(ent, pev_mins, fMins);
			pev(ent, pev_maxs, fMaxs);

			new escaped_type[64], escaped_id[64];
			SQL_QuoteString(Empty_Handle, escaped_type, charsmax(escaped_type), szType);
			SQL_QuoteString(Empty_Handle, escaped_id, charsmax(escaped_id), szId);

			formatex(szQuery, charsmax(szQuery),
				"INSERT INTO box (map, type, box_id, origin_x, origin_y, origin_z, mins_x, mins_y, mins_z, maxs_x, maxs_y, maxs_z) \
				 VALUES ('%s', '%s', '%s', %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f)",
				szMapName, escaped_type, escaped_id,
				fOrigin[0], fOrigin[1], fOrigin[2],
				fMins[0], fMins[1], fMins[2],
				fMaxs[0], fMaxs[1], fMaxs[2]);
			if (g_bDebugMode)
				log_amx("Executing query: %s", szQuery);
			SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery);
		}
	} else {
		if (g_bDebugMode)
			log_amx("No zones to save for map '%s', skipping insertion.", szMapName);
	}
}

public QueryHandler(iFailState, Handle:iQuery, szError[], iErrorCode) {
	if (g_bDebugMode)
		check_and_log_query_error(iFailState, szError, iErrorCode);
}

check_and_log_query_error(iFailState, const szError[], iErrorCode) {
	switch (iFailState) {
		case TQUERY_CONNECT_FAILED: log_amx("Connection failed (%i): %s", iErrorCode, szError);
		case TQUERY_QUERY_FAILED: log_amx("Query failed (%i): %s", iErrorCode, szError);
	}
}