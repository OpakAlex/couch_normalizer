-module(couch_normalizer_utils).
%
%  Utilities for reading/updating documents from Couch DB
%

-export([document_object/2, document_body/2, next_scenario/2, update_doc/2]).


document_object(DbName, DocInfoOrId) ->
  {ok, Db} = couch_db:open_int(DbName, []),

  case couch_db:open_doc(Db, DocInfoOrId) of
    {ok, Doc} ->
      {Body}  = couch_doc:to_json_obj(Doc, []),

      Id      = couch_util:get_value(<<"_id">>, Body),
      Rev     = couch_util:get_value(<<"_rev">>, Body),
      Normpos = couch_util:get_value(<<"normpos_">>, Body, <<"0">>),

      {Body, Id, Rev, Normpos};
    _ -> not_found
  end.

document_body(DbName, DocInfoOrId) ->
  case document_object(DbName, DocInfoOrId) of
    {Body, _, _, _} -> Body;
    _ -> not_found
  end.


update_doc(_DbName, not_found) ->
  not_found;

update_doc(DbName, Body) ->
  {ok, Db} = couch_db:open_int(DbName, []),
  couch_db:update_doc(Db, couch_doc:from_json_obj({Body}),[]).


next_scenario(Ets, Normpos) when is_list(Normpos) ->
  next_scenario(Ets, list_to_binary(Normpos));

next_scenario(Ets, Normpos) ->
  case ets:next(Ets, Normpos) of
    '$end_of_table' ->
      nil;
    Key -> [H|_] =
      ets:lookup(Ets, Key), H
  end.