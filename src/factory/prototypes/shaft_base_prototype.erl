-module(shaft_base_prototype).

-folder(<<"erlmachine/factory/prototypes/shaft_base_prototype">>).

%% I guess factory will write to catalogue via catalogue behaviour;
%% The main purpose of a prototype is to provide implemetation of both communication and configuration layers;
%% The main purpose of a detail is to provide mechanical intraface API over internal isolated product structure;
%% The main purpose of a model is to provide mechanical reflection of modelling process over whole assembly;

-behaviour(gen_server).

%% API.

-export([name/0]).

%% gen_server.
-export([
         init/1, 
         handle_call/3, handle_cast/2, handle_info/2, 
         terminate/2, 
         code_change/3
        ]).

-export([
         install/4, 
         attach/3, detach/3,
         overload/2, block/3, 
         replace/3,
         rotate/2,
         uninstall/3,
         accept/3
        ]).

-include("erlmachine_factory.hrl").
-include("erlmachine_system.hrl").

%% API.

-spec name() -> Name::atom().
name() ->
    ?MODULE.

format_name(SerialNumber) ->
    ID = erlang:binary_to_atom(SerialNumber, latin1),
    ID.

-record(install, {gearbox::assembly(), shaft::assembly(), options::list(tuple())}).

-spec install(Name::serial_no(), GearBox::assembly(), Shaft::assembly(), Options::list(tuple())) -> 
                     success(pid()) | ingnore | failure(E::term()).
install(Name, GearBox, Shaft, Options) ->
    ID = {local, format_name(Name)},
    gen_server:start_link(ID, ?MODULE, #install{gearbox=GearBox, shaft=Shaft, options=Options}, []).

%% I think about ability to reflect both kind of switching - manual and automated;
-record(attach, {part::assembly()}).

-spec attach(Name::serial_no(), Part::assembly(), Timeout::timeout()) -> 
                    success(Release::assembly()) | failure(E::term(), R::term()).
attach(Name, Part, Timeout) ->
    gen_server:call(format_name(Name), #attach{part = Part}, Timeout).

%% I think about ability to reflect both kind of switching - manual and automated;
-record(detach, {id::serial_no()}).

-spec detach(Name::serial_no(), ID::serial_no(), Timeout::timeout()) -> 
                    success(Release::assembly()) | failure(E::term(), R::term()).
detach(Name, ID, Timeout) ->
    gen_server:call(format_name(Name), #detach{id=ID}, Timeout).

-record(overload, {load::term()}).

-spec overload(Name::serial_no(), Load::term()) ->
                      Load::term().
overload(Name, Load) ->
    erlang:send(format_name(Name), #overload{load=Load}), 
    Load.

-record(block, {part::assembly(), failure::term()}).

-spec block(Name::serial_no(), Part::assembly(), Failure::term()) -> 
                   Failure::term().
block(Name, Part, Failure) ->
    erlang:send(format_name(Name), #block{part=Part, failure=Failure}), 
    Failure.

-record(replace, {repair::assembly()}).

-spec replace(Name::serial_no(), Repair::assembly(), Timeout::timeout()) -> 
                     success(Release::assembly()) | failure(E::term(), R::term()).
replace(Name, Repair, Timeout) ->
    gen_server:call(format_name(Name), #replace{repair=Repair}, Timeout).

-record(rotate, {motion::term()}).

-spec rotate(Name::serial_no(), Motion::term()) -> 
                    Motion::term().
rotate(Name, Motion) ->
    erlang:send(format_name(Name), #rotate{motion=Motion}), 
    Motion.

-spec uninstall(Name::serial_no(), Reason::term(), Timeout::timeout()) ->
                       ok.
uninstall(Name, Reason, Timeout) ->
    gen_server:stop({local, format_name(Name)}, Reason, Timeout).

-record(accept, {criteria::acceptance_criteria()}).

-spec accept(Name::serial_no(), Criteria::acceptance_criteria(), Timeout::timeout()) ->
                    accept() | reject().
accept(Name, Criteria, Timeout) -> 
    gen_server:call(Name, #accept{criteria=Criteria}, Timeout).

%% gen_server.
-record(state, {gearbox::assembly(), shaft::assembly()}).

init(#install{gearbox=GearBox, shaft=Shaft, options=Options}) ->
    [process_flag(ID, Param)|| {ID, Param} <- Options],
    %% process_flag(trap_exit, true), Needs to be passed by default;
    %% Gearbox is intended to use like specification of destination point (it's not about persistence);
    {ok, Release} = erlmachine_shaft:install_model(GearBox, Shaft),
    {ok, #state{gearbox=GearBox, shaft=Release}}.

handle_call(#attach{part = Part}, _From, #state{gearbox=GearBox, shaft=Shaft} = State) ->
    Result = {ok, Release} = erlmachine_shaft:attach_model(GearBox, Shaft, Part),
    {reply, Result, State#state{shaft=Release}};

handle_call(#detach{id = ID}, _From, #state{gearbox=GearBox, shaft=Shaft} = State) ->
    Result = {ok, Release} = erlmachine_shaft:detach_model(GearBox, Shaft, ID),
    {reply, Result, State#state{shaft=Release}};

handle_call(#replace{repair=Repair}, _From, #state{gearbox=GearBox, shaft=Shaft} = State) ->
    Result = {ok, Release} = erlmachine_shaft:replace_model(GearBox, Shaft, Repair),
    {reply, Result, State#state{shaft=Release}};

handle_call(#accept{criteria = Criteria}, _From, #state{gearbox=GearBox, shaft=Shaft} = State) ->
    {ok, Report, Release} = erlmachine_shaft:accept_model(GearBox, Shaft, Criteria),
    {reply, Report, State#state{shaft=Release}};

handle_call(Req, _From, #state{gearbox=GearBox, shaft=Shaft} = State) ->
    erlmachine_shaft:call(GearBox, Shaft, Req),
    {reply, ignored, State}.

handle_cast(Message, #state{gearbox=GearBox, shaft=Shaft} = State) ->
    erlmachine_shaft:cast(GearBox, Shaft, Message),
    {noreply, State}.

handle_info(#rotate{motion = Motion}, #state{gearbox=GearBox, shaft=Shaft} = State) ->
    %% At that place we can adress rotated part by SN; 
    %% In that case all parts will be rotated by default;
    %% If you need to provide measurements is's suitable place for that;
    erlmachine_shaft:rotate(GearBox, Shaft, Motion),
    %% Potentially clients can provide sync delivery inside this call;
    %% It can work a very similar to job queue);
    {noreply, State};

handle_info(#overload{load = Load}, #state{gearbox=GearBox, shaft=Shaft} = State) ->
    {ok, Release} = erlmachine_shaft:overload_model(GearBox, Shaft, Load),
    {noreply, State#state{shaft=Release}};

handle_info(#block{part=Part, failure = Failure}, #state{gearbox=GearBox, shaft=Shaft} = State) ->
    %% Damage, Crash and Failure will be translated to specialized system gears;
    %% This produced stream can be consumed by custom components which can be able to provide repair;
    {ok, Release} = erlmachine_shaft:block_model(GearBox, Shaft, Part, Failure),
    {noreply, State#state{shaft=Release}};

handle_info(Message, #state{gearbox=GearBox, shaft=Shaft} = State) ->
    erlmachine_shaft:info(GearBox, Shaft, Message),
    {noreply, State}.

%% When reason is different from normal, or stop - the broken part event is occured;
terminate(Reason, #state{gearbox=GearBox, shaft=Shaft}) ->
    erlmachine_gear:uninstall_model(GearBox, Shaft, Reason),
    ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.
