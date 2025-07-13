// Debug and SQL Configuration
#define DEBUG 1
#define USE_SQL 1 // Set the data saving mode: use 1 for SQL or 0 for .json file

// Entity Limits
#define MAX_ENTITIES 512

// Entity Property Shortcuts
#define PEV_TYPE    FAKEMETA_PEV_TYPE
#define PEV_ID      FAKEMETA_PEV_ID

// Menu and Input Configuration
#define KEYSBOX     (1<<0)|(1<<1)|(1<<2)|(1<<4)|(1<<5)|(1<<8)|(1<<9)
#define m_flNextAttack                   83  // (float) Gametime of nextattack

// Default Box Size Definitions
#define DEFAULT_MINSIZE { -32.0, -32.0, -32.0 }
#define DEFAULT_MAXSIZE { 32.0, 32.0, 32.0 }

// Touch Detection Variables
new gbTouchActive[MAX_PLAYERS + 1][MAX_ENTITIES];

// Model Definitions
new const gszModel[] = "sprites/cnt1.spr";

// Zone Management Variables
new giUNIQUE = 1;
new giZones[MAX_ENTITIES];
new Array:giZonesHistory[MAX_ENTITIES];
new giZonesP = 0;
new giZonesLast[33] = {-1, ...};
new gszType[33] = {-1, ...};

// Sprite and Rendering Variables
new sprite_line;

// Player Interaction Variables
new gbInMenu[33];
new Float:gfDistance[33];
new giCatched[33];
new giMarked[33];

// Forward Handles
new fwOnStartTouch;
new fwOnStopTouch;
new fwOnTouch;
new fwOnCreate;
new fwOnDelete;

// Storage Variables
new gszConfigDir[256];
new gszConfigDirPerMap[256];
new gszConfigFile[256+32];
new giConfigFile;

// Editor Mode Control
new bool:gbEditorMode = false;

// MySQL Settings
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
// ----------------------------------------------------------------------- //