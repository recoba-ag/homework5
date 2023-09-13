%%%-------------------------------------------------------------------
%%% @author recoba_ag
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. вер 2023 16:39
%%%-------------------------------------------------------------------
-module(my_cache).
-author("recoba_ag").

%% API
-export([create/1, insert/3, insert/4, lookup/2, delete_obsolete/1]).

-record(rec, {
    key :: any(),
    value :: any(),
    ttl :: integer()
}).

create(TableName) ->
  ets:new(TableName, [named_table, set, {keypos, #rec.key}]).

insert(TableName, Key, Value) ->
  ets:insert(TableName, #rec{key = Key, value = Value}).

insert(TableName, Key, Value, TTL) ->
  Timestamp = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
  ets:insert(TableName, #rec{key = Key, value = Value, ttl = Timestamp + TTL}).

lookup(TableName, Key) ->
  Timestamp = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
  case ets:lookup(TableName, Key) of
    [#rec{ttl = TTL, value = Value}] when Timestamp < TTL ->
      Value;
    _ ->
      undefined
  end.

delete_obsolete(TableName) ->
  Timestamp = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
  First = ets:first(TableName),
  clean_old_value(First, TableName, Timestamp).

clean_old_value('$end_of_table', _TableName, _Timestamp) ->
  ok;
clean_old_value(First, TableName, Timestamp) ->
  case ets:lookup(TableName, First) of
    [#rec{ttl = TTL}] when Timestamp < TTL ->
      ok;
    _ ->
      ets:delete(TableName, First)
  end,
  Next = ets:next(TableName, First),
  clean_old_value(Next, TableName, Timestamp).