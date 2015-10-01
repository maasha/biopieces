# Copyright (C) 2007-2011 Martin A. Hansen.

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

require 'narray'
require 'pp'

BitsInChar = 8

# Error class for all exceptions to do with BitArray.
class BitArrayError < StandardError; end

# Class containing methods for creating and manipulating a bit array.
class BitArray
  attr_accessor :byte_array
  attr_reader   :size

  # Method to initialize a new bit array of a given size in bits.
  def initialize(size)
    @size        = size
    @byte_array  = init_byte_array
    @count_array = init_count_array
  end

  # Method that sets all bits in the bit array.
  def fill!
    self.byte_array.fill!(~0)

    self
  end

  # Method that unsets all bits in the bit array.
  def clear!
    self.byte_array.fill!(0)

    self
  end

  # Method to set a bit to 1 at a given position in the bit array.
  def bit_set(pos)
    raise BitArrayError, "Position #{pos} must be an integer."                  unless pos.is_a? Fixnum
    raise BitArrayError, "Position #{pos} outside of range: 0 ... #{@size - 1}" unless (0 ... @size ).include? pos

    @byte_array[byte_pos(pos)] = @byte_array[byte_pos(pos)] | bit_pos(pos)
  end

  # Method to set a bit to 0 at a given position in the bit array.
  def bit_unset(pos)
    raise BitArrayError, "Position #{pos} must be an integer."                  unless pos.is_a? Fixnum
    raise BitArrayError, "Position #{pos} outside of range: 0 ... #{@size - 1}" unless (0 ... @size ).include? pos

    mask = bit_pos(pos)
    mask = ~mask

    @byte_array[byte_pos(pos)] = @byte_array[byte_pos(pos)] & mask
  end

  # Method to check if a bit at a given position in the bit array is set.
  def bit_set?(pos)
    raise BitArrayError, "Position #{pos} must be an integer."                  unless pos.is_a? Fixnum
    raise BitArrayError, "Position #{pos} outside of range: 0 ... #{@size - 1}" unless (0 ... @size ).include? pos

    (@byte_array[byte_pos(pos)] & bit_pos(pos)) != 0
  end

  # Method that returns the number of bits set "on" in a bit array.
  def bits_on
    index = NArray.sint(*self.byte_array.shape)
    index[] = self.byte_array
    NArray.to_na(@count_array)[index].sum
  end

  # Method that returns the number of bits set "off" in a bit array.
  def bits_off
    @size - bits_on
  end

  # Method to run bitwise AND (&) on two bit arrays and return the
  # result in the first bit array. Bits are copied if they exists in BOTH operands.
  # 00111100 & 00001101 = 00001100
  def &(ba)
    raise BitArrayError, "uneven size of bit arrays: #{self.size} != #{ba.size}" if self.size != ba.size

    self.byte_array = self.byte_array & ba.byte_array

    self
  end

  # Method to run bitwise OR (|) on two bit arrays and return the
  # result in the first bit array. Bits are copied if they exists in EITHER operands.
  # 00111100 | 00001101 = 00111101
  def |(ba)
    raise BitArrayError, "uneven size of bit arrays: #{self.size} != #{ba.size}" if self.size != ba.size

    self.byte_array = self.byte_array | ba.byte_array

    self
  end

  # Method to run bitwise XOR (^) on two bit arrays and return the
  # result in the first bit array. Bits are copied if they exists in ONE BUT NOT BOTH operands.
  # 00111100 ^ 00001101 = 00110001
  def ^(ba)
    raise BitArrayError, "uneven size of bit arrays: #{self.size} != #{ba.size}" if self.size != ba.size

    self.byte_array = self.byte_array ^ ba.byte_array

    self
  end

  # Method to flip all bits in a bit array. All set bits become unset and visa versa.
  def ~
    self.byte_array = ~(self.byte_array)

    self
  end

  # Method to convert a bit array to a string.
  def to_s
    string = ""

    (0 ... @size).each do |pos|
      if self.bit_set? pos 
        string << "1"
      else
        string << "0"
      end
    end

    string
  end

  alias :to_string :to_s

  # Method to set the bits to "on" in an interval in a bit array.
  # Returns the number of bits set.
  def interval_set(start, stop)
    raise BitArrayError, "interval start < 0 (#{start} < 0)"                               if start < 0
    raise BitArrayError, "interval stop > bit array size - 1 (#{stop} > #{self.size - 1})" if stop  > self.size - 1
    raise BitArrayError, "interval stop < interval start (#{stop} < #{start})"             if stop  < start

    byte_start = start / BitsInChar
    byte_stop  = stop  / BitsInChar

    bits_start = start % BitsInChar
    bits_stop  = stop  % BitsInChar

    mask = (2 ** BitsInChar) - 1  # 11111111
    
    if byte_start == byte_stop
      self.byte_array[byte_start] |= ((mask >> bits_start) & (mask << (BitsInChar - bits_stop - 1)))
    else
      if bits_start != 0
        self.byte_array[byte_start] |= (mask >> bits_start)
        byte_start += 1
      end

      self.byte_array[byte_stop] |= (mask << (BitsInChar - bits_stop - 1))

      if byte_start != byte_stop
        self.byte_array[byte_start ... byte_stop] = mask
      end
    end

    stop - start + 1
  end

  # Method to set the bits to "off" in an interval in a bit array.
  # Returns the number of bits unset.
  def interval_unset(start, stop)
    raise BitArrayError, "interval start < 0 (#{start} < 0)"                               if start < 0
    raise BitArrayError, "interval stop > bit array size - 1 (#{stop} > #{self.size - 1})" if stop  > self.size - 1
    raise BitArrayError, "interval stop < interval start (#{stop} < #{start})"             if stop  < start

    byte_start = start / BitsInChar
    byte_stop  = stop  / BitsInChar

    bits_start = start % BitsInChar
    bits_stop  = stop  % BitsInChar

    mask = (2 ** BitsInChar) - 1  # 11111111

    if byte_start == byte_stop
      self.byte_array[byte_start] &= ~((mask >> bits_start) & (mask << (BitsInChar - bits_stop - 1)))
    else
      if bits_start != 0
        self.byte_array[byte_start] &= ~(mask >> bits_start)
        byte_start += 1
      end

      self.byte_array[byte_stop] &= ~(mask << (BitsInChar - bits_stop - 1))

      if byte_start != byte_stop
        self.byte_array[byte_start ... byte_stop] = ~mask
      end
    end

    stop - start + 1
  end

  # Method to locate intervals of bits set to "on" in a bit array.
  #   BitArray.each_interval -> Array
  #   BitArray.each_interval { |start, stop| } -> Fixnum
  def each_interval
    intervals = []
    bit_start = 0
    bit_stop  = 0

    while bit_start < self.size
      bit_start += 1 while bit_start < self.size and not self.bit_set?(bit_start)

      if bit_start < self.size
        bit_stop = bit_start
        bit_stop  += 1 while bit_stop < self.size and self.bit_set?(bit_stop)

        if block_given?
          yield bit_start, bit_stop - 1
        else
          intervals << [bit_start, bit_stop - 1]
        end

        bit_start = bit_stop + 1
      end
    end

    return intervals unless block_given?
  end

  private

  # Method to initialize the byte array (string) that constitutes the bit array.
  def init_byte_array
    raise BitArrayError, "Size must be an integer, not #{@size}" unless @size.is_a? Fixnum
    raise BitArrayError, "Size must be positive, not #{@size}"   unless @size > 0

    NArray.byte(((@size - 1) / BitsInChar) + 1)
  end

  # Method that returns an array where the element index value is
  # the number of bits set for that index value.
  def init_count_array
    count_array = []

    (0 ... (2 ** BitsInChar)).each do |i|
      count_array << bits_in_char(i)
    end

    count_array
  end

  # Method that returns the number of set bits in a char.
  def bits_in_char(char)
    bits = 0

    (0 ... BitsInChar).each do |pos|
      bits += 1 if ((char & bit_pos(pos)) != 0)
    end

    bits
  end

  # Method that returns the byte position in the byte array for a given bit position.
  def byte_pos(pos)
    pos / BitsInChar
  end

  # Method that returns the bit position in a byte.
  def bit_pos(pos)
    1 << (BitsInChar - 1 - (pos % BitsInChar))
  end
end

