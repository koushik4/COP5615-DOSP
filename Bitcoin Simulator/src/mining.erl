%%%-------------------------------------------------------------------
%%% @author srinivaskoushik
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Sep 2022 2:37 PM
%%%-------------------------------------------------------------------
-module(mining).
-author("srinivaskoushik").
-import(string,[substr/3,equal/2]).
%% API
-export([hash/5,main/5]).

main(Keys,_,_,I,_) when I > length(Keys)->
  done;
main(_,_,_,_,C) when C >= 4->
  done;
main(Keys,Ks,Index,I,C)->
  % io:fwrite("~p ~n",[erlang:system_time()]),
  % io:fwrite("~p ~n",[C]),
  % io:fwrite("~p ~p ~n",[I,Ks]),
  % io:fwrite("~p ~n",[nodes()]),
  if 
    I =< -1->
      ok;

    Index == 0 ->
      Key = lists:nth(I, Keys),
      K = lists:nth(I,Ks),
      spawn(node(),mining,hash,[Key,K,self(),false,Key]),
      main(Keys,Ks,(Index+1) rem (length(nodes())+1),I+1,C);
    true->
      io:fwrite("~p ~p ~n",[Keys,I]),
      Key = lists:nth(I, Keys),
      K = lists:nth(I,Ks),
      io:fwrite("~p ~p ~n",[Key,I]),
      Deligation_Node = lists:nth(Index, nodes()),
      io:fwrite("Deligated Node is ~p ~n",[Deligation_Node]), 
      spawn(Deligation_Node,mining,hash,[Key,K,self(),false,Key]),
      main(Keys,Ks,(Index+1) rem (length(nodes())+1),I+1,C)
  end,

  receive
    {InputKey,Hash}->
      % io:fwrite(" ~p~n",[node]),
      % {ok,File} = file:open("kooushik.txt", [append]),
      % file:write(File, node()),
      % file:close(File),
      io:fwrite("~p \t ~p ~n",[InputKey,Hash])
      % io:fwrite("~p ~n",[erlang:system_time()])
      % if C < 3->
      %   main(Keys,Ks,(Index+1) rem (length(Keys)+1),-1,C+1);
      % true->
      %   ok
      % end
  end.

hash(Key,K,Pid,Status,Hash)->
  % io:fwrite("~p ~n",[node()]),
  % {ok,File} = file:open("Nodes.txt", [append]),
  % file:write(File, node()),
  if Status == true->
    % io:fwrite("Node : ~p ~n",[node()]),
    L = lists:duplicate((64-string:length(Hash)),$0),
    Pid ! {Key,string:concat(L,Hash)},
    done;
  true->
    % {ok,File} = file:open("Hash.txt",[append]),
    % Nl = io_lib:nl(),
    % X = string:concat(";",string:concat(Key,Nl)),
    % file:write(File,[X]),
    % file:close(File),
    Hash_8bit = crypto:hash(sha256,Hash),
    Hash_Int = crypto:bytes_to_integer(Hash_8bit),
    Hash_Final = integer_to_list(Hash_Int, 16),
    % io:fwrite("~p ~n",[Hash_Final]),
    L = string:length(Hash_Final),
    hash(Key,K,Pid,(64-K) == L,Hash_Final)
  end.