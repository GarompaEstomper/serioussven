enum DUALCOLTAnimation
{
	DUALCOLT_IDLE = 0,
	DUALCOLT_SHOOTRIGHT1,
	DUALCOLT_SHOOTLEFT1,
	DUALCOLT_SHOOTRIGHT2,
	DUALCOLT_SHOOTLEFT2,
	DUALCOLT_RELOADLEFT,
	DUALCOLT_RELOADRIGHT,
	DUALCOLT_DRAW
};

class weapon_dualcolt : ScriptBasePlayerWeaponEntity
{
	private int m_iShotsFired;
	private float m_flNextFakeReload;
	private float m_flThirdPersonReload;
	bool leftright = false;
	
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_colt.mdl" );
		self.pev.body = 1;

		self.m_iClip			= -1;
		m_iShotsFired = 0;
		
		
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
		
		g_Game.PrecacheModel( "models/serioussam/weapons/v_dualcolt.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/w_colt.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/p_dualcolt.mdl" );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/colt/fire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/colt/reload.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/colt/fire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/colt/reload.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_dualcolt.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= 12;
		info.iSlot 		= 1;
		info.iPosition 	= 6;
		info.iFlags 	= 0;
		info.iWeight 	= 30;

		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
	
		NetworkMessage dualcolt( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			dualcolt.WriteLong( self.m_iId );
		dualcolt.End();
			
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/serioussam/weapons/v_dualcolt.mdl" ), self.GetP_Model( "models/serioussam/weapons/p_dualcolt.mdl" ), DUALCOLT_DRAW, "uzis" );
		
			float deployTime = 0.5f;
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
		if( m_iShotsFired >= 12 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			FakeReload();
			return;
		}
		
		m_flNextFakeReload = WeaponTimeBase() + 0.3;
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.23;
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		
		m_iShotsFired++;
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		if( leftright == true )
		{
			int animright = Math.RandomLong( 0, 1 );
			
			m_pPlayer.m_szAnimExtension = "uzis_right";
			
			self.SendWeaponAnim( ( animright == 1 ? DUALCOLT_SHOOTLEFT2 : DUALCOLT_SHOOTLEFT1 ) );
			
			leftright = false;
		}
		else
		{
			int animleft = Math.RandomLong( 0, 1 );
			
			m_pPlayer.m_szAnimExtension = "uzis_left";
			
			self.SendWeaponAnim( ( animleft == 1 ? DUALCOLT_SHOOTRIGHT2 : DUALCOLT_SHOOTRIGHT1 ) );
			
			leftright = true;
		}
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 3.0;
		m_flThirdPersonReload = WeaponTimeBase() + 0.2;
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/colt/fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 0;
		
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_1DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_1DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_1DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		int iDamage = 25;
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
				
				if ( pHit.pev.takedamage != DAMAGE_NO )
				{
					g_WeaponFuncs.ClearMultiDamage();
					
					pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_SNIPER | DMG_LAUNCH | DMG_NEVERGIB );
					
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
				}
			}
		}
	}
	
	void FakeReload()
	{
		self.SendWeaponAnim( DUALCOLT_RELOADRIGHT, 0, 0 );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/colt/reload.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.7f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.7;
		
		m_iShotsFired = 0;
		
		m_pPlayer.m_szAnimExtension = "uzis_left";
		
		BaseClass.Reload();
		
		leftright == false;
		SetThink( ThinkFunction( LeftReload ));
		self.pev.nextthink = WeaponTimeBase() + 0.6;
	}
	
	void Reload()
	{
		if ( m_iShotsFired <= 0 || m_flNextFakeReload > WeaponTimeBase() )
			return;
		
		m_pPlayer.m_szAnimExtension = "uzis_left";
		
		FakeReload();
		
		BaseClass.Reload();
	}
	
	void LeftReload()
	{
		self.SendWeaponAnim( DUALCOLT_RELOADLEFT );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/colt/reload.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
	}
	
	void Holster( int skipLocal = 0 ) 
    {     
		SetThink( null );
		
        BaseClass.Holster( skipLocal ); 
    }
	
	void WeaponIdle()
	{
		if( m_flNextFakeReload < WeaponTimeBase() )
		{
			if ( m_iShotsFired >= 12 )
			{
				FakeReload();
			}
			
		}
		
		if( m_flThirdPersonReload < WeaponTimeBase() )
		{
			m_pPlayer.m_szAnimExtension = "uzis";
			
		}
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		m_pPlayer.m_szAnimExtension = "uzis";
		
		self.SendWeaponAnim( DUALCOLT_IDLE );
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 4.0;
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

void RegisterDUALCOLT()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dualcolt", "weapon_dualcolt" );
	g_ItemRegistry.RegisterWeapon( "weapon_dualcolt", "serioussam" );
}