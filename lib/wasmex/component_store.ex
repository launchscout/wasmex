defmodule Wasmex.ComponentStore do
  alias Wasmex.Wasi.WasiP2Options
  alias Wasmex.Engine

  defstruct resource: nil, reference: nil

  def __wrap_resource__(resource) do
    %__MODULE__{
      resource: resource,
      reference: make_ref()
    }
  end

  def new(%WasiP2Options{} = options, store_limits \\ nil, engine \\ nil) do
    %Engine{resource: engine_resource} = engine || Engine.default()

    case Wasmex.Native.store_new_wasi_p2(
           options,
           store_limits,
           engine_resource
         ) do
      {:error, err} -> {:error, err}
      resource -> {:ok, __MODULE__.__wrap_resource__(resource)}
    end
  end
end
