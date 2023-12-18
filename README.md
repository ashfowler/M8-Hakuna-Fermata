# M8-Hakuna-Fermata

## The song

Link to YouTube video here: https://youtu.be/K5ze_URN6qg

The above YouTube video uses the example output file with some added footage of my window on a rainy day.

I called this song "A Child's Dream". The name draws heavy inspiration from something my roommate, Julia, said about the outputs I was getting earlier on in the project. The melody was much more randomized and chaotic, and Julia said, "It sounds like a child's nightmare". Although I quite liked "A Child's Nightmare" for a song title, it didn't fit the song very well, so I renamed it to "A Child's Dream" instead.

At first, I wanted the song to be a soft, solumn piano piece, but once I discovered the kalimba synth, I changed my mind completely. I have a couple years of piano experience, so I decided I would create code that was similar to many pieces I've played where there the left hand plays chords and the right hand plays the melody. I chose to have the "left hand" in my code play a random inversion of a chord from a set chord progression while the the "right hand" played random notes from the relevant scale. As mentioned before, just having the melody consist of completely random notes sounded chaotic, so I introduced a weighted probability function. Notes that are closer to the previously played note have a higher change of being chosen. This made the songs much more cohesive. I also added in probabilities of the melody notes being different lengths. I kept it fairly simple and limited the choices for note types to quarter notes, eighth notes, and sixteenth notes. The song is played in 4/4 time, simply because that is what I am most familiar with. I chose a major key (F major) and its relative harmonic minor (D minor) and chose chord progressions for both keys.

The song starts out in F major and then switches to D minor. The section with the minor key is a bit slower to fit the slightly darker tone. The song then transitions back to the major, resumes the original speed, and adds the "ping-pong" effect to differentiate it from the first section. Once this third section is complete, the song slows down and has a new set of note type probabilities which favor longer notes. The song ends with a soft F major triad.

## The code and how to run it

The file can't be run directly from Sonic Pi because it exceeds the buffer limit. (Interestingly, I believe it's about the number of characters in the file and not anything to do with how many lines/instructions.) To run it, you have to create a buffer that just uses the "run_file" command with the path to the .rb file with the code.
