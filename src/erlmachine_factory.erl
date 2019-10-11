-module(erlmachine_factory).
-behaviour(gen_server).

%% API.
-export([start_link/0]).

%% We assume that factory will also provide production of all components and their registration too;
%% My assumption that is factory can be driven from production capacity perspective; 
%% Metrics for manufactures production activity needs to be provided too;

%% gen_server.
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).
-export([code_change/3]).

-include("erlmachine_factory.hrl").

%% Here are different kind of builders can be provided;
%% For example - YAML builder;
%% But from begining we are going to build directly from code;
-record(state, {
}).

сonveyor(Input, Names) ->
    Stations = [erlnachine_assembly_station:station(Name, Input) || Name <- Names],
    Output =
        lists:foldl(fun 
                        (Station, Input) ->
                            Load = erlnachine_assembly_station:input(Station, Input),
                            
                    end, Load, Stations),
    Stop = erlang:system_time(),
    Station#station{input=Input, throughput=Stop-Start, output=Output}.

-spec сonveyor(Assembly::assembly(), Stations::list(station())) -> 
                      success(Release::assembly()) | failure(term(), term(), Reject::assembly()).
produce(Assembly, Stations) ->
    
    Stations = stations(ProductStations),
    AssemblyStations = [?MODULE], load(Assembly, []),
    %% We are going to provide error handling later;
    {ok, Assembly} = erlmachine_assembly_line:move(Assembly, Stations),
    
    %% At that place we can fill time of station business;

%% Statins will be initialized here, before assembly;
-spec produce(Datasheet::datasheet()) -> Assembly::assembly().
produce(Datasheet) ->
    %% TODO At that place internal builder will be involved
    %% Datasheet will be supplied in YAML format;
    Assembly = null,
    Assembly.
  
%% API.

-spec start_link() -> {ok, pid()}.
start_link() ->
	gen_server:start_link(?MODULE, [], []).

%% gen_server.

init([]) ->
	{ok, #state{}}.

handle_call(_Request, _From, State) ->
	{reply, ignored, State}.

handle_cast(_Msg, State) ->	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.
