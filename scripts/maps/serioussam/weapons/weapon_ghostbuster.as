int GHOSTBUSTER_DEFAULT_GIVE	= 100;
int GHOSTBUSTER_MAX_CARRY 		= 500;

enum GHOSTBUSTERAnimation
{
	GHOSTBUSTER_IDLE = 0,
	GHOSTBUSTER_FIRE,
	GHOSTBUSTER_DRAW
}

class weapon_ghostbuster : ScriptBasePlayerWeaponEntity
{
	private bool m_bFiring;
	string laser = "sprites/serioussam/lightning.spr";
	
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_ghostbuster.mdl" );
		
		self.m_iDefaultAmmo = GHOSTBUSTER_DEFAULT_GIVE;
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
		
		m_bFiring = false;
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		
		g_Game.PrecacheModel( "models/serioussam/weapons/v_ghostbuster.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/w_ghostbuster.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/p_ghostbuster.mdl" );
		
		g_Game.PrecacheModel( "sprites/serioussam/lightning.spr" );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/ghostbuster_fire.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/ghostbuster_fire.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_ghostbuster.txt" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
		
			NetworkMessage ghostbuster( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				ghostbuster.WriteLong( self.m_iId );
			ghostbuster.End();
			
			ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
			return true;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= LASER_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 6;
		info.iPosition 	= 3;
		info.iFlags 	= 0;
		info.iWeight 	= 30;

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/serioussam/weapons/v_ghostbuster.mdl" ), self.GetP_Model( "models/serioussam/weapons/p_ghostbuster.mdl" ), GHOSTBUSTER_DRAW, "gauss" );
			
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
        SetThink(null);
		
		m_bFiring = false;
		
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/ghostbuster_fire.ogg" );
		
        BaseClass.Holster( skipLocal ); 
    }
	
	
	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			WeaponIdle();
			return;
		}
		
		if ( m_bFiring == false )
		{
			self.SendWeaponAnim( GHOSTBUSTER_FIRE );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/ghostbuster_fire.ogg", 0.9, ATTN_NORM, SND_FORCE_LOOP, PITCH_NORM );
			m_bFiring = true;
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.01;
			return;
		}
	
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
	
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		TraceResult tr;
			
		float x, y;
			
		g_Utility.GetCircularGaussianSpread( x, y );
			
		Vector vecDir;
			
		vecDir = vecAiming 
			+ x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right 
			+ y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;
			
		Vector vecEnd	= vecSrc + vecDir * 8192;
		
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		WW2DynamicLight( m_pPlayer.pev.origin, 8, 30, 255, 255, 8, 50 );
		
		int iDamage = 30;
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				g_WeaponFuncs.ClearMultiDamage();
					
				pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_ENERGYBEAM | DMG_LAUNCH | DMG_ALWAYSGIB ); 
					
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
			}
		}
		
		int laser_red = 255;	
		int laser_green = 255;	
		int laser_blue = 255;
		
		NetworkMessage laserbeam( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
			laserbeam.WriteByte(TE_BEAMENTPOINT);
			laserbeam.WriteShort( m_pPlayer.entindex() + 0x1000 );
			laserbeam.WriteCoord( tr.vecEndPos.x);
			laserbeam.WriteCoord( tr.vecEndPos.y);
			laserbeam.WriteCoord( tr.vecEndPos.z);
			laserbeam.WriteShort( g_EngineFuncs.ModelIndex(laser) );
			laserbeam.WriteByte( 1 );
			laserbeam.WriteByte( 100 );
			laserbeam.WriteByte( 2 );
			laserbeam.WriteByte( 30 );
			laserbeam.WriteByte( 5 );
			laserbeam.WriteByte( laser_red );
			laserbeam.WriteByte( laser_green );
			laserbeam.WriteByte( laser_blue );
			laserbeam.WriteByte( 255 );
			laserbeam.WriteByte( 255 );
		laserbeam.End();
		
		WW2DynamicLight( tr.vecEndPos, 8, 30, 255, 255, 8, 50 );
		
		NetworkMessage sparks( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
			sparks.WriteByte(TE_SPARKS);
			sparks.WriteCoord( tr.vecEndPos.x);
			sparks.WriteCoord( tr.vecEndPos.y);
			sparks.WriteCoord( tr.vecEndPos.z);
		sparks.End();
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.04;
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.1;
	}
	
	void SecondaryAttack()
	{
		if( ( m_pPlayer.pev.button & IN_ATTACK ) == 1  )
		WeaponIdle();
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );
		
		if ( m_bFiring == true )
		{
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/ghostbuster_fire.ogg" );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.1;
			m_bFiring = false;
		}
		
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

void RegisterGHOSTBUSTER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_ghostbuster", "weapon_ghostbuster" );
	g_ItemRegistry.RegisterWeapon( "weapon_ghostbuster", "serioussam", "energycells" );
}