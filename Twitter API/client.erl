-module(client).

-author("srinivaskoushik").

-export([tweet/3, register/4, retweet/3, subscribe/3, search_by_hashtag/3,
         search_by_mention/3, msg_handler/1]).

tweet(Username, Tweet, Server_Id) ->
    Server_Id ! {tweet, Username, Tweet}.

retweet(Username, Tweet, Server_Id) ->
    Server_Id ! {retweet, Username, Tweet}.

register(Username, Password, Email, Server_Id) ->
    Pid = spawn(client, msg_handler, [#{}]),

    Profile = #{"server" => Server_Id},
    Profile_Username = maps:put("username", Username, Profile),
    Profile_Password = maps:put("password", Password, Profile_Username),
    Profile_Email = maps:put("email", Email, Profile_Password),
    Profile_Tweet_List = maps:put("tweets", [], Profile_Email),
    Profile_Subscription = maps:put("subscriptions", [], Profile_Tweet_List),
    Profile_Feed = maps:put("feed", [], Profile_Subscription),
    Profile_Id = maps:put("id", Pid, Profile_Feed),

    Pid ! {start, Profile_Id},
    Server_Id ! {add_profile, Username, Profile_Id}.

subscribe(Username1, Username2, Server_Id) ->
    Server_Id ! {subscribe, Username1, Username2}.

search_by_hashtag(Username, Hashtag, Server_Id) ->
    Server_Id ! {search_by_hashtag, Username, Hashtag}.

search_by_mention(Username, Hashtag, Server_Id) ->
    Server_Id ! {search_by_mention, Username, Hashtag}.

msg_handler(My_Profile) ->
    {ok, Fd} = file:open("output.txt", [append]),
    Size = maps:size(My_Profile),
    if Size > 0 ->
           maps:get("server", My_Profile)
           ! {add_profile, maps:get("username", My_Profile), My_Profile};
       true ->
           ok
    end,
    receive
        {subscribe, Friend_Profile} ->
            Profile_Subscription = maps:get("subscriptions", My_Profile),
            New_Profile_Subscription = lists:append([Friend_Profile], Profile_Subscription),
            Updated_Profile = maps:put("subscriptions", New_Profile_Subscription, My_Profile),
            io:fwrite(Fd,"~p:Subscribed to ~p ~n",[maps:get("username", My_Profile),Friend_Profile]),
            msg_handler(Updated_Profile);
        {feed, Tweet} ->
            Feed = maps:get("feed", My_Profile),
            New_Tweets = lists:append(Feed, [Tweet]),
            Updated_Profile = maps:put("feed", New_Tweets, My_Profile),
            % io:fwrite(Fd,"~p ",[helper:get_timestamp()]),
            io:fwrite(Fd,"~p:Adding to Feed ~n",[maps:get("username", My_Profile)]),
            % io:fwrite(Fd,"~p ~n",[helper:get_timestamp()]),
            msg_handler(Updated_Profile);
        {search_by_hashtag, Hashtag, Tweets} ->
            io:fwrite(Fd,"~p:Search results for hashtag ~p are ~p ~n", [maps:get("username", My_Profile),Hashtag, Tweets]),
            msg_handler(My_Profile);
        {search_by_mention, Mention, Tweets} ->
            io:fwrite(Fd,"~p:Search results for mentions ~p are ~p ~n", [maps:get("username", My_Profile),Mention, Tweets]),
            msg_handler(My_Profile);
        {tweet, Tweet} ->
            Splited_Tweet = string:split(Tweet, " ", all),
            helper:helper_hashtags_from_tweets(Splited_Tweet,
                                               1,
                                               maps:get("server", My_Profile),
                                               Tweet),
            Mentions =
                helper:helper_mentions_from_tweets(Splited_Tweet,
                                                    1,
                                                    maps:get("server", My_Profile),
                                                    [],
                                                    Tweet),
            % maps:get("ser  ver", My_Profile) ! {update_hashtag,}
            Tweets = maps:get("tweets", My_Profile),
            New_Tweets = lists:append(Tweets, [Tweet]),
            Updated_Profile = maps:put("tweets", New_Tweets, My_Profile),
            % send this feed to all users who are subscribed to this
            L = lists:append(Mentions, maps:get("subscriptions", My_Profile)),
            helper:helper_send_tweet_to_subscriptions(L, 1, Tweet, maps:get("server", My_Profile)),
            io:fwrite(Fd,"~p:Tweet Added ~n",[maps:get("username", My_Profile)]),
            % io:fwrite(Fd,"~p ~n ~n",[helper:get_timestamp()]),
            msg_handler(Updated_Profile);
        {start, Profile} ->
            msg_handler(Profile)
    end.
