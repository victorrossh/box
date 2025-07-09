#if defined _box_globals_included
	#endinput
#endif
#define _box_globals_included

// MySQL settings
enum Settings {
	SQL_TYPE[32],
	SQL_HOST[32],
	SQL_USER[32],
	SQL_PASSWORD[32],
	SQL_DATABASE[32]
};

new g_eSettings[Settings];
new Handle:g_iSqlTuple;
new g_fwdDBLoaded;