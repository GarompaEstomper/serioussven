#include "proj_ss_laser"

int LASER_DEFAULT_GIVE		= 100;
int LASER_MAX_CARRY 		= 400;
int LASER_VELOCITY			= 4000;

const string LASER_MODEL_PROJECTILE		=	"models/serioussam/weapons/laserproj.mdl";

enum LASERAnimation
{
	LASER_SHOOT_TOPLEFT = 0,
	LASER_SHOOT_BOTTOMLEFT,
	LASER_SHOOT_TOPRIGHT,
	LASER_SHOOT_BOTTOMRIGHT,
	LASER_DRAW,
	LASER_IDLE
}

class weapon_laser : ScriptBasePlayerWeaponEntity
{
	private int m_iFiredShots;
	
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_laser.mdl" );
		
		self.m_iDefaultAmmo = LASER_DEFAULT_GIVE;
		
		m_iFiredShots = 0;
		
		BaseClass.Spawn();
		self.FallInit();
		//@m_pRotFunc = @g_Scheduler.SetInterval( this, "RotateThink", 0.01f, g_Scheduler.REPEAT_INFINITE_TIMES );
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
		
		g_Game.PrecacheModel( "models/serioussam/weapons/v_laser.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/w_laser.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/p_laser.mdl" );
		
		g_Game.PrecacheModel( LASER_MODEL_PROJECTILE );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/laser_fire.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/laser_fire.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_laser.txt" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
	
		NetworkMessage laser( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			laser.WriteLong( self.m_iId );
		laser.End();
			
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
		return true;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= LASER_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 6;
		info.iPosition 	= 2;
		info.iFlags 	= 0;
		info.iWeight 	= 30;

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/serioussam/weapons/v_laser.mdl" ), self.GetP_Model( "models/serioussam/weapons/p_laser.mdl" ), LASER_DRAW, "gauss" );
			
			float deployTime = 0.6;
			
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;
			
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
		
		m_iFiredShots++;
		
		//reset the shots counter so we can cycle through the anims again
		if ( m_iFiredShots >= 5 )
			m_iFiredShots = 1;
		
		self.SendWeaponAnim( LASER_SHOOT_TOPLEFT + ( m_iFiredShots - 1 ), 0, 0 );
		
		//g_Game.AlertMessage( at_console, "Laser::Shots:: " + m_iFiredShots + "\n" );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, "serioussam/weapons/laser_fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
	
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
	
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		int iDamage = 30;
			
		if ( m_iFiredShots == 1 )
		ShootLaser( EHandle( m_pPlayer ), vecSrc + g_Engine.v_forward * 30 + g_Engine.v_right * 0.5 + g_Engine.v_up * -6, g_Engine.v_forward * LASER_VELOCITY, iDamage	 );
		else if ( m_iFiredShots == 2 )
		ShootLaser( EHandle( m_pPlayer ), vecSrc + g_Engine.v_forward * 30 + g_Engine.v_right * -0.5 + g_Engine.v_up * -12, g_Engine.v_forward * LASER_VELOCITY, iDamage );
		else if ( m_iFiredShots == 3 )
		ShootLaser( EHandle( m_pPlayer ), vecSrc + g_Engine.v_forward * 30 + g_Engine.v_right * 9 + g_Engine.v_up * -12, g_Engine.v_forward * LASER_VELOCITY, iDamage );
		else if ( m_iFiredShots == 4 )
		ShootLaser( EHandle( m_pPlayer ), vecSrc + g_Engine.v_forward * 30 + g_Engine.v_right * 6 + g_Engine.v_up * -6, g_Engine.v_forward * LASER_VELOCITY, iDamage );
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1;
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 20.0;
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();
		
		m_iFiredShots = 0;
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( LASER_IDLE );
		
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

void RegisterLASERRIFLE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_laser", "weapon_laser" );
	g_ItemRegistry.RegisterWeapon( "weapon_laser", "serioussam", "energycells" );
}