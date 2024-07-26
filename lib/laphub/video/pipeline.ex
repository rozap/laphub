defmodule Laphub.Video.Pipeline do
  use Membrane.Pipeline

  alias Membrane.RTMP.SourceBin

  @impl true
  def handle_init(_context, opts) do
    structure = [
      child(:src, %SourceBin{client_ref: opts[:client_ref]})
      |> via_out(:audio)
      |> via_in(Pad.ref(:input, :audio),
        options: [encoding: :AAC, segment_duration: Membrane.Time.seconds(4)]
      )
      |> child(:sink, %Membrane.HTTPAdaptiveStream.SinkBin{
        manifest_module: Membrane.HTTPAdaptiveStream.HLS,
        target_window_duration: :infinity,
        persist?: true,
        storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{
          directory: opts[:path]
        }
      }),
      get_child(:src)
      |> via_out(:video)
      |> via_in(Pad.ref(:input, :video),
        options: [encoding: :H264, segment_duration: Membrane.Time.seconds(4)]
      )
      |> get_child(:sink)
    ]

    {[spec: structure], %{client_ref: opts[:client_ref], manager: opts[:manager]}}
  end

  @impl true
  def handle_info(message, _ctx, state) do
    IO.inspect {:info, message}
    {[], state}
  end


  def handle_child_notification(:end_of_stream, :sink, _, state)  do
    send(state.manager, :end_of_stream)
    {[], state}
  end

  def handle_child_notification(_, _, _, state)  do
    {[], state}
  end

  @impl true
  def handle_element_end_of_stream(:sink, _pad, _ctx, state) do
    IO.inspect {:eos, :sink}
    {[terminate: :normal], state}
  end

  @impl true
  def handle_element_end_of_stream(child, pad, ctx, state) do
    IO.inspect {:eos, child, pad, ctx}
    {[], state}
  end

  # def handle_setup(wha, state)  do
  #   IO.inspect {:handle_setup}
  #   {[], state}
  # end

  # def handle_playing(wha, state)  do
  #   IO.inspect {:handle_playing}
  #   {[], state}
  # end

  # def handle_terminate_request(wha, state)  do
  #   IO.inspect {:handle_terminate_request}
  #   {[], state}
  # end

  # def handle_info(wha, ctx, state)  do
  #   IO.inspect {:handle_info}
  #   {[], state}
  # end

  # def handle_spec_started(wha, ctx, state)  do
  #   IO.inspect {:handle_spec_started}
  #   {[], state}
  # end

  # def handle_child_setup_completed(wha, ctx, state)  do
  #   IO.inspect {:handle_child_setup_completed}
  #   {[], state}
  # end

  # def handle_child_playing(wha, ctx, state)  do
  #   IO.inspect {:handle_child_playing}
  #   {[], state}
  # end

  # def handle_tick(wha, ctx, state)  do
  #   IO.inspect {:handle_tick}
  #   {[], state}
  # end

  # def handle_crash_group_down(wha, ctx, state)  do
  #   IO.inspect {:handle_crash_group_down}
  #   {[], state}
  # end

  # def handle_call(wha, ctx, state)  do
  #   IO.inspect {:handle_call}
  #   {[], state}
  # end

  # def handle_element_start_of_stream(wha, a, b, state)  do
  #   IO.inspect {:handle_element_start_of_stream}
  #   {[], state}
  # end

  # def handle_element_end_of_stream(wha, a, b, state)  do
  #   IO.inspect {:handle_element_end_of_stream}
  #   {[], state}
  # end


  # def handle_child_pad_removed(wha, a, b, state) do
  #   IO.inspect {:handle_child_pad_removed}
  #   {[], state}
  # end

end
