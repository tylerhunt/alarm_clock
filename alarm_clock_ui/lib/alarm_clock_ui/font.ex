defmodule AlarmClockUI.Font do
  @path "static/fonts/ProFont"

  # See https://github.com/boydm/scenic/blob/master/guides/custom_fonts.md
  @font_hash "QeaJbshz8-ys7oSCwBv3-KNlhgWIp9hVplx0hFil8h0"
  @font_metrics_hash :code.priv_dir(:alarm_clock_ui)
                     |> Path.join(@path)
                     |> Path.join("ProFontWindows.ttf.metrics")
                     |> Scenic.Cache.Support.Hash.file!(:sha)

  @moduledoc """
  ProFont Windows font loader
  """

  @doc """
  Manually load the font

  If you want Scenic to unload the font when a process dies, pass that
  process's pid.
  """
  @spec load(:global | pid()) :: :ok
  def load(scope \\ :global) do
    {:ok, _hash} =
      Scenic.Cache.Static.FontMetrics.load(
        font_metrics(),
        @font_metrics_hash,
        scope: scope
      )

    {:ok, _hash} = Scenic.Cache.Static.Font.load(font_folder(), @font_hash, scope: scope)

    :ok
  end

  @doc """
  Return the hash for the font for use in graphs
  """
  @spec hash() :: <<_::216>>
  def hash() do
    @font_metrics_hash
  end

  defp font_folder() do
    :code.priv_dir(:alarm_clock_ui) |> Path.join(@path)
  end

  defp font_metrics() do
    font_folder() |> Path.join("ProFontWindows.ttf.metrics")
  end
end
