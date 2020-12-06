-module(erlmachine_factory).
%% NOTE: The factory is responsible to produce and register component by it's own SN;
%% TODO: The next features:
%% 1. Capacity driven factory. Production planning via allocated pool;
%% 2. Measurements and visualization of production activities in admin panel;
%% 3. Acceptance procedure execution: prototype layer (supported by test model), model (business layer);
%% 4. Registered part_no allocation;

-behaviour(gen_server).

%% API.

-export([start_link/0]).
-export([start/0]).
-export([process/2]).
-export([stop/0]).

%% gen_server.
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).

%% extensions
-export([gear/1, gear/2, gear/3, gear/4, gear/5]).
-export([shaft/1, shaft/2, shaft/3, shaft/5]).
-export([axle/1, axle/2, axle/3, axle/5]).
-export([gearbox/1, gearbox/3, gearbox/4, gearbox/6]).

-export([tabname/0]).

-include("erlmachine_assembly.hrl").
-include("erlmachine_system.hrl").

-type serial_no() :: binary().
-type part_no() :: binary().

-type datasheet() :: erlmachine_datasheet:datasheet().

-export_type([serial_no/0, part_no/0]).

-spec tabname() -> atom().
tabname() ->
    ?MODULE.

-spec update_counter() -> non_neg_integer().
update_counter() ->
    mnesia:dirty_update_counter(tabname(), ?MODULE, 1).

-record (erlmachine_factory, { id::atom(), count::integer() }).

id() -> 
    ?MODULE.

-spec start() -> success(pid()) | ingnore | failure(term()).
start() ->
    Id = id(),
    gen_server:start({local, Id}, ?MODULE, [], []).

-spec start_link() -> success(pid()) | ingnore | failure(term()).
start_link() ->
    gen_server:start_link({local, id()}, ?MODULE, [], []).

-record(process, { assembly::assembly(), datasheet::datasheet() }).

-spec process(Assembly::assembly()) ->
                     success(assembly()) | failure(term(), term()).
process(Assembly) ->
    process(Assembly, #{}).

-spec process(Assembly::assembly(), Datasheet::datasheet()) ->
                       success(assembly()) | failure(term(), term()).
process(Assembly, Datasheet) ->
    gen_server:call(id(), #process{ assembly = Assembly, datasheet =  Datasheet }).

-spec stop() -> success().
stop() ->
    gen_server:stop(id()).

-record(state, { hash::binary() }).

init([]) ->
    Attributes = {attributes, record_info(fields, ?MODULE)},
    _TabRes = mnesia:create_table(tabname(), [Attributes]),
    Hash = erlmachine:guid(update_counter()),
    {ok, #state{ hash = Hash }}.

handle_call(#process{ assembly = Assembly, datasheet = _Datasheet }, _From, #state{ hash = Hash } = State) ->
    <<B1:32, B2:32, B3:32, B4:32>> = Hash,
    SN = erlmachine:base64url(Hash),
    Name = erlmachine_assembly:name(Assembly),
    Rel = erlmachine_assembly:serial_no(Assembly, <<(Name:prefix())/binary, SN/binary>>),

    B5 = erlmachine:phash2({B1, update_counter()}),
    Rotated = <<(B2 bxor B5):32, (B3 bxor B5):32, (B4 bxor B5):32, B5:32>>,
    {reply, erlmachine:success(Rel), State#state{ hash = Rotated }};

handle_call(_Request, _From, State) ->
    {reply, ignored, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
    ok.

%%%===================================================================
%%% Extensions
%%%===================================================================
%% TODO: Factory is responsible to support datasheets; erlmachine_datasheet shouldn't know about assembly;
-spec gear(Datasheet::datasheet()) -> 
                  assembly().
gear(Datasheet) ->
    Gear = erlmachine_gear:gear(),

    {ok, Rel} = process(Gear, Datasheet),
    Rel.

-spec gear(ModelName::atom(), ModelOpt::term()) -> 
                  assembly().
gear(ModelName, ModelOpt) ->
    ProtName = erlmachine_worker_prototype_default:name(),
    ProtOpt = [],
    gear(ModelName, ModelOpt, ProtName, ProtOpt).

-spec gear(ModelName::atom(), ModelOpt::term(), Ext::assembly()) -> 
                  assembly().
gear(ModelName, ModelOpt, Ext) ->
    Gear = gear(ModelName, ModelOpt),
    erlmachine_assembly:extensions(Gear, [Ext]).

-spec gear(ModelName::atom(), ModelOpt::term(), ProtName::atom(), ProtOpt::list()) -> 
                  assembly().
gear(ModelName, ModelOpt, ProtName, ProtOpt) ->
    Gear = erlmachine_gear:gear(),

    Prot = erlmachine_prototype:prototype(ProtName, ProtOpt),
    Model = erlmachine_model:model(ModelName, ModelOpt, Prot),

    Assembly = erlmachine_assembly:model(Gear, Model),
    {ok, Rel} = process(Assembly),
    Rel.

-spec gear(ModelName::atom(), ModelOpt::term(), ProtName::atom(), ProtOpt::list(), Ext::assembly()) -> 
                  assembly().
gear(ModelName, ModelOpt, ProtName, ProtOpt, Ext) ->
    Gear = gear(ModelName, ModelOpt, ProtName, ProtOpt),
    erlmachine_assembly:extensions(Gear, [Ext]).

-spec shaft(Datasheet::datasheet()) ->
                  assembly().
shaft(Datasheet) ->
    Shaft = erlmachine_shaft:shaft(),

    {ok, Rel} = process(Shaft, Datasheet),
    Rel.

-spec shaft(ModelName::atom(), ModelOpt::term()) ->
                   assembly().
shaft(ModelName, ModelOpt) ->
    shaft(ModelName, ModelOpt, []).

-spec shaft(ModelName::atom(), ModelOpt::term(), Exts::list()) ->
                  assembly().
shaft(ModelName, ModelOpt, Exts) when is_list(Exts) ->
    ProtName = erlmachine_worker_prototype_default:name(),
    ProtOpt = [],
    shaft(ModelName, ModelOpt, ProtName, ProtOpt, Exts).

-spec shaft(ModelName::atom(), ModelOpt::term(), ProtName::atom(), ProtOpt::list(), Exts::list()) ->
                  assembly().
shaft(ModelName, ModelOpt, ProtName, ProtOpt, Exts) when is_list(Exts) ->
    Shaft = erlmachine_shaft:shaft(),

    Prot = erlmachine_prototype:prototype(ProtName, ProtOpt),
    Model = erlmachine_model:model(ModelName, ModelOpt, Prot),

    Assembly = erlmachine_assembly:model(Shaft, Model),
    {ok, Rel} = process(Assembly),
    erlmachine_assembly:extensions(Rel, Exts).

-spec axle(Datasheet::datasheet()) -> 
                   assembly().
axle(Datasheet) ->
    Axle = erlmachine_axle:axle(),

    {ok, Rel} = process(Axle, Datasheet),
    Rel.

-spec axle(ModelName::atom(), ModelOpt::term()) ->
                  assembly().
axle(ModelName, ModelOpt) ->
    axle(ModelName, ModelOpt, []).

-spec axle(ModelName::atom(), ModelOpt::term(), Exts::list()) ->
                   assembly().
axle(ModelName, ModelOpt, Exts) when is_list(Exts) ->
    ProtName = erlmachine_supervisor_prototype_default:name(),
    ProtOpt = [],
    axle(ModelName, ModelOpt, ProtName, ProtOpt, Exts).

-spec axle(ModelName::atom(), ModelOpt::term(), ProtName::atom(), ProtOpt::list(), Exts::list()) -> 
                   assembly().
axle(ModelName, ModelOpt, ProtName, ProtOpt, Exts) when is_list(Exts) ->
    Axle = erlmachine_axle:axle(),

    Prot = erlmachine_prototype:prototype(ProtName, ProtOpt),
    Model = erlmachine_model:model(ModelName, ModelOpt, Prot),

    Assembly = erlmachine_assembly:model(Axle, Model),
    {ok, Rel} = process(Assembly),
    erlmachine_assembly:extensions(Rel, Exts).

%% Gearbox should be responsible to pass env context through the each model;
%% Each extension inherites this context as execution scope;
-spec gearbox(Datasheet::datasheet()) -> 
                  assembly().
gearbox(Datasheet) ->
    GearBox = erlmachine_gearbox:gearbox(),

    {ok, Rel} = process(GearBox, Datasheet),
    Rel.

-spec gearbox(ModelName::atom(), ModelOpt::term(), Env::term()) ->
                     assembly().
gearbox(ModelName, ModelOpt, Env) ->
    gearbox(ModelName, ModelOpt, Env, []).

-spec gearbox(ModelName::atom(), ModelOpt::term(), Env::term(), Exts::list()) ->
                  assembly().
gearbox(ModelName, ModelOpt, Env, Exts) when is_list(Exts) ->
    ProtName = erlmachine_supervisor_prototype_default:name(),
    ProtOpt = [],
    gearbox(ModelName, ModelOpt, ProtName, ProtOpt, Env, Exts).

-spec gearbox(ModelName::atom(), ModelOpt::term(), ProtName::atom(), ProtOpt::list(), Env::term(), Exts::list()) -> 
                  assembly().
gearbox(ModelName, ModelOpt, ProtName, ProtOpt, Env, Exts) when is_list(Exts) ->
    GearBox = erlmachine_gearbox:gearbox(),

    Prot = erlmachine_prototype:prototype(ProtName, ProtOpt),
    Model = erlmachine_model:model(ModelName, ModelOpt, Prot),

    Assembly = erlmachine_assembly:env(erlmachine_assembly:model(GearBox, Model), Env),
    {ok, Rel} = process(Assembly),
    erlmachine_assembly:extensions(Rel, Exts).
