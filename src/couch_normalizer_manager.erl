-module(couch_normalizer_manager).
-behaviour(gen_server).

-include("couch_db.hrl").

-export([start_link/1, init/1, registry/0, next_scenario/1]).

-export([start_process/1]).


start_link([{scenario_path, Ph}, {num_workers, NumWorkers}]) ->
  % 1. setup registry
  application:start(elixir),
  application:set_env(?MODULE, registry, ets:new(s, [ordered_set, {keypos,1}])),

  % 2. compile and load scenarios
  'Elixir-CouchNormalizer-Registry':load_all(Ph),

  % 3. spawn server
  {ok, _} = gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


init(_args) ->
  % 1. init workers pool
  {ok, []}.


registry() ->
  application:get_env(?MODULE, registry).


next_scenario(Normpos) ->
  {ok, Pid} = registry(),
  case ets:next(Pid, Normpos) of
    '$end_of_table' -> nil;
    Key -> [H|T] = ets:lookup(Pid, Key), H
  end.


start_process(DbName) ->
  start_link([{scenario_path, "/Volumes/branch320/opt/AZatvornitskiy/couch_normalizer/src"}, {num_workers, x}]),
  try_enum_docs(DbName).


try_enum_docs(DbName) ->
  {ok, Db} = couch_db:open_int(DbName, []),

  Fun = fun(FullDocInfo, _, Acc) ->

    {ok, Doc} = couch_db:open_doc(Db, FullDocInfo),

    {Body} = couch_doc:to_json_obj(Doc, []),
    Id = couch_util:get_value(<<"_id">>, Body),
    Rev = couch_util:get_value(<<"_rev">>, Body),
    Normpos = couch_util:get_value(<<"normpos">>, Body, <<"0">>),


    % Check normpos parameter
    {_, _, Scenario} = next_scenario(Normpos),
    case Scenario(DbName, Id, Rev, Body) of
      {update, NewBody} ->
          io:fwrite("updated document '~s': ~n", [Id]),
          % update execution status
          % update doc
          couch_db:update_doc(Db, couch_doc:from_json_obj({NewBody}), []);
      _ ->
          % proceed
          io:fwrite("skipped document '~s'~n", [Id])
    end,

    {ok, Acc}
  end,

  {ok, _, _} = couch_db:enum_docs(Db, Fun, [], []),

  ok = couch_db:close(Db).