#include "proj_ss_cannonball"

namespace SS_CANNON
{
	const int CANNON_DEFAULT_GIVE	= 4;
	const int CANNON_MAX_CARRY 		= 30;

	const string CANNON_P_MODEL = "models/serioussam/weapons/p_cannon.mdl";
	const string CANNON_V_MODEL = "models/serioussam/weapons/v_cannon.mdl";
	const string CANNON_W_MODEL = "models/serioussam/weapons/w_cannon.mdl";

	const string CANNONBALL_SPRITE_EXPLOSION	=	"sprites/serioussam/ssexpparticle.spr";
	const string CANNONBALL_SPRITE_EXPLOSION2	=	"sprites/serioussam/ssexprocket.spr";
}

enum CANNONAnimation
{
	CANNON_IDLE = 0,
	CANNON_FIRE,
	CANNON_CHARGING,
	CANNON_DRAW
}

class weapon_cannon : ScriptBasePlayerWeaponEntity
{
	private int m_iCharging, m_iCannonCharge;
	private float damagescale = 500;
	
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, SS_CANNON::CANNON_W_MODEL );
		
		self.m_iDefaultAmmo = SS_CANNON::CANNON_DEFAULT_GIVE;
		BaseClass.Spawn();
		self.FallInit();
		
		self.pev.sequence = 1;
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		self.pev.movetype = MOVETYPE_NONE;
		
		//for the spawn height!
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
		
		g_Game.PrecacheModel( SS_CANNON::CANNON_P_MODEL );
		g_Game.PrecacheModel( SS_CANNON::CANNON_V_MODEL );
		g_Game.PrecacheModel( SS_CANNON::CANNON_W_MODEL );
		
		g_Game.PrecacheModel( "models/serioussam/weapons/cannonball.mdl" );
		
		g_Game.PrecacheModel( SS_CANNON::CANNONBALL_SPRITE_EXPLOSION );
		g_Game.PrecacheModel( SS_CANNON::CANNONBALL_SPRITE_EXPLOSION2 );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/cannon/fire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/cannon/bounce.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/cannon/prepare.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/explosion02.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/cannon/fire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/cannon/bounce.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/cannon/prepare.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/explosion02.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_cannon.txt" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ))
			return false;
		
		NetworkMessage cannon( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			cannon.WriteLong( self.m_iId );
		cannon.End();
			
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
		return true;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= SS_CANNON::CANNON_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 4;
		info.iPosition 	= 7;
		info.iFlags 	= 0;
		info.iWeight 	= 30;

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( SS_CANNON::CANNON_V_MODEL ), self.GetP_Model( SS_CANNON::CANNON_P_MODEL ), CANNON_DRAW, "gauss" );
			
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
		m_iCharging = 0;
		m_iCannonCharge = 0;
			
		BaseClass.Holster( skipLocal ); 
    }
	
	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		if ( m_iCharging == 0 )
		{
			self.SendWeaponAnim( CANNON_CHARGING );
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/cannon/prepare.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
			
			m_iCharging = 1;
			
			return;
		}
	
		if ( m_iCharging == 1 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.2;
			m_iCannonCharge++;
		}
		
		if ( m_iCharging == 1 && m_iCannonCharge >= 6 )
		{
			FireCannonBall( m_iCannonCharge );
			m_iCannonCharge = 0;
			m_iCharging = 0;
		}
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 3.0;
	}
	
	void FireCannonBall( int chargeresult )
	{
		self.SendWeaponAnim( CANNON_FIRE, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/cannon/fire.ogg", 0.9, ATTN_NORM, 0, 96 + Math.RandomLong( 0 , 10 ) );
	
		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		damagescale = 450 + ( 50 * chargeresult );
		
		if( !(m_pPlayer.HasNamedPlayerItem( "item_ss_seriousdamage" ) is null) )
			damagescale *= 2;
		
		Vector vecWantedSrc = vecSrc + g_Engine.v_right * 3 + g_Engine.v_up * -8; // g_Engine.v_forward * 40
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
		ShootCannonBall( EHandle( m_pPlayer ), vecWantedSrc, g_Engine.v_forward * 300 * ( chargeresult + 1 ), damagescale );
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.3;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 20.0;
	}
	
	void WeaponIdle()
	{
		if ( m_iCharging == 1 )
		{
			self.SendWeaponAnim( CANNON_FIRE );
			
			FireCannonBall( m_iCannonCharge );
			
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.75;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/cannon/fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
			
			m_iCharging = 0;
			m_iCannonCharge = 0;
			
			return;
		}
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( ( CANNON_IDLE ) );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 6.9;
	}	
}

void RegisterCANNON()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_cannon", "weapon_cannon" );
	g_ItemRegistry.RegisterWeapon( "weapon_cannon", "serioussam", "cannonballs" );
	RegisterSSCannonBall();
}