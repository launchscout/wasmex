defmodule Wasmex.Components do
  @moduledoc """
  This is the entry point to support for the [WebAssembly Component Model](https://component-model.bytecodealliance.org/).

  Support should be considered experimental at this point, with not all types yet supported.
  """

  use GenServer
  alias Wasmex.Wasi.WasiP2Options

  def start_link(%{bytes: component_bytes, wasi: %WasiP2Options{} = wasi_options}) do
    with {:ok, store} <- Wasmex.Components.Store.new_wasi(wasi_options),
         {:ok, component} <- Wasmex.Components.Component.new(store, component_bytes) do
      GenServer.start_link(__MODULE__, %{store: store, component: component})
    end
  end

  def start_link(%{bytes: component_bytes}) do
    with {:ok, store} <- Wasmex.Components.Store.new(),
         {:ok, component} <- Wasmex.Components.Component.new(store, component_bytes) do
      GenServer.start_link(__MODULE__, %{store: store, component: component})
    end
  end

  @spec call_function(pid(), String.t() | atom(), list(number()), pos_integer()) ::
          {:ok, list(number())} | {:error, any()}
  def call_function(pid, name, params, timeout \\ 5000) do
    GenServer.call(pid, {:call_function, stringify(name), params}, timeout)
  end

  @impl true
  def init(%{store: store, component: component} = state) do
    case Wasmex.Components.Instance.new(store, component) do
      {:ok, instance} -> {:ok, Map.merge(state, %{instance: instance})}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def handle_call(
        {:call_function, name, params},
        _from,
        %{instance: instance} = state
      ) do
    case Wasmex.Components.Instance.call_function(instance, name, params) do
      {:ok, result} -> {:reply, {:ok, result}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  defp stringify(s) when is_binary(s), do: s
  defp stringify(s) when is_atom(s), do: Atom.to_string(s)
end
