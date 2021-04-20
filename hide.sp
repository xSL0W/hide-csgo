/*
          $$\ $$\   $$\                                                                                                       
          $$ |\__|  $$ |                                                                                                      
 $$$$$$\  $$ |$$\ $$$$$$\    $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$\$$$$\   $$$$$$\   $$$$$$\   $$$$$$$\      $$$$$$\   $$$$$$\  
$$  __$$\ $$ |$$ |\_$$  _|  $$  __$$\ $$  __$$\  \____$$\ $$  _$$  _$$\ $$  __$$\ $$  __$$\ $$  _____|    $$  __$$\ $$  __$$\ 
$$$$$$$$ |$$ |$$ |  $$ |    $$$$$$$$ |$$ /  $$ | $$$$$$$ |$$ / $$ / $$ |$$$$$$$$ |$$ |  \__|\$$$$$$\      $$ |  \__|$$ /  $$ |
$$   ____|$$ |$$ |  $$ |$$\ $$   ____|$$ |  $$ |$$  __$$ |$$ | $$ | $$ |$$   ____|$$ |       \____$$\     $$ |      $$ |  $$ |
\$$$$$$$\ $$ |$$ |  \$$$$  |\$$$$$$$\ \$$$$$$$ |\$$$$$$$ |$$ | $$ | $$ |\$$$$$$$\ $$ |      $$$$$$$  |$$\ $$ |      \$$$$$$  |
 \_______|\__|\__|   \____/  \_______| \____$$ | \_______|\__| \__| \__| \_______|\__|      \_______/ \__|\__|       \______/ 
                                      $$\   $$ |                                                                              
                                      \$$$$$$  |                                                                              
                                       \______/                                                                               
*/

#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 
#include <cstrike>
#include <multicolors>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

#define TAG_COLOR 	"{lightgreen}[{green}Hide{lightgreen}]{default}"

ConVar  sm_hide_default_enabled,
        sm_hide_clientprefs_enabled;

Handle g_HideCookie;
bool     g_bHide[MAXPLAYERS + 1],
        g_bIsAlive[MAXPLAYERS + 1];

int g_iClientTeam[MAXPLAYERS + 1];

public Plugin myinfo =  
{ 
	name = "[CS:GO] Hide teammates", 
	author = "xSLOW, IT-KiLLER, Hardy", 
	description = "A plugin that can !hide teammates", 
	version = "2.1", 
	url = "" 
} 

public void OnPluginStart() 
{ 
	RegConsoleCmd("sm_hide", Command_Hide); 

	sm_hide_default_enabled	= CreateConVar("sm_hide_default_enabled", "0", "Default enabled for each player [0/1]");
	sm_hide_clientprefs_enabled	= CreateConVar("sm_hide_clientprefs_enabled", "1", "Client preferences enabled [0/1]");

	g_HideCookie = RegClientCookie("HideTeammates", "Hide your teammates", CookieAccess_Protected);

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client)) 
		{
			OnClientPutInServer(client);
			if(AreClientCookiesCached(client))
			{
				OnClientCookiesCached(client);
			}
            g_iClientTeam[client] = GetClientTeam(client);
            g_bIsAlive[client] = IsPlayerAlive(client);
		}
	}
    AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
	AddNormalSoundHook(OnNormalSoundPlayed);	

    AutoExecConfig(true, "hide");
    
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_team", Event_PlayerTeam);
} 

/*
$$$$$$$$\                             $$\               
$$  _____|                            $$ |              
$$ |  $$\    $$\  $$$$$$\  $$$$$$$\ $$$$$$\    $$$$$$$\ 
$$$$$\\$$\  $$  |$$  __$$\ $$  __$$\\_$$  _|  $$  _____|
$$  __|\$$\$$  / $$$$$$$$ |$$ |  $$ | $$ |    \$$$$$$\  
$$ |    \$$$  /  $$   ____|$$ |  $$ | $$ |$$\  \____$$\ 
$$$$$$$$\\$  /   \$$$$$$$\ $$ |  $$ | \$$$$  |$$$$$$$  |
\________|\_/     \_______|\__|  \__|  \____/ \_______/ 
                                                                                                   
*/

public Action Event_PlayerSpawn(Event event, char[] name, bool dontbroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_bIsAlive[client] = true;
}

public Action Event_PlayerDeath(Event event, char[] name, bool dontbroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_bIsAlive[client] = false;
}

public Action Event_PlayerTeam(Event event, char[] name, bool dontbroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_iClientTeam[client] = event.GetInt("team");

    return Plugin_Continue;
}


public void OnClientPutInServer(int client) 
{ 
    g_bHide[client] = false;
    //g_bHooked[client] = false;
    g_bIsAlive[client] = false;
    g_iClientTeam[client] = 0;

    HookPlayer(client);
}

public void OnClientDisconnect(int client)
{
    g_bHide[client] = false;
    //g_bHooked[client] = false;
    g_bIsAlive[client] = false;
    g_iClientTeam[client] = 0;
}


public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client)) return;
	
	char sCookieValue[4];
	GetClientCookie(client, g_HideCookie, sCookieValue, sizeof(sCookieValue));
	
	if(sm_hide_clientprefs_enabled.BoolValue && !StrEqual(sCookieValue, ""))
	{
		g_bHide[client] = !!StringToInt(sCookieValue);
	}
	else if(sm_hide_default_enabled.BoolValue)
	{
		g_bHide[client] = sm_hide_default_enabled.BoolValue;
	}
}

/*
 $$$$$$\                                                                  $$\           
$$  __$$\                                                                 $$ |          
$$ /  \__| $$$$$$\  $$$$$$\$$$$\  $$$$$$\$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$ | $$$$$$$\ 
$$ |      $$  __$$\ $$  _$$  _$$\ $$  _$$  _$$\  \____$$\ $$  __$$\ $$  __$$ |$$  _____|
$$ |      $$ /  $$ |$$ / $$ / $$ |$$ / $$ / $$ | $$$$$$$ |$$ |  $$ |$$ /  $$ |\$$$$$$\  
$$ |  $$\ $$ |  $$ |$$ | $$ | $$ |$$ | $$ | $$ |$$  __$$ |$$ |  $$ |$$ |  $$ | \____$$\ 
\$$$$$$  |\$$$$$$  |$$ | $$ | $$ |$$ | $$ | $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$ |$$$$$$$  |
 \______/  \______/ \__| \__| \__|\__| \__| \__| \_______|\__|  \__| \_______|\_______/                                                    
*/

public Action Command_Hide(int client, int args) 
{ 
	if(sm_hide_clientprefs_enabled.BoolValue && !AreClientCookiesCached(client))
	{
		CPrintToChat(client, "%s - please wait, your settings are retrieved...", TAG_COLOR);
		return Plugin_Handled;
	}

    if(g_bHide[client])
    {
        CPrintToChat(client, "%s - You {lightred}disabled{default} !hide", TAG_COLOR);
        g_bHide[client] = false;
    }
    else
    {
        CPrintToChat(client, "%s - You {green}enabled{default} !hide", TAG_COLOR);
        g_bHide[client] = true;
    }

	if(sm_hide_clientprefs_enabled.BoolValue)
	{
		char sCookieValue[4];
		FormatEx(sCookieValue, sizeof(sCookieValue), "%d", g_bHide[client]);
		SetClientCookie(client, g_HideCookie, sCookieValue);
	}

	return Plugin_Handled; 
} 

/*
 $$$$$$\  $$$$$$$\  $$\   $$\ $$\   $$\  $$$$$$\   $$$$$$\  $$\   $$\  $$$$$$\  
$$  __$$\ $$  __$$\ $$ | $$  |$$ |  $$ |$$  __$$\ $$  __$$\ $$ | $$  |$$  __$$\ 
$$ /  \__|$$ |  $$ |$$ |$$  / $$ |  $$ |$$ /  $$ |$$ /  $$ |$$ |$$  / $$ /  \__|
\$$$$$$\  $$ |  $$ |$$$$$  /  $$$$$$$$ |$$ |  $$ |$$ |  $$ |$$$$$  /  \$$$$$$\  
 \____$$\ $$ |  $$ |$$  $$<   $$  __$$ |$$ |  $$ |$$ |  $$ |$$  $$<    \____$$\ 
$$\   $$ |$$ |  $$ |$$ |\$$\  $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |\$$\  $$\   $$ |
\$$$$$$  |$$$$$$$  |$$ | \$$\ $$ |  $$ | $$$$$$  | $$$$$$  |$$ | \$$\ \$$$$$$  |
 \______/ \_______/ \__|  \__|\__|  \__| \______/  \______/ \__|  \__| \______/                                                                  
*/

public Action Hook_SetTransmit(int entity, int client)
{ 
	if(client != entity && g_bIsAlive[client] && g_bHide[client] && g_iClientTeam[entity] == g_iClientTeam[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue; 
}  

/*
 $$$$$$\            $$\   $$\                                             $$\  $$$$$$\                                      $$\ $$$$$$$\  $$\                                     $$\ 
$$  __$$\           $$$\  $$ |                                            $$ |$$  __$$\                                     $$ |$$  __$$\ $$ |                                    $$ |
$$ /  $$ |$$$$$$$\  $$$$\ $$ | $$$$$$\   $$$$$$\  $$$$$$\$$$$\   $$$$$$\  $$ |$$ /  \__| $$$$$$\  $$\   $$\ $$$$$$$\   $$$$$$$ |$$ |  $$ |$$ | $$$$$$\  $$\   $$\  $$$$$$\   $$$$$$$ |
$$ |  $$ |$$  __$$\ $$ $$\$$ |$$  __$$\ $$  __$$\ $$  _$$  _$$\  \____$$\ $$ |\$$$$$$\  $$  __$$\ $$ |  $$ |$$  __$$\ $$  __$$ |$$$$$$$  |$$ | \____$$\ $$ |  $$ |$$  __$$\ $$  __$$ |
$$ |  $$ |$$ |  $$ |$$ \$$$$ |$$ /  $$ |$$ |  \__|$$ / $$ / $$ | $$$$$$$ |$$ | \____$$\ $$ /  $$ |$$ |  $$ |$$ |  $$ |$$ /  $$ |$$  ____/ $$ | $$$$$$$ |$$ |  $$ |$$$$$$$$ |$$ /  $$ |
$$ |  $$ |$$ |  $$ |$$ |\$$$ |$$ |  $$ |$$ |      $$ | $$ | $$ |$$  __$$ |$$ |$$\   $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |$$  __$$ |$$ |  $$ |$$   ____|$$ |  $$ |
 $$$$$$  |$$ |  $$ |$$ | \$$ |\$$$$$$  |$$ |      $$ | $$ | $$ |\$$$$$$$ |$$ |\$$$$$$  |\$$$$$$  |\$$$$$$  |$$ |  $$ |\$$$$$$$ |$$ |      $$ |\$$$$$$$ |\$$$$$$$ |\$$$$$$$\ \$$$$$$$ |
 \______/ \__|  \__|\__|  \__| \______/ \__|      \__| \__| \__| \_______|\__| \______/  \______/  \______/ \__|  \__| \_______|\__|      \__| \_______| \____$$ | \_______| \_______|
                                                                                                                                                        $$\   $$ |                    
                                                                                                                                                        \$$$$$$  |                    
                                                                                                                                                         \______/                     
*/

public Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &target, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if ( StrContains(sample, "weapons/") != -1 || StrContains(sample, "player/") != -1 || StrContains(sample, "physics/") != -1)
    {
		int i, j;
    
        if(!IsValidEntity(target) || target <= 0 || target > MaxClients)
        {
            return Plugin_Continue;
        }
		for (i = 1; i <= numClients; i++)
		{
            if(clients[i] > 0 && clients[i] <= MaxClients)
            {
			    if (g_bIsAlive[clients[i]] && g_bHide[clients[i]] && clients[i] != target && g_iClientTeam[target] == g_iClientTeam[clients[i]] )
			    {
			    	for (j = i; j < numClients - 1; j++)
			    	{
			    		clients[j] = clients[j + 1];
			    	}
    
			    	numClients--;
			    	i--;
			    }
            }
		}
			
	
		return (numClients > 0) ? Plugin_Changed : Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/*
 $$$$$$\  $$\                  $$\                                    $$$$$$\  $$\                  $$\     
$$  __$$\ $$ |                 $$ |                                  $$  __$$\ $$ |                 $$ |    
$$ /  \__|$$$$$$$\   $$$$$$\ $$$$$$\    $$$$$$\  $$\   $$\ $$$$$$$\  $$ /  \__|$$$$$$$\   $$$$$$\ $$$$$$\   
\$$$$$$\  $$  __$$\ $$  __$$\\_$$  _|  $$  __$$\ $$ |  $$ |$$  __$$\ \$$$$$$\  $$  __$$\ $$  __$$\\_$$  _|  
 \____$$\ $$ |  $$ |$$ /  $$ | $$ |    $$ /  $$ |$$ |  $$ |$$ |  $$ | \____$$\ $$ |  $$ |$$ /  $$ | $$ |    
$$\   $$ |$$ |  $$ |$$ |  $$ | $$ |$$\ $$ |  $$ |$$ |  $$ |$$ |  $$ |$$\   $$ |$$ |  $$ |$$ |  $$ | $$ |$$\ 
\$$$$$$  |$$ |  $$ |\$$$$$$  | \$$$$  |\$$$$$$$ |\$$$$$$  |$$ |  $$ |\$$$$$$  |$$ |  $$ |\$$$$$$  | \$$$$  |
 \______/ \__|  \__| \______/   \____/  \____$$ | \______/ \__|  \__| \______/ \__|  \__| \______/   \____/ 
                                       $$\   $$ |                                                           
                                       \$$$$$$  |                                                           
                                        \______/                                                            
*/

public Action CSS_Hook_ShotgunShot(const char[] te_name, const Players[], int numClients, float delay)
{
    int[] newClients = new int[MaxClients];    
    int client, i;
    int newTotal = 0;
    int attacker = TE_ReadNum("m_iPlayer") + 1;

    if(attacker <= 0 || attacker > MaxClients)
    {
        return Plugin_Continue;
    }
    
    for (i = 0; i < numClients; i++)
    {
        client = Players[i];
        
        if(g_bIsAlive[client] && g_bHide[client] && g_iClientTeam[attacker] == g_iClientTeam[client])
            continue;
            
        newClients[newTotal++] = client;
    }
    
    if (newTotal == numClients)
        return Plugin_Continue;
    else if (newTotal == 0)
        return Plugin_Stop;
    
    float vTemp[3];
    TE_Start("Shotgun Shot");
    TE_ReadVector("m_vecOrigin", vTemp);
    TE_WriteVector("m_vecOrigin", vTemp);
    TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
    TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
    TE_WriteNum("m_weapon", TE_ReadNum("m_weapon"));
    TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
    TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
    TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
    TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
    TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
    TE_Send(newClients, newTotal, delay);
    
    return Plugin_Stop;
}

/*
$$$$$$$$\ $$\   $$\ $$\   $$\  $$$$$$\   $$$$$$\  
$$  _____|$$ |  $$ |$$$\  $$ |$$  __$$\ $$  __$$\ 
$$ |      $$ |  $$ |$$$$\ $$ |$$ /  \__|$$ /  \__|
$$$$$\    $$ |  $$ |$$ $$\$$ |$$ |      \$$$$$$\  
$$  __|   $$ |  $$ |$$ \$$$$ |$$ |       \____$$\ 
$$ |      $$ |  $$ |$$ |\$$$ |$$ |  $$\ $$\   $$ |
$$ |      \$$$$$$  |$$ | \$$ |\$$$$$$  |\$$$$$$  |
\__|       \______/ \__|  \__| \______/  \______/          
*/

void HookPlayer(int client)
{
    SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit); 
}
