#include <amxmodx>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <box_system>

new const g_szClassname[] = "box_killzone";

public plugin_init()
{
	register_plugin("Box Kill Zone", "0.1", "MrShark45");
}

public box_touch(box, ent, const szClass[])
{		
	if(!equal(szClass, g_szClassname)) 
		return PLUGIN_CONTINUE;
		
	if(!is_user_connected(ent))
		return PLUGIN_CONTINUE

	if(is_user_alive(ent) && cs_get_user_team(ent) == CS_TEAM_CT)
		ExecuteHamB(Ham_Killed, ent, 0, 0);

	return PLUGIN_CONTINUE;
}