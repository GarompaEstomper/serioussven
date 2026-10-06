#include "proj_ss_mine"

namespace SS_MINELAYER
{
	
const int MINELAYER_DEFAULT_GIVE	= 15;
const int MINELAYER_MAX_CARRY 		= 15;

const string MINELAYER_P_MODEL = "models/serioussam/weapons/p_minelayer.mdl";
const string MINELAYER_V_MODEL = "models/serioussam/weapons/v_minelayer.mdl";
const string MINELAYER_W_MODEL = "models/serioussam/weapons/w_minelayer.mdl";

const string MINELAYER_SPRITE_EXPLOSION	= "sprites/serioussam/ssexpparticle.spr";
const string MINELAYER_SPRITE_EXPLOSION2 = "sprites/serioussam/ssexprocket.spr";

}

enum MINELAYERAnimation
{
	MINELAYER_IDLE = 0,
	MINELAYER_FIRE,
	MINELAYER_DRAW
}

class weapon_minelayer : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, SS_MINELAYER::MINELAYER_W_MODEL );
		
		self.m_iDefaultAmmo = SS_MINELAYER::MINELAYER_DEFAULT_GIVE;
		
		BaseClass.Spawn();
		
		self.FallInit();
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.sequence = 1;
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -30;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 16;
			}
		}
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		
		g_Game.PrecacheModel( SS_MINELAYER::MINELAYER_P_MODEL );
		g_Game.PrecacheModel( SS_MINELAYER::MINELAYER_V_MODEL );
		g_Game.PrecacheModel( SS_MINELAYER::MINELAYER_W_MODEL );
		
		g_Game.PrecacheModel( SS_MINELAYER::MINELAYER_SPRITE_EXPLOSION );
		g_Game.PrecacheModel( SS_MINELAYER::MINELAYER_SPRITE_EXPLOSION2 );
		
		g_Game.PrecacheModel( "models/serioussam/weapons/mine.mdl" );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/minelayer/fire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/minelayer/arm.ogg"  );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/minelayer/detonating.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/minelayer/fire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/minelayer/arm.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/minelayer/detonating.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_minelayer.txt" );
	}
	
	bool CanDeploy()
	{ 
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
	
		NetworkMessage minelayer( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			minelayer.WriteLong( self.m_iId );
		minelayer.End();
			
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
		return true;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= SS_MINELAYER::MINELAYER_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 6;
		info.iPosition 	= 5;
		info.iFlags 	= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
		info.iWeight 	= 30;

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( SS_MINELAYER::MINELAYER_V_MODEL ), self.GetP_Model( SS_MINELAYER::MINELAYER_P_MODEL ), MINELAYER_DRAW, "saw" );
			
			float deployTime = 0.6;
			
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;
			
			return bResult;
		}
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void Holster( int skipLocal = 0 ) 
    {     
		BaseClass.Holster( skipLocal ); 
    }
	
	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			WeaponIdle();
			return;
		}
		
		self.SendWeaponAnim( MINELAYER_FIRE );
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.40;
		
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/minelayer/fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		int iDamage = 200;
		
		if( !(m_pPlayer.HasNamedPlayerItem("item_ss_seriousdamage") is null) )
			iDamage *= 2;
		
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecWantedSrc = vecSrc + g_Engine.v_forward * 40 + g_Engine.v_right * 3 + g_Engine.v_up * -8;
		
		TraceResult tr;
		g_Utility.TraceHull( vecSrc+g_Engine.v_forward*40, vecSrc+g_Engine.v_forward*60,  dont_ignore_monsters, large_hull, self.edict(), tr );
		if(tr.fStartSolid == 0 && tr.fAllSolid == 0)
			vecWantedSrc = vecWantedSrc + g_Engine.v_forward*(40*tr.flFraction);
		else
		{
			// trace backwards: fixes slopes
			g_Utility.TraceHull( vecSrc-g_Engine.v_forward*10, vecSrc-g_Engine.v_forward*20,  dont_ignore_monsters, large_hull, self.edict(), tr );
			//if(tr.fStartSolid == 0 && tr.fAllSolid == 0)
				vecWantedSrc = vecWantedSrc - g_Engine.v_forward*(20*tr.flFraction);
			//else // no possible space? default to normal
			//	vecWantedSrc = vecSrc + g_Engine.v_right * 3 + g_Engine.v_up * -8 + g_Engine.v_forward * 40;
			
		}
		
		ShootMine( EHandle( m_pPlayer ), vecWantedSrc, g_Engine.v_forward * 500, iDamage );
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 3.0;
	}
	
	void SecondaryAttack()
	{
		edict_t@ pPlayer = m_pPlayer.edict();
		CBaseEntity@ pMine = null;

		while( ( @pMine = g_EntityFuncs.FindEntityInSphere( pMine, m_pPlayer.pev.origin, 16384, "proj_ss_mine", "classname" ) ) !is null )
		{
			if( pMine.pev.owner is pPlayer && pMine.pev.iuser1 == 1 ) // only detonate armed mines!
			{
				pMine.Use( m_pPlayer, m_pPlayer, USE_ON, 0 );
			}
		}
		
		self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
		self.m_flNextPrimaryAttack = g_Engine.time + 1.0;
	}
	
	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( MINELAYER_IDLE );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 6.9;
	}
}

void RegisterMINELAYER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_minelayer", "weapon_minelayer" );
	g_ItemRegistry.RegisterWeapon( "weapon_minelayer", "serioussam", "mines" );
}