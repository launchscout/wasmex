defmodule Wasmex.WasmComponentsTest do
  use ExUnit.Case, async: true

  alias Wasmex.Engine
  alias Wasmex.EngineConfig

  test "invoke component func" do
    {:ok, store} = Wasmex.Components.Store.new(%Wasmex.Wasi.WasiP2Options{})
    component_bytes = File.read!("test/component_fixtures/hello_world/hello_world.wasm")
    {:ok, component} = Wasmex.Components.Component.new(store, component_bytes)
    IO.inspect("building instance")
    {:ok, instance} = Wasmex.Components.Instance.new(store, component)
    IO.inspect("executing component function")

    assert {:ok, "Hello, Elixir!"} =
             Wasmex.Components.Instance.call_function(instance, "greet", ["Elixir"])

    assert {:ok, ["Hello, Elixir!", "Hello, Elixir!"]} =
             Wasmex.Components.Instance.call_function(instance, "multi-greet", ["Elixir", 2])
  end

  test "functions with maps and lists" do
    {:ok, store} = Wasmex.Components.Store.new(%Wasmex.Wasi.WasiP2Options{inherit_stdout: true})

    component_bytes = File.read!("test/component_fixtures/live_state/live-state.wasm")
    {:ok, component} = Wasmex.Components.Component.new(store, component_bytes)
    {:ok, instance} = Wasmex.Components.Instance.new(store, component)

    assert {:ok, %{"customers" => [customer]} = state} =
             Wasmex.Components.Instance.call_function(instance, "init", [])

    assert customer["email"] == "bob@jones.com"

    customer2 = Map.put(customer, "last-name", "Smith")

    assert {:ok, shown} =
             Wasmex.Components.Instance.call_function(instance, "show-customer", [customer2])

    assert {:ok, %{"customers" => customers} = state} =
             Wasmex.Components.Instance.call_function(instance, "add-customer", [customer2, state])

    assert Enum.count(customers) == 2
  end

  describe "error handling" do
    setup do
      {:ok, store} = Wasmex.Components.Store.new(%Wasmex.Wasi.WasiP2Options{inherit_stdout: true})

      component_bytes = File.read!("test/component_fixtures/hello_world/hello_world.wasm")
      {:ok, component} = Wasmex.Components.Component.new(store, component_bytes)
      {:ok, instance} = Wasmex.Components.Instance.new(store, component)
      %{instance: instance}
    end

    test "function not exported", %{instance: instance} do

      assert {:error, error} = Wasmex.Components.Instance.call_function(instance, "garbage", [:wut])
      assert error =~ "garbage not exported"
    end

    test "invalid arguments", %{instance: instance} do
      assert {:error, error} = Wasmex.Components.Instance.call_function(instance, "greet", [1])
      assert error =~ "type mismatch"
    end
  end
end