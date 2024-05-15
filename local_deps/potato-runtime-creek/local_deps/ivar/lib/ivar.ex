defmodule Ivar do
  defstruct ref: nil, pid: nil

  def new do
    ref = make_ref()

    pid =
      spawn(fn ->
        lvar_empty(ref)
      end)

    %Ivar{ref: ref, pid: pid}
  end

  def put(%Ivar{ref: ref, pid: pid}, value) do
    send(pid, {:put, ref, value})
  end

  def get(%Ivar{ref: ref, pid: pid}) do
    send(pid, {:get, ref, self()})

    receive do
      {^ref, value} -> value
    end
  end

  defp lvar_empty(ref) do
    receive do
      {:put, ^ref, value} ->
        lvar_full(ref, value)
    end
  end

  defp lvar_full(ref, value) do
    receive do
      {:get, ^ref, from} ->
        send(from, {ref, value})
        lvar_full(ref, value)
    end
  end
end
