#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <box_system>

#define FALLOFF 0.3

new const g_szClassname[] = "box_bounce";

public plugin_init()
{
	register_plugin("Box Bounce Zone", "0.1", "MrShark45");
}

public box_touch(box, ent, const szClass[])
{		
	if(!equal(szClass, g_szClassname)) 
		return PLUGIN_CONTINUE;
		
	if(!is_user_connected(ent))
		return PLUGIN_CONTINUE;

	if(is_user_alive(ent) && cs_get_user_team(ent) == CS_TEAM_CT)
	{
		bounce_player(ent);
	}
		

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
