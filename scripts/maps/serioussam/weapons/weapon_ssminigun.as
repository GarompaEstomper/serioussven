enum SSMINIGUNAnimation
{
	SSMINIGUN_IDLE = 0,
	SSMINIGUN_DRAW,
	SSMINIGUN_SPINUP,
	SSMINIGUN_FIRE,
	SSMINIGUN_SPINDOWN
};

int SSMINIGUN_DEFAULT_GIVE	= 100;
int SSMINIGUN_MAX_CARRY		= 500;

class weapon_ssminigun : ScriptBasePlayerWeaponEntity
{
	private int m_iInAttack;
	private int m_iShell2;
	
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_minigun.mdl" );
				
		m_iShell2 = g_Game.PrecacheModel( "models/serioussam/ss_shell.mdl" );
		
		self.m_iDefaultAmmo = SSMINIGUN_DEFAULT_GIVE;
		
		BaseClass.Spawn();
		self.pev.sequence = 1;
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		self.FallInit();
		//@m_pRotFunc = @g_Scheduler.SetInterval( this, "RotateThink", 0.01f, g_Scheduler.REPEAT_INFINITE_TIMES );
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
		
		g_Game.PrecacheModel( "models/serioussam/weapons/v_minigun.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/w_minigun.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/p_minigun.mdl" );
		g_Game.PrecacheModel( "models/serioussam/weapons/p_minigunspin.mdl" );
		
		g_Game.PrecacheModel( "models/serioussam/ss_shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/minigun/click.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/minigun/fire.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/minigun/rotate.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/minigun/rotatedown.ogg" );
		g_Game.PrecacheGeneric( "sound/serioussam/weapons/minigun/rotateup.ogg" );
		
		g_SoundSystem.PrecacheSound( "serioussam/weapons/minigun/click.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/minigun/fire.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/minigun/rotate.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/minigun/rotatedown.ogg" );
		g_SoundSystem.PrecacheSound( "serioussam/weapons/minigun/rotateup.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/serioussam/weapon_ssminigun.txt" );
		
		g_Game.PrecacheGeneric( "events/muzzle_ss_minigun.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= SSMINIGUN_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot		= 3;
		info.iPosition	= 6;
		info.iFlags		= 0;
		info.iWeight	= 39;
		
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
	
			NetworkMessage ssminigun( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				ssminigun.WriteLong( self.m_iId );
			ssminigun.End();
			
			ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
			return true;
	}
	
	void Holster( int skipLocal = 0 ) 
    {     
		m_iInAttack = 0;
		
		SetThink( null );
			
		BaseClass.Holster( skipLocal ); 
    }
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/minigun/click.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	bool Deploy()
	{	
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/serioussam/weapons/v_minigun.mdl" ), self.GetP_Model( "models/serioussam/weapons/p_minigun.mdl" ), SSMINIGUN_DRAW, "minigun", 0 );
			
			float deployTime = 0.5;
			
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			
			return bResult;
		}
	}
	
	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.55f;
			WeaponIdle();
			return;
		}
		
		if ( m_iInAttack == 0 )
		{
			self.SendWeaponAnim( SSMINIGUN_SPINUP );
			
			m_pPlayer.pev.weaponmodel = ("models/serioussam/weapons/p_minigunspin.mdl" );
			
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.7;
			
			self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/minigun/rotateup.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
			
			m_iInAttack = 1;
			
			return;
		}
		
		if ( m_iInAttack == 1 )
		{
			MinigunAttack();
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, "serioussam/weapons/minigun/fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
			//g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, "serioussam/weapons/minigun/rotate.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
			
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.05;
		}
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0;
	}
	
	void MinigunAttack()
	{	
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		
		self.SendWeaponAnim( SSMINIGUN_FIRE );
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		//slightly larger than 2degrees
		Vector vecSpread = Vector( 0.021, 0.021, 0.021 );
		
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecSpread, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, 0 );
		
		DoShellEjection();
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * vecSpread.x * g_Engine.v_right 
						+ y * vecSpread.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		int iDamage = 25;
			
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
				{
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
				}
				
				g_WeaponFuncs.ClearMultiDamage();
					
				if ( pHit.pev.takedamage != DAMAGE_NO && pHit.pev.classname != "monster_robogrunt" && pHit.pev.classname != "monster_gargantua" && pHit.pev.classname != "monster_bigmomma" )
				{
					pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_SNIPER | DMG_LAUNCH | DMG_NEVERGIB ); 
				}
				else if ( pHit.pev.classname == "monster_robogrunt" )
				{
					pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_ENERGYBEAM | DMG_LAUNCH | DMG_NEVERGIB );  // -25% damage to robogrunts
				}
				else if ( pHit.pev.classname == "monster_gargantua" )
				{
					pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_BLAST | DMG_SNIPER | DMG_NEVERGIB ); // -50% to gargs
				}
				else if ( pHit.pev.classname == "monster_bigmomma" )
					pHit.TakeDamage ( m_pPlayer.pev, m_pPlayer.pev, iDamage, DMG_BLAST | DMG_SNIPER | DMG_NEVERGIB );	// -50% to bigmommas
					
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
				
			}
		}
		
		//Get's the barrel attachment
		Vector vecAttachOrigin;
		Vector vecAttachAngles;
		
		g_EngineFuncs.GetAttachment( m_pPlayer.edict(), 0, vecAttachOrigin, vecAttachAngles );
		
		WW2DynamicLight( m_pPlayer.pev.origin, 8, 240, 180, 0, 8, 50 );
		
		//Produces a tracer at the start of the attachment at a rate of 2 bullets
		switch( ( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) ) % 2 )
		{
			case 0: WW2DynamicTracer( vecAttachOrigin, tr.vecEndPos ); break;
		}
	}
	
	void DoShellEjection()
	{
			Vector vecShellVelocity2, vecShellOrigin2;
		
			//shell
			CS16GetDefaultShellInfo( EHandle(m_pPlayer), vecShellVelocity2, vecShellOrigin2, 15, 8, -9, false, false );
		
			M134EjectBrass( vecShellOrigin2, vecShellVelocity2, m_pPlayer.pev.angles[ 1 ], m_iShell2, TE_BOUNCE_SHELL );
	}
	
	void SecondaryAttack()
	{	
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.0;
		WeaponIdle();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( m_iInAttack == 1 )
		{
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.5;
			self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.5;
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/minigun/rotatedown.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
			
			self.SendWeaponAnim( SSMINIGUN_SPINDOWN );
			
			m_iInAttack = 0;
			
			return;
		}
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( SSMINIGUN_IDLE );
		
		m_pPlayer.pev.weaponmodel = ("models/serioussam/weapons/p_minigun.mdl" );
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 30.0;
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

// Aperture: The M134 uses a custom EjectBrass function because it spawns a ton of shells very quickly and they don't disappear fast enough to clear up the epoly count.
void M134EjectBrass ( Vector& in vecOrigin, Vector& in vecVelocity, float rotation, int model, int soundtype )
{
	NetworkMessage shell( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				shell.WriteByte( TE_MODEL );
				shell.WriteCoord( vecOrigin.x );
				shell.WriteCoord( vecOrigin.y );
				shell.WriteCoord( vecOrigin.z );
				shell.WriteCoord( vecVelocity.x ); 
				shell.WriteCoord( vecVelocity.y );
				shell.WriteCoord( vecVelocity.z );
				shell.WriteAngle( rotation );
				shell.WriteShort( ( model ) );
				shell.WriteByte( soundtype );
				shell.WriteByte( 7 );
			shell.End();
}

void RegisterSSMINIGUN()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_ssminigun", "weapon_ssminigun" );
	g_ItemRegistry.RegisterWeapon( "weapon_ssminigun", "serioussam", "9mm" );
}