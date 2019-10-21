-module(erlmachine_transmission).
-behaviour(gen_server).

%% API.
-export([start_link/0]).
 
%% gen_server.
-export([
         init/1, 
         handle_call/3, handle_cast/2, handle_info/2, 
         terminate/2,
         code_change/3
        ]).

%% Transmission will be loaded directly by call where ID argument is provided; 
%% Transmission can be represented by a lot of copies where each of them is marked by unique serial number;

-export([attach/3]).

-export([switch_model/3, rotate_model/3]).

-export([switched/3]).

-include("erlmachine_factory.hrl").
-include("erlmachine_system.hrl").

-callback transmit(SN::serial_no(), Motion::term(), Body::term()) -> 
    success(term(), term()) | failure(term(), term(), term()) | failure(term()).

-spec attach(Assembly::assembly(), Part::assembly()) -> 
                    success(term()) | failure(term(), term(), term()) | failure(term()).
attach(Assembly::assembly(), Part::assembly()) ->
    Module = erlmachine_assembly:prototype_name(Assembly),
    SN = erlmachine_assembly:serial_no(Assembly),
    

-spec rotate(Assembly::assembly(), Motion::term()) ->
                    Motion::term().
rotate(Assembly, Motion) ->
    Module = erlmachine_assembly:prototype_name(Assembly),
    SN = erlmachine_assembly:serial_no(Assembly),
  
-record(state, {
}).

%% API.

%% That next statement will be produced by system itself: erlmachine_system:damage(Assembly, Damage);
%% Transmission can provide a lot of abilities, for example:
%% Time measurements between parts, different flow algorithms inside gearbox etc..
%% Actually, it's just tree , and we'll be able to do that by various ways;
%% We can even provide slowering between parts or persistence layer, because control level was provided;
%% Error handling will be implemented by product API parts instead;
%% In generally term transmission is about processing algorithms over mechanical topology;

-spec start_link() -> {ok, pid()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, [], []).

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
