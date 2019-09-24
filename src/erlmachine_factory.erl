-module(erlmachine_factory).
-behaviour(gen_server).

%% API.
-export([start_link/0]).

%% We assume that factory will also provide production of all components and their registration  by consistent way
%% gen_server.
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).
-export([code_change/3]).

-include("erlmachine_factory.hrl").

-record(model, {id::atom(), model_no::model_no(), product::gear()|shaft()|axle()|gearbox(), part_no::part_no()}).
-record(prototype, {id::atom()}).

-record(state, {
}).

%% API.

-spec start_link() -> {ok, pid()}.
start_link() ->
	gen_server:start_link(?MODULE, [], []).

%% gen_server.

init([]) ->
	{ok, #state{}}.

handle_call(_Request, _From, State) ->
	{reply, ignored, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.
