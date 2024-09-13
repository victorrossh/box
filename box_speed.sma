#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <box_system>

new const g_szClassname[] = "box_speed";

public plugin_init()
{
	register_plugin("Box Limit Speed Zone", "0.1", "MrShark45");
}

public box_touch(box, ent, const szClass[])
{		
	if(!equal(szClass, g_szClassname)) 
		return PLUGIN_CONTINUE;
		
	if(!is_user_connected(ent))
		return PLUGIN_CONTINUE;

	if(is_user_alive(ent) && cs_get_user_team(ent) == CS_TEAM_CT)
	{
		limit_user_velocity(ent, 250);
	}
		

	return PLUGIN_CONTINUE;
}

stock limit_user_velocity(id, value){
	new Float:velocity[3], Float:x, Float:y;
	get_user_velocity(id, velocity);
	new Float:speed = floatsqroot(floatpower(velocity[0],2.0) + floatpower(velocity[1],2.0));
	if(speed > value){
		x = velocity[0]/speed;
		y = velocity[1]/speed;
		velocity[0] = x * value;
		velocity[1] = y * value;
	}
	set_user_velocity(id, velocity);
	return PLUGIN_CONTINUE;
}