#include "proj_ss_flame"

enum FLAMERAnimation
{
	FLAMER_IDLE = 0,
	FLAMER_SHOOT,
	FLAMER_SHOOTEND,
	FLAMER_DRAW
};

int FLAMER_DEFAULT_GIVE	= 100;
int FLAMER_MAX_CARRY	= 500;

class weapon_flamer : ScriptBasePlayerWeaponEntity
{
	private int m_iAnimate;
	private int m_iInAttack;
	private int ammoburn;
	
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_flamer.mdl" );
		
		self.m_iDefaultAmmo = FLAMER_DEFAULT_GIVE;
		
		m_iAnimate = 0;
		ammoburn = 0;
		
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
		
		g_Game.PrecacheModel( "models/serioussam/weapons/v_flamer.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/w_flamer.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/p_flamer.mdl" );
		
		g_Game.PrecacheModel( "models/serioussam/items/ammo/ammo_napalm.mdl" );
		
		g_Game.PrecacheModel( "sprites/serioussam/ssflame.spr" );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/flamer/fire.ogg"  );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/flamer/stop.ogg"  );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/flamer/fire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/flamer/stop.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_flamer.txt" );
		
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= FLAMER_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 5;
		info.iPosition 	= 5;
		info.iFlags 	= 0;
		info.iWeight 	= 30;

		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
		
			NetworkMessage flamethrower( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				flamethrower.WriteLong( self.m_iId );
			flamethrower.End();
			
			ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
			return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/serioussam/weapons/v_flamer.mdl" ), self.GetP_Model( "models/serioussam/weapons/p_flamer.mdl" ), FLAMER_DRAW, "bow" );
		
			float deployTime = 0.5f;
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
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.55f;
			WeaponIdle();
			return;
		}
		
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		m_iInAttack = 1;
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.03;
		
		FlamethrowerFire();
	}
	
	void FlamethrowerFire()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.55f;
			WeaponIdle();
			return;
		}
		
		if ( m_iAnimate == 0 && m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			self.SendWeaponAnim( FLAMER_SHOOT );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/flamer/fire.ogg", 0.9, ATTN_NORM, SND_FORCE_LOOP, PITCH_NORM );
			m_iAnimate = 1;
			return;
		}
		
		ammoburn++;
		
		if ( ammoburn == 3 )
		{
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
			ammoburn = 0;
		}
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		int iDamage = 15;
		
		if( !(m_pPlayer.HasNamedPlayerItem("item_ss_seriousdamage") is null) )
			iDamage *= 2;
			
		CreateFlameEffect( EHandle(m_pPlayer), m_pPlayer.GetGunPosition() + g_Engine.v_forward * 16 + g_Engine.v_right * 2 + g_Engine.v_up * -2, m_pPlayer.pev.velocity + g_Engine.v_forward * 700, iDamage );
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 3.0f;
	}
	
	void Holster( int skipLocal = 0 ) 
    {     
        self.m_fInReload = false; 
         
		SetThink(null);
		
		m_iAnimate = 0;
		m_iInAttack = 0;
		
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/flamer/fire.ogg" );
		
        BaseClass.Holster( skipLocal ); 
    }
	
	void WeaponIdle()
	{
		self.ResetEmptySound();
		
		if( m_iInAttack == 1 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1;	
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 2.0;
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/flamer/fire.ogg" );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/flamer/stop.ogg", 0.9, ATTN_NORM, 0, 100 );
			self.SendWeaponAnim( FLAMER_SHOOTEND );
			m_iInAttack = 0;
			m_iAnimate = 0;
			return;
		}
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
			
		self.SendWeaponAnim( FLAMER_IDLE );
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 6, 9 );
	}
	
	void RotateThink()
	{
		self.pev.angles.y +=2;
	}

	void UpdateOnRemove()
	{
		BaseClass.UpdateOnRemove();
	}
}

void RegisterSSFLAMETHROWER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_flamer", "weapon_flamer" );
	g_ItemRegistry.RegisterWeapon( "weapon_flamer", "serioussam", "ssnapalm" );
}