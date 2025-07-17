#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <xs>
#include <json>
#include <sqlx>
#include <box_globals>
#include <box_system>
#include <box_types>
#include <box_db>

#if !USE_SQL
#include <box_storage>
#endif

#define PLUGIN "Box"
#define VERSION "2.0"
#define AUTHOR "R3X (Modified by MrShark45 and ftl~)"

public LOAD_SETTINGS() {
	new szFilename[256];
	get_configsdir(szFilename, charsmax(szFilename));
	add(szFilename, charsmax(szFilename), "/box.cfg");
	new iFilePointer = fopen(szFilename, "rt");
	new szData[256], szKey[32], szValue[256];

	if (iFilePointer) {
		while (!feof(iFilePointer)) {
			fgets(iFilePointer, szData, charsmax(szData));
			trim(szData);

			switch (szData[0]) {
				case EOS, '#', ';': continue;
			}

			strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=');
			trim(szKey); trim(szValue);

			if (equal(szKey, "SQL_TYPE")) {
				copy(g_eSettings[SQL_TYPE], charsmax(g_eSettings[SQL_TYPE]), szValue);
			}
			if (equal(szKey, "SQL_HOST")) {
				copy(g_eSettings[SQL_HOST], charsmax(g_eSettings[SQL_HOST]), szValue);
			}
			if (equal(szKey, "SQL_USER")) {
				copy(g_eSettings[SQL_USER], charsmax(g_eSettings[SQL_USER]), szValue);
			}
			if (equal(szKey, "SQL_PASSWORD")) {
				copy(g_eSettings[SQL_PASSWORD], charsmax(g_eSettings[SQL_PASSWORD]), szValue);
			}
			if (equal(szKey, "SQL_DATABASE")) {
				copy(g_eSettings[SQL_DATABASE], charsmax(g_eSettings[SQL_DATABASE]), szValue);
			}
		}
		fclose(iFilePointer);
	}
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_menucmd(register_menuid("box"), KEYSBOX|(1<<6), "Pressedbox");

	register_clcmd("box", "cmdBox", ADMIN_IMMUNITY);
	register_clcmd("boxid", "cmdBoxRename", ADMIN_IMMUNITY);
	register_clcmd("radio1", "cmdUndo", ADMIN_IMMUNITY);
	
	register_think("box", "Box_Think");
	
	register_forward(FM_TraceLine, "fwTraceLine", 1);
	register_forward(FM_PlayerPreThink, "fwPlayerPreThink", 1);
	
	register_touch("box", "*", "fwBoxTouch");
	
	fwOnStartTouch = CreateMultiForward("box_start_touch", ET_STOP, FP_CELL, FP_CELL, FP_STRING);
	fwOnStopTouch = CreateMultiForward("box_stop_touch", ET_STOP, FP_CELL, FP_CELL, FP_STRING);
	fwOnTouch = CreateMultiForward("box_touch", ET_STOP, FP_CELL, FP_CELL, FP_STRING);
	fwOnCreate = CreateMultiForward("box_created", ET_STOP, FP_CELL, FP_STRING);
	fwOnDelete = CreateMultiForward("box_deleted", ET_STOP, FP_CELL, FP_STRING);

	g_bDebugMode = bool:(plugin_flags() & AMX_FLAG_DEBUG);

	#if USE_SQL
		g_fwdDBLoaded = CreateMultiForward("box_db_loaded", ET_IGNORE);
		LOAD_SETTINGS();
		mysql_init();
	#endif
}

public plugin_precache() {
	precache_model(gszModel);
	sprite_line = precache_model("sprites/white.spr");
}

public plugin_cfg() {
	register_dictionary("box_editor.txt");

	get_configsdir(gszConfigDir, charsmax(gszConfigDir));
	
	copy(gszConfigFile, charsmax(gszConfigFile), gszConfigDir);
	add(gszConfigFile, charsmax(gszConfigFile), "/Box/types/");
	giConfigFile = strlen(gszConfigFile);

	new szMapName[32];
	get_mapname(szMapName, 31);
	
	copy(gszConfigDirPerMap, charsmax(gszConfigDirPerMap), gszConfigDir);
	add(gszConfigDirPerMap, charsmax(gszConfigDirPerMap), "/Box/");
	add(gszConfigDirPerMap, charsmax(gszConfigDirPerMap), szMapName);
	add(gszConfigDirPerMap, charsmax(gszConfigDirPerMap), ".json");
	
	Types_LoadList();
	
	#if USE_SQL
		strtolower(szMapName);
		DB_LoadMapConfig(szMapName);
	#else
		BOX_Load();
	#endif
}

public plugin_end() {
	#if USE_SQL
		if (g_iSqlTuple != Empty_Handle) {
			DB_SaveMapConfig();
			SQL_FreeHandle(g_iSqlTuple);
		}
	#else
		BOX_Save();
	#endif
}

public client_putinserver(id) {
	gbInMenu[id] = false;
	giCatched[id] = 0;
	giMarked[id] = 0;

	for (new i = 0; i < MAX_ENTITIES; i++)
		gbTouchActive[id][i] = 0;
}

public refreshMenu(id) {
	client_cmd(id, "box");
}

public cmdBoxRename(id, level, cid) {
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new iZonesLast = giZonesLast[id];
	
	if (iZonesLast != -1 && giZonesP) {    
		new szNewId[64];
		read_args(szNewId, 63);
		remove_quotes(szNewId);
		
		trim(szNewId);
		
		if (szNewId[0] != '^0')
			set_pev(giZones[iZonesLast], PEV_ID, szNewId);
			
		refreshMenu(id);
	}        
	return PLUGIN_HANDLED;
}

public cmdBox(id, level, cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
		
	BOX_EditorMode(true);
	
	new AddKeyBit = 0;
	new szMenu[512];
	
	formatex(szMenu, charsmax(szMenu), "\r[FWO] \d- \wBox Menu^n^n");

	formatex(szMenu, charsmax(szMenu), "%s\r1. %L^n", szMenu, id, "CREATE_BOX");
	
	if (giZonesLast[id] != -1 && giZonesP)
		formatex(szMenu, charsmax(szMenu), "%s\r2. %L^n", szMenu, id, "REMOVE_BOX");
	else
		formatex(szMenu, charsmax(szMenu), "%s\d2. %L^n\w", szMenu, id, "REMOVE_BOX");
	
	formatex(szMenu, charsmax(szMenu), "%s\r3. %L: \y%s\w^n^n", szMenu, id, "BOX_CLASS", gszType[id] == -1 ? "box" : gszTypeClass[gszType[id]]);
	
	if (giZonesLast[id] != -1 && giZonesP)
		formatex(szMenu, charsmax(szMenu), "%s\r5. %L^n", szMenu, id, "GOTO_LAST");
	else
		formatex(szMenu, charsmax(szMenu), "%s\d5. %L^n\w", szMenu, id, "GOTO_LAST");
	
	formatex(szMenu, charsmax(szMenu), "%s\r6. %L^n^n", szMenu, id, "USE_NEAREST");
	
	if (giZonesLast[id] != -1 && giZonesP) {
		new szId[32];
		pev(giZones[giZonesLast[id]], PEV_ID, szId, 31);
		formatex(szMenu, charsmax(szMenu), "%s\r7. %L^n^n", szMenu, id, "UNIQUE", szId);
		AddKeyBit |= (1<<6);
	}
	
	formatex(szMenu, charsmax(szMenu), "%s\r9. \wNoClip - %s^n^n", szMenu, (pev(id, pev_movetype) == MOVETYPE_NOCLIP) ? "\yOn" : "\rOff");

	formatex(szMenu, charsmax(szMenu), "%s\r0. %L", szMenu, id, "BOX_EXIT");
	
	gbInMenu[id] = true;
	
	show_menu(id, KEYSBOX | AddKeyBit, szMenu, -1, "box");
	return PLUGIN_HANDLED;
}

public Pressedbox(id, key) {
	switch (key) {
		case 0: {
			new Float:fOrigin[3];
			pev(id, pev_origin, fOrigin);
			new ent = BOX_Create(gszType[id] == -1 ? "box" : gszTypeClass[gszType[id]], "", fOrigin, _, _, id);
			BOX_CreateAnchors(ent);
		}

		case 1: BOX_Remove(giZonesLast[id], id);

		case 2: {
			if (giTypes >= 0) {
				gszType[id]++;
				if (gszType[id] >= giTypes + 1)
					gszType[id] = -1;
				if (giZonesLast[id] != -1) {
					new ent = giZones[giZonesLast[id]];
					new iRet;
					new szClass[32];
					pev(ent, PEV_TYPE, szClass, 31);
					ExecuteForward(fwOnDelete, iRet, ent, szClass);
					set_pev(ent, PEV_TYPE, gszType[id] == -1 ? "box" : gszTypeClass[gszType[id]]);
					pev(ent, PEV_TYPE, szClass, 31);
					ExecuteForward(fwOnCreate, iRet, ent, szClass);
				}
			}
		}

		case 4: {
			if (giZonesLast[id] != -1 && giZonesP) {
				new ent = giZones[giZonesLast[id]];
				new Float:fOrigin[3];
				pev(ent, pev_origin, fOrigin);
				set_pev(id, pev_origin, fOrigin);
			}
		}

		case 5: {
			if (!giZonesP)
				client_print_color(id, print_chat, "%L", id, "THERE_IS_NO");
			else {
				new iNearest = -1;
				new Float:fNearestDistance = 9999999.0;
				new Float:fDistance;
				for (new i = 0; i < giZonesP; i++) {
					fDistance = entity_range(id, giZones[i]);
					if (fDistance < fNearestDistance) {
						fNearestDistance = fDistance;
						iNearest = i;
					}
				}
				if (iNearest >= 0) {
					new szClass[32];
					pev(giZones[iNearest], PEV_TYPE, szClass, 31);
					gszType[id] = getTypeId(szClass);
					Create_Implode(giZones[iNearest]);
					giZonesLast[id] = iNearest;
				}
			}
		}

		case 6: {
			client_cmd(id, "messagemode ^"boxid^"");
			return;
		}

		case 8: {
			new iMoveType = (pev(id, pev_movetype) == MOVETYPE_NOCLIP) ? MOVETYPE_WALK : MOVETYPE_NOCLIP;
			set_pev(id, pev_movetype, iMoveType);
		}

		case 9: {
			BOX_EditorMode(false);
			gbInMenu[id] = false;
			return;
		}
	}
	refreshMenu(id);
	return;
}

public cmdUndo(id, level, cid) {
	if (pev(id, pev_button) & IN_DUCK == 0 || !gbEditorMode || giZonesLast[id] == -1)
		return PLUGIN_CONTINUE;
		
	new ent = giZones[giZonesLast[id]];    
	if (!pev_valid(ent))
		return PLUGIN_CONTINUE;
		
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
		
	BOX_History_Pop(ent);
	client_cmd(id, "spk buttons/latchlocked2.wav");
		
	return PLUGIN_HANDLED;
}

public fwPlayerPreThink(id) {
	if (gbInMenu[id]) {
		set_pdata_float(id, m_flNextAttack, 1.0, 5);
				
		if (is_valid_ent(giCatched[id])) {
			if (pev(id, pev_button) & IN_ATTACK)
				BOX_AnchorMoveProcess(id, giCatched[id]);
			else
				BOX_AnchorMoveUninit(id, giCatched[id]);
		}
	}
}

public fwTraceLine(const Float:v1[], const Float:v2[], fNoMonsters, pentToSkip, ptr) {
	if (is_user_alive(pentToSkip)) {
		
		if (gbInMenu[pentToSkip]) {
			
			new ent = get_tr2(ptr, TR_pHit);
			
			if (!is_valid_ent(ent)) {
				BOX_AnchorMoveUnmark(pentToSkip, giMarked[pentToSkip]);
				return FMRES_IGNORED;
			}
				
			if (giCatched[pentToSkip]) {
				if (pev(pentToSkip, pev_button) & IN_ATTACK)
					BOX_AnchorMoveProcess(pentToSkip, giCatched[pentToSkip]);
				else
					BOX_AnchorMoveUninit(pentToSkip, giCatched[pentToSkip]);
			}
			else {
				new szClass[32];
				pev(ent, pev_classname, szClass, 31);
				if (equal(szClass, "box_anchor")) {
					if (pev(pentToSkip, pev_button) & IN_ATTACK)                
						BOX_AnchorMoveInit(pentToSkip, ent);
					else
						BOX_AnchorMoveMark(pentToSkip, ent);
				}
				else
					BOX_AnchorMoveUnmark(pentToSkip, giMarked[pentToSkip]);
			}
		}
	}
	return FMRES_IGNORED;
}

BOX_EditorMode(bool:status = true) {
	if (status) {
		if (gbEditorMode) return;
		
		for (new i = 0; i < giZonesP; i++)
			BOX_CreateAnchors(giZones[i]);
	}
	else {
		if (!gbEditorMode) return;
		
		for (new i = 0; i < giZonesP; i++) {
			BOX_RemoveAnchors(giZones[i]);
		}
	}
	gbEditorMode = status;
}

public BOX_Add(ent, id) {
	giZonesLast[id] = giZonesP;
	giZones[giZonesP] = ent;
	giZonesHistory[giZonesP] = ArrayCreate(3);
	giZonesP++;
}

BOX_Remove(num, id = 0) {
	if (giZonesLast[id] != -1 && giZonesP) {
		new ent = giZones[num];
		
		new iZonesLast = giZonesLast[id];
		
		giZones[iZonesLast] = giZones[--giZonesP];
		
		new Array:history = giZonesHistory[iZonesLast];
		giZonesHistory[iZonesLast] = giZonesHistory[giZonesP];
		ArrayDestroy(history);   
		
		new szClass[32];
		pev(ent, PEV_TYPE, szClass, 31);
		
		new iRet;
		ExecuteForward(fwOnDelete, iRet, ent, szClass);
				
		BOX_RemoveAnchors(ent);
		remove_entity(ent);
					
		giZonesLast[id] = -1;
		giMarked[id] = 0;
		giCatched[id] = 0;
	}
}

public BOX_GetEntIndex(ent) {
	for (new i = 0; i < giZonesP; i++)
	{
		if (giZones[i] == ent) return i;
	}
	return -1;
}

public BOX_History_Push(ent) {
	new index = BOX_GetEntIndex(ent);
	
	if (index == -1) return;
	
	new Array:history = giZonesHistory[index];
	
	new Float:fVec[3];
	
	pev(ent, pev_absmin, fVec);
	ArrayPushArray(history, fVec);
	
	pev(ent, pev_absmax, fVec);
	ArrayPushArray(history, fVec);
}

public BOX_History_Pop(ent) {
	new index = BOX_GetEntIndex(ent);
	
	if (index == -1) return 0;
	
	new Float:fMins[3];
	new Float:fMaxs[3];
	
	new Array:history = giZonesHistory[index];
	
	new iSize = ArraySize(history);

	if (iSize < 2) return 0;
	
	ArrayGetArray(history, iSize-1, fMaxs);
	ArrayGetArray(history, iSize-2, fMins);
	
	ArrayDeleteItem(history, --iSize);
	ArrayDeleteItem(history, --iSize);    
	
	BOX_UpdateSize(ent, fMaxs, fMins);
	
	return 1;
}

BOX_Create(const szClass[], const szId[], const Float:fOrigin[3], const Float:fMins[3] = DEFAULT_MINSIZE, const Float:fMaxs[3] = DEFAULT_MAXSIZE, editor = 0) {
	new ent = create_entity("info_target");
	
	entity_set_string(ent, EV_SZ_classname, "box");
	set_pev(ent, PEV_TYPE, szClass);
	
	new szActualId[32];
	if (szId[0] == '^0') {
		formatex(szActualId, 31, "Box#%d", (giUNIQUE));
		set_pev(ent, PEV_ID, szActualId);
	}
	else
		set_pev(ent, PEV_ID, szId);

	giUNIQUE++;
	
	DispatchSpawn(ent);
	
	entity_set_model(ent, gszModel);
	
	set_pev(ent, pev_effects, EF_NODRAW);
	set_pev(ent, pev_solid, SOLID_TRIGGER);
	set_pev(ent, pev_movetype, MOVETYPE_NONE);
	set_pev(ent, pev_enemy, 1);
	
	set_pev(ent, pev_nextthink, get_gametime()+0.1);
	BOX_Add(ent, editor);
	
	entity_set_origin(ent, fOrigin);
	entity_set_size(ent, fMins, fMaxs);
	
	new iRet;
	ExecuteForward(fwOnCreate, iRet, ent, szClass);
	
	return ent;
}

public BOX_CreateAnchors(ent) {
	new Float:fMins[3], Float:fMaxs[3];
	pev(ent, pev_absmin, fMins);
	pev(ent, pev_absmax, fMaxs);
	
	BOX_CreateAnchorsEntity(ent, 0b000, fMins[0], fMins[1], fMins[2]);
	BOX_CreateAnchorsEntity(ent, 0b001, fMins[0], fMaxs[1], fMins[2]);
	BOX_CreateAnchorsEntity(ent, 0b010, fMaxs[0], fMins[1], fMins[2]);
	BOX_CreateAnchorsEntity(ent, 0b011, fMaxs[0], fMaxs[1], fMins[2]);
	BOX_CreateAnchorsEntity(ent, 0b100, fMins[0], fMins[1], fMaxs[2]);
	BOX_CreateAnchorsEntity(ent, 0b101, fMins[0], fMaxs[1], fMaxs[2]);
	BOX_CreateAnchorsEntity(ent, 0b110, fMaxs[0], fMins[1], fMaxs[2]);
	BOX_CreateAnchorsEntity(ent, 0b111, fMaxs[0], fMaxs[1], fMaxs[2]);
}

public BOX_GetAnchor(box, num) {
	new ent = 0;
	new a = -1;
	while ((a = find_ent_by_owner(a, "box_anchor", box)))
	{
		if (pev(a, pev_iuser4) == num) {
			ent = a;
			break;
		}
	}
	return ent;
}

public BOX_UpdateAnchorsEntity(box, num, Float:x, Float:y, Float:z) {
	new ent = BOX_GetAnchor(box, num);
	
	if (is_valid_ent(ent)) {
		new Float:fOrigin[3];
		fOrigin[0] = x;
		fOrigin[1] = y;
		fOrigin[2] = z;
		
		entity_set_origin(ent, fOrigin);
	}
}

public BOX_CreateAnchorsEntity(box, num, Float:x, Float:y, Float:z) {    
	new Float:fOrigin[3];
	fOrigin[0] = x;
	fOrigin[1] = y;
	fOrigin[2] = z;
		
	new ent = create_entity("info_target");
	entity_set_string(ent, EV_SZ_classname, "box_anchor");
		
	entity_set_model(ent, gszModel);
	entity_set_origin(ent, fOrigin);
		
	entity_set_size(ent, Float:{-3.0, -3.0, -3.0}, Float:{3.0, 3.0, 3.0});
		
	set_pev(ent, pev_solid, SOLID_BBOX);
	set_pev(ent, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(ent, pev_owner, box);
		
	set_pev(ent, pev_iuser4, num);
	
	set_pev(ent, pev_scale, 0.25);
		
	set_rendering(ent, kRenderFxPulseFast, 0, 150, 0, kRenderTransAdd, 255);
}

public BOX_RemoveAnchors(box) {
	new ent = -1;
	while ((ent = find_ent_by_owner(ent, "box_anchor", box))) {
		remove_entity(ent);
	}
}

public BOX_AnchorMoveProcess(id, ent) {
	if (giCatched[id] != ent)
		BOX_AnchorMoveInit(id, ent);
	
	new Float:fVec[3];
	pev(id, pev_v_angle, fVec);
	angle_vector(fVec, ANGLEVECTOR_FORWARD, fVec);
	
	xs_vec_mul_scalar(fVec, gfDistance[id], fVec);
	
	new Float:fOrigin[3];
	pev(id, pev_origin, fOrigin);
	
	new Float:fView[3];
	pev(id, pev_view_ofs, fView);
	
	xs_vec_add(fOrigin, fView, fOrigin);
	xs_vec_add(fOrigin, fVec, fVec);
	
	set_pev(ent, pev_origin, fVec);    
	if(g_bDebugMode)
		server_print("[DEBUG] BOX_AnchorMoveProcess: Moved anchor %d to (%f, %f, %f)", ent, fVec[0], fVec[1], fVec[2]);
	
	new box = pev(ent, pev_owner);
	new num1 = pev(ent, pev_iuser4);
	
	new num2 = (~num1)&0b111;
	new ent2 = BOX_GetAnchor(box, num2);
	
	new Float:fVec2[3];
	pev(ent2, pev_origin, fVec2);
	
	BOX_UpdateSize(box, fVec, fVec2, num1);
}

BOX_UpdateSize(box, const Float:fVec[3], const Float:fVec2[3], anchor = -1) {
	new Float:fMins[3];
	fMins[0] = floatmin(fVec[0], fVec2[0]);
	fMins[1] = floatmin(fVec[1], fVec2[1]);
	fMins[2] = floatmin(fVec[2], fVec2[2]);
	
	new Float:fMaxs[3];
	fMaxs[0] = floatmax(fVec[0], fVec2[0]);
	fMaxs[1] = floatmax(fVec[1], fVec2[1]);
	fMaxs[2] = floatmax(fVec[2], fVec2[2]);
	

	anchor != 0b000 && BOX_UpdateAnchorsEntity(box, 0b000, fMins[0], fMins[1], fMins[2]);
	anchor != 0b001 && BOX_UpdateAnchorsEntity(box, 0b001, fMins[0], fMaxs[1], fMins[2]);
	anchor != 0b010 && BOX_UpdateAnchorsEntity(box, 0b010, fMaxs[0], fMins[1], fMins[2]);
	anchor != 0b011 && BOX_UpdateAnchorsEntity(box, 0b011, fMaxs[0], fMaxs[1], fMins[2]);
	anchor != 0b100 && BOX_UpdateAnchorsEntity(box, 0b100, fMins[0], fMins[1], fMaxs[2]);
	anchor != 0b101 && BOX_UpdateAnchorsEntity(box, 0b101, fMins[0], fMaxs[1], fMaxs[2]);
	anchor != 0b110 && BOX_UpdateAnchorsEntity(box, 0b110, fMaxs[0], fMins[1], fMaxs[2]);
	anchor != 0b111 && BOX_UpdateAnchorsEntity(box, 0b111, fMaxs[0], fMaxs[1], fMaxs[2]);
	
	new Float:fOrigin[3];
	xs_vec_add(fMaxs, fMins, fOrigin);
	xs_vec_mul_scalar(fOrigin, 0.5, fOrigin);
	
	xs_vec_sub(fMaxs, fOrigin, fMaxs);
	xs_vec_sub(fMins, fOrigin, fMins);
	
	entity_set_origin(box, fOrigin);
	entity_set_size(box, fMins, fMaxs);
}

public BOX_AnchorMoveMark(id, ent) {
	giMarked[id] = ent;
	set_pev(ent, pev_scale, 0.35);
}

public BOX_AnchorMoveUnmark(id, ent) {
	giMarked[id] = 0;
	set_pev(ent, pev_scale, 0.25);
}

public BOX_AnchorMoveInit(id, ent) {
	static szClass[32];
	
	gfDistance[id] = entity_range(id, ent);
	giCatched[id] = ent;
	
	set_rendering(ent, kRenderFxGlowShell, 255, 0, 0, kRenderTransAdd, 255);
	
	new box = pev(ent, pev_owner);
	for (new i = 0; i < giZonesP; i++) {
		if (giZones[i] == box) {
			giZonesLast[id] = i;
			
			pev(box, PEV_TYPE, szClass, 31);
			gszType[id] = getTypeId(szClass);
			refreshMenu(id);
			break;
		}
	}
	
	BOX_History_Push(pev(ent, pev_owner));
}

public BOX_AnchorMoveUninit(id, ent) {    
	gfDistance[id] = 0.0;
	giCatched[id] = 0;
	
	set_rendering(ent, kRenderFxNone, 0, 150, 0, kRenderTransAdd, 255);
}

public _Box_Think(ent) {
	new Float:fMins[3], Float:fMaxs[3];
	pev(ent, pev_absmin, fMins);
	pev(ent, pev_absmax, fMaxs);
	
	_Create_Line(ent, fMaxs[0], fMaxs[1], fMaxs[2], fMaxs[0], fMaxs[1], fMins[2]);
	_Create_Line(ent, fMins[0], fMaxs[1], fMaxs[2], fMins[0], fMaxs[1], fMins[2]);
	_Create_Line(ent, fMaxs[0], fMins[1], fMaxs[2], fMaxs[0], fMins[1], fMins[2]);
	_Create_Line(ent, fMins[0], fMins[1], fMaxs[2], fMins[0], fMins[1], fMins[2]);
	
	_Create_Line(ent, fMaxs[0], fMaxs[1], fMaxs[2], fMins[0], fMaxs[1], fMaxs[2]);
	_Create_Line(ent, fMaxs[0], fMaxs[1], fMins[2], fMins[0], fMaxs[1], fMins[2]);
	_Create_Line(ent, fMaxs[0], fMins[1], fMaxs[2], fMins[0], fMins[1], fMaxs[2]);
	_Create_Line(ent, fMaxs[0], fMins[1], fMins[2], fMins[0], fMins[1], fMins[2]);
	
	_Create_Line(ent, fMaxs[0], fMaxs[1], fMaxs[2], fMaxs[0], fMins[1], fMaxs[2]);
	_Create_Line(ent, fMins[0], fMaxs[1], fMaxs[2], fMins[0], fMins[1], fMaxs[2]);
	_Create_Line(ent, fMaxs[0], fMaxs[1], fMins[2], fMaxs[0], fMins[1], fMins[2]);
	_Create_Line(ent, fMins[0], fMaxs[1], fMins[2], fMins[0], fMins[1], fMins[2]);
	
	_Create_Line(ent, fMins[0], fMins[1], fMins[2], fMaxs[0], fMaxs[1], fMaxs[2]);
}

public Box_Think(ent) {
	gbEditorMode && _Box_Think(ent);
	set_pev(ent, pev_nextthink, get_gametime()+0.3);
}

public _Create_Line(ent, Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2) {
	new Float:start[3];
	start[0] = x1;
	start[1] = y1;
	start[2] = z1;
	
	new Float:stop[3];
	stop[0] = x2;
	stop[1] = y2;
	stop[2] = z2;
	
	Create_Line(ent, start, stop);
}

public Create_Line(ent, Float:start[], Float:stop[]) {
	new iColor[3];
	getTypeColor(ent, iColor);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(0);
	engfunc(EngFunc_WriteCoord, start[0]);
	engfunc(EngFunc_WriteCoord, start[1]);
	engfunc(EngFunc_WriteCoord, start[2]);
	engfunc(EngFunc_WriteCoord, stop[0]);
	engfunc(EngFunc_WriteCoord, stop[1]);
	engfunc(EngFunc_WriteCoord, stop[2]);
	write_short(sprite_line);
	write_byte(1);
	write_byte(5);
	write_byte(5);
	write_byte(7);
	write_byte(0);
	write_byte(iColor[0]);         // RED
	write_byte(iColor[1]);         // GREEN
	write_byte(iColor[2]);         // BLUE        
	write_byte(250);               // brightness
	write_byte(5);
	message_end();
}

public Create_Implode(ent) {
	new Float:fOrigin[3];
	pev(ent, pev_origin, fOrigin);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_IMPLOSION);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_byte(50);
	write_byte(12);
	write_byte(2);
	message_end();
}

public getBoxFromTaskId(tid, &box, &ent) {
	ent = tid&0xFFFF;
	box = (tid&0xFFFF0000) >> 16;
}

public getTaskIdFormBox(box, ent) {
	return ((box<<16) | ent);
}

public fwBoxTouch(box, ent) {
	if (gbEditorMode) return;

	if (g_bDebugMode)
		server_print("[DEBUG] fwBoxTouch called for box %d, ent %d", box, ent);

	new szClass[32];
	pev(box, PEV_TYPE, szClass, 31);
	
	new id = ent;
	if (id <= 0 || id > MAX_PLAYERS) {
		if (g_bDebugMode)
			server_print("[DEBUG] Invalid player ID %d", id);
		return;
	}

	// Check if it is the beginning of the touch
	if (!gbTouchActive[id][box]) {
		gbTouchActive[id][box] = 1;
		new iRet;
		if (!ExecuteForward(fwOnStartTouch, iRet, box, id, szClass)) {
		}
		if (g_bDebugMode)
			server_print("[DEBUG] Starting touch for box %d, type %s", box, szClass);
	}

	new iRet;
	if (!ExecuteForward(fwOnTouch, iRet, box, id, szClass)) {
	}
	if (g_bDebugMode)
		server_print("[DEBUG] Touching box %d, type %s", box, szClass);

	if (!is_valid_ent(box) || !is_user_alive(id)) {
		gbTouchActive[id][box] = 0;
		new iRetStop;
		if (g_bDebugMode)
			server_print("[DEBUG] Stopping touch for box %d", box);
		if (!ExecuteForward(fwOnStopTouch, iRetStop, box, id, szClass)) {
		}
	}
}

/*
public fwStartTouch(box, ent) {
	if (gbEditorMode) return;
	if (g_bDebugMode)
		server_print("[DEBUG] fwStartTouch called for box %d, ent %d", box, ent);
}

public fwStopTouch(box, ent) {
	if (gbEditorMode) return;
	if (g_bDebugMode)
		server_print("[DEBUG] fwStopTouch called for box %d, ent %d", box, ent);
}

public fwTouch(box, ent) {
	if (gbEditorMode) return;
	if (g_bDebugMode)
		server_print("[DEBUG] fwTouch called for box %d, ent %d", box, ent);
}
*/