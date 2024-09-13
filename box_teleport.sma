#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <box_system>

new const g_szClassname[] = "box_teleport";
new Float:g_flSpawnPoint[3];
new Float:g_flVelocity[3];

public plugin_init()
{
	register_plugin("Box Teleport Zone", "0.1", "MrShark45");

	new iEnt = find_ent_by_class(iEnt, "info_player_start");
	pev(iEnt, pev_origin, g_flSpawnPoint);

	g_flVelocity[0] = 0.0;
	g_flVelocity[1] = 0.0;
	g_flVelocity[2] = 0.0;
}

public box_touch(box, ent, const szClass[])
{		
	if(!equal(szClass, g_szClassname)) 
		return PLUGIN_CONTINUE;
		
	if(!is_user_connected(ent))
		return PLUGIN_CONTINUE;

	if(is_user_alive(ent) && cs_get_user_team(ent) == CS_TEAM_CT)
	{
		set_pev(ent, pev_origin, g_flSpawnPoint);
		set_pev(ent, pev_velocity, g_flVelocity);
	}
		

	return PLUGIN_CONTINUE;
}