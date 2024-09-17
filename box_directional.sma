#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <box_system>

enum _:DIR{
	X = 0,  // Positive X direction
	_X,     // Negative X direction
	Y,      // Positive Y direction
	_Y      // Negative Y direction
}

new const g_szClassname[4][] = {
	"box_directionalX",
	"box_directionalY",
	"box_directionalX-",
	"box_directionalY-"
}

new const g_aDirections[4] = {
	X,
	_X,
	Y,
	_Y
}

public plugin_init()
{
	register_plugin("Box Directional Zone", "0.1", "MrShark45");
}

public box_touch(box, ent, const szClass[])
{	
	new type = isBox(szClass);
	if(type == -1) 
		return PLUGIN_CONTINUE;
		
	if(!is_user_connected(ent))
		return PLUGIN_CONTINUE;

	if(is_user_alive(ent) && cs_get_user_team(ent) == CS_TEAM_CT)
	{
		bounce_player(ent, g_aDirections[type]);
	}
	
	return PLUGIN_CONTINUE;
}

stock bounce_player(id, type)
{
	new Float:velocity[3];
	get_user_velocity(id, velocity);

	// Adjust velocity based on the direction type
	switch(type)
	{
		case X:
		{
			velocity[0] = floatabs(velocity[0]); // Set positive X velocity
		}
		case _X:
		{
			velocity[0] = -floatabs(velocity[0]); // Set negative X velocity
		}
		case Y:
		{
			velocity[1] = floatabs(velocity[1]); // Set positive Y velocity
		}
		case _Y:
		{
			velocity[1] = -floatabs(velocity[1]); // Set negative Y velocity
		}
	}

	// Apply the new velocity
	set_user_velocity(id, velocity);
	return PLUGIN_CONTINUE;
}

public isBox(const szClassname[])
{
	for(new i = 0; i < 4; i++)
	{
		if(equal(szClassname, g_szClassname[i]))
			return i;
	}
	return -1;
}
