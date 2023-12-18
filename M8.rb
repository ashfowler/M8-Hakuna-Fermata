# M8: Hakuna Fermata
# Ash Fowler


# the bpm of the body
bpm = 65
# the bpm of the section in the minor
minor_bpm = 62
# the target bpm of the conclusion
concl_bpm = 55
# how many beats the body of the song consists of
body_length = 124
# how many beats the section of the song in the minor key consists of
minor_length = 84
# how many beats the second body of the song consists of
second_body_length = 108
# how many beats the ending of the song consists of
conclusion_length = 20
# how many beats long a note of the melody can be
note_types = [0.25, 0.5, 1] # sixteenth notes, eighth notes, quarter notes
# the weights of the probabilities of the different note types
note_weights = [0.02, 0.45, 0.53] # sixteenth notes, eighth notes, quarter notes
# the note weights for the conclusion
concl_note_weights = [0.01, 0.34, 0.65]
# I, V, vi, IV
chord_progression_f4 = [(chord :f3, :major),
                        (chord :c4, :major),
                        (chord :d4, :minor),
                        (chord :bb3, :major)]
# i, iv, v, i
chord_progression_d4 = [(chord :d3, :minor),
                        (chord :g4, :minor),
                        (chord :a4, :minor),
                        (chord :d3, :minor)]
# tracks which chord of the progression is the next one to be played
chord_prog_counter = 0

# Chooses an element from choices, weighted according to the given weights.
# Larger numbers will be more likely to be chosen.
# Raises an error if the length of choices is not the same as the length of weights,
# or if choices is empty.
#
# @param choices an array of elements to choose from
# @param weights the respective weights of the choices
# @return the element that was chosen
define :weighted_choose do |choices, weights|
  # check that the two lists are the same length
  if choices.length() != weights.length()
    raise "Number of choices must match number of weights"
  end
  # check that there is something in choices
  if choices.length() == 0
    raise "Must have at least one element to choose from"
  end
  
  num = rrand_i(0, weights.sum)
  sum = 0
  for i in range(0, weights.length())
    sum = sum + weights[i]
    if num <= sum
      return choices[i]
    end
  end
  return choices[choices.length()-1]
end

# Returns the absolute value of the given value.
# No checks are performed for what is passed in
#
# @param value the number to find the absolute value of
# @return the absolute value of the given value
define :abs do |value|
  if value >= 0
    return value
  else
    return -1 * value
  end
end

# Plays a chord with the given parameters.
#
# @param chord the chord to be played
# @param inversion the inversion of the chord to be played. 0 means no inversion
# @param sustain_time the number of beats to sustain the chord for
# @param amp the amplitude at which to play the chord
define :chord_player do |chord, inversion, sustain_time, amp|
  play (chord_invert chord, inversion), sustain: sustain_time, amp: amp
  sleep 1
end

define :melody_note_player do |scale_notes, sustain_time, last_note, amp|
  weights = create_note_weights(scale_notes, last_note)
  note_choice = weighted_choose scale_notes, weights
  play note_choice, release: sustain_time, amp: amp
  sleep sustain_time
  return note_choice
end

define :create_note_weights do |scale_notes, last_note|
  weights = []
  num_notes_in_scale = scale_notes.length()
  for i in range 0, num_notes_in_scale
    distance = abs(last_note - scale_notes[i])
    if distance == 0
      # choose weight of repeating a note to be 1
      weights[i] = 1
    else
      weights[i] = num_notes_in_scale/distance
    end
  end
  return weights
end


use_bpm bpm
use_random_seed Time.now.to_i
use_synth :kalimba

# initialize last note to be F4
# this is so that when generating the next melody note, it will have
# something to generate the probabilities with
last_note = 65

# ---------- FIRST BODY ----------

in_thread(name: :body_thread) do
  
  in_thread(name: :body_base_thread) do
    sync :start # wait for melody thread to start
    num_beats = 4
    
    live_loop :body_base do
      # play a random inversion of the next chord in the chord progression
      inv = choose([0, 1, 2])
      chrd = chord_progression_f4[chord_prog_counter]
      chord_player(chrd, inv, num_beats, 1)
      chord_prog_counter = (chord_prog_counter + 1) % 4
      
      sleep 1
      
      sync :stop
      stop if body_length <= 0
    end
  end
  
  in_thread(name: :body_melody_thread) do
    cue :start # start in time with base thread
    ampl = 1
    
    scale_notes_f4 = scale :f4, :major, num_octaves: 2 # returns a ring
    
    live_loop :body_melody do
      4.times do
        note_type = weighted_choose(note_types, note_weights)
        
        if note_type == 0.25 # sixteenth note
          4.times do
            last_note = melody_note_player scale_notes_f4, note_type, last_note, ampl
          end
        elsif note_type == 0.5 # eighth note
          2.times do
            last_note = melody_note_player scale_notes_f4, note_type, last_note, ampl
          end
        else # quarter note
          last_note = melody_note_player scale_notes_f4, note_type, last_note, ampl
        end
      end
      
      # in the last three measures, decrease (or increase) bpm to get to the target minor_bpm
      if body_length <= 8
        dec_by = (current_bpm - minor_bpm) / 4
        use_bpm (current_bpm - dec_by)
      end
      cue :stop
      body_length = body_length - 4
      if body_length <= 0
        cue :body_stopped
        stop
      end
    end
  end
end

# ---------- KEY CHANGE TO MINOR ----------

in_thread(name: :minor_thread) do
  sync :body_stopped
  
  use_bpm minor_bpm
  ampl = 1
  
  in_thread(name: :minor_base_thread) do
    sync :start_minor # wait for melody thread to start
    num_beats = 4
    chord_prog_counter = 0 # reset to 0
    
    live_loop :minor_base do
      inv = choose([0, 1, 2])
      
      chrd = chord_progression_d4[chord_prog_counter]
      chord_player(chrd, inv, num_beats, ampl)
      chord_prog_counter = (chord_prog_counter + 1) % 4
      
      sleep 1
      
      sync :stop_minor
      stop if minor_length <= 0
    end
  end
  
  in_thread(name: :minor_melody_thread) do
    cue :start_minor # start in time with base thread
    
    scale_notes_d4 = []
    for note in (scale :d4, :minor, num_octaves: 2)
      if note % 12 == 0
        # sharp each C to create the harmonic minor
        note = note + 1
      end
      scale_notes_d4.push note
    end
    
    
    live_loop :minor_melody do
      4.times do
        note_type = weighted_choose(note_types, note_weights)
        
        if note_type == 0.25 # sixteenth note
          4.times do
            last_note = melody_note_player scale_notes_d4, note_type, last_note, ampl
          end
          
        elsif note_type == 0.5 # eighth note
          2.times do
            last_note = melody_note_player scale_notes_d4, note_type, last_note, ampl
          end
          
        else # quarter note
          last_note = melody_note_player scale_notes_d4, note_type, last_note, ampl
        end
        
        
      end
      
      cue :stop_minor
      minor_length = minor_length - 4
      if minor_length <= 0
        cue :minor_stopped
        stop
      end
    end
  end
end

# ---------- KEY CHANGE BACK TO MAJOR & CONCLUSION ----------

in_thread(name: :second_body_thread) do
  sync :minor_stopped
  current_bpm = bpm
  ampl = 1
  
  in_thread(name: :second_body_base_thread) do
    sync :second_body_start # wait for melody thread to start
    num_beats = 4
    chord_prog_counter = 0 # reset to 0
    #with_fx :ping_pong do
    live_loop :second_body_base do
      inv = choose([0, 1, 2])
      
      chrd = chord_progression_f4[chord_prog_counter]
      chord_player(chrd, inv, num_beats, ampl)
      chord_prog_counter = (chord_prog_counter + 1) % 4
      
      sleep 1
      
      if second_body_length <= 0
        sync :concl_started # wait for conclusion to start, then continue
        use_octave -1
        if current_bpm > concl_bpm
          new_bpm = current_bpm - 2
          use_bpm new_bpm
        end
        if ampl > 0.5
          ampl = ampl - 0.05
        end
        if conclusion_length <= 0
          sync :concl_stopped
          stop
        end
      #end
    end
  end
  end
  in_thread(name: :second_body_melody_thread) do
    cue :second_body_start # start in time with base thread
    ampl = 1
    
    scale_notes_f4 = scale :f4, :major, num_octaves: 2 # returns a ring
    with_fx :ping_pong do
    live_loop :second_body_melody do
      4.times do
        note_type = weighted_choose(note_types, note_weights)
        
        if note_type == 0.25 # sixteenth note
          4.times do
            last_note = melody_note_player scale_notes_f4, note_type, last_note, ampl
          end
          
        elsif note_type == 0.5 # eighth note
          2.times do
            last_note = melody_note_player scale_notes_f4, note_type, last_note, ampl
          end
          
        else # quarter note
          last_note = melody_note_player scale_notes_f4, note_type, last_note, ampl
        end
      end
      
      second_body_length = second_body_length - 4
      if second_body_length <= 0
        cue :concl_started
        use_octave -1 # shift all following notes down an octave
        if current_bpm > concl_bpm
          new_bpm = current_bpm - 1
          use_bpm new_bpm
        end
        if ampl > 0.5
          ampl = ampl - 0.05
        end
        note_weights = concl_note_weights
        conclusion_length = conclusion_length - 4
        if conclusion_length <= 0
          cue :concl_stopped
          chord_player chord(:f5, :major), 0, 12, ampl
          stop
        end
      end
    end
  end
end
end