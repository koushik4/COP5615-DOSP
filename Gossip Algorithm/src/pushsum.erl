-module(pushsum).

-author("srinivaskoushik").

-export([process/2, msg_handler/4]).

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

start_spawns(Pids, Index) ->
    if Index > length(Pids) ->
           started;
       true ->
           Pid = lists:nth(Index, Pids),
           Pid ! {start, 0, Pids, Index, 1},
           start_spawns(Pids, Index + 1)
    end.

process(0, Pids) ->
    % io:fwrite("The Pids are ~p ~n", [Pids]),
    start_spawns(Pids, 1),
    Pid = lists:nth(1, Pids),
    io:fwrite("~p ~n",[get_time_stamp()]),
    Pid ! {pushsum, full_network, 0, 0, 1};
% Pid ! {pushsum, line_network, 0, 0, 1};
% Pid ! {pushsum, grid_network, 0, 0, 1};
% Pid ! {pushsum, threeD_grid_network, 0, 0, 1};
process(N, Pids) ->
    Pid = spawn(pushsum, msg_handler, [-1, [], 1, 1]),
    process(N - 1, lists:append([Pids, [Pid]])).

msg_handler(3, Pids, _, _) ->
    io:fwrite("Converged ~n"),
    io:fwrite("~p ~n",[get_time_stamp()]),
    end_spawns(Pids, 1,self()),
    done;
msg_handler(Count, Pids, Current_S, Current_W) ->
    receive
        {pushsum, full_network, S, W, Index} ->
            New_S = Current_S + S,
            New_W = Current_W + W,
            Previous_Ratio = Current_S / Current_W,
            New_Ratio = New_S / New_W,
            send_full_network(Pids, New_S / 2, New_W / 2, Index),
            % io:fwrite("The difference in ratio is ~p ~n", [abs(Previous_Ratio - New_Ratio)]),
            % io:fwrite("The count is ~p ~n", [Count]),
            if abs(Previous_Ratio - New_Ratio) =< 0.0000000001 ->
                   msg_handler(Count + 1, Pids, New_S / 2, New_W / 2);
               true ->
                   msg_handler(0, Pids, New_S / 2, New_W / 2)
            end;

        {pushsum, line_network, S, W, Index} ->
            New_S = Current_S + S,
            New_W = Current_W + W,
            Previous_Ratio = Current_S / Current_W,
            New_Ratio = New_S / New_W,
            send_line_network(Pids, New_S / 2, New_W / 2, Index),
            io:fwrite("The difference in ratio is ~p ~n", [Previous_Ratio - New_Ratio]),
            % io:fwrite("The count is ~p ~n", [Count]),
            if abs(Previous_Ratio - New_Ratio) =< 0.0000000001 ->
                   msg_handler(Count + 1, Pids, New_S / 2, New_W / 2);
               true ->
                   msg_handler(0, Pids, New_S / 2, New_W / 2)
            end;

        {pushsum, grid_network, S, W, Index} ->
            New_S = Current_S + S,
            New_W = Current_W + W,
            Previous_Ratio = Current_S / Current_W,
            New_Ratio = New_S / New_W,
            send_2d_network(Pids, New_S / 2, New_W / 2, Index),
            io:fwrite("The difference in ratio is ~p ~n", [Previous_Ratio - New_Ratio]),
            % io:fwrite("The count is ~p ~n", [Count]),
            if abs(Previous_Ratio - New_Ratio) =< 0.0000000001 ->
                   msg_handler(Count + 1, Pids, New_S / 2, New_W / 2);
               true ->
                   msg_handler(0, Pids, New_S / 2, New_W / 2)
            end;

        {pushsum, threeD_grid_network, S, W, Index} ->
            New_S = Current_S + S,
            New_W = Current_W + W,
            Previous_Ratio = Current_S / Current_W,
            New_Ratio = New_S / New_W,
            send_3d_network(Pids, New_S / 2, New_W / 2, Index),
            io:fwrite("The difference in ratio is ~p ~n", [Previous_Ratio - New_Ratio]),
            % io:fwrite("The count is ~p ~n", [Count]),
            if abs(Previous_Ratio - New_Ratio) =< 0.0000000001 ->
                   msg_handler(Count + 1, Pids, New_S / 2, New_W / 2);
               true ->
                   msg_handler(0, Pids, New_S / 2, New_W / 2)
            end;

        {start, C, Ids, S, W} ->
            % io:fwrite("The initial S,W are ~p ~p ~n", [S, W]),
            msg_handler(C, Ids, S, W);

        {done}->
            exit("")
    end.

get_2d_index(I, N) ->
    [round(I / N), I rem N].

get_1d_index(I, J, N) ->
    round(I * N + J).

get_random_index_2d(I, J, N) ->
    A = [1, 0, -1],
    Random_Index_1 =
        I
        + lists:nth(
              rand:uniform(3), A),
    Random_Index_2 =
        J
        + lists:nth(
              rand:uniform(3), A),
    if Random_Index_1 == I andalso Random_Index_2 == J ->
           get_random_index_2d(I, J, N);
       Random_Index_1 >= 0
       andalso Random_Index_1 < N
       andalso Random_Index_2 >= 0
       andalso Random_Index_2 < N ->
           [Random_Index_1, Random_Index_2];
       true ->
           get_random_index_2d(I, J, N)
    end.

get_random_index(N, Index) ->
    J = rand:uniform(N),
    if Index /= J ->
           J;
       true ->
           get_random_index(N, Index)
    end.

send_full_network(Pids, S, W, Index) ->
    N = length(Pids),
    Random_Index = get_random_index(N, Index),
    Pid = lists:nth(Random_Index, Pids),
    Pid ! {pushsum, full_network, S, W, Random_Index}.

send_line_network(Pids, S, W, Index) ->
    N = length(Pids),
    if Index == 1 ->
           Random_Index = Index + 1;
       Index == N ->
           Random_Index = Index - 1;
       true ->
           A = [-1, 1],
           Random_Index =
               Index
               + lists:nth(
                     rand:uniform(2), A)
    end,
    Pid = lists:nth(Random_Index, Pids),
    io:fwrite("Sending gossip from ~p to ~p ~n", [self(), Pid]),
    Pid ! {pushsum, line_network, S, W, Random_Index}.

send_2d_network(Pids, S, W, Index) ->
    N = round(math:sqrt(length(Pids))),
    % io:fwrite("~p ~n",[N]),
    Indices = get_2d_index(Index, 4),
    I = lists:nth(1, Indices),
    J = lists:nth(2, Indices),
    Random_Indices = get_random_index_2d(I, J, N),
    Random_Index =
        get_1d_index(lists:nth(1, Random_Indices), lists:nth(2, Random_Indices), N) + 1,
    % io:fwrite("~p ~n",[Random_Indices]),
    Pid = lists:nth(Random_Index, Pids),
    io:fwrite("Sending gossip from ~p to ~p ~n", [self(), Pid]),
    Pid ! {pushsum, grid_network, S, W, Random_Index}.

send_3d_network(Pids, S, W, Index) ->
    N = round(math:sqrt(length(Pids))),
    % io:fwrite("~p ~n",[N]),
    Indices = get_2d_index(Index, 4),
    I = lists:nth(1, Indices),
    J = lists:nth(2, Indices),
    Random_Indices = get_random_index_2d(I, J, N),
    Grid_Random_Index =
        get_1d_index(lists:nth(1, Random_Indices), lists:nth(2, Random_Indices), N) + 1,
    Random_Index = get_random_index(length(Pids), Index),
    Random_Pid = lists:nth(Random_Index, Pids),
    Pid = lists:nth(Grid_Random_Index, Pids),
    % io:fwrite("Sending gossip from ~p to ~p ~n", [self(), Pid]),
    Pid ! {pushsum, threeD_grid_network, S, W, Grid_Random_Index},
    Random_Pid ! {pushsum, threeD_grid_network, S, W, Random_Index}.
