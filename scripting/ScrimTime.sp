#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

#define VETOMAP "lobby_mapveto"

ConVar g_cVarGameMode;
ConVar g_cVarGameType;

bool g_isInLobby = true;

int g_player_info[MAXPLAYERS][2];


public Plugin myinfo =
{
	name = "ScrimTime",
	author = "SauerkrautKebap",
	description = "",
	version = "1.0",
	url = "https://github.com/SauerkrautKebap/ScrimTime"
};


public void OnPluginStart()
{
    RegConsoleCmd("readyvote", Command_ReadyVote);
    RegAdminCmd("start_game", Command_StartGame, ADMFLAG_CHANGEMAP, "immediately starts the game without voting");
    g_cVarGameMode = FindConVar("game_mode");
    g_cVarGameType = FindConVar("game_type");
    g_cVarGameType.IntValue = 1;
    g_cVarGameMode.IntValue = 2;
    HookEvent("player_connect_full", Event_PlayerConnectFull);
    HookEvent("player_team", Event_PlayerTeam);
    HookEntityOutput("mapvetopick_controller", "OnSidesPicked", Entity_VetoController_OnSidesPicked);
    AddCommandListener(Command_JoinTeam, "jointeam");
}

public void Entity_VetoController_OnSidesPicked(const char[] output, int caller, int activator, float delay)
{
    int switchSides = GetEntProp(caller, Prop_Data, "m_OnSidesPicked");
    if(switchSides)
    {
        for(int i = 0; i < sizeof(g_player_info); i++)
        {
            if(g_player_info[i][1] == CS_TEAM_T)
            {
                g_player_info[i][1] = CS_TEAM_CT;
            }
            else if(g_player_info[i][1] == CS_TEAM_CT)
            {
                g_player_info[i][1] = CS_TEAM_T;
            }
        }
    }
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
    if(!g_isInLobby)
        return Plugin_Continue;

    int team = GetEventInt(event, "team");
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    g_player_info[client][0] = GetClientUserId(client);
    g_player_info[client][1] = team;

    return Plugin_Continue;
}

public Action Event_PlayerConnectFull(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int user_id = GetEventInt(event, "userid");

    if(!g_isInLobby)
    {
        SetEntPropFloat(client, Prop_Send, "m_fForceTeam", 0.0);
        for(int i = 0; i < sizeof(g_player_info); i++)
        {
            if(g_player_info[i][0] == user_id)
            {
                CS_SwitchTeam(client, g_player_info[i][1]);
                return Plugin_Continue;
            }
        }
    }
    else
    {
        SetEntPropFloat(client, Prop_Send, "m_fForceTeam", 60.0);
    }
    return Plugin_Continue;
}

public Action Command_JoinTeam(int client, const char[] command, int argc)
{
    if(!g_isInLobby)
        return Plugin_Stop;

    return Plugin_Continue;
}

public void OnMapStart()
{
    char map[MAX_NAME_LENGTH];

    GetCurrentMap(map, sizeof(map));

    if(g_isInLobby)
        GameRules_SetProp("m_nQueuedMatchmakingMode", 0, 1, 0, true);
    else
        GameRules_SetProp("m_nQueuedMatchmakingMode", 1, 1, 0, true);
}

public Action Command_ReadyVote(int client, int args)
{
    PrintToServer("Starting ready vote");
    if(IsVoteInProgress())
        return Plugin_Handled;

    Menu menu = new Menu(Handle_VoteMenu);
    menu.VoteResultCallback = Handle_VoteResults;
    menu.SetTitle("Ready?");
    menu.AddItem("yes", "Yes");
    menu.ExitButton = false;
    menu.DisplayVoteToAll(20);

    return Plugin_Handled;
}

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End)
        /* This is called after VoteEnd */
        delete menu;
}

public void Handle_VoteResults(Menu menu,
                        int num_votes,
                        int num_clients,
                        const int[][] client_info,
                        int num_items,
                        const int[][] item_info)
{
    if(num_votes < num_clients)
    {
        char clientName[MAX_NAME_LENGTH];
        PrintToChatAll("%d players are not ready", GetClientCount() - num_votes);
        PrintCenterTextAll("%d players are not ready", GetClientCount() - num_votes);
        for(int i = 0; i < num_clients; i++)
        {
            if(client_info[i][VOTEINFO_CLIENT_ITEM] == -1)
            {
                GetClientName(client_info[i][VOTEINFO_CLIENT_INDEX], clientName, MAX_NAME_LENGTH);
                PrintToChatAll("%s is not ready", clientName);
            }
        }
        return;
    }
    PrintToChatAll("All players ready");
    PrintCenterTextAll("All players ready");
    StartGame();
}

public Action Command_StartGame(int client, int args)
{
    StartGame();
}

public void StartGame()
{
    PrintToChatAll("Starting map veto...");
    PrintCenterTextAll("Starting map veto...");
    g_isInLobby = false;
    g_cVarGameType.IntValue = 0;
    g_cVarGameMode.IntValue = 1;
    ForceChangeLevel(VETOMAP, "start map vote");
}
