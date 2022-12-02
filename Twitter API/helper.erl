-module(helper).

-author("srinivaskoushik").

-export([helper_hashtags_from_tweets/4, helper_mentions_from_tweets/5,
         helper_send_tweet_to_subscriptions/4,helper_get_usernames/3,get_timestamp/0]).

helper_send_tweet_to_subscriptions(Subscriptions, Index, Tweet, Server_Id) ->
    if Index > length(Subscriptions) ->
           ok;
       true ->
           Server_Id ! {add_tweet_to_feed, lists:nth(Index, Subscriptions), Tweet},
           helper_send_tweet_to_subscriptions(Subscriptions,Index+1,Tweet,Server_Id)
    end.

helper_hashtags_from_tweets(Splited_Tweet, Index, Server_Id, Tweet) ->
    if Index > length(Splited_Tweet) ->
           ok;
       true ->
           S = lists:nth(Index, Splited_Tweet),
           B = string:equal("#", string:sub_string(S, 1, 1)),
           if B ->
                  Server_Id ! {update_hashtag_mapping, S, Tweet},
                  helper_hashtags_from_tweets(Splited_Tweet, Index + 1, Server_Id, Tweet);
              true ->
                  helper_hashtags_from_tweets(Splited_Tweet, Index + 1, Server_Id, Tweet)
           end
    end.

helper_get_usernames(0,L,_)->
    L;
helper_get_usernames(N,L,Id)->
    Allowed = "abcdefghijklmnopqrstuvwxyz",
    S = get_random_string(4, Allowed),
    B = lists:any(fun(E)->E==S end,L),
    if B->
        helper_get_usernames(N, L,Id);
        true->
            client:register(S,S,S,Id),
            helper_get_usernames(N-1, lists:append([S],L),Id)
    end.

helper_mentions_from_tweets(Splited_Tweet, Index, Server_Id, L, Tweet) ->
    if Index > length(Splited_Tweet) ->
           L;
       true ->
           S = lists:nth(Index, Splited_Tweet),
           B = string:equal("@", string:sub_string(S, 1, 1)),
           if B ->
                  Server_Id ! {update_mention_mapping, S, Tweet},
                  L1 = lists:append(L, [string:sub_string(S, 2)]),
                  helper_mentions_from_tweets(Splited_Tweet, Index + 1, Server_Id, L1, Tweet);
              true ->
                  helper_mentions_from_tweets(Splited_Tweet, Index + 1, Server_Id, L, Tweet)
           end
    end.

get_random_string(Length, Allowed) ->
    L = lists:foldl(fun(_, Acc) ->
                       [lists:nth(
                            rand:uniform(length(Allowed)), Allowed)]
                       ++ Acc
                    end,
                    [],
                    lists:seq(1, Length)),
    L.
get_timestamp() ->
  {Mega, Sec, Micro} = os:timestamp(),
  (Mega*1000000 + Sec)*1000 + (Micro/1000).
