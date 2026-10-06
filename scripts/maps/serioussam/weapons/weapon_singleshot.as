
namespace SS_SINGLESHOT
{
	const Vector VECTOR_CONE_SINGLESHOT( 0.08, 0.06, 0  ); // 12 4

	const int SINGLESHOT_DEFAULT_GIVE	= 10;
	const int SINGLESHOT_MAX_CARRY 		= 100;
	const int SINGLESHOT_WEIGHT 		= 20;
	
	const string SINGLESHOT_P_MODEL = "models/serioussam/weapons/p_shotgun.mdl";
	const string SINGLESHOT_V_MODEL = "models/serioussam/weapons/v_shotgun.mdl";
	const string SINGLESHOT_W_MODEL = "models/serioussam/weapons/w_shotgun.mdl";
	
	const uint SINGLESHOT_PELLETCOUNT = 7;
}

enum SingleShotAnimation
{
	SINGLESHOT_IDLE = 0,
	SINGLESHOT_IDLE2,
	SINGLESHOT_SHOOT,
	SINGLESHOT_DRAW
}

class weapon_singleshot : ScriptBasePlayerWeaponEntity
{
	private int m_iShell;
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, SS_SINGLESHOT::SINGLESHOT_W_MODEL );
		m_iShell = g_Game.PrecacheModel( "models/shotgunshell.mdl" );
		self.m_iDefaultAmmo = SS_SINGLESHOT::SINGLESHOT_DEFAULT_GIVE;

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
		
		g_Game.PrecacheModel( SS_SINGLESHOT::SINGLESHOT_P_MODEL );
		g_Game.PrecacheModel( SS_SINGLESHOT::SINGLESHOT_V_MODEL );
		g_Game.PrecacheModel( SS_SINGLESHOT::SINGLESHOT_W_MODEL );

		g_Game.PrecacheModel( "models/shotgunshell.mdl" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/singleshotgun_fire.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/singleshotgun_fire.ogg" );
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_singleshot.txt" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
	
		NetworkMessage singleshot( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			singleshot.WriteLong( self.m_iId );
		singleshot.End();
			
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
		return true;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= SS_SINGLESHOT::SINGLESHOT_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 5;
		info.iFlags 	= 0;
		info.iWeight 	= SS_SINGLESHOT::SINGLESHOT_WEIGHT;

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( SS_SINGLESHOT::SINGLESHOT_V_MODEL ), self.GetP_Model( SS_SINGLESHOT::SINGLESHOT_P_MODEL ), SINGLESHOT_DRAW, "shotgun" );
			
			float deployTime = 0.6;
			
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;
			
			return bResult;
		}
	}
	
	void Holster( int skipLocal = 0 ) 
    {     
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
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		self.SendWeaponAnim( SINGLESHOT_SHOOT, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/singleshotgun_fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
	
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
	
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		m_pPlayer.FireBullets( 7, vecSrc, vecAiming, SS_SINGLESHOT::VECTOR_CONE_SINGLESHOT, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, 0 );

		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.1;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 20.0;
		
		CreatePelletDecals( vecSrc, vecAiming, SS_SINGLESHOT::VECTOR_CONE_SINGLESHOT, SS_SINGLESHOT::SINGLESHOT_PELLETCOUNT );
		
		self.pev.nextthink = WeaponTimeBase() + 0.65;
		SetThink( ThinkFunction( EjectShell ) );
	}
	
	//MAKE AMERICA GREAT AGAIN
	//BUILD THE WALL
	void EjectShell()
	{
		Vector vecShellVelocity, vecShellOrigin;
       
		//The last 3 parameters are unique for each weapon (this should be using an attachment in the model to get the correct position, but most models don't have that).
		CS16GetDefaultShellInfo( EHandle(m_pPlayer), vecShellVelocity, vecShellOrigin, 18, 15, -10, false, false );
       
		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;
       
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHOTSHELL );
	}
	
	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		int anim = Math.RandomLong( 0 , 5 );
		
		//The second idle animation rarely plays
		self.SendWeaponAnim( ( anim == 2 ? SINGLESHOT_IDLE2 : SINGLESHOT_IDLE ) );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 20.0;
	}
}

void RegisterSingleShot()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_singleshot", "weapon_singleshot" );
	g_ItemRegistry.RegisterWeapon( "weapon_singleshot", "serioussam", "ssshells" );
}