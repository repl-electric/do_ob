load "/Users/josephwilk/Workspace/repl-electric/live-coding-space/lib/shaderview.rb"
load "/Users/josephwilk/Workspace/repl-electric/live-coding-space/lib/samples.rb"
load "/Users/josephwilk/Workspace/repl-electric/live-coding-space/lib/dsp.rb"
load "/Users/josephwilk/Workspace/repl-electric/live-coding-space/lib/monkey.rb"
load "/Users/josephwilk/Workspace/repl-electric/live-coding-space/lib/log.rb"
_=nil
set_volume! 1.0
def note_slices(n, m)
  NoteSlices.find(note: n, max: m, pat: "sop|alto|bass").select{|s| s[:path] =~ /sop|alto/}.take(64)
end
@slices ||= {"Gs2/4" => note_slices("Gs2",1/4.0),"D2/4" => note_slices("D2",1/4.0), "E2/4" => note_slices("E2",1/4.0), "A2/4" => note_slices("A2",1/4.0), "Fs2/4" => note_slices("F#2",1/4.0),"Fs2/8" => note_slices("F#2",1/8.0), "E3/4" => note_slices("E3",1/4.0), "D3/4" => note_slices("D3",1/4.0),"D3/8" => note_slices("D3",1/8.0),"Cs3/4" => note_slices("C#3",1/4.0), "Fs3/8" => note_slices("F#3",1/8.0),"Fs3/4" => note_slices("F#3",1/4.0), "Gs3/4" => note_slices("G#3",1/4.0), "A3/8" => note_slices("A3",1/8.0),"A3/4" => note_slices("A3",1/4.0), "B3/4" => note_slices("B3",1/4.0), "Cs4/4" => note_slices("C#4",1/4.0), "Cs4/8" => note_slices("C#4",1/8.0), "D4/4" => note_slices("D4",1/4.0),"D4/8" => note_slices("D4",1/8.0), "E4/4" => note_slices("E4",1/4.0),"E4/8" => note_slices("E4",1/8.0), "Fs4/4" => note_slices("F#4",1/4.0),"Fs4/8" => note_slices("F#4",1/8.0), "FS4/8" => note_slices("F#4",1/8.0), "Gs4/4" => note_slices("G#4",1/4.0), "B4/4" => note_slices("B4",1/4.0),"Fs5/4" => note_slices("F#5",1/4.0), "Fs6/4" => note_slices("F#6",1/4.0),"A4/4" => note_slices("A4",1/4.0),"E5/4" => note_slices("E5",1/4.0)}
@slices.values.flatten.each{|f| load_sample f[:path]}
puts @slices.values.flatten.count
#smp Harp.slice(:Fs3).look, amp: 2, cutoff:  ramp(10, 130, 128).tick(:ram)
module Straw
  def self.slice(n, size: 1/4.0)
    @straw_cache ||= {}
    n = n.to_s.downcase.gsub(/s/,"#")
    if !@straw_cache.has_key?(n)
      @straw_cache[n] = NoteSlices.find(note: n, max: size, pat: "Straw").take(64)
    end
    @straw_cache[n]
  end
end
module Berry
  def self.pick(a)
    self[a]
  end
  def self.[](*a)
    samples = Dir["/Users/josephwilk/Workspace/music/samples/strawberry/Samples/**/*.wav"]
    Sample.matches(samples, a)
  end
end
module Harp
  def self.slice(n, size: 1/4.0)
    @harp_cache ||= {}
    n = n.to_s.gsub(/s/,"#")
    if !@harp_cache.has_key?(n)
      @harp_cache[n] = NoteSlices.find(note: n, max: size, pat: "Harp").take(64)
    end
    @harp_cache[n]
  end
end

☠ =Straw
❄️ =Straw
☃️=Straw
🐿️=Straw
♥️ =Straw
🌶️ =Straw
⚡︎ =Straw
〄=Straw
㉿=Straw

def live(name, *args, &block)
  fx = resolve_synth_opts_hash_or_array(args)
  x = lambda{||
    with_fx((fx[:fx] || :none), mix: (fx[:mix] || 0)) do
      block.()
    end}
  live_loop(name, *args, &x)
end
def play_midi(*args)
  notes = args.first
  if notes.is_a?(SonicPi::Core::RingVector)||notes.is_a?(Array)
    notes.map{|n|
      midi *([n]+args[1..-1])
    }
  else
    midi *args
  end
end

def form(*args)play_midi *(args << {port: :reaktor_6_virtual_input});end
def mass(*args)play_midi *(args << {port: :massive_virtual_input});end
def blof(*args)play_midi *(args << {port: :blofeld});end
def moog(*args)play_midi *(args << {port: :moog_minitaur});end
def stop_midi() midi('C-2', channel: 16);end

def bass(note, *args)
  if note.is_a?(Array)
    args = args << {sustain: note[1]}
    note = note[0]
  end
  args_h = resolve_synth_opts_hash_or_array(args)
  if(args_h[:cutoff])
    bass_cc(args_h[:cutoff])
  end
  midi note, *(args << {port: :iac_bus_1} << {channel: 5})
end
def bass_cc(vv)
  #6=>cutoff
  midi_cc 6, vv*127.0, port: :iac_bus_1, channel: 5
end
def bass_x
  midi_all_notes_off port: :iac_bus_1, channel: 5
end

def sharp(note,*args)
  if note.is_a?(Array)
    args =  args  << {sustain: note[1]}
    note = note[0]
  end
  midi note, *(args << {port: :iac_bus_1} << {channel: 8})
end
def harp(note,*args)
  if note.is_a?(Array)
    args =  args  << {sustain: note[1]}
    note = note[0]
  end
  midi note, *(args << {port: :iac_bus_1} << {channel: 3})
end
def harp_cc(cc,vv)
  n = case cc
  when :cutoff; 4
  when :gain;   5
  when :drive;  8
  when :charge; 9
  when :sound; 12
  when :phase; 13
  else
  end
  midi_cc n, (vv*127.0), port: :iac_bus_1, channel: 3
end
def harp_x
  midi_all_notes_off port: :iac_bus_1, channel: 3
end

def jup(*args)
  midi *(args << {port: :iac_bus_1} << {channel: 4})
end
def jup_x
  midi_all_notes_off port: :iac_bus_1, channel: 4
end

def zero(*args)
  midi *(args << {port: :iac_bus_1} << {channel: 7})
end
def zero_x
  midi_all_notes_off port: :iac_bus_1, channel: 7
end

puts "Init Complete"
