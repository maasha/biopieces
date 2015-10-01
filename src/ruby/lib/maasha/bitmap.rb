# Copyright (C) 2012 Martin A. Hansen.

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

CHAR_BIT      = 8    # This is not guaranteed! FIXME
BITS_PER_WORD = 64   # This is not portable!   FIXME

# Error class for all exceptions to do with BitMap.
class BitMapError < StandardError; end

# Bitmap - 13 columns, 3 rows:
# 1000000000000
# 0000001000000
# 0000000000001
class BitMap
  attr_reader :cols, :rows, :map, :width

  # Method to initialize a BitMap.
  def initialize(cols, rows)
    @cols  = cols
    @rows  = rows
    @pads  = pad_init
    @width = @cols + @pads
    @map   = map_init
  end

  # Method that set bits to 1 at specified columns, and rows.
  # Usage: set(1, 4)
  #        set(true, 4)
  #        set([0, 4, 5], true)
  #        set([0 .. 4], true)
  # TODO:  set(-1, true)
  # TODO:  set([1 .. -2], true)
  def set(cols, rows)
    cols = cols_expand(cols)
    rows = rows_expand(rows)

    set_c(@map, @width, cols, rows)
  end

  # Method that set bits to 0 at specified columns, and rows.
  # Usage: unset(1, 4)
  #        unset(true, 4)
  #        unset([0, 4, 5], true)
  #        unset([0 .. 4], true)
  # TODO:  unset(-1, true)
  # TODO:  unset([1 .. -2], true)
  def unset(cols, rows)
    cols = cols_expand(cols)
    rows = rows_expand(rows)

    unset_c(@map, @width, cols, rows)
  end

  def sum
    size = @rows * @width / BITS_PER_WORD
    sum_c(@map, size)
  end

  def sum_rows
    sum_rows_c(@map, @width, rows)
  end

  # Method to get a slice from a bitmap from specified rows and columns,
  # and return this slice as a new BitMap object.
  # Usage: slice(1, 4)
  #        slice(true, 4)
  #        slice([0, 4, 5], true)
  #        slice([0 .. 4], true)
  # TODO:  slice(-1, true)
  # TODO:  slice([1 .. -2], true)
  def slice(cols, rows)
    cols = cols_expand(cols)
    rows = rows_expand(rows)
    bm   = BitMap.new(cols.size, rows.size)

    slice_c(@map, @width, bm.map, bm.width, cols, rows)

    bm
  end

  # Method that performs bit wise and operation between:
  #   1: an entire bit map.
  #   2: a bit map row.
  #   3: a bit map column.
  # The result is saved in self.
  def &(bit_map)
    bm = BitMap.new(@cols, @rows)

    if @rows == bit_map.rows and @cols == bit_map.cols
      raise # TODO
      bitwise_and_c()
    elsif @rows == bit_map.rows
      raise # TODO
      bitwise_and_col_c()
    elsif @cols == bit_map.cols
      bitwise_and_row_c(@map, bm.map, bit_map.map, @width, @rows)
    else
      raise BitMapError, "can't & uneven bit maps: #{@rows} x #{@cols} & #{bit_map.rows} x #{bit_map.cols}"
    end

    bm
  end

  def set?(c, r)
    btest_c(@map, @width, c, r)
  end

  # Method to convert a bit array to a string.
  def to_s
    max_rows = 20
    max_cols = 60
    rows     = []

    (0 ... @rows).each do |r|
      row = ""
      (0 ... @cols).each do |c|
        if set?(c, r)
          row << "1"
        else
          row << "0"
        end
      end

      if @cols > max_cols
        row = row[0 ... max_cols] + " ... (#{@cols})"
      end

      if rows.size > max_rows
        rows << "..."
        rows << "(#{@rows})"
        break
      end

      rows << row
    end

    rows.join($/)
  end

  private

  def pad_init
    if (@cols % BITS_PER_WORD) != 0
      pads = BITS_PER_WORD - (@cols % BITS_PER_WORD)
    else
      pads = 0
    end

    pads
  end

  # Method to initialize a block of memory holding a bitmap.
  # The block will be initialized as a zeroed Ruby string, but
  # will be padded with 0's so that each row is a multiplum of
  # BITS_PER_WORD - which is 64 or 32 bits.
  def map_init
    size = @rows * @width / CHAR_BIT

    "\0" * size
  end

  def rows_expand(rows)
    if rows.is_a? Fixnum
      rows = [rows]
    elsif rows == true
      rows = (0 ... @rows).to_a
    elsif rows.is_a? Array and rows.first.is_a? Range
      rows = rows.first.to_a
      rows = [0] if rows.empty? # FIXME
    end

    raise BitMapError, "row outside bitmap: #{rows.first}" if rows.first < 0
    raise BitMapError, "row outside bitmap: #{rows.last}"  if rows.last  >= @rows

    rows
  end

  def cols_expand(cols)
    if cols.is_a? Fixnum
      cols = [cols]
    elsif cols == true
      cols = (0 ... @cols).to_a
    elsif cols.is_a? Array and cols.first.is_a? Range
      cols = cols.first.to_a
    end

    raise BitMapError, "column outside bitmap: #{cols.first}" if cols.first < 0
    raise BitMapError, "column outside bitmap: #{cols.last}"  if cols.last  >= @cols

    cols
  end

  inline do |builder|
    builder.add_static "rows",       'rb_intern("@rows")',       "ID"
    builder.add_static "cols",       'rb_intern("@cols")',       "ID"
    builder.add_static "byte_array", 'rb_intern("@byte_array")', "ID"

    # New
    builder.prefix %s{
      typedef uint64_t word_t;
    }

    # New
    builder.prefix %s{
      enum { BITS_PER_WORD = sizeof(word_t) * CHAR_BIT };
    }

    # New
    builder.prefix %s{
      #define WORD_OFFSET(b) ((b) / BITS_PER_WORD)
    }

    # New
    builder.prefix %s{
      #define BIT_OFFSET(b)  ((b) % BITS_PER_WORD)
    }

    # Method to count all set bits in an unsigned long int (64 bits)
    # based on a variant of pop_count optimal for bits with most 0 
    # bits set.
    builder.prefix %{
      int count_bits_c(word_t x) {
        int count;

        for (count = 0; x; count++)
          x &= x - 1;

        return count;
      }
    }

    # New
    builder.prefix %{
      void bit_set_c(word_t *map, int pos) { 
        map[WORD_OFFSET(pos)] |= (1 << BIT_OFFSET(pos));
      }
    }

    # New
    builder.prefix %{
      void bit_unset_c(word_t *map, int pos) { 
        map[WORD_OFFSET(pos)] &= ~(1 << BIT_OFFSET(pos));
      }
    }

    builder.c %{
      void set_c(VALUE _map, VALUE _width, VALUE _cols_ary, VALUE _rows_ary)
      {
        word_t *map          = (word_t *) StringValuePtr(_map);
        int     width        = NUM2INT(_width);
        VALUE  *cols_ary     = RARRAY_PTR(_cols_ary);
        VALUE  *rows_ary     = RARRAY_PTR(_rows_ary);
        int     col_ary_size = (int) RARRAY_LEN(_cols_ary);
        int     row_ary_size = (int) RARRAY_LEN(_rows_ary);
        int     c            = 0;
        int     r            = 0;
        int     pos          = 0;

        for (r = 0; r < row_ary_size; r++)
        {
          for (c = 0; c < col_ary_size; c++)
          {
            pos = NUM2INT(rows_ary[r]) * width + NUM2INT(cols_ary[c]);

            bit_set_c(map, pos);
          }
        }
      }
    }

    builder.c %{
      void unset_c(VALUE _map, VALUE _width, VALUE _cols_ary, VALUE _rows_ary)
      {
        word_t *map           = (word_t *) StringValuePtr(_map);
        int     width         = NUM2INT(_width);
        VALUE  *cols_ary      = RARRAY_PTR(_cols_ary);
        VALUE  *rows_ary      = RARRAY_PTR(_rows_ary);
        int     cols_ary_size = (int) RARRAY_LEN(_cols_ary);
        int     rows_ary_size = (int) RARRAY_LEN(_rows_ary);
        int     c             = 0;
        int     r             = 0;
        int     pos           = 0;

        for (r = 0; r < rows_ary_size; r++)
        {
          for (c = 0; c < cols_ary_size; c++)
          {
            pos = NUM2INT(rows_ary[r]) * width + NUM2INT(cols_ary[c]);

            bit_unset_c(map, pos);
          }
        }
      }
    }

    # New
    builder.prefix %{
      int bit_test_c(word_t* map, int pos)
      {
        word_t bit = map[WORD_OFFSET(pos)] & (1 << BIT_OFFSET(pos));

        return bit != 0; 
      }
    }

    # New
    builder.c %{
      VALUE btest_c(VALUE _map, VALUE _width, VALUE _col, VALUE _row)
      {
        word_t *map   = (word_t*) StringValuePtr(_map);
        int     width = NUM2INT(_width);
        int     col   = NUM2INT(_col);
        int     row   = NUM2INT(_row);
        int     pos   = row * width + col;

        return bit_test_c(map, pos);
      }
    }

    builder.c %{
      void slice_c(VALUE _old_map, VALUE _old_width, VALUE _new_map, VALUE _new_width, VALUE _cols_ary, VALUE _rows_ary)
      {
        word_t *old_map       = (word_t*) StringValuePtr(_old_map);
        int     old_width     = NUM2INT(_old_width);
        word_t *new_map       = (word_t*) StringValuePtr(_new_map);
        int     new_width     = NUM2INT(_new_width);
        VALUE  *cols_ary      = RARRAY_PTR(_cols_ary);
        VALUE  *rows_ary      = RARRAY_PTR(_rows_ary);
        int     cols_ary_size = (int) RARRAY_LEN(_cols_ary);
        int     rows_ary_size = (int) RARRAY_LEN(_rows_ary);
        int     old_pos       = 0;
        int     new_pos       = 0;
        int     c             = 0;
        int     r             = 0;

        for (r = 0; r < rows_ary_size; r++)
        {
          for (c = 0; c < cols_ary_size; c++)
          {
            old_pos = NUM2INT(rows_ary[r]) * old_width + NUM2INT(cols_ary[c]);

            if (bit_test_c(old_map, old_pos))
            {
              new_pos = r * new_width + c;
              bit_set_c(new_map, new_pos);
            }
          }
        }
      }
    }

    builder.c %{
      void bitwise_and_row_c(VALUE _old_map, VALUE _new_map, VALUE _row_map, VALUE _width, VALUE _rows)
      {
        word_t *old_map = (word_t*) StringValuePtr(_old_map);
        word_t *new_map = (word_t*) StringValuePtr(_new_map);
        word_t *row_map = (word_t*) StringValuePtr(_row_map);
        int     width   = NUM2INT(_width);
        int     rows    = NUM2INT(_rows);
        int     size    = width / BITS_PER_WORD;
        int     c       = 0;
        int     r       = 0;

        for (r = 0; r < rows; r++)
        {
          for (c = 0; c < size; c++) {
            new_map[r * size + c] = old_map[r * size + c] & row_map[c];
          }
        }
      }
    }

    builder.c %{
      VALUE sum_c(VALUE _map, VALUE _size)
      {
        word_t *map  = (word_t*) StringValuePtr(_map);
        int     size = NUM2INT(_size);
        int     i    = 0;
        int     sum  = 0;

        for (i = 0; i < size; i++)
          sum += count_bits_c(map[i]);

        return INT2NUM(sum);
      }
    }

    builder.c %{
      VALUE sum_rows_c(VALUE _map, VALUE _width, VALUE _rows)
      {
        word_t *map   = (word_t*) StringValuePtr(_map);
        int     width = NUM2INT(_width);
        int     rows  = NUM2INT(_rows);
        int     r     = 0;
        int     c     = 0;
        int     sums[rows];
        VALUE   sums_ary = rb_ary_new();
        int     size  = width / BITS_PER_WORD;
        int     pos   = 0;

        for (r = 0; r < rows; r++) sums[r] = 0;

        for (r = 0; r < rows; r++)
        {
          for (c = 0; c < size; c++) {
            pos = r * size + c;

            sums[r] += count_bits_c(map[pos]);
          }
        }

        for (r = 0; r < rows; r++) rb_ary_push(sums_ary, INT2FIX(sums[r]));
      
        return sums_ary;
      }
    }
  end
end
