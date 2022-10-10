-module(gossip).
-author("srinivaskoushik").

-export([process/3,msg_handler/2]).

get_time_stamp()->
    {Mega, Sec, Micro} = os:timestamp(),
    (Mega*1000000 + Sec)*1000 + (Micro/1000).
end_spawns(Pids, Index,Cuurent_Pid) ->
    if Index > length(Pids) ->
           started;
       true ->
            Pid = lists:nth(Index, Pids),
            if 
            Pid /= Cuurent_Pid->
                Pid ! {done};
            true->
                ok
    end,
           end_spawns(Pids, Index + 1,Cuurent_Pid)
    end.

start_spawns(Pids,I,N)->
    if
        I > length(Pids)->
            done;
        true->
            Pid = lists:nth(I, Pids),
            Pid ! {start,Pids},
            start_spawns(Pids, I+1, N)
    end.

process(0,Pids,Gossip)->
    start_spawns(Pids, 1, length(Pids)),
    io:fwrite("~p ~n",[get_time_stamp()]),
    % send_full_network(Pids,Gossip,1);
    send_line_network(Pids,Gossip,1);
    % send_2d_network(Pids, Gossip, 1);
    % send_3d_network(Pids, Gossip, 1);

process(N,Pids,Gossip)->
    Pid = spawn(gossip,msg_handler,[0,[]]),
    process(N-1, lists:append([Pids,[Pid]]), Gossip).

msg_handler(10,Pids)->
    io:fwrite("Converged ~n"),
    io:fwrite("~p ~n",[get_time_stamp()]),
    end_spawns(Pids, 1,self()),
    done;
msg_handler(Count,Pids)->
    receive
        {gossip,full_network,Gossip,Index}->
            send_full_network(Pids,Gossip,Index),
            msg_handler(Count+1, Pids);
        
        {gossip,line_network,Gossip,Index}->
            send_line_network(Pids,Gossip,Index),
            msg_handler(Count+1, Pids);

        {gossip,grid_network,Gossip,Index}->
            send_2d_network(Pids,Gossip,Index),
            msg_handler(Count+1, Pids);
        
        {gossip,threeD_grid_network,Gossip,Index}->
            send_3d_network(Pids,Gossip,Index),
            msg_handler(Count+1, Pids);

        {start,Ids}->
            % io:fwrite("Initiating the Actors ~p ~n",[self()]),
            msg_handler(Count,Ids);

        {done}->
            erlang:exit("exiting")
    end.
get_2d_index(I,N)->
    [round(I/N), I rem N].
    
get_1d_index(I,J,N)->
    round(I*N + J).
    
get_random_index_2d(I,J,N)->
    A = [1,0,-1],
    Random_Index_1 = I + lists:nth(rand:uniform(3), A),
    Random_Index_2 = J + lists:nth(rand:uniform(3), A),
    if
        Random_Index_1 == I andalso Random_Index_2 == J->
            get_random_index_2d(I, J, N);
        Random_Index_1 >= 0 andalso Random_Index_1 < N andalso Random_Index_2 >= 0 andalso Random_Index_2 < N ->
            [Random_Index_1,Random_Index_2];
        true->
            get_random_index_2d(I, J, N)
    end.
    
get_random_index(N,Index)->
    J = rand:uniform(N),
    if 
        Index /= J->
            J;
        true->
            get_random_index(N, Index)
    end.
send_full_network(Pids,Gossip,Index)->
    N = length(Pids),
    Random_Index =  get_random_index(N, Index),
    Pid = lists:nth(Random_Index, Pids),
    % io:fwrite("Sending gossip from ~p to ~p ~n",[self(),Pid]),
    Pid ! {gossip,full_network,Gossip,Random_Index},
    ok.

send_line_network(Pids,Gossip,Index)->
    N = length(Pids),
    if 
        Index == 1->
            Random_Index = Index+1;
        Index == N->
            Random_Index = Index - 1;
        true->
            A = [-1,1],
            Random_Index = Index + lists:nth(rand:uniform(2), A)   
    end,
    Pid = lists:nth(Random_Index, Pids),
    % io:fwrite("Sending gossip from ~p to ~p ~n",[self(),Pid]),
    Pid ! {gossip,line_network,Gossip,Random_Index},
    ok.

send_2d_network(Pids,Gossip,Index)->
    N = round(math:sqrt(length(Pids))),
    Indices = get_2d_index(Index, 4),
    I = lists:nth(1, Indices),
    J = lists:nth(2, Indices),
    Random_Indices = get_random_index_2d(I,J,N),
    Random_Index = get_1d_index(lists:nth(1, Random_Indices), lists:nth(2, Random_Indices), N)+1,
    Pid = lists:nth(Random_Index, Pids),
    % io:fwrite("Sending gossip from ~p to ~p ~n",[self(),Pid]),
    Pid ! {gossip,grid_network,Gossip,Random_Index},
    ok.

send_3d_network(Pids,Gossip,Index)->
    N = round(math:sqrt(length(Pids))),
    % io:fwrite("~p ~n",[N]),
    Indices = get_2d_index(Index, 4),
    I = lists:nth(1, Indices),
    J = lists:nth(2, Indices),
    Random_Indices = get_random_index_2d(I,J,N),
    Grid_Random_Index = get_1d_index(lists:nth(1, Random_Indices), lists:nth(2, Random_Indices), N)+1,
    Random_Index = get_random_index(length(Pids), Index),
    Random_Pid = lists:nth(Random_Index, Pids),
    Pid = lists:nth(Grid_Random_Index, Pids),
    % io:fwrite("Sending gossip from ~p to ~p ~n",[self(),Pid]),
    Pid ! {gossip,threeD_grid_network,Gossip,Grid_Random_Index},
    Random_Pid !{gossip,threeD_grid_network,Gossip,Random_Index},
    ok.
