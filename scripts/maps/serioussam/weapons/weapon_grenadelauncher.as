#include "proj_ss_grenade"

namespace SS_GRENADELAUNCHER
{
	const int GRENADELAUNCHER_DEFAULT_GIVE	= 10;
	const int GRENADELAUNCHER_MAX_CARRY 	= 50;
	const int SSGRENADE_DAMAGE_DIRECT = 75;

	const string SSGRENADE_P_MODEL = "models/serioussam/weapons/p_grenadelauncher.mdl";
	const string SSGRENADE_V_MODEL = "models/serioussam/weapons/v_grenadelauncher.mdl";
	const string SSGRENADE_W_MODEL = "models/serioussam/weapons/w_grenadelauncher.mdl";

	const string SSGRENADE_SPRITE_EXPLOSION	= "sprites/serioussam/ssexpparticle.spr";
	const string SSGRENADE_SPRITE_EXPLOSION2 = "sprites/serioussam/ssexprocket.spr";
	const string SSGRENADE_SPRITE_TRAIL	= "sprites/laserbeam.spr";
	const string SSGRENADE_MODEL = "models/serioussam/weapons/grenade.mdl";
}

enum GRENADELAUNCHERAnimation
{
	GRENADELAUNCHER_CHARGING = 0,
	GRENADELAUNCHER_FIRE,
	GRENADELAUNCHER_DRAW
}

class weapon_grenadelauncher : ScriptBasePlayerWeaponEntity
{
	private int m_iCharging;
	private int m_iCharge;
	
	private int damagescale;
	
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_grenadelauncher.mdl" );
		
		self.m_iDefaultAmmo = SS_GRENADELAUNCHER::GRENADELAUNCHER_DEFAULT_GIVE;
		
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
		
		g_Game.PrecacheModel( SS_GRENADELAUNCHER::SSGRENADE_P_MODEL );
		g_Game.PrecacheModel( SS_GRENADELAUNCHER::SSGRENADE_V_MODEL );
		g_Game.PrecacheModel( SS_GRENADELAUNCHER::SSGRENADE_W_MODEL );
		
		g_Game.PrecacheModel( SS_GRENADELAUNCHER::SSGRENADE_MODEL );
		
		g_Game.PrecacheModel( SS_GRENADELAUNCHER::SSGRENADE_SPRITE_EXPLOSION );
		g_Game.PrecacheModel( SS_GRENADELAUNCHER::SSGRENADE_SPRITE_EXPLOSION2 );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/grenadelauncher/fire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/grenadelauncher/bounce.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/grenadelauncher/fire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/grenadelauncher/bounce.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_grenadelauncher.txt" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
	
		NetworkMessage gl( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			gl.WriteLong( self.m_iId );
		gl.End();
		
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg");
		
		return true;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= SS_GRENADELAUNCHER::GRENADELAUNCHER_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 4;
		info.iPosition 	= 6;
		info.iFlags 	= 0;
		info.iWeight 	= 30;

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/serioussam/weapons/v_grenadelauncher.mdl" ), self.GetP_Model( "models/serioussam/weapons/p_grenadelauncher.mdl" ), GRENADELAUNCHER_DRAW, "gauss" );
			
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
		m_iCharge = 0;
		
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
			self.SendWeaponAnim( GRENADELAUNCHER_CHARGING );
			m_iCharging = 1;
			
			return;
		}
		
		if ( m_iCharging == 1 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.2;
			m_iCharge++;
			//g_Game.AlertMessage( at_console, "Charge++\n");
		}
		
		if ( m_iCharging == 1 && m_iCharge >= 4 )
		{
			FireGrenade( m_iCharge );
			m_iCharge = 0;
			m_iCharging = 0;
		}
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 3.0;
	}
	
	void FireGrenade( int chargeresult )
	{
		self.SendWeaponAnim( GRENADELAUNCHER_FIRE );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/grenadelauncher/fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
	
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
	
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
			
		if ( chargeresult == 1 )
			damagescale = 25;
		else if ( chargeresult == 2 )
			damagescale = 50;
		else if ( chargeresult == 3 )
			damagescale = 75;
		else if ( chargeresult == 4 )
			damagescale = 100;
		
		if( !(m_pPlayer.HasNamedPlayerItem("item_ss_seriousdamage") is null) )
			damagescale *= 2;

		//zode: fix in-walls
		Vector vecWantedSrc = vecSrc + g_Engine.v_right * 3 + g_Engine.v_up * -8;
		//Vector vecWantedSrc = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 40 + g_Engine.v_right * 3 + g_Engine.v_up * -8;
		TraceResult tr;
		g_Utility.TraceHull( vecWantedSrc+g_Engine.v_forward*40, vecWantedSrc+g_Engine.v_forward*60,  dont_ignore_monsters, large_hull, self.edict(), tr );
		if(tr.fStartSolid == 0 && tr.fAllSolid == 0)
		{
			vecWantedSrc = vecWantedSrc + g_Engine.v_forward*(40*tr.flFraction);
		}
		else
		{
			//trace backwards
			g_Utility.TraceHull( vecWantedSrc-g_Engine.v_forward*10, vecWantedSrc-g_Engine.v_forward*20,  dont_ignore_monsters, large_hull, self.edict(), tr );
			vecWantedSrc = vecWantedSrc - g_Engine.v_forward*(20*tr.flFraction);
		}
		
		// Fire the missile!
		ShootGrenade( EHandle( m_pPlayer ), vecWantedSrc, g_Engine.v_forward * 400 * ( chargeresult + 1 ), damagescale );
		
		//g_Game.AlertMessage( at_console, "Charge was " + chargeresult + "\n");
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.3;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 20.0;
	}
	
	void WeaponIdle()
	{
		if ( m_iCharging == 1 )
		{
			self.SendWeaponAnim( GRENADELAUNCHER_FIRE );
			
			FireGrenade( m_iCharge );
			
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.3;
			
			m_iCharging = 0;
			m_iCharge = 0;
			
			return;
		}
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( ( GRENADELAUNCHER_FIRE ) );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 6.9;
	}
}

void RegisterGRENADELAUNCHER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_grenadelauncher", "weapon_grenadelauncher" );
	g_ItemRegistry.RegisterWeapon( "weapon_grenadelauncher", "serioussam", "ssgrenades" );
	RegisterSSGrenade();
}