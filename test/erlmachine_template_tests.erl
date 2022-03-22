-module(erlmachine_template_tests).

%% NOTE: Template test is responsible to inspect the next related concerns:

%% 1) Load template file;
%% 2) Decoding content of the template file;
%% 3) Validation of decoded content accordingly to the schema

-include_lib("eunit/include/eunit.hrl").

erlmachine_template_test_() ->
    Modules = [ 'erlmachine_assembly', 'erlmachine_graph'
              ],

    { foreach,
      fun() ->
              application:start(yamerl),

              Res = erlmachine:init(Modules),
              Res
      end,
      fun(_) ->
              Res = application:stop(yamerl),
              Res
      end,
     [
      { "Inspect file: datasheets/extensions/ct.yaml",
        fun() ->
                Path = erlmachine:filename("datasheets/extensions/ct.yaml"),

                {ok, T} = erlmachine_assembly:template(Path),
                true = is_map(T),

                ?debugFmt("~n~p~n", [T])

        end
      },
      { "Inspect file: datasheets/extensions/sup_ct.yaml",
        fun() ->
                Path = erlmachine:filename("datasheets/extensions/sup_ct.yaml"),

                {ok, T} = erlmachine_assembly:template(Path),
                true = is_map(T),

                ?debugFmt("~n~p~n", [T])
        end
      },
      { "Inspect file: datasheets/ct.yaml",
        fun() ->
                Path = erlmachine:filename("datasheets/ct.yaml"),

                {ok, T} = erlmachine_graph:template(Path),
                true = is_map(T),

                ?debugFmt("~n~p~n", [T])
        end
      }
     ]
    }.
