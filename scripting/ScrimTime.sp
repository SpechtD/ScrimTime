#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

ConVar g_cVarGameMode;
ConVar g_cVarGameType;

bool isInLobby = true;

Handle playerTeams;

public Plugin myinfo =
  {
    name = "ScrimTime",
    author = "SauerkrautKebap",
    description = "",
    version = "1.0",
    url = "https://github.com/SauerkrautKebap/ScrimTime"};


public void OnPluginStart()
{
    RegConsoleCmd("readyvote", Command_ReadyVote);
    g_cVarGameMode = FindConVar("game_mode");
    g_cVarGameType = FindConVar("game_type");
    AddCommandListener(Command_JoinTeam, "jointeam");

    playerTeams = CreateArray(2, 0);
}

public void OnMapStart()
{
    switch(isInLobby)
    {
    case true:
    {
        g_cVarGameType.IntValue = 1;
        g_cVarGameMode.IntValue = 2;
    }
    case false:
    {
        GameRules_SetProp("m_nQueuedMatchmakingMode", 1, 1, 0, true);
        g_cVarGameType.IntValue = 0;
        g_cVarGameMode.IntValue = 1;
    }
    }
}

public void OnMapEnd()
{
    /*
    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS];
    int target_count;
    bool tn_is_ml;
    */

    int playerTeam[1][2];

    for(int i = 0; i <= MaxClients; i++)
    {
        playerTeam[0][0] = GetClientSerial(i);
        playerTeam[0][1] = GetClientTeam(i);
        PushArrayArray(playerTeams, playerTeam[0], 2);
    }
}
/*
public void OnClientPutInServer(int client)
{
    if(!isInLobby)
    {
        CS_SwitchTeam(client, CS_TEAM_CT);
    }
}
*/
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
    if(num_votes < GetClientCount())
    {
        PrintToChatAll("%d players are not ready", GetClientCount() - num_votes);
        PrintCenterTextAll("%d players are not ready", GetClientCount() - num_votes);
        return;
    }
    PrintToChatAll("All players ready. Starting game.");
    PrintCenterTextAll("All players ready. Starting game.");
    isInLobby = false;
    ForceChangeLevel("lobby_mapveto", "start map vote");
}

public Action Command_JoinTeam(int client, char[] command, int args)
{
    if(!isInLobby)
    {
        CS_SwitchTeam(client, CS_TEAM_CT);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}
