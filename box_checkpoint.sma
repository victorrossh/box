#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <box_system>

#define MAX_PLAYERS 32
#define MAX_ENTITIES 512
#define MAX_CHECKPOINTS 8

native get_user_run_time(id);
forward timer_player_started(id);

new const g_szClassname[] = "box_checkpoint";

// entity id (0–512) -> checkpoint index (0–63)
new g_iEntToCheckpoint[MAX_ENTITIES + 1];

// total checkpoints on map
new g_iCheckpointCount;

// per-player checkpoint touched
new bool:g_bPlayerTouched[MAX_PLAYERS + 1][MAX_CHECKPOINTS];

public plugin_init()
{
    register_plugin("Box Checkpoint", "0.1", "MrShark45");

    // initialize entity mapping to -1
    for(new i; i <= MAX_ENTITIES; i++)
        g_iEntToCheckpoint[i] = -1;
}

public client_putinserver(id)
{
    ResetPlayerCheckpoints(id);
}

public box_created(ent, const szClass[])
{
    if(!equal(szClass, g_szClassname))
        return;

    if(g_iCheckpointCount >= MAX_CHECKPOINTS)
        return;

    g_iEntToCheckpoint[ent] = g_iCheckpointCount;
    g_iCheckpointCount++;
}

public box_touch(ent, id, const szClass[])
{
    if(!is_user_alive(id))
        return PLUGIN_CONTINUE;

    new checkpoint = g_iEntToCheckpoint[ent];

    // not one of our checkpoints
    if(checkpoint == -1)
        return PLUGIN_CONTINUE;

    // already touched
    if(g_bPlayerTouched[id][checkpoint])
        return PLUGIN_CONTINUE;

    g_bPlayerTouched[id][checkpoint] = true;

    new iTimeMS = get_user_run_time(id);
    if(iTimeMS <= 0)
        return PLUGIN_CONTINUE;

    client_print(id, print_chat,
        "[Checkpoint] %d:%02d.%02d",
        iTimeMS / 6000,
        (iTimeMS / 100) % 60,
        iTimeMS % 100
    );

    return PLUGIN_CONTINUE;
}

public timer_player_started(id)
{
    ResetPlayerCheckpoints(id);
}

stock ResetPlayerCheckpoints(id)
{
    for(new i; i < g_iCheckpointCount; i++)
        g_bPlayerTouched[id][i] = false;
}
