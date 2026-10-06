#include "proj_ss_rocket"

namespace SS_ROCKETLAUNCHER
{

const int ROCKET_DEFAULT_GIVE	= 5;
const int ROCKET_MAX_CARRY 		= 50;

const string ROCKET_P_MODEL = "models/serioussam/weapons/p_rlauncher.mdl";
const string ROCKET_V_MODEL = "models/serioussam/weapons/v_rlauncher.mdl";
const string ROCKET_W_MODEL = "models/serioussam/weapons/w_rlauncher.mdl";

const string ROCKET_MODEL_PROJECTILE 	=	"models/serioussam/weapons/rocket.mdl";
const string ROCKET_SPRITE_SMOKE 		=	"sprites/smoke.spr";
const string ROCKET_SPRITE_ZBEAM1		=	"sprites/zbeam1.spr";
const string ROCKET_SPRITE_EXPLOSION	=	"sprites/serioussam/ssexpparticle.spr";
const string ROCKET_SPRITE_EXPLOSION2	=	"sprites/serioussam/ssexprocket.spr";

}

enum ROCKETLAUNCHERAnimation
{
	ROCKETLAUNCHER_IDLE = 0,
	ROCKETLAUNCHER_IDLE2,
	ROCKETLAUNCHER_SHOOT,
	ROCKETLAUNCHER_DRAW
}
	
class weapon_rocketlauncher : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_rlauncher.mdl" );
		
		self.m_iDefaultAmmo = SS_ROCKETLAUNCHER::ROCKET_DEFAULT_GIVE;

		BaseClass.Spawn();
		
		self.FallInit();
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.sequence = 1;
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time;
		self.pev.frame = Math.RandomLong(0, 300);
		self.pev.scale = 2.0;
		
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
		
		g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_P_MODEL );
		g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_V_MODEL );
		g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_W_MODEL );
		
		g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_MODEL_PROJECTILE );
		g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_SPRITE_SMOKE );
		g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_SPRITE_ZBEAM1 );
		g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_SPRITE_EXPLOSION );
		g_Game.PrecacheModel( SS_ROCKETLAUNCHER::ROCKET_SPRITE_EXPLOSION2 );

		g_Game.PrecacheGeneric( "sound/serioussam/weapons/rocketlauncher_fire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/projectilefly.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/explosion01.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/rocketlauncher_fire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/explosion01.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/projectilefly.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_rocketlauncher.txt" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
		
		NetworkMessage rocketlauncher( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			rocketlauncher.WriteLong( self.m_iId );
		rocketlauncher.End();
			
		ScheduleSeriousItemSound( pPlayer, "serioussam/items/weapon.ogg" );
			
		return true;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= SS_ROCKETLAUNCHER::ROCKET_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 4;
		info.iPosition 	= 5;
		info.iFlags 	= 0;
		info.iWeight 	= 30;

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( SS_ROCKETLAUNCHER::ROCKET_V_MODEL ), self.GetP_Model( SS_ROCKETLAUNCHER::ROCKET_P_MODEL  ), ROCKETLAUNCHER_DRAW, "gauss" );
			
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
		
		self.SendWeaponAnim( ROCKETLAUNCHER_SHOOT, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/rocketlauncher_fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
	
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		int iDamage = 75;
		
		// Fire the missile!
		ShootRocket( EHandle( m_pPlayer ), m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 24 + g_Engine.v_right * 3 + g_Engine.v_up * -8, g_Engine.v_forward * 1500, iDamage );
			
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.7;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomLong( 8, 12 );
	}
	
	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		int idle_animation = Math.RandomLong( 0, 5 );
		
		//The second idle animation rarely plays
		self.SendWeaponAnim( ( idle_animation == 2 ? ROCKETLAUNCHER_IDLE2 : ROCKETLAUNCHER_IDLE ) );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomLong( 8, 12 );
	}
}

void RegisterROCKETLAUNCHER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_rocketlauncher", "weapon_rocketlauncher" );
	g_ItemRegistry.RegisterWeapon( "weapon_rocketlauncher", "serioussam", "ssrockets" );
	RegisterSSROCKET();
}