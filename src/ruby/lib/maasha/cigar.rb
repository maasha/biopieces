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

# Methods to handle extended CIGAR format used in the
# SAM format version v1.4-r962 - April 17, 2011

# http://samtools.sourceforge.net/SAM1.pdf

# Error class for all exceptions to do with CIGAR.
class CigarError < StandardError; end

# Class to manipulate CIGAR strings.
class Cigar
  attr_accessor :cigar

  # Method to initialize a CIGAR string.
  def initialize(cigar)
    @cigar = cigar

    check_cigar
  end

  # Method to convert the CIGAR string to
  # a printable string.
  def to_s
    @cigar
  end

  # Method to iterate over the length and operators
  # in a CIGAR string.
  def each
    cigar.scan(/(\d+)([MIDNSHPX=])/).each do |len, op|
      yield [len.to_i, op]
    end
  end

  # Method to return the number length of
  # the residues described in the CIGAR string.
  # This length should match the length of the
  # aligned sequence.
  def length
    total = 0

    self.each do |len, op|
      total += len unless op == 'I'
    end

    total
  end

  # Method to return the number of matched
  # residues in the CIGAR string.
  def matches
    total = 0

    self.each do |len, op|
      total += len if op == 'M'
    end

    total
  end

  # Method to return the number of inserted
  # residues in the CIGAR string.
  def insertions
    total = 0

    self.each do |len, op|
      total += len if op == 'I'
    end

    total
  end

  # Method to return the number of deleted
  # residues in the CIGAR string.
  def deletions
    total = 0

    self.each do |len, op|
      total += len if op == 'D'
    end

    total
  end

  # Method to return the number of hard clipped
  # residues in the CIGAR string.
  def clip_hard
    total = 0

    self.each do |len, op|
      total += len if op == 'H'
    end

    total
  end

  # Method to return the number of soft clipped
  # residues in the CIGAR string.
  def clip_soft
    total = 0

    self.each do |len, op|
      total += len if op == 'S'
    end

    total
  end

  private

  # Method to check that the CIGAR string is formatted
  # correctly, including hard clipping and soft clipping
  # that cant be located internally.
  def check_cigar
    unless  cigar =~ /^(\*|([0-9]+[MIDNSHPX=])+)$/
      raise CigarError, "Bad cigar format: #{cigar}"
    end

    if cigar.gsub(/^[0-9]+H|[0-9]+H$/, "").match('H')
      raise CigarError, "Bad cigar with internal H: #{cigar}"
    end

    if cigar.gsub(/^[0-9]+H|[0-9]+H$/, "").gsub(/^[0-9]+S|[0-9]+S$/, "").match('S')
      raise CigarError, "Bad cigar with internal S: #{cigar}"
    end
  end
end
