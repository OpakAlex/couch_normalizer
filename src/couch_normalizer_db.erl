-module(couch_normalizer_db).
%
%  Utilities for reading/updating documents using a CouchDB functions
%
-include("couch_db.hrl").
-export([document_object/2, document_body/2, update_doc/2, touch_db/2]).


document_object(DbName, DocInfoOrId) when is_binary(DbName) ->
  touch_db(DbName, fun(Db) -> document_object(Db, DocInfoOrId) end);

document_object(Db, DocInfoOrId) when is_record(Db, db) ->
  case couch_db:open_doc(Db, DocInfoOrId) of
    {ok, Doc} ->
      {Body}        = couch_doc:to_json_obj(Doc, []),
      Id            = couch_util:get_value(<<"_id">>, Body),
      Rev           = couch_util:get_value(<<"_rev">>, Body),
      {RevHistory}  = couch_util:get_value(<<"rev_history_">>, Body, {[{<<"normpos">>, 0}]}),
      Normpos       = couch_util:get_value(<<"normpos">>, RevHistory, 0),

      {Body, Id, Rev, Normpos};
    _ ->
      not_found
  end.


document_body(DbName, DocInfoOrId) ->
  case document_object(DbName, DocInfoOrId) of
    {Body, _, _, _} -> Body;
    _ -> not_found
  end.


update_doc(_DbName, not_found) ->
  not_found;

update_doc(DbName, Body) when is_binary(DbName) and is_tuple(Body) ->
  update_doc(DbName, Body:to_list());

update_doc(DbName, Body) when is_binary(DbName) and is_list(Body) ->
  touch_db(DbName, fun(Db) -> update_doc(Db, Body) end);

update_doc(Db, Body) when is_record(Db, db) and is_tuple(Body) ->
  update_doc(Db, Body:to_list());

update_doc(Db, Body) when is_record(Db, db) and is_list(Body) ->
  try couch_db:update_doc(Db, couch_doc:from_json_obj({Body}), []) of
    {ok, _}  -> ok
  catch
    conflict -> conflict
  end.


touch_db(DbName, Fun) ->
  {ok, Db} = couch_db:open_int(DbName, []),
  R = Fun(Db),
  couch_db:close(Db),
  R.