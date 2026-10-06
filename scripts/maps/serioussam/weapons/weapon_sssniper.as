enum SSSNIPERAnimation
{
    SSSNIPER_FIRE = 0,
    SSSNIPER_IDLE,
    SSSNIPER_DRAW
};

int SSSNIPER_DEFAULT_GIVE      = 5;
int SSSNIPER_MAX_CARRY         = 50;

class weapon_sssniper : ScriptBasePlayerWeaponEntity
{
    int g_iCurrentMode;
	int m_iZoom;
    int m_iShell;
    
	private CBasePlayer@ m_pPlayer = null;
	
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/weapons/w_sniper.mdl" );
        m_iShell = g_Game.PrecacheModel( "models/serioussam/shell_sniper.mdl" );
        self.m_iDefaultAmmo = SSSNIPER_DEFAULT_GIVE;
		
        g_iCurrentMode = 0;
		m_iZoom = 0;
		
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
		
        g_Game.PrecacheModel( "models/serioussam/weapons/v_sniper.mdl" );
        g_Game.PrecacheModel( "models/serioussam/weapons/w_sniper.mdl" );
        g_Game.PrecacheModel( "models/serioussam/weapons/p_sniper.mdl" );
		
        g_Game.PrecacheModel( "models/serioussam/shell_sniper.mdl" );
        
        g_Game.PrecacheGeneric( "sound/serioussam/weapons/sniper/fire.ogg" );
        g_Game.PrecacheGeneric( "sound/serioussam/weapons/sniper/quickzoom.ogg" );
        g_Game.PrecacheGeneric( "sound/serioussam/weapons/sniper/zoom.ogg" );
        
        g_SoundSystem.PrecacheSound( "serioussam/weapons/sniper/fire.ogg" );
        g_SoundSystem.PrecacheSound( "serioussam/weapons/sniper/quickzoom.ogg" );
        g_SoundSystem.PrecacheSound( "serioussam/weapons/sniper/zoom.ogg" );
		
        g_Game.PrecacheGeneric( "sprites/serioussam/weapon_sssniper.txt");
    }
    
    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1  = SSSNIPER_MAX_CARRY;
        info.iMaxAmmo2  = -1;
        info.iMaxClip   = WEAPON_NOCLIP;
        info.iSlot      = 5;
        info.iPosition  = 6;
        info.iFlags     = 0;
        info.iWeight    = 50;
        
        return true;
    }
    
    bool AddToPlayer( CBasePlayer@ pPlayer )
    {
        @m_pPlayer = pPlayer;
		
		if( !BaseClass.AddToPlayer( pPlayer ) )
		return false;
	
            NetworkMessage sssniper( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
                sssniper.WriteLong( self.m_iId );
            sssniper.End();
			
			ScheduleSeriousItemSound(pPlayer, "serioussam/items/weapon.ogg" );
			
            return true;
    }
    
    void Holster( int skipLocal = 0 ) 
    {     
        self.m_fInReload = false; 
         
        if ( self.m_fInZoom ) 
        { 
            SecondaryAttack(); 
        }
		
        g_iCurrentMode = 0;
		m_iZoom = 0;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/sniper/zoom.ogg" );
        ToggleZoom( 0 );
        
		SetThink(null);
		
        BaseClass.Holster( skipLocal ); 
    }
    
    void SetFOV( int fov )
    {
        m_pPlayer.pev.fov = m_pPlayer.m_iFOV = fov;
    }
    
    void ToggleZoom( int zoomedFOV )
    {
        if ( self.m_fInZoom == true )
        {
            SetFOV( 0 ); // 0 means reset to default fov
        }
        else if ( self.m_fInZoom == false )
        {
            SetFOV( zoomedFOV );
        }
    }
    
    float WeaponTimeBase()
    {
        return g_Engine.time;
    }
    
    bool Deploy()
    {
        bool bResult;
        {
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/serioussam/weapons/v_sniper.mdl" ), self.GetP_Model( "models/serioussam/weapons/p_sniper.mdl" ), SSSNIPER_DRAW, "sniper" );
        
			float deployTime = 0.5;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
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
        
       m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
        
        m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
        m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        
		 self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.5f;
        self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.2f;
        
        self.SendWeaponAnim( SSSNIPER_FIRE, 0, 0 );
            
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/sniper/fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
        
        Vector vecSrc    = m_pPlayer.GetGunPosition();
        Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
        
        int m_iBulletDamage = 0;
        
        m_pPlayer.FireBullets( 1, vecSrc, vecAiming,( g_iCurrentMode == 0 ? VECTOR_CONE_3DEGREES :  g_vecZero ), 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );
       
        if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
            
        self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
        
        TraceResult tr;
        
        float x, y;
        
        g_Utility.GetCircularGaussianSpread( x, y );
        
        Vector vecDir;
        
		vecDir = vecAiming + x * ( g_iCurrentMode == 0 ? VECTOR_CONE_3DEGREES.x : g_vecZero.x ) * g_Engine.v_right + y * ( g_iCurrentMode == 0 ? VECTOR_CONE_3DEGREES.y : g_vecZero.y ) * g_Engine.v_up;
       
		Vector vecEnd   = vecSrc + vecDir * 8192;
		
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
        
		int iDamage = 200;
			
		if( tr.flFraction < 1.0 )
        {
            if( tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                
                if( pHit is null || pHit.IsBSPModel() == true )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
				
				
					g_WeaponFuncs.ClearMultiDamage();
					
					if ( pHit.pev.takedamage != DAMAGE_NO && pHit.pev.classname != "monster_robogrunt" && pHit.pev.classname != "monster_gargantua" )
					{
						pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_SNIPER | DMG_LAUNCH | DMG_NEVERGIB );
					}
					else if ( pHit.pev.classname == "monster_robogrunt" )
					{
						pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_ENERGYBEAM | DMG_LAUNCH | DMG_NEVERGIB ); 
					}
					else if ( pHit.pev.classname == "monster_gargantua" )
					{
						pHit.TraceAttack( m_pPlayer.pev, iDamage, vecDir, tr, DMG_BLAST | DMG_LAUNCH | DMG_NEVERGIB ); 
					}
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
					
				
			}
        }
        
		SetThink( ThinkFunction( RadishSoup ) );
		
		self.pev.nextthink = WeaponTimeBase() + 0.7;
    }
    
	void RadishSoup()
	{
		Vector vecShellVelocity, vecShellOrigin;
       //The last 3 parameters are unique for each weapon (this should be using an attachment in the model to get the correct position, but most models don't have that).
        CS16GetDefaultShellInfo( EHandle(m_pPlayer), vecShellVelocity, vecShellOrigin, 13, 9, -8, false, false );
       
        //Lefthanded weapon, so invert the Y axis velocity to match.
        vecShellVelocity.y *= 1;
       
        g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
    void SecondaryAttack()
    {
		if(g_iCurrentMode == 2)
		{
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1f;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/sniper/quickzoom.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
			g_iCurrentMode = 3;
			ToggleZoom( 0 );
			m_iZoom = 0;
			m_pPlayer.m_szAnimExtension = "sniper";
		}else if (g_iCurrentMode == 0){
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.025f;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/sniper/zoom.ogg", 0.9, ATTN_NORM, SND_FORCE_LOOP, PITCH_NORM );
			g_iCurrentMode = 1;
			ToggleZoom( 40-m_iZoom );
			m_pPlayer.m_szAnimExtension = "sniperscope";
		}
		
		if(g_iCurrentMode == 1)
		{
			if(m_iZoom < 30)
			{
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.025f;
				m_iZoom++;
				ToggleZoom( 40-m_iZoom );
			}else{
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1f;
				ToggleZoom( 40-m_iZoom );
				g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/sniper/zoom.ogg" );
			}
		}
    }
    
    void WeaponIdle()
    {
		if(g_iCurrentMode == 1) { g_iCurrentMode = 2; g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "serioussam/weapons/sniper/zoom.ogg" );}
		if(g_iCurrentMode == 3) { g_iCurrentMode = 0;}
	
        self.ResetEmptySound();
        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
        
        if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
            return;
        
        self.SendWeaponAnim( SSSNIPER_IDLE );
        self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
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

void RegisterSSSNIPER()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_sssniper", "weapon_sssniper" );
    g_ItemRegistry.RegisterWeapon( "weapon_sssniper", "serioussam", "sniperbullets" );
}
