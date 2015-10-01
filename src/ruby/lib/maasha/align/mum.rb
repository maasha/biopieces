#!/usr/bin/env ruby

require 'inline'
require 'maasha/seq'
require 'pp'
#require 'profile'

BYTES_IN_BIN   = 4
BYTES_IN_POS   = 4
BYTES_IN_OLIGO = BYTES_IN_BIN + BYTES_IN_POS

class MUMs
  include Enumerable

  def self.find(q_seq, s_seq, space, kmer_size)
    m = self.new(q_seq, s_seq, space, kmer_size)
    m.to_a
  end

  def initialize(q_seq, s_seq, space, kmer_size)
    q_space_beg = space.q_min
    q_space_end = space.q_max
    s_space_beg = space.s_min
    s_space_end = space.s_max

    @mums = []

    q_index = Index.new(q_space_beg, q_space_end, q_seq.seq, kmer_size, kmer_size)
    s_index = Index.new(s_space_beg, s_space_end, s_seq.seq, kmer_size, 1)

    find_mums(q_index, s_index, kmer_size)

    @mums.each do |match|
      match.expand(q_seq.seq, s_seq.seq, q_space_beg, q_space_end, s_space_beg, s_space_end)
    end
  end

  def each
    @mums.each do |match|
      yield match
    end
  end

  private

  def find_mums(q_index, s_index, kmer_size)
    q_index.each do |q_oligo|
      if s_pos = s_index[q_oligo]
        q_pos = q_oligo.unpack("II").last

        last_match = @mums.last
        new_match  = Match.new(q_pos, s_pos, kmer_size)

        if last_match and
           last_match.q_beg + last_match.length == new_match.q_beg and
           last_match.s_beg + last_match.length == new_match.s_beg

           last_match.length += kmer_size
        else
          @mums << new_match
        end
      end
    end
  end

  class Index
    def initialize(space_beg, space_end, seq, kmer_size, step_size)
      index_size = (space_end - space_beg) * BYTES_IN_OLIGO
      index      = "\0" * index_size
      index_size = create_index_C(space_beg, space_end, seq, kmer_size, step_size, index)
      sort_by_oligo_C(index, index_size)
      @index_size = uniq_oligo_C(index, index_size)

      @index = index[0 ... @index_size * BYTES_IN_OLIGO]
    end

    def each
      (0 ... @index_size - 1).each do |i|
        yield @index[BYTES_IN_OLIGO * i ... BYTES_IN_OLIGO * i + BYTES_IN_OLIGO]
      end
    end

    def [](oligo)
      search_index_C(@index, @index_size, oligo)
    end

    private

    inline do |builder|
      builder.prefix %{
        unsigned char nuc2bin[256] = {
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

      builder.prefix %{
        typedef struct 
        {
          unsigned int bin;
          unsigned int pos;
        } oligo;
      }

      builder.prefix %{
        int oligo_cmp(const void *a, const void *b) 
        { 
          oligo *ia = (oligo *) a;
          oligo *ib = (oligo *) b;

          return (int) (ia->bin - ib->bin);
        } 
      }

      builder.c %{
        VALUE create_index_C(
          VALUE _space_beg,
          VALUE _space_end,
          VALUE _seq,
          VALUE _kmer_size,
          VALUE _step_size,
          VALUE _index
        )
        {
          unsigned int   space_beg = NUM2UINT(_space_beg);
          unsigned int   space_end = NUM2UINT(_space_end);
          unsigned char *seq       = (unsigned char *) StringValuePtr(_seq);
          unsigned int   kmer_size = NUM2UINT(_kmer_size);
          unsigned int   step_size = NUM2UINT(_step_size);
          oligo         *index     = (oligo *) StringValuePtr(_index);

          oligo        new  = {0, 0};
          unsigned int mask = (1 << (2 * kmer_size)) - 1;
          unsigned int bin  = 0;
          unsigned int size = 0;
          unsigned int i    = 0;

          for (i = space_beg; i < space_beg + kmer_size; i++)
          {
            bin <<= 2;
            bin |= nuc2bin[seq[i]];
          }

          new.bin       = bin;
          new.pos       = i - kmer_size;
          index[size++] = new;

          while (i <= space_end)
          {
            bin <<= 2;
            bin |= nuc2bin[seq[i]];

            i++;

            if ((i % step_size) == 0) {
              new.bin       = (bin & mask);
              new.pos       = i - kmer_size;
              index[size++] = new;
            }
          }

          return UINT2NUM(size);
        }
      }

      builder.c %{
        void sort_by_oligo_C(
          VALUE _index,
          VALUE _index_size
        )
        {
          oligo        *index      = (oligo *) StringValuePtr(_index);
          unsigned int  index_size = NUM2UINT(_index_size);
        
          qsort(index, index_size, sizeof(oligo), oligo_cmp);
        }
      } 

      builder.c %{
        VALUE uniq_oligo_C(
          VALUE _index,
          VALUE _index_size
        )
        { 
          oligo        *index      = (oligo *) StringValuePtr(_index);
          unsigned int  index_size = NUM2UINT(_index_size);

          unsigned int  new_index_size = 0;
          unsigned int  i              = 0;
          unsigned int  j              = 0;

          for (i = 1; i < index_size; i++) 
          { 
            if (index[i].bin != index[j].bin) 
            { 
              j++; 
              index[j] = index[i]; // Move it to the front 
            } 
          } 

          new_index_size = j + 1;

          return UINT2NUM(new_index_size);
        }
      }

      builder.c %{
        VALUE search_index_C(
          VALUE _index,
          VALUE _index_size,
          VALUE _item
        )
        {
          oligo        *index      = (oligo *) StringValuePtr(_index);
          unsigned int  index_size = NUM2UINT(_index_size);
          oligo        *item       = (oligo *) StringValuePtr(_item);
          oligo        *result     = NULL;
          
          result = (oligo *) bsearch(item, index, index_size, sizeof(oligo), oligo_cmp);
        
          if (result == NULL)
            return Qfalse;
          else
            return UINT2NUM(result->pos);
        }
      }
    end
  end

  class Match
    attr_accessor :length, :score
    attr_reader :q_beg, :s_beg

    def initialize(q_beg, s_beg, length)
      @q_beg  = q_beg
      @s_beg  = s_beg
      @length = length
      @score  = 0.0
    end

    def q_end
      @q_beg + @length - 1
    end

    def s_end
      @s_beg + @length - 1
    end

    # Method to expand a match as far as possible to the left and right
    # within a given search space.
    def expand(q_seq, s_seq, q_space_beg, q_space_end, s_space_beg, s_space_end)
      length = expand_left_C(q_seq, s_seq, @q_beg, @s_beg, q_space_beg, s_space_beg)
      @length += length
      @q_beg  -= length
      @s_beg  -= length
  
      length = expand_right_C(q_seq, s_seq, q_end, s_end, q_space_end, s_space_end)
      @length += length
    end

    private

    # Method to expand a match as far as possible to the right within a given
    # search space.
    def expand_right(q_seq, s_seq, q_space_end, s_space_end)
      while q_end + 1 <= q_space_end and s_end + 1 <= s_space_end and q_seq[q_end + 1] == s_seq[s_end + 1]
        @length += 1
      end
    end

    inline do |builder|
      # Method to expand a match as far as possible to the left within a given
      # search space.
      builder.c %{
        VALUE expand_left_C(
          VALUE _q_seq,
          VALUE _s_seq,
          VALUE _q_beg,
          VALUE _s_beg,
          VALUE _q_space_beg,
          VALUE _s_space_beg
        )
        {
          unsigned char *q_seq       = (unsigned char *) StringValuePtr(_q_seq);
          unsigned char *s_seq       = (unsigned char *) StringValuePtr(_s_seq);
          unsigned int   q_beg       = NUM2UINT(_q_beg);
          unsigned int   s_beg       = NUM2UINT(_s_beg);
          unsigned int   q_space_beg = NUM2UINT(_q_space_beg);
          unsigned int   s_space_beg = NUM2UINT(_s_space_beg);

          unsigned int   len = 0;
        
          while (q_beg > q_space_beg && s_beg > s_space_beg && q_seq[q_beg - 1] == s_seq[s_beg - 1])
          {
            q_beg--;
            s_beg--;
            len++;
          }

          return UINT2NUM(len);
        }
      }

      builder.c %{
        VALUE expand_right_C(
          VALUE _q_seq,
          VALUE _s_seq,
          VALUE _q_end,
          VALUE _s_end,
          VALUE _q_space_end,
          VALUE _s_space_end
        )
        {
          unsigned char *q_seq       = (unsigned char *) StringValuePtr(_q_seq);
          unsigned char *s_seq       = (unsigned char *) StringValuePtr(_s_seq);
          unsigned int   q_end       = NUM2UINT(_q_end);
          unsigned int   s_end       = NUM2UINT(_s_end);
          unsigned int   q_space_end = NUM2UINT(_q_space_end);
          unsigned int   s_space_end = NUM2UINT(_s_space_end);

          unsigned int   len = 0;
        
          while (q_end + 1 <= q_space_end && s_end + 1 <= s_space_end && q_seq[q_end + 1] == s_seq[s_end + 1])
          {
            q_end++;
            s_end++;
            len++;
          }

          return UINT2NUM(len);
        }
      }
    end
  end
end
