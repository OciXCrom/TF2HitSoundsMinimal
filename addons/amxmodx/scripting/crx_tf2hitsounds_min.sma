#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>

#define PLUGIN_VERSION "1.0 [Minimal]"
#define XO_PLAYER 5
#define MAX_STREAK 5

new g_iSound[33], g_iCrit[33], g_iCritR[33], g_iKillstreak[33], g_iStreak[33]
new m_LastHitGroup = 75
new g_iVault

new const g_szMiscSounds[][] = {
	"tf2/crit_hit.wav",
	"tf2/crit_received.wav",
	"tf2/killstreak.wav"
}

new const g_szHitSounds[][] = {
	"tf2/hitsound_default.wav",
	"tf2/hitsound_beepo.wav",
	"tf2/hitsound_electro1.wav",
	"tf2/hitsound_note1.wav",
	"tf2/hitsound_percussion1.wav",
	"tf2/hitsound_retro1.wav",
	"tf2/hitsound_space.wav",
	"tf2/hitsound_squasher.wav",
	"tf2/hitsound_vortex1.wav"
}

new const g_szSoundNames[][] = {
	"Default",
	"Beepo",
	"Electro",
	"Notes",
	"Percussion",
	"Retro",
	"Space",
	"Squasher",
	"Vortex",
	"\rOff"
}

public plugin_init()
{
	register_plugin("TF2: Hit Sounds", PLUGIN_VERSION, "OciXCrom")
	register_cvar("TF2HitSounds", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_event("DeathMsg", "eventKilled", "a")
	RegisterHam(Ham_Spawn, "player", "eventSpawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "eventDamage", 0)
	register_clcmd("say /hitsounds", "menuSounds")
	register_clcmd("say_team /hitsounds", "menuSounds")
	register_clcmd("say /hsnd", "menuSounds")
	register_clcmd("say_team /hsnd", "menuSounds")
	g_iVault = nvault_open("TF2HitSounds")
}

public client_putinserver(id)
	LoadData(id)

public client_disconnect(id)
	SaveData(id)

public SaveData(id)
{	
	new szVaultKey[64], szVaultData[256], szName[32]
	get_user_name(id, szName, charsmax(szName))
	format(szVaultKey, charsmax(szVaultKey), "%s", szName)
	format(szVaultData, charsmax(szVaultData), "%i#%i#%i#%i#", g_iSound[id], g_iCrit[id], g_iCritR[id], g_iKillstreak[id])
	nvault_set(g_iVault, szVaultKey, szVaultData)
	return PLUGIN_CONTINUE
}

LoadData(id)
{
	new szVaultKey[64], szVaultData[256], szName[32]
	get_user_name(id, szName, charsmax(szName))
	format(szVaultKey, charsmax(szVaultKey), "%s", szName)
	format(szVaultData, charsmax(szVaultData), "%i#%i#%i#%i#", g_iSound[id], g_iCrit[id], g_iCritR[id], g_iKillstreak[id])
	nvault_get(g_iVault, szVaultKey, szVaultData, charsmax(szVaultData))
	replace_all(szVaultData, charsmax(szVaultData), "#", " ")
	
	new iSound[2], iCrit[2], iCritR[2], iKillstreak[2]
	parse(szVaultData, iSound, charsmax(iSound), iCrit, charsmax(iCrit), iCritR, charsmax(iCritR), iKillstreak, charsmax(iKillstreak))
	
	g_iSound[id] = str_to_num(iSound)
	g_iCrit[id] = str_to_num(iCrit)
	g_iCritR[id] = str_to_num(iCritR)
	g_iKillstreak[id] = str_to_num(iKillstreak)
	
	return PLUGIN_CONTINUE
}

public menuSounds(id)
{	
	new szTitle[128], szItem[64], iSound = g_iSound[id]
	formatex(szTitle, charsmax(szTitle), "\rTeam Fortress 2: \yHit Sounds")
	new iSoundsMenu = menu_create(szTitle, "handlerSounds")

	formatex(szItem, charsmax(szItem), "Current Hit Sound: \y%s", g_szSoundNames[iSound])
	menu_additem(iSoundsMenu, szItem, "0", 0)
	
	formatex(szItem, charsmax(szItem), "%sPreview Hit Sound", iSound == 9 ? "\d" : "")
	menu_additem(iSoundsMenu, szItem, "1", 0)
	
	formatex(szItem, charsmax(szItem), "Crit Sound: %s", !g_iCrit[id] ? "\yEnabled" : "\rDisabled")
	menu_additem(iSoundsMenu, szItem, "2", 0)
	
	formatex(szItem, charsmax(szItem), "Crit Received: %s", !g_iCritR[id] ? "\yEnabled" : "\rDisabled")
	menu_additem(iSoundsMenu, szItem, "3", 0)
	
	formatex(szItem, charsmax(szItem), "Killstreak: %s", !g_iKillstreak[id] ? "\yEnabled" : "\rDisabled")
	menu_additem(iSoundsMenu, szItem, "4", 0)
	
	menu_setprop(iSoundsMenu, MPROP_EXITNAME, "\rClose the menu")
	menu_display(id, iSoundsMenu, 0)
	return PLUGIN_HANDLED
}

public handlerSounds(id, iSoundsMenu, iItem)
{	
	if(iItem == MENU_EXIT)
	{
		menu_destroy(iSoundsMenu)
		return PLUGIN_HANDLED
	}
	
	new iName[64], szData[6], access, callback
	menu_item_getinfo(iSoundsMenu, iItem, access, szData, charsmax(szData), iName, charsmax(iName), callback)
	new iKey = str_to_num(szData)
	
	switch(iKey)
	{
		case 0:
		{
			if(g_iSound[id] < sizeof(g_szSoundNames) - 1) g_iSound[id]++
			else g_iSound[id] = 0
		}
		case 1: player_hitsound(id)
		case 2: g_iCrit[id] = g_iCrit[id] ? 0 : 1
		case 3: g_iCritR[id] = g_iCritR[id] ? 0 : 1
		case 4: g_iKillstreak[id] = g_iKillstreak[id] ? 0 : 1
	}
	
	menu_destroy(iSoundsMenu)
	menuSounds(id)
	return PLUGIN_HANDLED
}
		
public player_hitsound(id)
{
	new iSound = g_iSound[id]
	
	if(iSound != 9)
		client_cmd(id, "spk %s", g_szHitSounds[iSound])
}

public player_critsound(id, iType)
	client_cmd(id, "spk %s", g_szMiscSounds[iType])
	
public player_streaksound(id)
	client_cmd(id, "spk %s", g_szMiscSounds[2])
	
public eventKilled()
{
	new iAttacker = read_data(1), iVictim = read_data(2)
	
	if(!is_user_connected(iAttacker) || !is_user_connected(iVictim) || iAttacker == iVictim)
		return
		
	if(g_iStreak[iAttacker] < MAX_STREAK - 1) g_iStreak[iAttacker]++
	else
	{
		g_iStreak[iAttacker] = 0
		
		if(!g_iKillstreak[iAttacker])
			player_streaksound(iAttacker)
	}
}

public eventSpawn(id)
	g_iKillstreak[id] = 0

public eventDamage(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageBits)
{
	if(!is_user_connected(iAttacker) || !is_user_connected(iVictim) || get_user_team(iAttacker) == get_user_team(iVictim) || iAttacker == iVictim)
		return HAM_IGNORED
		
	if(get_pdata_int(iVictim, m_LastHitGroup, XO_PLAYER) == HIT_HEAD)
	{
		if(!g_iCrit[iAttacker]) player_critsound(iAttacker, 0)
		else player_hitsound(iAttacker)
		if(!g_iCritR[iVictim]) player_critsound(iVictim, 1)
	}
	else player_hitsound(iAttacker)
	return HAM_IGNORED
}
	
public plugin_precache()
{
	for(new i = 0; i < sizeof(g_szMiscSounds); i++)
		precache_sound(g_szMiscSounds[i])
		
	for(new i = 0; i < sizeof(g_szHitSounds); i++)
		precache_sound(g_szHitSounds[i])
}