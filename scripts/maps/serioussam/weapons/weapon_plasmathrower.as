#include "proj_ss_plasma"

namespace SS_PLASMATHROWER
{
	
const int PLASMATHROWER_DEFAULT_GIVE = 50;
const int PLASMATHROWER_MAX_CARRY 	= 150;
const int PLASMATHROWER_VELOCITY	= 4000;

const string PLASMATHROWER_SPRITE_EXPLOSION	= "sprites/serioussam/ssexpparticle.spr";
const string PLASMATHROWER_SPRITE_EXPLOSION2 = "sprites/serioussam/ssexprocket.spr";

const string LASER_MODEL_PROJECTILE2 = "models/serioussam/weapons/laserproj.mdl";
float M_PI	=	3.14159265358979323846; // PI here

}

enum PLASMATHROWERAnimation
{
	PLASMATHROWER_IDLE = 0,
	PLASMATHROWER_SHOOTLEFT,
	PLASMATHROWER_SHOOTRIGHT,
	PLASMATHROWER_SHOOTCENTER,
	PLASMATHROWER_DRAW
}

class weapon_plasmathrower : ScriptBasePlayerWeaponEntity
{
	private int m_iFiredShots;
	private bool m_bSecondaryFire;
	
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_plasmathrower.mdl" );
		
		self.m_iDefaultAmmo = SS_PLASMATHROWER::PLASMATHROWER_DEFAULT_GIVE;
		
		m_iFiredShots = 0;
		
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
					self.pev.origin.z = tr.vecEndPos.z + 30;
			}
		}
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		
		g_Game.PrecacheModel( "models/serioussam/weapons/v_plasmathrower.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/w_plasmathrower.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/p_plasmathrower.mdl" );
		
		g_Game.PrecacheModel( SS_PLASMATHROWER::LASER_MODEL_PROJECTILE2 );
		
		g_Game.PrecacheModel( SS_PLASMATHROWER::PLASMATHROWER_SPRITE_EXPLOSION );
		g_Game.PrecacheModel( SS_PLASMATHROWER::PLASMATHROWER_SPRITE_EXPLOSION2 );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/plasmathrower/fire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/plasmathrower/explosion.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/plasmathrower/fire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/plasmathrower/explosion.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_plasmathrower.txt" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
		
			NetworkMessage plasmathrower( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				plasmathrower.WriteLong( self.m_iId );
			plasmathrower.End();
			
			ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg");
			
			return true;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= SS_PLASMATHROWER::PLASMATHROWER_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 6;
		info.iPosition 	= 4;
		info.iFlags 	= 0;
		info.iWeight 	= 30;

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/serioussam/weapons/v_plasmathrower.mdl" ), self.GetP_Model( "models/serioussam/weapons/p_plasmathrower.mdl" ), PLASMATHROWER_DRAW, "gauss" );
			
			float deployTime = 0.6;
			
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			
			return bResult;
		}
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		FirePlasma( false );
	}
	
	void FirePlasma( bool m_bSecondaryFire )
	{
		//counter only increments on primary fire
		if ( m_bSecondaryFire == false )
		{
			m_iFiredShots++;
		
			//reset the shots counter so we can cycle through the anims again
			if ( m_iFiredShots >= 3 )
				m_iFiredShots = 1;
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/plasmathrower/fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
	
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
	
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - ( m_bSecondaryFire == true ? 8 : 1 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		if ( m_iFiredShots == 1 )
		{
			self.SendWeaponAnim( PLASMATHROWER_SHOOTLEFT );
			ShootPlasma( m_pPlayer.pev, vecSrc + g_Engine.v_forward * 30 + g_Engine.v_right * 2.5 + g_Engine.v_up * -15, g_Engine.v_forward * SS_PLASMATHROWER::PLASMATHROWER_VELOCITY	 );
		}
		else if ( m_iFiredShots == 2 )
		{
			self.SendWeaponAnim( PLASMATHROWER_SHOOTRIGHT );
			ShootPlasma( m_pPlayer.pev, vecSrc + g_Engine.v_forward * 30 + g_Engine.v_right * 17.5 + g_Engine.v_up * -15, g_Engine.v_forward * SS_PLASMATHROWER::PLASMATHROWER_VELOCITY	 );
		}
		
		if ( m_bSecondaryFire == true )
		{
			self.SendWeaponAnim( PLASMATHROWER_SHOOTCENTER );
			
			float angle = -SS_PLASMATHROWER::M_PI/2;
			
			ShootPlasma( m_pPlayer.pev, vecSrc + g_Engine.v_forward * 30 + g_Engine.v_right * 17.5 + g_Engine.v_up * -15, g_Engine.v_forward * SS_PLASMATHROWER::PLASMATHROWER_VELOCITY );
			ShootPlasma( m_pPlayer.pev, vecSrc + g_Engine.v_forward * 30 + g_Engine.v_right * 2.5 + g_Engine.v_up * -15, g_Engine.v_forward * SS_PLASMATHROWER::PLASMATHROWER_VELOCITY	 );
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.34;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.34;
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 6.9;
	}
	
	void SecondaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < 8 )
		{
			self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		FirePlasma( true );
		
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.0;
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		m_iFiredShots = 0;
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( PLASMATHROWER_IDLE );
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 6.9;
	}
	
	void RotateThink()
	{
		self.pev.angles.y +=2;
	}

	void UpdateOnRemove()
	{
		//if (m_pRotFunc !is null)
			//g_Scheduler.RemoveTimer( m_pRotFunc );
		BaseClass.UpdateOnRemove();
	}
}

void RegisterPLASMATHROWER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_plasmathrower", "weapon_plasmathrower" );
	g_ItemRegistry.RegisterWeapon( "weapon_plasmathrower", "serioussam", "plasmacells" );
}