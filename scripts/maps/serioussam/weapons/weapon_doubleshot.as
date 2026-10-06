
namespace SS_DOUBLESHOT
{
	const Vector VECTOR_CONE_DOUBLESHOT( 0.16, 0.10, 0  );	// 18 8

	const int DOUBLESHOT_DEFAULT_GIVE	= 10;
	const int DOUBLESHOT_MAX_CARRY 		= 100;
	const int DOUBLESHOT_WEIGHT 		= 20;

	const uint DOUBLESHOT_PELLETCOUNT 	= 14;
	
	const string DOUBLESHOT_P_MODEL     = "models/serioussam/weapons/p_dbarrel.mdl";
	const string DOUBLESHOT_V_MODEL     = "models/serioussam/weapons/v_dbarrel.mdl";
	const string DOUBLESHOT_W_MODEL     = "models/serioussam/weapons/w_dbarrel.mdl";
}

enum DoubleShotAnimation
{
	DOUBLESHOT_IDLE = 0,
	DOUBLESHOT_IDLE2,
	DOUBLESHOT_SHOOT,
	DOUBLESHOT_DRAW
}

class weapon_doubleshot : ScriptBasePlayerWeaponEntity
{
	private int m_iFiringGun;
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, SS_DOUBLESHOT::DOUBLESHOT_W_MODEL );
		self.m_iDefaultAmmo = SS_DOUBLESHOT::DOUBLESHOT_DEFAULT_GIVE;
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
		
		g_Game.PrecacheModel( SS_DOUBLESHOT::DOUBLESHOT_P_MODEL );
		g_Game.PrecacheModel( SS_DOUBLESHOT::DOUBLESHOT_V_MODEL );
		g_Game.PrecacheModel( SS_DOUBLESHOT::DOUBLESHOT_W_MODEL );

		g_Game.PrecacheGeneric( "sound/serioussam/weapons/doubleshotgun/fire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/doubleshotgun/reload.ogg" ); //QC event
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/doubleshotgun/fire.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_doubleshot.txt" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
	
		NetworkMessage doubleshot( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			doubleshot.WriteLong( self.m_iId );
		doubleshot.End();
			
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
		return true;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= SS_DOUBLESHOT::DOUBLESHOT_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 6;
		info.iFlags 	= 0;
		info.iWeight 	= SS_DOUBLESHOT::DOUBLESHOT_WEIGHT;

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( SS_DOUBLESHOT::DOUBLESHOT_V_MODEL ), self.GetP_Model( SS_DOUBLESHOT::DOUBLESHOT_P_MODEL ), DOUBLESHOT_DRAW, "shotgun" );
			
			float deployTime = 0.6;
			
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;
			
			return bResult;
		}
	}
	
	bool CanHolster()
	{
		// no quick switching until we're done firing it...
		return ( m_iFiringGun == 0 );
	}
	
	void Holster( int skipLocal = 0 ) 
    {    
		self.m_bExclusiveHold = false;
		m_iFiringGun = 0;
		
		SetThink(null);
		BaseClass.Holster( skipLocal ); 
    }
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void CreatePelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount )
	{
		int iDamage = 25;
			
		TraceResult tr;
		
		float x, y;
		
		for( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
		{
			g_Utility.GetCircularGaussianSpread( x, y );
			
			Vector vecDir = vecAiming 
							+ x * vecSpread.x * g_Engine.v_right 
							+ y * vecSpread.y * g_Engine.v_up;

			Vector vecEnd	= vecSrc + vecDir * 8192;
			
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			
			if( tr.flFraction < 1.0 )
			{
				if( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					
					if( pHit is null || pHit.IsBSPModel() == true )
						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );
					
					if ( pHit.pev.takedamage != DAMAGE_NO && pHit.IsAlive() == true )
					{
						g_WeaponFuncs.ClearMultiDamage();
						
						pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_LAUNCH | DMG_NEVERGIB ); 
						g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
						
					}	
					
				}
			}
		}
	}
	
	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 1 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		self.SendWeaponAnim( DOUBLESHOT_SHOOT, 0, 0 );
		
		m_iFiringGun = 1;
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/doubleshotgun/fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
	
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
	
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 2 );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		m_pPlayer.FireBullets( 14, vecSrc, vecAiming, SS_DOUBLESHOT::VECTOR_CONE_DOUBLESHOT, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, 0 );

		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.65;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.65;
		
		CreatePelletDecals( vecSrc, vecAiming, SS_DOUBLESHOT::VECTOR_CONE_DOUBLESHOT, SS_DOUBLESHOT::DOUBLESHOT_PELLETCOUNT );
	}
	
	void WeaponIdle()
	{
		self.m_bExclusiveHold = m_iFiringGun == 1 ? true : false;
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		m_iFiringGun = 0;
		
		int anim = Math.RandomLong( 0 , 5 );
		
		//The second idle animation rarely plays
		self.SendWeaponAnim( ( anim == 2 ? DOUBLESHOT_IDLE2 : DOUBLESHOT_IDLE ) );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 20.0;
	}
}

void RegisterDoubleShot()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doubleshot", "weapon_doubleshot" );
	g_ItemRegistry.RegisterWeapon( "weapon_doubleshot", "serioussam", "ssshells" );
}