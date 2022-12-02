-module(twitter).

-author("srinivaskoushik").

-export([server/3, get_server/0]).

get_server() ->
    spawn(twitter, server, [#{}, #{}, #{}]).

server(Username_Profile_Mapping, Hashtag_Mapping, Mentions_Mapping) ->
    {ok, Fd} = file:open("output.txt", [append]),
    receive
        {update, Username, Profile} ->
            server(maps:put(Username, Profile, Username_Profile_Mapping),
                   Hashtag_Mapping,
                   Mentions_Mapping);
        {update_mention_mapping, S, Tweet} ->
            B = maps:is_key(S, Mentions_Mapping),
            if B ->
                   L = maps:get(S, Mentions_Mapping),
                   M = maps:put(S, lists:append(L, [Tweet]), Mentions_Mapping),
                   server(Username_Profile_Mapping, Hashtag_Mapping, M);
               true ->
                   M = maps:put(S, [Tweet], Mentions_Mapping),
                   server(Username_Profile_Mapping, Hashtag_Mapping, M)
            end;
        {update_hashtag_mapping, S, Tweet} ->
            B = maps:is_key(S, Hashtag_Mapping),
            if B ->
                   L = maps:get(S, Hashtag_Mapping),
                   M = maps:put(S, lists:append(L, [Tweet]), Hashtag_Mapping),
                   server(Username_Profile_Mapping, M, Mentions_Mapping);
               true ->
                   M = maps:put(S, [Tweet], Hashtag_Mapping),
                   server(Username_Profile_Mapping, M, Mentions_Mapping)
            end;
        {add_profile, Username, Profile} ->
            Map = maps:put(Username, Profile, Username_Profile_Mapping),
            server(Map, Hashtag_Mapping, Mentions_Mapping);
        {subscribe, Username1, Username2} ->
            % Profile_1 = maps:get(Username1, Username_Profile_Mapping),
            Profile_2 = maps:get(Username2, Username_Profile_Mapping),
            % Pid1 = maps:get("id", Profile_1),
            Pid2 = maps:get("id", Profile_2),
            % Pid1 ! {subscribe, Username2},
            Pid2 ! {subscribe, Username1},
            server(Username_Profile_Mapping, Hashtag_Mapping, Mentions_Mapping);
        {search_by_hashtag, Username, Hashtag} ->
            Profile = maps:get(Username, Username_Profile_Mapping),
            Pid = maps:get("id", Profile),
            B = maps:is_key(Hashtag, Hashtag_Mapping),
            if B ->
                   Pid ! {search_by_hashtag, Hashtag, maps:get(Hashtag, Hashtag_Mapping)};
               true ->
                %    file:write(Fd, "Hashtag not found ~n"),
                   io:fwrite(Fd,"Hashtag not found ~n"),
                   Pid ! {search_by_hashtag, Hashtag, []}
            end,
            server(Username_Profile_Mapping, Hashtag_Mapping, Mentions_Mapping);
        {search_by_mention, Username, Mention} ->
            Profile = maps:get(Username, Username_Profile_Mapping),
            Pid = maps:get("id", Profile),
            B = maps:is_key(Mention, Mentions_Mapping),
            if B ->
                   Pid ! {search_by_mention, Mention, maps:get(Mention, Mentions_Mapping)};
               true ->
                %    file:write(Fd, "User not found ~n"),
                   io:fwrite(Fd,"User not found ~n"),
                   Pid ! {search_by_mention, Mention, []}
            end,
            server(Username_Profile_Mapping, Hashtag_Mapping, Mentions_Mapping);
        {add_tweet_to_feed, Username, Tweet} ->
            B = lists:any(fun(E) -> E == Username end, maps:keys(Username_Profile_Mapping)),
            if B ->
                   Profile = maps:get(Username, Username_Profile_Mapping),
                   Pid = maps:get("id", Profile),
                   Pid ! {feed, Tweet},
                   server(Username_Profile_Mapping, Hashtag_Mapping, Mentions_Mapping);
               true ->
                   server(Username_Profile_Mapping, Hashtag_Mapping, Mentions_Mapping)
            end;
        {retweet, Username, Tweet} ->
            Profile = maps:get(Username, Username_Profile_Mapping),
            Pid = maps:get("id", Profile),
            Predicate = fun(E) -> E == Tweet end,
            A = lists:any(Predicate, maps:get("feed", Profile)),
            if A == true ->
                   Pid ! {tweet, Tweet};
               true ->
                %    file:write(Fd, "Tweet not found ~n"),
                   io:fwrite(Fd,"Tweet not found ~n"),
                   ok
            end,
            server(Username_Profile_Mapping, Hashtag_Mapping, Mentions_Mapping);
        {tweet, Username, Tweet} ->
            Profile = maps:get(Username, Username_Profile_Mapping),
            Pid = maps:get("id", Profile),
            Pid ! {tweet, Tweet},
            server(Username_Profile_Mapping, Hashtag_Mapping, Mentions_Mapping)
    end.
