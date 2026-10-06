class item_ss_backpack : ScriptBasePlayerAmmoEntity
{
	private int m_iBulletAmt;
	private int m_iShellAmt;
	private int m_iRocketAmt;
	private int m_iSniperAmt;
	private int m_iNapalmAmt;
	private int m_iGrenadesAmt;
	private int m_iLaserAmt;
	private int m_iCannonBallAmt;
	
	private int m_iGaveBullets;
	private int m_iGaveShells;
	private int m_iGaveRockets;
	private int m_iGaveSniper;
	private int m_iGaveNapalm;
	private int m_iGaveGrenades;
	private int m_iGaveLaser;
	private int m_iGaveCannonBalls;
	
	private int m_iRemove;
	private int m_iItemTier;
	
	void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/backpack.mdl" );
		self.pev.body = 0;
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		RandomizeAmmo();
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 16;
			}
		}
    }
	
	//Aperture: Hey, anyone up for a $5 fill up at KFC? I'm soooooooo hungry!!! D:
	void RandomizeAmmo()
	{
		m_iItemTier = Math.RandomLong( 0, 3 );
		
		m_iBulletAmt = Math.RandomLong( 50, 150 );
		m_iShellAmt = Math.RandomLong( 10, 30 );
		m_iRocketAmt = Math.RandomLong( 5, 15 );
		m_iSniperAmt = Math.RandomLong( 5, 15 );
		m_iNapalmAmt = Math.RandomLong( 50, 150 );
		m_iGrenadesAmt = Math.RandomLong( 10, 15 );
		m_iLaserAmt = Math.RandomLong( 40, 120 );
		m_iCannonBallAmt = Math.RandomLong( 5, 15 );
	}
	
	void ResetAmmo()
	{
		m_iGaveBullets = 0;
		m_iGaveShells = 0;
		m_iGaveRockets = 0;
		m_iGaveSniper = 0;
		m_iGaveNapalm = 0;
		m_iGaveGrenades = 0;
		m_iGaveLaser = 0;
		m_iGaveCannonBalls = 0;
		
		m_iRemove = 0;
		
		RandomizeAmmo();
	}
	
    bool AddAmmo( CBaseEntity@ pOther )
    {
		if ( pOther is null || !pOther.IsPlayer() || pOther.pev.health <= 0 ) 
			return false;
		
		//This is really shitty lol...
		if ( pOther.GiveAmmo( m_iBulletAmt, "9mm", 500 ) >= 0 && m_iGaveBullets <= 0 )
		{
			m_iGaveBullets = 1;
			m_iRemove = 1;
		}
		
		if ( pOther.GiveAmmo( m_iShellAmt, "ssshells", 100 ) >= 0 && m_iGaveShells <= 0 )
		{
			m_iGaveShells = 1;
			m_iRemove = 1;
		}
		
		if ( m_iItemTier <= 1 )
		{
			if ( pOther.GiveAmmo( m_iRocketAmt, "ssrockets", 50 ) >= 0 && m_iGaveRockets <= 0 )
			{
				m_iGaveRockets = 1;
				m_iRemove = 1;
			}
			
			if ( pOther.GiveAmmo( m_iSniperAmt, "sniperbullets", 50 ) >= 0 && m_iGaveSniper <= 0 )
			{
				m_iGaveSniper = 1;
				m_iRemove = 1;
			}
		}
		
		
		if ( m_iItemTier == 2 )
		{
			if ( pOther.GiveAmmo( m_iNapalmAmt, "ssnapalm", 500 ) >= 0 && m_iGaveNapalm <= 0 )
			{
				m_iGaveNapalm = 1;
				m_iRemove = 1;
			}
		
			if ( pOther.GiveAmmo( m_iGrenadesAmt, "ssgrenades", 50 ) >= 0 && m_iGaveGrenades <= 0 )
			{
				m_iGaveGrenades = 1;
				m_iRemove = 1;
			}
		}
		
		if ( m_iItemTier == 3 )
		{
			if ( pOther.GiveAmmo( m_iLaserAmt, "energycells", 400 ) >= 0 && m_iGaveLaser <= 0 )
			{
				m_iGaveLaser = 1;
				m_iRemove = 1;
			}
			
			if ( pOther.GiveAmmo( m_iCannonBallAmt, "cannonballs", 50 ) >= 0 && m_iGaveCannonBalls <= 0 )
			{
				m_iGaveCannonBalls = 1;
				m_iRemove = 1;
			}
		}
		
		//Did I get something from it? If so, remove it.
		if ( m_iRemove > 0 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
			ResetAmmo();
			return true;
		}
		return false;
    }
}

void RegisterItemSSBackPack()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "item_ss_backpack", "item_ss_backpack" );
}
//serious backpack
// fill up ALL ammotypes to the MAX!!!
class item_ss_seriouspack : ScriptBasePlayerAmmoEntity
{
	private int m_iBulletAmt;
	private int m_iShellAmt;
	private int m_iRocketAmt;
	private int m_iSniperAmt;
	private int m_iNapalmAmt;
	private int m_iGrenadesAmt;
	private int m_iLaserAmt;
	private int m_iCannonBallAmt;
	
	private int m_iGaveBullets;
	private int m_iGaveShells;
	private int m_iGaveRockets;
	private int m_iGaveSniper;
	private int m_iGaveNapalm;
	private int m_iGaveGrenades;
	private int m_iGaveLaser;
	private int m_iGaveCannonBalls;
	
	private int m_iRemove;
	
	void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/serioussam/items/backpack.mdl" );
		self.pev.body = 1;
        BaseClass.Spawn();
		
		self.pev.movetype = MOVETYPE_NONE;
		
		self.pev.framerate = 1.0;
		self.pev.animtime = g_Engine.time + 0.001;
		self.pev.frame = Math.RandomLong(0, 300);
		
		m_iBulletAmt = 500;
		m_iShellAmt = 100;
		m_iRocketAmt = 50;
		m_iSniperAmt = 50;
		m_iNapalmAmt = 500;
		m_iGrenadesAmt = 50;
		m_iLaserAmt = 400;
		m_iCannonBallAmt = 30;
		
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -36;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		self.pev.scale = 1.5;
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + 16;
			}
		}
    }
	
    bool AddAmmo( CBaseEntity@ pOther )
    {
		if ( pOther is null || !pOther.IsPlayer() || pOther.pev.health <= 0 ) 
			return false;
		
		if ( pOther.GiveAmmo( m_iBulletAmt, "9mm", 500 ) >= 0 && m_iGaveBullets <= 0 )
		{
			m_iGaveBullets = 1;
			m_iRemove = 1;
		}
		
		if ( pOther.GiveAmmo( m_iShellAmt, "ssshells", 100 ) >= 0 && m_iGaveShells <= 0 )
		{
			m_iGaveShells = 1;
			m_iRemove = 1;
		}
		
		if ( pOther.GiveAmmo( m_iRocketAmt, "ssrockets", 50 ) >= 0 && m_iGaveRockets <= 0 )
		{
			m_iGaveRockets = 1;
			m_iRemove = 1;
		}
			
		if ( pOther.GiveAmmo( m_iSniperAmt, "sniperbullets", 50 ) >= 0 && m_iGaveSniper <= 0 )
		{
			m_iGaveSniper = 1;
			m_iRemove = 1;
		}
		
		if ( pOther.GiveAmmo( m_iNapalmAmt, "ssnapalm", 500 ) >= 0 && m_iGaveNapalm <= 0 )
		{
			m_iGaveNapalm = 1;
			m_iRemove = 1;
		}
		
		if ( pOther.GiveAmmo( m_iGrenadesAmt, "ssgrenades", 50 ) >= 0 && m_iGaveGrenades <= 0 )
		{
			m_iGaveGrenades = 1;
			m_iRemove = 1;
		}
		
		if ( pOther.GiveAmmo( m_iLaserAmt, "energycells", 400 ) >= 0 && m_iGaveLaser <= 0 )
		{
			m_iGaveLaser = 1;
			m_iRemove = 1;
		}
			
		if ( pOther.GiveAmmo( m_iCannonBallAmt, "cannonballs", 50 ) >= 0 && m_iGaveCannonBalls <= 0 )
		{
			m_iGaveCannonBalls = 1;
			m_iRemove = 1;
		}
		
		//Did I get something from it? If so, remove it.
		if ( m_iRemove > 0 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "serioussam/items/ammo.ogg", 1, ATTN_NORM );
			ResetAmmo();
			return true;
		}
		return false;
    }
	
	void ResetAmmo()
	{
		m_iGaveBullets = 0;
		m_iGaveShells = 0;
		m_iGaveRockets = 0;
		m_iGaveSniper = 0;
		m_iGaveNapalm = 0;
		m_iGaveGrenades = 0;
		m_iGaveLaser = 0;
		m_iGaveCannonBalls = 0;
		
		m_iRemove = 0;
	}
}

void RegisterItemSSSeriousPack()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "item_ss_seriouspack", "item_ss_seriouspack" );
}