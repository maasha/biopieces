#!/usr/bin/env ruby

require 'maasha/align/match'

class Mem
  def self.find(q_seq, s_seq, kmer, q_space_beg, s_space_beg, q_space_end, s_space_end)
    m = self.new(q_seq, s_seq, kmer, q_space_beg, s_space_beg, q_space_end, s_space_end)
    m.find_mems
  end

  def initialize(q_seq, s_seq, kmer, q_space_beg, s_space_beg, q_space_end, s_space_end)
    @q_seq       = q_seq.downcase
    @s_seq       = s_seq.downcase
    @kmer        = kmer
    @q_space_beg = q_space_beg
    @s_space_beg = s_space_beg
    @q_space_end = q_space_end
    @s_space_end = s_space_end
  end

  def find_mems
    mask      = (1 << (2 * @kmer)) - 1;
    matches   = []
    pos_ary   = []
    map_ary   = []
    redundant = {}

    index_seq(@q_seq, @q_space_beg, @q_space_end, @kmer, pos_ary, map_ary)

    i   = @s_space_beg
    bin = 0

    while i < @s_space_beg + @kmer
      bin <<= 2

      case @s_seq[i]
      when 'a' then bin |= 0
      when 't' then bin |= 1
      when 'u' then bin |= 1
      when 'c' then bin |= 2
      when 'g' then bin |= 3
      else
        raise
      end

      i += 1
    end

    i =  @s_space_beg + @kmer

    while i <= @s_space_end
      pos = pos_ary[bin & mask]

      while pos
        match = Match.new(i - @kmer, pos, @kmer)

        unless redundant[match.q_beg * 1_000_000_000 + match.s_beg]
          match.expand(@q_seq, @s_seq, 0, 0, @q_seq.length - 1, @s_seq.length - 1)

          (0 ... match.length).each do |j|
            redundant[(match.q_beg + j) * 1_000_000_000 + match.s_beg + j] = true
          end

          matches << match
        end

        pos = map_ary[pos]
      end

      bin <<= 2

      case @s_seq[i]
      when 'a' then bin |= 0
      when 't' then bin |= 1
      when 'u' then bin |= 1
      when 'c' then bin |= 2
      when 'g' then bin |= 3
      else
        raise
      end

      i += 1
    end

    pos = pos_ary[bin & mask]

    while pos
      match = Match.new(i - @kmer, pos, @kmer)

      unless redundant[match.q_beg * 1_000_000_000 + match.s_beg]
        match.expand(@q_seq, @s_seq, 0, 0, @q_seq.length - 1, @s_seq.length - 1)

        (0 ... match.length).each do |j|
          redundant[(match.q_beg + j) * 1_000_000_000 + match.s_beg + j] = true
        end

        matches << match
      end

      pos = map_ary[pos]
    end

    matches
  end

  def index_seq(seq, start, stop, kmer, pos_ary, map_ary)
    bin  = 0
    mask = (1 << (2 * kmer)) - 1;

    i = start

    while i < start + kmer
      bin <<= 2

      case seq[i]
      when 'a' then bin |= 0
      when 't' then bin |= 1
      when 'u' then bin |= 1
      when 'c' then bin |= 2
      when 'g' then bin |= 3
      end

      i += 1
    end

    i = start + kmer

    while i <= stop
      key = bin & mask

      map_ary[i - kmer] = pos_ary[key]
      pos_ary[key]      = i - kmer

      bin <<= 2

      case seq[i]
      when 'a' then bin |= 0
      when 't' then bin |= 1
      when 'u' then bin |= 1
      when 'c' then bin |= 2
      when 'g' then bin |= 3
      else
        raise
      end

      i += 1
    end

    key = bin & mask

    map_ary[i - kmer] = pos_ary[key]
    pos_ary[key]      = i - kmer
  end
end


__END__
