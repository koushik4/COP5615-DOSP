-module(chord).

-author("srinivaskoushik").

-export([main/1, msg_handler/4]).

get_sucessor_for_n(Nodes, Index, N) ->
    if Index == length(Nodes) + 1 ->
           1;
       true ->
           I = lists:nth(Index, Nodes),
           if I >= N ->
                  Index;
              true ->
                  get_sucessor_for_n(Nodes, Index + 1, N)
           end
    end.

get_finger_table(Nodes, Max_Value, Start, Finger_Table, Power) ->
    P = round(math:pow(2, Power)),
    Index = get_sucessor_for_n(Nodes, 1, Start + P),
    B = lists:any(fun(E) -> E == Index end, Finger_Table),
    N = lists:nth(Index, Nodes),
    N_Length = math:log(length(Nodes)),
    if length(Finger_Table) == N_Length ->
           Finger_Table;
       Index == 1 ->
           Finger_Table;
       N > Max_Value ->
           Finger_Table;
       B ->
           get_finger_table(Nodes, Max_Value, Start, Finger_Table, Power + 1);
       true ->
           New_Finger_Table = lists:append(Finger_Table, [Index]),
           get_finger_table(Nodes, Max_Value, Start, New_Finger_Table, Power + 1)
    end.

get_sha1_hash(Key) ->
    Hash_8bit = crypto:hash(sha, Key),
    crypto:bytes_to_integer(Hash_8bit) rem round(math:pow(2,20)).

add_node(Nodes, Pids) ->
    Pid = spawn(chord, msg_handler, [Nodes, Pids, 1, []]),
    New_Pids = lists:append(Pids, [Pid]),
    Pid_Str = pid_to_list(Pid),
    Hashed_Pid = get_sha1_hash(Pid_Str),
    New_Nodes = lists:append(Nodes, [Hashed_Pid]),
    Fun = fun(A, B) -> get_sha1_hash(pid_to_list(A)) < get_sha1_hash(pid_to_list(B)) end,
    Sorted_Pids = lists:sort(Fun, New_Pids),
    Sorted_Nodes = lists:sort(New_Nodes),
    start_process(Sorted_Nodes, Sorted_Pids, 1),
    [Sorted_Nodes, Sorted_Pids].

get_n_nodes(Nodes, 0, Pids) ->
    [Nodes, Pids];
get_n_nodes(Nodes, N, Pids) ->
    [New_Nodes, New_Pids] = add_node(Nodes, Pids),
    get_n_nodes(New_Nodes, N - 1, New_Pids).

lookup(Nodes, Finger_Table, Node, Index) ->
    if Index > length(Finger_Table) ->
           length(Finger_Table);
       true ->
           N = lists:nth(
                   lists:nth(Index, Finger_Table), Nodes),
           if N == Node ->
                  -1;
              N > Node ->
                  Index;
              true ->
                  lookup(Nodes, Finger_Table, Node, Index + 1)
           end
    end.

msg_handler(Nodes, Pids, Index, Finger_Table) ->
    receive
        {lookup, Node, C} ->
            X = lookup(Nodes, Finger_Table, Node, 1),

            if X == -1 orelse X == 0 orelse Index == length(Nodes) ->
                   io:fwrite("Hopping Count : ~p ~n", [C]);
               true ->
                   I = lists:nth(X - 1, Finger_Table),
                   if I == Index ->
                          lists:nth(I - 1, Pids) ! {lookup, Node, C + 1};
                      true ->
                          lists:nth(I, Pids) ! {lookup, Node, C + 1}
                   end
            end,
            msg_handler(Nodes, Pids, Index, Finger_Table);
        {start, N, P, I} ->
            F = lists:append([Index], get_finger_table(N, lists:max(N), lists:nth(I, N), [], 0)),
            msg_handler(N, P, I, F)
    end.

start_process(Nodes, Pids, Index) ->
    if Index > length(Pids) ->
           done;
       true ->
           lists:nth(Index, Pids) ! {start, Nodes, Pids, Index},
           start_process(Nodes, Pids, Index + 1)
    end.

find(Nodes, Pids, Node) ->
    % S = get_sucessor_for_n(Nodes, 1, Node),
    S = lists:nth(get_sucessor_for_n(Nodes, 1, get_sha1_hash(Node)), Nodes),
    lists:nth(1, Pids) ! {lookup, S, 0},
    ok.

main(N) ->
    [Nodes, Pids] = get_n_nodes([], N, []),

    find(Nodes, Pids, "<1.123213.12>"),
    find(Nodes, Pids, "<1.4425.3242342>"),
    find(Nodes, Pids, "<3243242.4425.12>"),
    find(Nodes, Pids, "<1133.432432.32434234>"),
    find(Nodes, Pids, "<10023.4425.12>"),
    find(Nodes, Pids, "<1232.123213.12>"),
    find(Nodes, Pids, "<1654.4425.3242342>"),
    find(Nodes, Pids, "<654242.25.12654>"),
    find(Nodes,Pids,"<13453.432445.6234>").