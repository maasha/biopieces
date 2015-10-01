# Copyright (C) 2007-2012 Martin A. Hansen.

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

# http://www.gnu.org/copyleft/gpl.html

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# This software is part of the Biopieces framework (www.biopieces.org).

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

require 'inline'
require 'maasha/fasta'
require 'maasha/align'

BYTES_IN_INT      = 4
BYTES_IN_FLOAT    = 4
BYTES_IN_HIT      = 2 * BYTES_IN_INT + 1 * BYTES_IN_FLOAT   # i.e. 12
NUC_ALPH_SIZE     = 4            # Alphabet size of nucleotides.
RESULT_ARY_BUFFER = 10_000_000   # Buffer for the result_ary.
HIT_ARY_BUFFER    = 1_000_000    # Buffer for the hit_ary.

# FindSim is an implementation of the SimRank logic proposed by Niels Larsen.
# The purpose is to find similarities between query DNA/RNA sequences and a
# database of small subunit ribosomal DNA/RNA sequences. The sequence
# similarities are calculated as the number of shared unique oligos/kmers
# divided by the smallest number of unique oligoes in either the query or
# database sequence. This yields a rough under estimate of similarity e.g. 50%
# oligo similarity may correspond to 80% similarity on a nucleotide level
# (needs clarification). 
class FindSim
  include Enumerable

  # Method to initialize FindSim Object.
  def initialize(opt_hash)
    @opt_hash     = opt_hash
    @q_size       = 0
    @q_ary        = nil
    @q_begs_ary   = nil
    @q_ends_ary   = nil
    @q_total_ary  = nil
    @result       = nil
    @result_count = 0
    @q_ids        = []
    @s_ids        = []
    @q_entries    = []
    @s_entries    = []
  end

  # Method to load sequences from a query file in FASTA format
  # and index these for oligo based similarty search.
  def load_query(file)
    time       = Time.now
    q_total    = []
    oligo_hash = Hash.new { |h, k| h[k] = [] }

    count = 0

    Fasta.open(file, 'r') do |ios|
      ios.each do |entry|
        @q_ids     << entry.seq_name if @opt_hash[:query_ids]
        @q_entries << entry          if @opt_hash[:realign]

        oligos = str_to_oligo_rb_ary_c(entry.seq, @opt_hash[:kmer], 1).uniq.sort

        q_total << oligos.size

        oligos.each do |oligo|
          oligo_hash[oligo] << count
        end

        count += 1
      end
    end

    @q_size = count

    create_query_index(q_total, oligo_hash)

    $stderr.puts "Loaded #{count} query sequences in #{(Time.now - time)} seconds." if @opt_hash[:verbose]
  end

  # Method to search database or subject sequences from a FASTA file by
  # locating for each sequence all shared oligos with the query index.
  def search_db(file)
    time         = Time.now
    oligo_ary    = "\0" * (NUC_ALPH_SIZE ** @opt_hash[:kmer]) * BYTES_IN_INT
    shared_ary   = "\0" * @q_size                             * BYTES_IN_INT
    result_ary   = "\0" * RESULT_ARY_BUFFER                   * BYTES_IN_HIT
    result_count = 0

    Fasta.open(file, 'r') do |ios|
      ios.each_with_index do |entry, s_index|
        @s_ids     << entry.seq_name if @opt_hash[:subject_ids]
        @s_entries << entry          if @opt_hash[:realign]

        zero_ary_c(oligo_ary,  (NUC_ALPH_SIZE ** @opt_hash[:kmer]) * BYTES_IN_INT)
        zero_ary_c(shared_ary, @q_size                             * BYTES_IN_INT)

        oligo_ary_size = str_to_oligo_ary_c(entry.seq, entry.len, oligo_ary, @opt_hash[:kmer], @opt_hash[:step])

        count_shared_c(@q_ary, @q_begs_ary, @q_ends_ary, oligo_ary, oligo_ary_size, shared_ary)

        result_count = calc_scores_c(@q_total_ary, shared_ary, @q_size, oligo_ary_size, result_ary, result_count, s_index, @opt_hash[:min_score])

        if ((s_index + 1) % 1000) == 0 and @opt_hash[:verbose]
          $stderr.puts "Searched #{s_index + 1} sequences in #{Time.now - time} seconds (#{result_count} hits)."
        end

        if result_ary.size / BYTES_IN_HIT - result_count < RESULT_ARY_BUFFER / 2
          result_ary << "\0" * RESULT_ARY_BUFFER * BYTES_IN_HIT
        end
      end
    end

    @result       = result_ary[0 ... result_count * BYTES_IN_HIT]
    @result_count = result_count
  end

  # Method that for each query index yields all hits, sorted according to
  # decending score, as Hit objects.
  def each
    sort_hits_c(@result, @result_count)

    hit_ary = "\0" * HIT_ARY_BUFFER * BYTES_IN_HIT

    hit_index = 0

    (0 ... @q_size).each do |q_index|
      zero_ary_c(hit_ary, HIT_ARY_BUFFER * BYTES_IN_HIT)
      hit_ary_size = get_hits_c(@result, @result_count, hit_index, hit_ary, q_index)

      if @opt_hash[:max_hits]
        max = (hit_ary_size > @opt_hash[:max_hits]) ? @opt_hash[:max_hits] : hit_ary_size
      else
        max = hit_ary_size
      end

      best_score = 0

      (0 ... max).each do |i|
        q_index, s_index, score = hit_ary[BYTES_IN_HIT * i ... BYTES_IN_HIT * i + BYTES_IN_HIT].unpack("IIF")

        q_id = @opt_hash[:query_ids]   ? @q_ids[q_index] : q_index
        s_id = @opt_hash[:subject_ids] ? @s_ids[s_index] : s_index

        if @opt_hash[:realign]
          new_score = Align.muscle([@q_entries[q_index], @s_entries[s_index]]).identity
          score     = new_score if new_score > score
        end

        if @opt_hash[:max_diversity]
          best_score = score if i == 0

          break if best_score - score >= (@opt_hash[:max_diversity] / 100)
        end

        yield Hit.new(q_id, s_id, score)
      end

      hit_index += hit_ary_size
    end

    self
  end

  private

  # Method to create the query index for FindSim search. The index consists of
  # four lookup arrays which are stored as instance variables:
  # *  @q_total_ary holds per index the total of unique oligos for that
  #    particular query sequences.
  # *  @q_ary holds sequencially lists of query indexes so it is possible
  #    to lookup the list for a particular oligo and get all query indeces for
  #    query sequences containing this oligo.
  # *  @q_begs_ary holds per index the begin coordinate for the @q_ary list for
  #    a particular oligo.
  # *  @q_ends_ary holds per index the end coordinate for the @q_ary list for a
  #    particular oligo.
  def create_query_index(q_total, oligo_hash)
    @q_total_ary = q_total.pack("I*")
    @q_ary       = ""

    beg        = 0
    oligo_begs = Array.new(NUC_ALPH_SIZE ** @opt_hash[:kmer], 0)
    oligo_ends = Array.new(NUC_ALPH_SIZE ** @opt_hash[:kmer], 0)

    oligo_hash.each do |oligo, list|
      @q_ary << list.pack("I*")
      oligo_begs[oligo] = beg
      oligo_ends[oligo] = beg + list.size

      beg += list.size
    end

    @q_begs_ary = oligo_begs.pack("I*")
    @q_ends_ary = oligo_ends.pack("I*")
  end

  # >>>>>>>>>>>>>>> RubyInline C code <<<<<<<<<<<<<<<

  inline do |builder|
    # Bitmap lookup table where the index is ASCII values
    # and the following nucleotides are encoded as:
    # T or t = 1
    # U or u = 1
    # C or c = 2
    # G or g = 3
    builder.prefix %{
      unsigned char oligo_map[256] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      };
    }

    # Defining a hit struct to hold hits consisting of query
    # sequence index, subject sequence index and score.
    builder.prefix %{
      typedef struct 
      {
        unsigned int q_index;
        unsigned int s_index;
        float          score;
      } hit;
    }

    # Qsort unsigned int comparison function.
    # Returns negative if b > a and positive if a > b.
    builder.prefix %{
      int uint_cmp(const void *a, const void *b) 
      { 
        const unsigned int *ia = (const unsigned int *) a;
        const unsigned int *ib = (const unsigned int *) b;

        return *ia - *ib; 
      }
    }

    # Qsort hit struct comparision function of q_index.
    # Returns negative if b > a and positive if a > b.
    builder.prefix %{
      int hit_cmp_by_q_index(const void *a, const void *b) 
      { 
        hit *ia = (hit *) a;
        hit *ib = (hit *) b;

        return (int) (ia->q_index - ib->q_index);
      } 
    }
 
    # Qsort hit struct comparision function of score.
    # Returns negative if b < a and positive if a < b.
    # We multiply with 1000 to maintain 2 decimal floats.
    builder.prefix %{
      int hit_cmp_by_score(const void *a, const void *b) 
      { 
        hit *ia = (hit *) a;
        hit *ib = (hit *) b;

        return (int) (1000 * ib->score - 1000 * ia->score);
      } 
    }

    # Given a sorted unsigned integer removes all duplicate values
    # and move the unique values to the front of the array. Returns
    # the new size of the array.
    builder.prefix %{
      unsigned int uniq_ary(unsigned int *ary, unsigned int ary_size) 
      { 
        unsigned int new_ary_size = 0;
        unsigned int i            = 0;
        unsigned int j            = 0;

        for (i = 1; i < ary_size; i++) 
        { 
          if (ary[i] != ary[j]) 
          { 
            j++; 
            ary[j] = ary[i]; // Move it to the front 
          } 
        } 

        new_ary_size = j + 1;

        return new_ary_size;
      }
    }

    # Method that given a byte array and its size in bytes
    # sets all bytes to 0.
    builder.c %{
      void zero_ary_c(
        VALUE _ary,       // Byte array to zero.
        VALUE _ary_size   // Size of array.
      )
      {
        char         *ary      = (char *) StringValuePtr(_ary);
        unsigned int  ary_size = FIX2UINT(_ary_size);

        bzero(ary, ary_size);
      }
    }

    # Method to sort array of hits according to q_index.
    builder.c %{
      void sort_hits_c(
        VALUE _ary,       // Array of hits.
        VALUE _ary_size   // Size of array.
      )
      {
        hit          *ary      = (hit *) StringValuePtr(_ary);
        unsigned int  ary_size = FIX2UINT(_ary_size);

        qsort(ary, ary_size, sizeof(hit), hit_cmp_by_q_index);
      }
    }

    # Method that given a string (char array) encodes all kmers overlapping
    # with a given step size as integers that are saved in an unsigned integer
    # array. Then the array is sorted and uniq'ed and the number of unique
    # elements is returned.
    builder.c %{
      VALUE str_to_oligo_ary_c(
        VALUE _str,        // DNA or RNA string.
        VALUE _str_size,   // String length.
        VALUE _ary,        // Array to store result in.
        VALUE _kmer,       // Size of kmers/oligos.
        VALUE _step        // Step size for overlapping kmers.
      )
      {
        char *str               = StringValuePtr(_str);
        unsigned int   str_size = FIX2UINT(_str_size);
        unsigned int  *ary      = (unsigned int *) StringValuePtr(_ary);
        unsigned int   kmer     = FIX2UINT(_kmer);
        unsigned int   step     = FIX2UINT(_step);
        
        unsigned int ary_size = 0;
        unsigned int mask     = (1 << (2 * kmer)) - 1;
        unsigned int bin      = 0;
        unsigned int i        = 0;

        for (i = 0; i < kmer; i++)
        {
          bin <<= 2;
          bin |= oligo_map[str[i]];
        }

        ary[ary_size++] = bin;

        for (i = kmer; i < str_size; i++)
        {
          bin <<= 2;
          bin |= oligo_map[str[i]];

          if ((i % step) == 0) {
            ary[ary_size++] = (bin & mask);
          }
        }

        qsort(ary, ary_size, sizeof(unsigned int), uint_cmp);
        ary_size = uniq_ary(ary, ary_size);

        return UINT2NUM(ary_size);
      }
    }

    # Method that given a string (char array) encodes all kmers overlapping
    # with a given step size as integers that are pushed onto a Ruby array
    # which is returned.
    # TODO should have an option for skipping oligos with ambiguity codes.
    builder.c %{
      VALUE str_to_oligo_rb_ary_c(
        VALUE _str,    // DNA or RNA string.
        VALUE _kmer,   // Size of kmer or oligo.
        VALUE _step    // Step size for overlapping kmers.
      )
      {
        char         *str   = StringValuePtr(_str);
        unsigned int  kmer  = FIX2UINT(_kmer);
        unsigned int  step  = FIX2UINT(_step);
        
        VALUE         array = rb_ary_new();
        long          len   = strlen(str);
        unsigned int  mask  = (1 << (2 * kmer)) - 1;
        unsigned int  bin   = 0;
        unsigned int  i     = 0;

        for (i = 0; i < kmer; i++)
        {
          bin <<= 2;
          bin |= oligo_map[str[i]];
        }

        rb_ary_push(array, INT2FIX(bin));

        for (i = kmer; i < len; i++)
        {
          bin <<= 2;
          bin |= oligo_map[str[i]];

          if ((i % step) == 0) {
            rb_ary_push(array, INT2FIX((bin & mask)));
          }
        }

        return array;
      }
    }

    # Method that counts all shared oligos/kmers between a subject sequence and
    # all query sequences. For each oligo in the subject sequence (s_ary) the
    # index of all query sequences containing this oligo is found for the q_ary
    # where this information is stored sequentially in intervals. For the
    # particula oligo the interval is looked up in the q_beg and q_end arrays.
    # Shared oligos are recorded in the shared_ary.
    builder.c %{
      void count_shared_c(
        VALUE _q_ary,        // Lookup array with q_index lists.
        VALUE _q_begs_ary,   // Lookup array with interval begins of q_index lists.
        VALUE _q_ends_ary,   // Lookup array with interval ends of q_index lists.
        VALUE _s_ary,        // Subject sequence oligo array.
        VALUE _s_ary_size,   // Subject sequence oligo array size.
        VALUE _shared_ary    // Array with shared oligo counts.
      )
      {
        unsigned int *q_ary      = (unsigned int *) StringValuePtr(_q_ary);
        unsigned int *q_begs_ary = (unsigned int *) StringValuePtr(_q_begs_ary);
        unsigned int *q_ends_ary = (unsigned int *) StringValuePtr(_q_ends_ary);
        unsigned int *s_ary      = (unsigned int *) StringValuePtr(_s_ary);
        unsigned int  s_ary_size = FIX2UINT(_s_ary_size);
        unsigned int *shared_ary = (unsigned int *) StringValuePtr(_shared_ary);

        unsigned int oligo = 0;
        unsigned int s     = 0;
        unsigned int q     = 0;
        unsigned int q_beg = 0;
        unsigned int q_end = 0;

        for (s = 0; s < s_ary_size; s++)  // each oligo do
        {
          oligo = s_ary[s];

          q_beg = q_begs_ary[oligo];
          q_end = q_ends_ary[oligo];

          for (q = q_beg; q < q_end; q++)
          {
            shared_ary[q_ary[q]]++;
          }
        }
      }
    }

    # Method to calculate the score for all query vs subject sequence comparisons.
    # The score is calculated as the number of unique shared oligos divided by the 
    # smallest number of unique oligos in either the subject or query sequence.
    # Only scores greater than or equal to a given minimum is stored in the hit
    # array and the size of the hit array is returned.
    builder.c %{
      VALUE calc_scores_c(
        VALUE _q_total_ary,    // Lookup array with total oligo counts.
        VALUE _shared_ary,     // Lookup arary with shared oligo counts.
        VALUE _q_size,         // Number of query sequences.
        VALUE _s_count,        // Number of unique oligos in subject sequence.
        VALUE _hit_ary,        // Result array.
        VALUE _hit_ary_size,   // Result array size.
        VALUE _s_index,        // Subject sequence index.
        VALUE _min_score       // Minimum score to include.
      )
      {
        unsigned int *q_total_ary  = (unsigned int *) StringValuePtr(_q_total_ary);
        unsigned int *shared_ary   = (unsigned int *) StringValuePtr(_shared_ary);
        unsigned int  q_size       = FIX2UINT(_q_size);
        unsigned int  s_count      = FIX2UINT(_s_count);
        hit          *hit_ary      = (hit *) StringValuePtr(_hit_ary);
        unsigned int  hit_ary_size = FIX2UINT(_hit_ary_size);
        unsigned int  s_index      = FIX2UINT(_s_index);
        float         min_score    = (float) NUM2DBL(_min_score);

        unsigned int  q_index      = 0;
        unsigned int  q_count      = 0;
        unsigned int  shared_count = 0;
        unsigned int  total_count  = 0;
        float         score        = 0;
        hit           new_score    = {0, 0, 0};

        for (q_index = 0; q_index < q_size; q_index++)
        {
          shared_count = shared_ary[q_index];
          q_count      = q_total_ary[q_index];
          total_count  = (s_count < q_count) ? s_count : q_count;

          score = shared_count / (float) total_count;

          if (score >= min_score)
          {
            new_score.q_index = q_index;
            new_score.s_index = s_index;
            new_score.score   = score;

            hit_ary[hit_ary_size] = new_score;

            hit_ary_size++;
          }
        }

        return UINT2NUM(hit_ary_size);  
      }
    }
    
    # Method that fetches all hits matching a given q_index value 
    # from the result_ary. Since the result_ary is sorted according
    # to q_index we start at a given hit_index and fetch until
    # the next hit with a different q_index. The fetched hits are
    # stored in an array which is sorted according to decreasing 
    # score. The size of this array is returned.
    builder.c %{
      VALUE get_hits_c(
        VALUE _result_ary,        // Result array
        VALUE _result_ary_size,   // Result array size
        VALUE _hit_index,         // Offset position in hit_ary to search from.
        VALUE _hit_ary,           // Array to store hits in.
        VALUE _q_index)           // q_index to fetch.
      {
        hit          *result_ary      = (hit *) StringValuePtr(_result_ary);
        unsigned int  result_ary_size = FIX2UINT(_result_ary_size);
        unsigned int  hit_index       = FIX2UINT(_hit_index);
        hit          *hit_ary         = (hit *) StringValuePtr(_hit_ary);
        unsigned int  q_index         = FIX2UINT(_q_index);
        hit           new_hit         = {0, 0, 0};
        unsigned int  hit_ary_size    = 0;
      
        while ((hit_index + hit_ary_size) < result_ary_size)
        {
          new_hit = result_ary[hit_index + hit_ary_size];

          if (new_hit.q_index == q_index)
          {
            hit_ary[hit_ary_size] = new_hit;

            hit_ary_size++;
          }
          else
          {
            break;
          }
        }

        qsort(hit_ary, hit_ary_size, sizeof(hit), hit_cmp_by_score);

        return UINT2NUM(hit_ary_size);
      }
    }
  end

  # >>>>>>>>>>>>>>> Embedded classes <<<<<<<<<<<<<<<

  # Class for holding score information.
  class Hit
    attr_reader :q_id, :s_id, :score

    # Method to initialize Hit object with
    # query and subject id a score.
    def initialize(q_id, s_id, score)
      @q_id  = q_id
      @s_id  = s_id
      @score = score
    end

    # Method for outputting score objects.
    def to_s
      "#{@q_id}:#{@s_id}:#{@score.round(2)}"
    end

    # Method to convert to a Biopiece record.
    def to_bp
      hash = {}
      hash[:REC_TYPE] = "findsim"
      hash[:Q_ID]     = @q_id
      hash[:S_ID]     = @s_id
      hash[:SCORE]    = @score.round(2)

      hash
    end
  end
end

__END__
