#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <box_system>

#define FALLOFF 0.9

new const g_szClassnameAll[] = "box_bounce"; 
new const g_szClassnameCT[] = "box_bounce_ct";
new const g_szClassnameT[] = "box_bounce_t";

public plugin_init()
{
	register_plugin("Box Bounce Zone", "0.2", "MrShark45");
}

public box_touch(box, ent, const szClass[])
{		
	if(!is_user_connected(ent)) 
		return PLUGIN_CONTINUE;

	if(!is_user_alive(ent))
		return PLUGIN_CONTINUE;

	new CsTeams:team = cs_get_user_team(ent);

	if(team == CS_TEAM_CT && equal(szClass, g_szClassnameCT)) 
		bounce_player(ent);
	else if(team == CS_TEAM_T && equal(szClass, g_szClassnameT))
		bounce_player(ent);
	else if(equal(szClass, g_szClassnameAll))
		bounce_player(ent);

	return PLUGIN_CONTINUE;
}

stock bounce_player(id)
{
	new Float:velocity[3];

	get_user_velocity(id, velocity);

	velocity[0] = -velocity[0] * FALLOFF;
	velocity[1] = -velocity[1] * FALLOFF;
	velocity[2] = -velocity[2] * FALLOFF;

	set_user_velocity(id, velocity);
	return PLUGIN_CONTINUE;
}
