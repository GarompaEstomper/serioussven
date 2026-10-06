/*
Serious sam level main file
Weapons originally by Aperture, Modified by Zode
Rest scripted by Zode.
*/

/*
TODO:
- break samiam.as into more easy to edit multiple files.
- skill.as check
- music.as
- hud.as
- player.as

- challenge mode: lives & ranking (missing funcionality: ranking)
- entity: serious_spawner, for spawning shit
- entity: trigger_jumppad
- entity: serious_end/levelchange ? (to handle level transitions w/ skill settings n shit)
- flamethrower wont score
- grenade launcher missing sfx while holding
- better CoinOpFailure instead of just fade+restart
- control moosic (that is, able to stop and start the music system from map)
- add: reptiloids
- add: kleer
- add: werebull
- add: bio-mechs
- add: beheaded

- laser beam splash fx
- serious font counters (abandon: can't override hud.txt)
*/

/*
sprchannels used:
0,1 PWRUP 
2,3 PWRUP
4,5 PWRUP
6,7  PWRUP
8
9
10 deathcounter
11 crosshair
12 count
13 ilives
14 count 
15 ihiscore
*/

/*
targetnames:
votespawn - spawnpoints for skill vote room
firstspawn - spawnpoints for level itself.
music_medium - triggered when enemies exist, used for music 
music_peace - triggered when no enemies exist, used for music
*/

#include "skill"

#include "weapons/weapon_rocketlauncher"
#include "weapons/weapon_cannon"
#include "weapons/weapon_thompson"
#include "weapons/weapon_ssknife"
#include "weapons/weapon_colt"
#include "weapons/weapon_dualcolt"
#include "weapons/weapon_singleshot"
#include "weapons/weapon_doubleshot"
#include "weapons/weapon_ssminigun"
#include "weapons/weapon_grenadelauncher"
#include "weapons/weapon_flamer"
#include "weapons/weapon_ghostbuster"
#include "weapons/weapon_laser"
#include "weapons/weapon_minelayer"
#include "weapons/weapon_plasmathrower"
#include "weapons/weapon_sschainsaw"
#include "weapons/weapon_sssniper"

#include "enemies/gizmo"
#include "enemies/kamikaze"

#include "entities/trigger_look"
#include "entities/ammo"
#include "entities/armor"
#include "entities/health"
#include "entities/backpacks"
#include "entities/powerups"

//these always exist in the map
EHandle eMusicPeace;
EHandle eMusicMedium;
//vars for music
bool bMusicMode = false; // true for medium
bool bMusicLastMode = false;
int iMusicFade = 10;

//stuff
bool GLOBAL_COIN_COOP = false;
float GLOBAL_SCORE = 0;
float GLOBAL_LIVES = 0;

void pSound(string snd)
{
	g_SoundSystem.PrecacheSound(snd);
	g_Game.PrecacheGeneric("sound/"+snd);
}

class empty_entity : ScriptBaseEntity {}

void MapInit()
{	
	//these exist so that the game wont throw away the entities upon start, needed for remapping
	g_CustomEntityFuncs.RegisterCustomEntity( "empty_entity", "item_ss_armor_shard" );
	g_CustomEntityFuncs.RegisterCustomEntity( "empty_entity", "item_ss_armor_small" );
	g_CustomEntityFuncs.RegisterCustomEntity( "empty_entity", "item_ss_armor_medium" );
	g_CustomEntityFuncs.RegisterCustomEntity( "empty_entity", "item_ss_armor_strong" );
	g_CustomEntityFuncs.RegisterCustomEntity( "empty_entity", "item_ss_armor_super" );
	g_CustomEntityFuncs.RegisterCustomEntity( "empty_entity", "item_ss_health_pill" );
	g_CustomEntityFuncs.RegisterCustomEntity( "empty_entity", "item_ss_health_small" );
	g_CustomEntityFuncs.RegisterCustomEntity( "empty_entity", "item_ss_health_medium" );
	g_CustomEntityFuncs.RegisterCustomEntity( "empty_entity", "item_ss_health_large" );
	g_CustomEntityFuncs.RegisterCustomEntity( "empty_entity", "item_ss_health_super" );

	PrecachePlayerSounds();
	pSound( "serioussam/items/weapon.ogg" );
	pSound( "serioussam/items/ammo.ogg" );
	pSound( "serioussam/items/key.ogg" );
	pSound( "serioussam/items/itemplaced.ogg" );
	pSound( "serioussam/hey.ogg" );
	pSound( "serioussam/uh_oh.ogg" );
	pSound( "serioussam/extralife.ogg" );
	pSound( "serioussam/press.ogg" );
	pSound( "serioussam/select.ogg" );
	pSound( "serioussam/select2.ogg" );
	pSound( "serioussam/treasurebag.ogg" );
	pSound( "serioussam/treasurechest.ogg" );
	pSound( "serioussam/tele.ogg" );
	
	g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_bullets.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_cannonballs.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_cells.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_grenades.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_minepack.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_napalm.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_plasmapack.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_rockets.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_shells.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_sniperbullets.mdl" );
	
	g_Game.PrecacheModel( "sprites/serioussam/null.spr" );
	g_Game.PrecacheModel( "sprites/serioussam/chaticon.spr" );
	g_Game.PrecacheModel( "sprites/serioussam/hsuper.spr" );
	g_Game.PrecacheModel( "sprites/serioussam/ihiscore.spr" );
	g_Game.PrecacheModel( "sprites/serioussam/medal_bronze.spr" );
	g_Game.PrecacheModel( "sprites/serioussam/medal_silver.spr" );
	g_Game.PrecacheModel( "sprites/serioussam/medal_gold.spr" );
	g_Game.PrecacheModel( "sprites/serioussam/sscrosshair.spr" );
	g_Game.PrecacheModel( "sprites/serioussam/boink03.spr" );

	pSound("serioussam/items/healthsuper.ogg");
	pSound("serioussam/items/healthlarge.ogg");
	pSound("serioussam/items/healthmedium.ogg");
	pSound("serioussam/items/healthsmall.ogg");
	pSound("serioussam/items/healthpill.ogg");
	g_Game.PrecacheModel( "models/serioussam/items/health/super.mdl" ); // 200
	g_Game.PrecacheModel( "models/serioussam/items/health/large.mdl" ); // 100
	g_Game.PrecacheModel( "models/serioussam/items/health/medium.mdl" ); // 50
	g_Game.PrecacheModel( "models/serioussam/items/health/small.mdl" ); // 25
	g_Game.PrecacheModel( "models/serioussam/items/health/pill.mdl" ); // 1
	pSound("serioussam/items/armorsuper.ogg");
	pSound("serioussam/items/armorstrong.ogg");
	pSound("serioussam/items/armormedium.ogg");
	pSound("serioussam/items/armorsmall.ogg");
	pSound("serioussam/items/armorshard.ogg");
	g_Game.PrecacheModel( "models/serioussam/items/armor/super.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/armor/strong.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/armor/medium.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/armor/small.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/armor/shard.mdl" );
	
	pSound("serioussam/items/powerup.ogg");
	pSound("serioussam/items/powerupbeep.ogg");
	g_Game.PrecacheModel( "models/serioussam/items/backpack.mdl" );
	g_Game.PrecacheModel( "models/serioussam/items/seriousdamage.mdl" );
	g_Game.PrecacheModel( "sprites/serioussam/seriousdamage.spr" );
	g_Game.PrecacheModel( "models/serioussam/items/seriousspeed.mdl" );
	g_Game.PrecacheModel( "sprites/serioussam/seriousspeed.spr" );
	g_Game.PrecacheModel( "models/serioussam/items/seriousinvuln.mdl" );
	g_Game.PrecacheModel( "sprites/serioussam/seriousinvuln.spr" );
	g_Game.PrecacheModel( "models/serioussam/items/seriousjump.mdl" );
	g_Game.PrecacheModel( "sprites/serioussam/seriousjump.spr" );
	
	RegisterCANNON(); //fgd
	RegisterROCKETLAUNCHER(); //fgd
	RegisterTOMMY(); //fgd
	RegisterSSKNIFE(); //fgd
	RegisterCOLT(); //fgd
	RegisterDUALCOLT(); //fgd
	RegisterSingleShot(); //fgd
	RegisterDoubleShot();  //fgd
	RegisterSSMINIGUN(); //fgd
	RegisterGRENADELAUNCHER(); //fgd
	RegisterSSFLAMETHROWER(); //fgd
	RegisterSSFLAME(); 
	RegisterGHOSTBUSTER(); //fgd
	RegisterLASERRIFLE(); //fgd
	RegisterSSLASER(); //fgd
	RegisterMINELAYER(); //fgd
	RegisterSSMINE();
	RegisterPLASMATHROWER(); //fgd
	RegisterSSPLASMA();
	RegisterSSCHAINSAW(); //fgd
	RegisterSSSNIPER(); //fgd
	
	RegisterMonsterGizmo(); //fgd
	RegisterMonsterKamikaze(); //fgd
	
	g_CustomEntityFuncs.RegisterCustomEntity("trigger_look", "trigger_look"); // fgd
	RegisterMINEPACK(); //fgd
	RegisterPLASMAPACK(); //fgd
	RegisterSSSNIPERBULLETS(); //fgd
	RegisterSSROCKETS(); //fgd
	RegisterSSNAPALM(); //fgd
	RegisterSSGRENADES(); //fgd
	RegisterSSCELLS(); //fgd
	RegisterSSCANNONBALLS(); //fgd
	RegisterSSSHELLS(); //fgd
	RegisterSSBULLETS(); //fgd
	
	RegisterItemSSArmor(); //fgd
	RegisterItemSSHealth(); //fgd
	RegisterItemSSBackPack(); //fgd
	RegisterItemSSSeriousPack(); //fgd
	
	RegisterSSPowerUpSeriousDamage(); //
	RegisterSSPowerUpSeriousSpeed(); //
	RegisterSSPowerUpSeriousInvuln(); //
	RegisterSSPowerUpSeriousJump(); //
	
	g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @PlayerSpawn);
	g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @PlayerKilled);
	g_Hooks.RegisterHook(Hooks::Player::PlayerPostThink, @PlayerPostThink);
	g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);
	g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
	g_Hooks.RegisterHook(Hooks::Player::PlayerCanRespawn, @PlayerCanRespawn);
	g_Hooks.RegisterHook(Hooks::PickupObject::Collected, @PickupCollected);
	g_Scheduler.SetInterval("Update", 0.05, g_Scheduler.REPEAT_INFINITE_TIMES);
}

void Update()
{
	SkillLevel@ skl = cast<SkillLevel>(GLOBAL_SKILLMAP[GLOBAL_SKILL]);
	CBasePlayer@ pPlayer = null;
	for(int i = 0; i < g_Engine.maxClients; i++)
	{
		@pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if(pPlayer is null) continue;
		
		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
		int lastfrag = pCustom.GetKeyvalue("$i_sslastfrag").GetInteger();
		int floorfrag = int(floor(pPlayer.pev.frags));
		if(floorfrag > lastfrag)
		{
			if(skl is null)
				continue;
				
			int lastdelta = floorfrag - lastfrag;
			int newScore = int(floor(lastdelta*100*skl.scoreMultiplier));
			if(newScore < 1)
				newScore = 1;
			GLOBAL_SCORE += newScore;
			pCustom.SetKeyvalue("$i_sslastfrag", floorfrag);
		}
		else if(floorfrag < lastfrag)
		{
			 pCustom.SetKeyvalue("$i_sslastfrag", floorfrag);
		}
		
		if(GLOBAL_SCORE >= 1000000)
		{
			GLOBAL_SCORE -= 1000000;
			if(GLOBAL_SCORE < 0)
				GLOBAL_SCORE = 0;
				
			int newLives = int(floor(GetPlayerCount()*skl.extraLifeMultiplier)); 
			if(newLives < 1)
				newLives = 1;
				
			GLOBAL_LIVES += newLives;
			g_SoundSystem.EmitSound(g_EntityFuncs.IndexEnt(0), CHAN_STATIC, "serioussam/extralife.ogg", 1.0f, ATTN_NONE);
			CBasePlayer@ pTemp = null;
			for(int j = 0; j < g_Engine.maxClients; j++)
			{
				@pTemp = g_PlayerFuncs.FindPlayerByIndex(j);
				if(pTemp is null) continue;
				
				CustomKeyvalues@ pCustom2 = pTemp.GetCustomKeyvalues();
				pTemp.pev.frags = 0;
				pCustom2.SetKeyvalue("$i_sslastfrag", 0);
			}
		}
		
		g_PlayerFuncs.HudUpdateNum(pPlayer, 14, GLOBAL_SCORE);
		g_PlayerFuncs.HudUpdateNum(pPlayer, 12, GLOBAL_LIVES);
	
		CBaseEntity@ pEntity = g_Utility.FindEntityForward(pPlayer, 4096);
		
		HUDSpriteParams spriteParams;
		spriteParams.channel = 11;
		spriteParams.flags = HUD_ELEM_SCR_CENTER_X | HUD_ELEM_SCR_CENTER_Y;
		spriteParams.x = 0.0;
		spriteParams.y = 0.0;
		
		//192 128
		if(pPlayer.pev.fov != 0 || pPlayer.m_iHideHUD != 0 || !pPlayer.IsAlive())
		{
			spriteParams.color1 = RGBA(255, 255, 255, 0);
		}
		else if(pEntity is null)
		{
			spriteParams.color1 = RGBA(255, 255, 255, 255);
		}
		else
		{
			if(pEntity.Classify() == CLASS_NONE || !pEntity.IsAlive())
			{
				spriteParams.color1 = RGBA(255, 255, 255, 255);
			}
			else
			{
				if(pEntity.pev.health >= pEntity.pev.max_health*0.66)
				{
					spriteParams.color1 = RGBA(0, 255, 0, 255);
				}
				else if(pEntity.pev.health >= pEntity.pev.max_health*0.33)
				{
					spriteParams.color1 = RGBA(255, 255, 0, 255);
				}
				else
				{
					spriteParams.color1 = RGBA(255, 0, 0, 255);
				}
			}
		}
		spriteParams.spritename = "serioussam/sscrosshair.spr";
		g_PlayerFuncs.HudCustomSprite(pPlayer, spriteParams);
	}
}

int GetPlayerCount()
{
	int ret = 0;
	
	CBasePlayer@ pPlayer = null;
	for(int i = 0; i < g_Engine.maxClients; i++)
	{
		@pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if(pPlayer is null) continue;
		ret += 1;
	}
	
	return ret;
}

void MapActivate()
{
	GetEntity("music_peace");
	GetEntity("music_medium");
	g_Scheduler.SetInterval("musicTick", 0.1f);
	g_Scheduler.SetInterval("monsterTick", 2.0f);
	setMusicVolumes();
	g_EntityFuncs.FireTargets("votespawn", null, null, USE_ON, 0.0f, 0.0f);
	g_EntityFuncs.FireTargets("firstspawn", null, null, USE_OFF, 0.0f, 0.0f);
}

void MoveSpawn()
{
	g_PlayerFuncs.ScreenFadeAll(Vector(0.0, 16.0, 0.0), 3.0f, 0.0f, 255, 0);
	g_EntityFuncs.FireTargets("votespawn", null, null, USE_OFF, 0.0f, 0.0f);
	g_EntityFuncs.FireTargets("firstspawn", null, null, USE_ON, 0.0f, 0.0f);
	g_PlayerFuncs.RespawnAllPlayers(true, true);
	GLOBAL_SKILLVOTE_RUNNING = false;
}

void musicTick()
{
	if(bMusicMode)
		if(iMusicFade > 0)
		{
			iMusicFade = iMusicFade-1;
			setMusicVolumes();
		}
			
	if(!bMusicMode)
		if(iMusicFade < 10)
		{
			iMusicFade = iMusicFade+1;
			setMusicVolumes();
		}
}

void monsterTick()
{
	bool bFinalMode = false;
	CBaseEntity@ pSearch = null;
	while((@pSearch = g_EntityFuncs.FindEntityByClassname( pSearch, "monster_*" )) !is null)
	{
		if(pSearch.IsAlive())
		{
			int iRelation = pSearch.IRelationshipByClass(CLASS_PLAYER);
			if(iRelation != R_AL && iRelation != R_NO)
				bFinalMode = true;
		}
	}
	
	bMusicMode = bFinalMode;
}

void setMusicVolumes()
{
	CBaseEntity@ pMusicPeace = cast<CBaseEntity@>(eMusicPeace);
	CBaseEntity@ pMusicMedium = cast<CBaseEntity@>(eMusicMedium);
	// this thing below wont work until ambient_music updates its volume based on the keyvalue in real time
	//g_Game.AlertMessage( at_console, "SetMusicVolumes: "+string(iMusicFade)+" \n" );
	/*if(pMusicPeace !is null)
	{
		g_EntityFuncs.DispatchKeyValue(pMusicPeace.edict(), "volume", string(iMusicFade));
	}
	else
		g_Game.AlertMessage( at_console, "Music failure: pMusicPeace\n" );
		
	if(pMusicMedium !is null)
	{
		g_EntityFuncs.DispatchKeyValue(pMusicMedium.edict(), "volume", string(10-iMusicFade));
	}
	else
		g_Game.AlertMessage( at_console, "Music failure: pMusicMedium\n" );
	*/
		
	// workaround
	if(pMusicPeace !is null && pMusicMedium !is null)
	{
		if(iMusicFade == 10 && bMusicLastMode == true)
		{
			g_EntityFuncs.FireTargets("music_peace", null, null, USE_ON, 0.0f, 0.0f);
			g_EntityFuncs.FireTargets("music_medium", null, null, USE_OFF, 0.0f, 0.0f);
			bMusicLastMode = false;
		}else if(iMusicFade == 0 && bMusicLastMode == false)
		{
			g_EntityFuncs.FireTargets("music_peace", null, null, USE_OFF, 0.0f, 0.0f);
			g_EntityFuncs.FireTargets("music_medium", null, null, USE_ON, 0.0f, 0.0f);
			bMusicLastMode = true;
		}
	}
}

void GetEntity(string sInput)
{
	CBaseEntity@ pSearch = null;
	while((@pSearch = g_EntityFuncs.FindEntityByTargetname(pSearch, sInput)) !is null)
	{ // lels hardcoded cuz this thing isnt used anywhere else
		EHandle eSearch = pSearch;
		if(sInput == "music_peace")
			eMusicPeace = eSearch;
		else if(sInput == "music_medium")
			eMusicMedium = eSearch;
	}
}

void CS16GetDefaultShellInfo( EHandle &in ePlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale, bool leftShell, bool downShell )
{  
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );
	
	Vector vecForward, vecRight, vecUp;

	float fR;
	float fU;
	
	g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
	
	( leftShell == true ) ? fR = Math.RandomFloat( -70, -50 ) : fR = Math.RandomFloat( 50, 70 );
	( downShell == true ) ? fU = Math.RandomFloat( -150, -100 ) : fU = Math.RandomFloat( 100, 150 );
 
	for( int i = 0; i < 3; ++i )
	{
		ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
		ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
	}
}

void WW2DynamicTracer( Vector start, Vector end, NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
{
	NetworkMessage WW2DT( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
	WW2DT.WriteByte( TE_TRACER );
	WW2DT.WriteCoord( start.x );
	WW2DT.WriteCoord( start.y );
	WW2DT.WriteCoord( start.z );
	WW2DT.WriteCoord( end.x );
	WW2DT.WriteCoord( end.y );
	WW2DT.WriteCoord( end.z );
	WW2DT.End();
}

void WW2DynamicLight( Vector vecPos, int radius, int r, int g, int b, int8 life, int decay )
{
	NetworkMessage WW2DL( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
		WW2DL.WriteByte( TE_DLIGHT );
		WW2DL.WriteCoord( vecPos.x );
		WW2DL.WriteCoord( vecPos.y );
		WW2DL.WriteCoord( vecPos.z );
		WW2DL.WriteByte( radius );
		WW2DL.WriteByte( int(r) );
		WW2DL.WriteByte( int(g) );
		WW2DL.WriteByte( int(b) );
		WW2DL.WriteByte( life );
		WW2DL.WriteByte( decay );
	WW2DL.End();
}

void ScheduleSeriousItemSound(CBasePlayer @pPlayer, string m_sSound) 
{
	EHandle ePlayer = pPlayer;
	g_Scheduler.SetTimeout("ScheduledSeriousItemSound", 0.001, ePlayer, m_sSound);
}

void ScheduledSeriousItemSound(EHandle ePlayer, string m_sSound) 
{
	if(!ePlayer)
		return;
		
	CBaseEntity@ pEnt = ePlayer;
	CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEnt);
	
	g_SoundSystem.StopSound(pPlayer.edict(), CHAN_ITEM, "items/gunpickup2.wav", true);
	g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_ITEM, m_sSound, 1.0, ATTN_NORM);
}

HookReturnCode PlayerCanRespawn(CBasePlayer@ pPlayer, bool &out canSpawn)
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	if(pCustom.GetKeyvalue("$i_dead").GetInteger() == 0)
	{
		//needed so that the hook doesn't spam the fuck out of the scheduler since it seems to be checked multiple times if it returns false
		pCustom.SetKeyvalue("$i_dead", 1);
		EHandle ePlayer = pPlayer;
		g_Scheduler.SetTimeout("PostPlayerCanRespawn", 3.0, ePlayer);
		ShowDeathCounter(ePlayer, 3);
	}
	canSpawn = false;
	return HOOK_HANDLED;
}

void ShowDeathCounter(EHandle ePlayer, int count)
{
	if(!ePlayer)
		return;
		
	CBaseEntity@ pEnt = ePlayer;
	CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEnt);
	
	if(count > 0)
	{
		HUDSpriteParams spriteParams;
		spriteParams.channel = 10;
		spriteParams.flags = HUD_SPR_MASKED | HUD_ELEM_SCR_CENTER_X | HUD_ELEM_SCR_CENTER_Y;
		spriteParams.x = 0.0;
		spriteParams.y = 0.0;
		spriteParams.frame = count;
		spriteParams.numframes = 4;
		spriteParams.framerate = 0.0f;
		spriteParams.color1 = RGBA(255, 255, 255, 255);
		spriteParams.spritename = "serioussam/boink03.spr";
		g_PlayerFuncs.HudCustomSprite(pPlayer, spriteParams);
	
		count -= 1;
		g_Scheduler.SetTimeout("ShowDeathCounter", 1.0, ePlayer, count);
	}
	else
	{
		g_PlayerFuncs.HudToggleElement(pPlayer, 10, false);
	}
}

void PostPlayerCanRespawn(EHandle ePlayer)
{
	if(!ePlayer)
		return;
		
	CBaseEntity@ pEnt = ePlayer;
	CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEnt);
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	
	if(GLOBAL_COIN_COOP)
	{
		if(GLOBAL_LIVES > 0)
		{
			GLOBAL_LIVES -= 1;
			g_PlayerFuncs.RespawnPlayer(pPlayer, true, true);
			//cancel out middletext lol
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "");
			pCustom.SetKeyvalue("$i_dead", 0);
		}
		else
		{
			pPlayer.GetObserver().StartObserver(pPlayer.pev.origin, pPlayer.pev.angles);
			g_Scheduler.SetTimeout("PostObserverSet", 0.1, ePlayer);
		}
		
		CheckCoinOpConditions();
	}
	else
	{
		g_PlayerFuncs.RespawnPlayer(pPlayer, true, true);
		//cancel out middletext lol
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "");
		pCustom.SetKeyvalue("$i_dead", 0);
	}
}

void PostObserverSet(EHandle ePlayer)
{
	if(!ePlayer)
		return;

	if(GLOBAL_LIVES > 0)
	{
		PostPlayerCanRespawn(ePlayer);
		return;
	}
		
	CBaseEntity@ pEnt = ePlayer;
	CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEnt);
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	if(pCustom.GetKeyvalue("$i_dead").GetInteger() == 1)
	{
		pPlayer.m_flRespawnDelayTime = Math.FLOAT_MAX;
		g_Scheduler.SetTimeout("PostObserverSet", 1.0, ePlayer);
	}
}

HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue("$fl_lastHealth", pPlayer.pev.health);
	pCustom.SetKeyvalue("$fl_lastJump", 0.0);
	pCustom.SetKeyvalue("$fl_lastPain", 0.0);
	pCustom.SetKeyvalue("$fl_lastWater", 0.0);
	pCustom.SetKeyvalue("$i_wasInWater", 0);
	pCustom.SetKeyvalue("$i_dead", 0);
  
    return HOOK_CONTINUE;
}
HookReturnCode PlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib) 
{
	if(pPlayer.pev.waterlevel == WATERLEVEL_HEAD)
		g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "serioussam/player/deathwater.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
	else
		g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "serioussam/player/death.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
   
	return HOOK_CONTINUE;
}

HookReturnCode PlayerPostThink(CBasePlayer@ pPlayer) {
  PlayPlayerPainSounds(pPlayer);
  PlayPlayerJumpSounds(pPlayer);
  PlayPlayerWaterSounds(pPlayer);
  
  return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	HUDSpriteParams spriteParams;
	spriteParams.channel = 15;
	spriteParams.flags = HUD_SPR_MASKED;
	spriteParams.x = 0.02;
	spriteParams.y = 0.3;
	spriteParams.color1 = RGBA(255, 255, 255, 255);
	spriteParams.spritename = "serioussam/ihiscore.spr";
	g_PlayerFuncs.HudCustomSprite(pPlayer, spriteParams);
	
	HUDNumDisplayParams numParams;
	numParams.channel = 14;
	numParams.flags = HUD_NUM_LEADING_ZEROS;
	numParams.value = 0.0f;
	numParams.defdigits = 6;
	numParams.maxdigits = 18;
	numParams.x = 0.04;//850;
	numParams.y = 0.307;
	numParams.color1 = RGBA(255, 255, 255, 255);
	numParams.color2 = RGBA(255, 255, 255, 255);
	numParams.spritename = "serioussam/null.spr";
	g_PlayerFuncs.HudNumDisplay(pPlayer, numParams);
	
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	if(!pCustom.GetKeyvalue("$i_sslastfrag").Exists())
		pCustom.SetKeyvalue("$i_sslastfrag", 0);
		
	if(GLOBAL_COIN_COOP)
	{
		spriteParams.channel = 13;
		spriteParams.flags = HUD_SPR_MASKED;
		spriteParams.x = 0.02;
		spriteParams.y = 0.35;
		spriteParams.color1 = RGBA(255, 255, 255, 255);
		spriteParams.spritename = "serioussam/hsuper.spr";
		g_PlayerFuncs.HudCustomSprite(pPlayer, spriteParams);
		
		numParams.channel = 12;
		numParams.flags = HUD_NUM_LEADING_ZEROS;
		numParams.value = 0.0f;
		numParams.defdigits = 2;
		numParams.maxdigits = 18;
		numParams.x = 0.04;//850;
		numParams.y = 0.357;
		numParams.color1 = RGBA(255, 255, 255, 255);
		numParams.color2 = RGBA(255, 255, 255, 255);
		numParams.spritename = "serioussam/null.spr";
		g_PlayerFuncs.HudNumDisplay(pPlayer, numParams);
	}
	
	return HOOK_CONTINUE;
}

void SendCoinCoopToAll()
{
	CBasePlayer@ pPlayer = null;
	for(int i = 0; i < g_Engine.maxClients; i++)
	{
		@pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if(pPlayer is null) continue;
			
		HUDSpriteParams spriteParams;
		spriteParams.channel = 13;
		spriteParams.flags = HUD_SPR_MASKED;
		spriteParams.x = 0.02;
		spriteParams.y = 0.35;
		spriteParams.color1 = RGBA(255, 255, 255, 255);
		spriteParams.spritename = "serioussam/hsuper.spr";
		g_PlayerFuncs.HudCustomSprite(pPlayer, spriteParams);
		
		HUDNumDisplayParams numParams;
		numParams.channel = 12;
		numParams.flags = HUD_NUM_LEADING_ZEROS;
		numParams.value = 0.0f;
		numParams.defdigits = 2;
		numParams.maxdigits = 18;
		numParams.x = 0.04;//850;
		numParams.y = 0.357;
		numParams.color1 = RGBA(255, 255, 255, 255);
		numParams.color2 = RGBA(255, 255, 255, 255);
		numParams.spritename = "serioussam/null.spr";
		g_PlayerFuncs.HudNumDisplay(pPlayer, numParams);
	}
}

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer)
{
	CheckCoinOpConditions();
	return HOOK_CONTINUE;
}

dictionary itemscoretable =
{
	{"item_ss_seriousdamage", 150},
	{"item_ss_seriousspeed", 150},
	{"item_ss_seriousjump", 150},
	{"item_ss_seriousinvuln", 150},
	{"item_ss_seriouspack", 250},
	{"item_ss_backpack", 100},
	{"item_ss_armor", 5},
	{"item_ss_health", 5},
	{"ammo_", 5},
	{"weapon_", 200}
};

HookReturnCode PickupCollected(CBaseEntity@ object, CBaseEntity@ player)
{
	if(string(object.pev.classname).SubString(0,11) == "weapon_colt" || string(object.pev.classname).SubString(0,14) == "weapon_ssknife")
		return HOOK_CONTINUE;
		
	array<string> keys = itemscoretable.getKeys();
	for(uint i = 0; i < keys.length(); i++)
	{
		if(string(object.pev.classname).SubString(0,keys[i].Length()) == keys[i])
		{
			SkillLevel@ skl = cast<SkillLevel>(GLOBAL_SKILLMAP[GLOBAL_SKILL]);
			int newScore = int(floor(int(itemscoretable[keys[i]])*skl.scoreMultiplier));
			if(newScore < 1)
				newScore = 1;
			GLOBAL_SCORE += newScore;
			break;
		}
	}
	
	return HOOK_CONTINUE;
}

// based on quake scripts
void PlayPlayerPainSounds(CBasePlayer@ pPlayer) {
  // get all damage we've accumulated and play AUTHENTIC PAIN SOUNDS
  // there's no robust way to actually get damage that the player
  // received during the previous frame, so we store his previous health
  // in a custom keyvalue and also a pain timeout to not scream too often
  CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
  float flLastHealth = pCustom.GetKeyvalue("$fl_lastHealth").GetFloat();
  float flLastPain = pCustom.GetKeyvalue("$fl_lastPain").GetFloat();

  bool bInWater = pPlayer.pev.waterlevel == WATERLEVEL_HEAD ? true : false;
  
  if (flLastHealth <= pPlayer.pev.health) return;
  pCustom.SetKeyvalue("$fl_lastHealth", pPlayer.pev.health); 
  if (flLastPain > g_Engine.time) return;
  if (pPlayer.pev.health <= 0) return;

  float flDmg = pPlayer.m_lastPlayerDamageAmount;
  if (flDmg < 1.0 || (flLastHealth - pPlayer.pev.health < 1.0)) return;
  
  if(bInWater)
	g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "serioussam/player/drown.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
  else{
	  if ( flDmg > 20 )
	  {
		g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "serioussam/player/woundstrong.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
	  }else if ( flDmg >= 10 && flDmg <= 20 )
	  {
		g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "serioussam/player/woundmedium.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
	  }else if ( flDmg < 10 )
	  {
		g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "serioussam/player/woundweak.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
	  }
  }
  
  pCustom.SetKeyvalue("$fl_lastPain", g_Engine.time + 0.5f);
  
}

void PlayPlayerWaterSounds(CBasePlayer@ pPlayer){
	if(!pPlayer.IsAlive())
		return;
	
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flLastWater = pCustom.GetKeyvalue("$fl_lastWater").GetFloat();
	int iWasInWater = pCustom.GetKeyvalue("$i_wasInWater").GetInteger();
	if (flLastWater > g_Engine.time) return;
	
	if(pPlayer.pev.waterlevel == WATERLEVEL_HEAD && iWasInWater == 0)
	{
		g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_BODY, "serioussam/player/waterenter.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
		
		pCustom.SetKeyvalue("$i_wasInWater", 1);
	}else if(pPlayer.pev.waterlevel != WATERLEVEL_HEAD && iWasInWater == 1)
	{
		int iNoise = Math.RandomLong(0, 2);
		if(iNoise == 0)
		{
			g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "serioussam/player/inhale00.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
		}else if(iNoise == 1)
		{
			g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "serioussam/player/inhale01.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
		}else{
			g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "serioussam/player/inhale02.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
		}
		g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_BODY, "serioussam/player/waterleave.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
		
		pCustom.SetKeyvalue("$i_wasInWater", 0);
	}
	
	pCustom.SetKeyvalue("$fl_lastWater", g_Engine.time + 0.1);
}

// based on quake scripts
void PlayPlayerJumpSounds(CBasePlayer@ pPlayer) {
  CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
  float flLastJump = pCustom.GetKeyvalue("$fl_lastJump").GetFloat();
  if (flLastJump > g_Engine.time) return;
  
  if ((pPlayer.m_afButtonPressed & IN_JUMP) != 0 && (pPlayer.pev.waterlevel < WATERLEVEL_WAIST) && pPlayer.IsAlive()) {
    TraceResult tr;
    // gotta trace it because we already jumped at this point
    // this is a hack, but there's no PlayerJump hook or anything, so it'll do
	//zode: fix crouch not playing sound
	if((pPlayer.pev.button & IN_DUCK) != 0)
		g_Utility.TraceHull(pPlayer.pev.origin, pPlayer.pev.origin - Vector(0, 0, 5), dont_ignore_monsters, head_hull, pPlayer.edict(), tr);
	else
		g_Utility.TraceHull(pPlayer.pev.origin, pPlayer.pev.origin - Vector(0, 0, 5), dont_ignore_monsters, human_hull, pPlayer.edict(), tr);
	
    if (tr.flFraction < 1.0)
	{
		pCustom.SetKeyvalue("$fl_lastJump", g_Engine.time + 0.1);
		g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "serioussam/player/jump.ogg", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
	}
  }
}

void PrecachePlayerSounds() 
{
  g_SoundSystem.PrecacheSound("serioussam/player/woundweak.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/woundmedium.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/woundstrong.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/drown.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/death.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/deathwater.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/jump.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/waterenter.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/waterleave.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/inhale00.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/inhale01.ogg");
  g_SoundSystem.PrecacheSound("serioussam/player/inhale02.ogg");
}

void CheckCoinOpConditions()
{
	if(!GLOBAL_COIN_COOP)
		return;
		
	int alive = 0;
	
	CBasePlayer@ pPlayer = null;
	for(int i = 0; i < g_Engine.maxClients; i++)
	{
		@pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if(pPlayer is null) continue;
		
		if(pPlayer.IsAlive())
			alive += 1;
	}
	
	if(alive > 0 || GLOBAL_LIVES > 0)
		return;
		
	g_PlayerFuncs.ScreenFadeAll(Vector(0.0, 16.0, 0.0), 6.0f, 666.0f, 255, 1);
	g_Scheduler.SetTimeout("CoinOpFailure", 7.0f);
}

void CoinOpFailure()
{
	g_EngineFuncs.ChangeLevel(g_Engine.mapname);
}