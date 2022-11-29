-module(twitter).
-author("srinivaskoushik").

-export([register/4,subscribe/3,msg_handler/1,server/3,tweet/3,retweet/3,get_server/0,search_by_hashtag/3,search_by_mention/3]).

get_server()->
    spawn(twitter,server,[#{},#{},#{}]).
helper_send_tweet_to_subscriptions(Subscriptions, Index, Tweet, Server_Id)->
    if Index > length(Subscriptions)->
        ok;
    true->
        Server_Id ! {add_tweet_to_feed, lists:nth(Index, Subscriptions), Tweet}
    end.

helper_hashtags_from_tweets(Splited_Tweet, Index, Server_Id,Tweet)->
    if Index > length(Splited_Tweet)->
        ok;
   true->
       S = lists:nth(Index, Splited_Tweet),
       B = string:equal("#",string:sub_string(S,1, 1)),
       if 
           B->
               Server_Id ! {update_hashtag_mapping,S,Tweet},
                helper_hashtags_from_tweets(Splited_Tweet,Index+1, Server_Id,Tweet);
            true->
                helper_hashtags_from_tweets(Splited_Tweet,Index+1, Server_Id,Tweet)
        end
    end.

helper_mentions_from_tweets(Splited_Tweet, Index, Server_Id,L,Tweet)->
    if Index > length(Splited_Tweet)->
        L;
   true->
       S = lists:nth(Index, Splited_Tweet),
       B = string:equal("@",string:sub_string(S,1, 1)),
       io:fwrite("Mentions are ~p and ~p ~n",[S,B]),
       if 
           B->
               Server_Id ! {update_mention_mapping,S,Tweet},
               L1 = lists:append(L,[string:sub_string(S, 2)]),
                helper_mentions_from_tweets(Splited_Tweet,Index+1, Server_Id,L1,Tweet);
            true->
                helper_mentions_from_tweets(Splited_Tweet,Index+1, Server_Id,L,Tweet)
        end
    end.

server(Username_Profile_Mapping,Hashtag_Mapping,Mentions_Mapping)->
    receive
        {update,Username,Profile}->
            server(maps:put(Username,Profile,Username_Profile_Mapping),Hashtag_Mapping,Mentions_Mapping);
        {update_mention_mapping,S,Tweet}->
            B = maps:is_key(S, Mentions_Mapping),
            if 
                B->
                    L=  maps:get(S,Mentions_Mapping),
                    M = maps:put(S, lists:append(L,[Tweet]), Mentions_Mapping),
                    server(Username_Profile_Mapping,M,Mentions_Mapping);
                true->
                    M = maps:put(S, [Tweet], Hashtag_Mapping),
                    io:fwrite("~p ~n",[M]),
                    server(Username_Profile_Mapping,Hashtag_Mapping,M)
            end;

        {update_hashtag_mapping,S,Tweet}->
            B = maps:is_key(S, Hashtag_Mapping),
            if 
                B->
                    L=  maps:get(S,Hashtag_Mapping),
                    M = maps:put(S, lists:append(L,[Tweet]), Hashtag_Mapping),
                    io:fwrite("hashhhhhhhhhh ~p ~n ~n",[M]),
                    server(Username_Profile_Mapping,M,Mentions_Mapping);
                true->
                    M = maps:put(S, [Tweet], Hashtag_Mapping),
                    io:fwrite("hashhhhhhhhhh ~p ~n ~n",[M]),
                    server(Username_Profile_Mapping,M,Mentions_Mapping)
            end;
            
        {add_profile,Username, Profile}->
            Map = maps:put(Username, Profile, Username_Profile_Mapping),
            io:fwrite("Username: ~p and Profile: ~p ~n",[Username,Map]),
            server(Map,Hashtag_Mapping,Mentions_Mapping);

        {subscribe, Username1, Username2}->
            Profile_1 = maps:get(Username1,Username_Profile_Mapping),
            Profile_2 = maps:get(Username2,Username_Profile_Mapping),
            Pid1 = maps:get("id",Profile_1),
            Pid2 = maps:get("id",Profile_2),
            Pid1 ! {subscribe, Username2},
            Pid2 ! {subscribe, Username1},
            server(Username_Profile_Mapping,Hashtag_Mapping,Mentions_Mapping);
        
        {search_by_hashtag, Username,Hashtag}->
            Profile = maps:get(Username,Username_Profile_Mapping),
            Pid = maps:get("id",Profile),
            B = maps:is_key(Hashtag, Hashtag_Mapping),
            if 
                B->
                    Pid ! {search_by_hashtag,Hashtag,maps:get(Hashtag,Hashtag_Mapping)};
                true->
                    Pid ! {search_by_hashtag,Hashtag,[]}
            end,
            server(Username_Profile_Mapping,Hashtag_Mapping,Mentions_Mapping);

        {search_by_mention, Username,Mention}->
            Profile = maps:get(Username,Username_Profile_Mapping),
            Pid = maps:get("id",Profile),
            B = maps:is_key(Mention, Mentions_Mapping),
            if 
                B->
                    Pid ! {search_by_mention,Mention,maps:get(Mention,Mentions_Mapping)};
                true->
                    Pid ! {search_by_mention,Mention,[]}
            end,
            server(Username_Profile_Mapping,Hashtag_Mapping,Mentions_Mapping);

        {add_tweet_to_feed,Username,Tweet}->
            B = lists:any(fun(E)->E == Username end, maps:keys(Username_Profile_Mapping)),
            if 
                B->
                    Profile = maps:get(Username, Username_Profile_Mapping),
                    Pid = maps:get("id", Profile),
                    Pid ! {feed, Tweet},
                    server(Username_Profile_Mapping,Hashtag_Mapping,Mentions_Mapping);
                true->
                    server(Username_Profile_Mapping,Hashtag_Mapping,Mentions_Mapping)
            end;
        
        {retweet, Username, Tweet}->
            Profile = maps:get(Username, Username_Profile_Mapping),
            Pid = maps:get("id", Profile),
            Predicate = fun(E) -> E == Tweet end,
            A = lists:any(Predicate, maps:get("feed",Profile)),
            if A == true->
                Pid ! {tweet, Tweet};
                true->
                    ok
        end,
            server(Username_Profile_Mapping,Hashtag_Mapping,Mentions_Mapping);

        {tweet, Username, Tweet}->
            Profile = maps:get(Username, Username_Profile_Mapping),
            Pid = maps:get("id", Profile),
            Pid ! {tweet, Tweet},
            server(Username_Profile_Mapping,Hashtag_Mapping,Mentions_Mapping)
    end.

tweet(Username, Tweet, Server_Id)->
    Server_Id ! {tweet, Username, Tweet}.

retweet(Username, Tweet, Server_Id)->
    Server_Id ! {retweet, Username, Tweet}.
register(Username, Password, Email, Server_Id)->
    Pid = spawn(twitter,msg_handler,[#{}]),

    Profile = #{"server"=>Server_Id},
    Profile_Username = maps:put("username",Username,Profile),
    Profile_Password = maps:put("password",Password,Profile_Username),
    Profile_Email = maps:put("email",Email,Profile_Password),
    Profile_Tweet_List = maps:put("tweets",[],Profile_Email),
    Profile_Subscription = maps:put("subscriptions",[],Profile_Tweet_List),
    Profile_Feed = maps:put("feed",[],Profile_Subscription),
    Profile_Id = maps:put("id", Pid, Profile_Feed),
    
    Pid ! {start,Profile_Id},
    Server_Id ! {add_profile,Username, Profile_Id}.

subscribe(Username1, Username2,Server_Id)->
    Server_Id ! {subscribe, Username1, Username2}.

search_by_hashtag(Username,Hashtag, Server_Id)->
    Server_Id ! {search_by_hashtag, Username,Hashtag}.

search_by_mention(Username,Hashtag, Server_Id)->
    Server_Id ! {search_by_mention, Username,Hashtag}.

msg_handler(My_Profile)->
    Size = maps:size(My_Profile),
    if Size > 0->
        maps:get("server",My_Profile) !  {add_profile,maps:get("username",My_Profile), My_Profile};
        true->
            ok
    end,
    receive
        {subscribe,Friend_Profile}->
            Profile_Subscription = maps:get("subscriptions",My_Profile),
            New_Profile_Subscription = lists:append([Friend_Profile],Profile_Subscription),
            Updated_Profile = maps:put("subscriptions",New_Profile_Subscription,My_Profile),            
            msg_handler(Updated_Profile);

        {feed, Tweet}->
            Feed = maps:get("feed", My_Profile),
            New_Tweets = lists:append(Feed,[Tweet]),
            Updated_Profile = maps:put("feed",New_Tweets,My_Profile),
            msg_handler(Updated_Profile);

        {search_by_hashtag,Hashtag,Tweets}->
            io:fwrite("Search results for hashtag ~p are ~p ~n",[Hashtag,Tweets]),
            msg_handler(My_Profile);

        {search_by_mention,Mention,Tweets}->
            io:fwrite("Search results for mentions ~p are ~p ~n",[Mention,Tweets]),
            msg_handler(My_Profile);
        
        {tweet, Tweet}->
            % TODO:get #s and @s from tweet
            Splited_Tweet = string:split(Tweet, " ",all),
            io:fwrite("Split is ~p ~n",[Splited_Tweet]),
            helper_hashtags_from_tweets(Splited_Tweet, 1, maps:get("server", My_Profile),Tweet),
            Mentions  = helper_mentions_from_tweets(Splited_Tweet, 1, maps:get("server", My_Profile), [],Tweet),
            % maps:get("server", My_Profile) ! {update_hashtag,}
            Tweets = maps:get("tweets", My_Profile),
            New_Tweets = lists:append(Tweets,[Tweet]),
            Updated_Profile = maps:put("tweets",New_Tweets,My_Profile),
            % send this feed to all users who are subscribed to this
            L = lists:append(Mentions,maps:get("subscriptions", My_Profile)),
            helper_send_tweet_to_subscriptions(L, 1, Tweet, maps:get("server", My_Profile)),
            msg_handler(Updated_Profile);

        {start,Profile}->
            msg_handler(Profile)
    end.