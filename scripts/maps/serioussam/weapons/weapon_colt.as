
enum ColtAnimation
{
	COLT_IDLE = 0,
	COLT_IDLE2,
	COLT_SHOOT1,
	COLT_SHOOT2,
	COLT_RELOAD,
	COLT_DRAW
};

class weapon_colt : ScriptBasePlayerWeaponEntity
{
	private int m_iShotsFired;
	private float m_flNextFakeReload;
	
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_colt.mdl" );
		self.pev.body = 0;
		
		self.m_iClip = -1;
		self.pev.sequence = 1;
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		m_iShotsFired = 0;
		
		BaseClass.Spawn();
		self.FallInit();
		//@m_pRotFunc = @g_Scheduler.SetInterval( this, "RotateThink", 0.01f, g_Scheduler.REPEAT_INFINITE_TIMES );
		self.pev.movetype = MOVETYPE_NONE;
		
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
		
		g_Game.PrecacheModel( "models/serioussam/weapons/v_colt.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/w_colt.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/p_colt.mdl" );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/colt/fire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/colt/reload.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/colt/fire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/colt/reload.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_colt.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= 6;
		info.iSlot 		= 1;
		info.iPosition 	= 5;
		info.iFlags 	= 0;
		info.iWeight 	= 7;

		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
	
		NetworkMessage colt( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			colt.WriteLong( self.m_iId );
		colt.End();
			
		ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg");
			
		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/serioussam/weapons/v_colt.mdl" ), self.GetP_Model( "models/serioussam/weapons/p_colt.mdl" ), COLT_DRAW, "python" );
		
			float deployTime = 0.5;
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
		if( m_iShotsFired >= 6 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			FakeReload();
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.45;
		m_flNextFakeReload = WeaponTimeBase() + 0.5;
		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		
		m_iShotsFired++;
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )
		{
			case 0: self.SendWeaponAnim( COLT_SHOOT1, 0, 0 ); break;
			case 1: self.SendWeaponAnim( COLT_SHOOT2, 0, 0 ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/colt/fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
	
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 0;
		
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );//Nero
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		int iDamage = 30;
		
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
	
	void Reload()
	{
		if ( m_iShotsFired <= 0 || m_flNextFakeReload > WeaponTimeBase() )
			return;
		
		FakeReload();
		
		BaseClass.Reload();
	}
	
	void FakeReload()
	{
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/colt/reload.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
		self.SendWeaponAnim( COLT_RELOAD, 0, 0 );
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.2f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.2;//Nero
		
		m_iShotsFired = 0;
		
		BaseClass.Reload();
	}
	
	void Holster( int skipLocal = 0 ) 
    {     
        BaseClass.Holster( skipLocal ); 
    }
	
	void WeaponIdle()
	{
		if( m_flNextFakeReload > WeaponTimeBase() )
			return;
		
		if ( m_iShotsFired >= 6 )
		{
			FakeReload();
		}
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( COLT_IDLE );
		
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

void RegisterCOLT()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_colt", "weapon_colt" );
	g_ItemRegistry.RegisterWeapon( "weapon_colt", "serioussam" );
}
