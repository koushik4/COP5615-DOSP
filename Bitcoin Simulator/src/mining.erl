-module(mining).
-author("srinivaskoushik").
-import(string,[substr/3,equal/2]).
-export([start/1,hash/5,main/3,run/1,msg_handler/1,stop_program/0,stop_all_nodes/1]).

%% 
% Generates a random string of length 'Length' appending UFID at the beginning
% @parm Length - Length of the random string
% @parm ALlowed - [a-z A-Z 0-9]
%%
get_random_string(Length,Allowed) ->
  L = lists:foldl(fun(_, Acc) ->
    [lists:nth(rand:uniform(length(Allowed)),Allowed)]++ Acc
                end, 
                [], 
                lists:seq(1, Length)),
  "kondubhatlas;" ++ L.


% Stops the current program  
stop_program()->
      exit("Coin Mined").

%% 
% Stop the programs of all connected that are running 
% Invoked right after getting 1 hash.
%%
stop_all_nodes([])->
  stopped;
stop_all_nodes(Nodes)->
  [H|T] = Nodes,
  spawn(H,mining,stop_program,[]),
  stop_all_nodes(T).

%% 
% Handles messages that will Print the key and the desired Hash
%%
msg_handler(1)->
  done;
msg_handler(C)->
  receive
    {Key,Hash}->
      io:fwrite("~p \t ~p ~n",[Key,Hash]),
      msg_handler(C+1),
      stop_all_nodes(nodes()),
    io:fwrite("~p ~n",[erlang:system_time()])
  end.
start([])->
  ok;
start(K)->
  io:fwrite("~p ~n",[erlang:system_time()]),
  [H|T] = K,
  run(H),
  start(T).

run(K)->
  Pid = spawn(node(),mining,msg_handler,[0]),
  main(K,0,Pid).

main(K,Index,Pid)->
  L = nodes(),
  if Index > length(L)->
    done;

  true->
    Allowed = "abcdefghiklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",  
    S = get_random_string(rand:uniform(10),Allowed),
    if Index == 0 ->
      spawn(node(),mining,hash,[S,K,Pid,false,S]);
    true ->
      spawn(lists:nth(Index,nodes()),mining,hash,[S,K,Pid,false,S])
    end,
    main(K,Index+1,Pid)
  end.
hash(Key,K,Pid,Status,Hash)->
  Allowed = "abcdefghiklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
  % io:fwrite("~p ~p ~n",[nodes(),node()]),
  if Status == true->
    L = lists:duplicate((64-string:length(Hash)),$0),
    Pid ! {Key,string:concat(L,Hash)},
    done;
  true->
    Hash_8bit = crypto:hash(sha256,Key),
    Hash_Int = crypto:bytes_to_integer(Hash_8bit),
    Hash_Final = integer_to_list(Hash_Int, 16),
    L = string:length(Hash_Final),
    if 64 - K == L->
      hash(Key,K,Pid,true,Hash_Final);
    true->
      New_Key = get_random_string(rand:uniform(10), Allowed),
      hash(New_Key,K,Pid,false,Hash_Final)
    end

  end.