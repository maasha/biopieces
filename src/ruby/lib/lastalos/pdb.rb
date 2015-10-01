#!/usr/bin/env ruby

# Copyright (C) 2014 Lukas Astalos.

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

# This program is part of the Biopieces framework (www.biopieces.org).

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



# PDB file indexes, see http://www.wwpdb.org/documentation/format33/v3.3.html
HEADER_IDCODE_START = 62
HEADER_IDCODE_END   = 65
ATOM_CHAIN_ID       = 21
ATOM_ALTLOC         = 16
ATOM_RESNAME_START  = 17
ATOM_RESNAME_END    = 19
ATOM_RESSEQ_START   = 22
ATOM_RESSEQ_END     = 25
ATOM_ICODE          = 26
SEQRES_CHAIN_ID     = 11
SEQRES_RESIDUE1     = 19
ATOM_ATMNAME_START  = 12
ATOM_ATMNAME_END    = 15
RECNAME_START      = 0
RECNAME_END        = 5

# Error class for all exceptions to do with Seq.
class SeqError < StandardError; end

class Pdb
	attr_accessor :type, :seq_name, :seq, :seq_chain, :coords

	def self.new_pdb(*args)
	    type      = "PDB".to_sym
	    seq_name  = args.shift
	    seq       = args.shift
	    seq_chain = args.shift
	    coords    = args.shift

	    self.new(type: type, seq_name: seq_name, seq: seq, seq_chain: seq_chain, coords: coords)
  	end

  	def initialize(options = {})
	    @type      = options[:type]
	    @seq_name  = options[:seq_name]
	    @seq       = options[:seq]
	    @seq_chain = options[:seq_chain]
	    @coords    = options[:coords]	    
	end

	def to_pdb
	    raise SeqError, "Missing seq_name" if self.seq_name.nil?
	    raise SeqError, "Missing seq"      if self.seq.nil?

	    record             = {}
	    record[:REC_TYPE] = self.type
	    record[:SEQ_NAME] = self.seq_name
	    record[:SEQ]      = self.seq
	    record[:SEQ_LEN]  = self.seq.length
	    record[:SEQ_CHAIN]   = self.seq_chain
	    record[:ATOM_COORD] = self.coords
	    record
	  end

end


def is_letter?(char)
  char =~ /[[:alpha:]]/
end

def normalize(m)	#create hash from missing residues	
	m.map do |line| 
		line.gsub!(/REMARK 465 */i, '').gsub!(/\s+$/,'')		
  	end  
  	# "REMARK 465     SER H   127A"  -->  "H 127A" => "SER"
  	missing_residues = Hash.new
  	m.each do |line|  		
  		key = line.match(/([[:alpha:]]|[[:digit:]]) +-?[[:digit:]]+[[:alpha:]]?$/)[0].gsub(/ +/,' ')  		
  		value = line.match(/^\w{1,3} /)[0].strip
  		missing_residues[key] = value
  	end  	
  	return missing_residues
end

def convert_acid (acid)	
	code = acid.gsub(/GLY|ALA|VAL|LEU|ILE|MET|PHE|TRP|PRO|SER|THR|CYS|TYR|ASN|GLN|ASP|GLU|LYS|ARG|HIS|UNK|DC|DA|DG|DT|DI|\
0A8|10C|1MA|1MG|2KK|2KP|DPN|2MG|3DR|5BU|5IU|5MC|5MU|DSN|6MZ|7MG|8AN|8FG|DPP|DPR|DVA|8OG|A23|A2L|A2M|A3P|A44|DOC|A5N|ABA|AEI|AIB|ALC|\
CXM|CY0|ALY|AZK|BB6|BB7|BB8|CSA|CSB|BB9|BMT|BRU|BZG|C2L|4IN|4FB|C3Y|CAF|CAS|CCC|CCS|TGP|TLN|CSD|CSO|CSP|CSS|CSX|SAR|SBL|CY3|CYD|DBB|\
DBU|DDG|TPO|TPQ|ESC|FAK|FGA|FGP|DHA|TQQ|TRN|FHU|FME|FZN|G2L|G48|GHP|CGU|GMU|GNE|GTP|H2U|HIA|SAC|SCH|HIC|HSE|HYP|IIL|IT1|KCX|SCS|KPI|\
LCA|LEF|LLP|LLY|SCY|SE7|LYX|M1G|M2G|M3L|MA7|TRO|TRQ|MEA|MEN|MHS|MIS|MK8|YG|YYG|MLE|MLY|MLZ|MSE|MSO|PTR|SEB|MTY|MVA|CME|T6A|TCQ|USM|\
YCM|NAL|NEP|NFA|NIY|TYS|U2L|U8U|NLE|NMM|NVA|O2G|OCS|TYI|TYO|OCY|OMC|OMG|OMT|ORN|TY2|TYB|PBF|PCA|PF5|PFF|PG1|SVV|T39|PHA|PHD|PHI|PRN|\
PSU|SPT|SRA|SEC|SEP|SMC|SME|SNC|SNN|TXY|MEQ|CYG|CR2|CRF|CRG|CRO|CRQ|MDO|NRQ|PIA|RC7|SUI|5ZA|FVA|DLE|PBT|A5M|GDP|MCY|BGM|6MA|D11|FMG|\
AFG|2DT|HSO|CBR|68Z|LYZ|TTD/, 
					"ALA" => 'A', "ARG" => 'R', "ASN" => 'N', "ASP" => 'D',
					"CYS" => 'C',
					"GLU" => 'E', "GLY" => 'G', "GLN" => 'Q',
					"HIS" => 'H',
					"ILE" => 'I',
					"LEU" => 'L', "LYS" => 'K',
					"MET" => 'M',
					"PHE" => 'F', "PRO" => 'P',
					"SER" => 'S',
					"THR" => 'T', "TRP" => 'W', "TYR" => 'Y',
					"UNK" => 'X',
					"VAL" => 'V',			  
					"DA"  => 'A', "DC"  => 'C', "DG"  => 'G', "DI"  => 'I', "DT"  => 'T',	# deoxy- forms					
					# modified residues, possible future updates
					"0A8" => 'C', "10C" => 'C', "1MA" => 'A', "1MG" => 'G', "2KK" => 'K', "2KP" => 'K', "DPN" => 'F',
					"2MG" => 'G', "3DR" => 'N', "5BU" => 'U', "5IU" => 'U', "5MC" => 'C', "5MU" => 'U', "DSN" => 'S',
					"6MZ" => 'N', "7MG" => 'G', "8AN" => 'A', "8FG" => 'G', "DPP" => 'A', "DPR" => 'P', "DVA" => 'V',
					"8OG" => 'G', "A23" => 'A', "A2L" => 'A', "A2M" => 'A', "A3P" => 'A', "A44" => 'A', "DOC" => 'C',
					"A5N" => 'N', "ABA" => 'A', "AEI" => 'D', "AIB" => 'A',	"ALC" => 'A', "CXM" => 'M', "CY0" => 'C',
					"ALY" => 'K', "AZK" => 'K', "BB6" => 'C', "BB7" => 'C',	"BB8" => 'F', "CSA" => 'C', "CSB" => 'C',
					"BB9" => 'C', "BMT" => 'T', "BRU" => 'U', "BZG" => 'N',	"C2L" => 'C', "4IN" => 'W', "4FB" => 'P',
					"C3Y" => 'C', "CAF" => 'C', "CAS" => 'C', "CCC" => 'C', "CCS" => 'C', "TGP" => 'G', "TLN" => 'U',
					"CSD" => 'C', "CSO" => 'C', "CSP" => 'C', "CSS" => 'C', "CSX" => 'C', "SAR" => 'G', "SBL" => 'S',
					"CY3" => 'C', "CYD" => 'C', "DBB" => 'T', "DBU" => 'T', "DDG" => 'G', "TPO" => 'T', "TPQ" => 'Y',
					"ESC" => 'M', "FAK" => 'K', "FGA" => 'E', "FGP" => 'S', "DHA" => 'S', "TQQ" => 'W', "TRN" => 'W', 
					"FHU" => 'U', "FME" => 'M', "FZN" => 'K', "G2L" => 'G', "G48" => 'G', "GHP" => 'G', "CGU" => 'E',  
					"GMU" => 'U', "GNE" => 'N', "GTP" => 'G', "H2U" => 'U', "HIA" => 'H', "SAC" => 'S', "SCH" => 'C',
					"HIC" => 'H', "HSE" => 'S', "HYP" => 'P', "IIL" => 'I', "IT1" => 'K', "KCX" => 'K', "SCS" => 'C',
					"KPI" => 'K', "LCA" => 'A', "LEF" => 'L', "LLP" => 'K', "LLY" => 'K', "SCY" => 'C', "SE7" => 'A',
					"LYX" => 'K', "M1G" => 'G', "M2G" => 'G', "M3L" => 'K', "MA7" => 'A', "TRO" => 'W', "TRQ" => 'W',
					"MEA" => 'F', "MEN" => 'N', "MHS" => 'H', "MIS" => 'S', "MK8" => 'L', "YG"  => 'G', "YYG" => 'G', 
					"MLE" => 'L', "MLY" => 'K', "MLZ" => 'K', "MSE" => 'M', "MSO" => 'M', "PTR" => 'Y', "SEB" => 'S',
					"MTY" => 'Y', "MVA" => 'V', "CME" => 'C', "T6A" => 'A', "TCQ" => 'Y', "USM" => 'U', "YCM" => 'C', 
					"NAL" => 'A', "NEP" => 'H', "NFA" => 'F', "NIY" => 'Y', "TYS" => 'Y', "U2L" => 'U', "U8U" => 'U', 
					"NLE" => 'L', "NMM" => 'R', "NVA" => 'V', "O2G" => 'G', "OCS" => 'C', "TYI" => 'Y', "TYO" => 'Y',
					"OCY" => 'C', "OMC" => 'C', "OMG" => 'G', "OMT" => 'M', "ORN" => 'A', "TY2" => 'Y', "TYB" => 'Y',
					"PBF" => 'F', "PCA" => 'E', "PF5" => 'F', "PFF" => 'F', "PG1" => 'S', "SVV" => 'S', "T39" => 'T',
					"PHA" => 'F', "PHD" => 'D', "PHI" => 'F', "PRN" => 'A', "PSU" => 'U', "SPT" => 'T', "SRA" => 'A', 
					"SEC" => 'U', "SEP" => 'S', "SMC" => 'C', "SME" => 'M', "SNC" => 'C', "SNN" => 'N', "TXY" => 'Y', 
					"MEQ" => 'Q', "CYG" => 'C', "FVA" => 'V', "DLE" => 'L', "PBT" => 'N', "A5M" => 'C', "GDP" => 'G',
					"MCY" => 'C', "BGM" => 'G', "6MA" => 'A', "D11" => 'T', "FMG" => 'G', "AFG" => 'G', "2DT" => 'T',
					"HSO" => 'H', "CBR" => 'C', "68Z" => 'G', "LYZ" => 'K', "TTD" => 'T',
					"CR2" => "GYG", "CRF" => "TWG", "CRG" => "THG", "CRO" => "GYG", "CRQ" => "QYG", "MDO" => "ASG", 
					"NRQ" => "MYG", "PIA" => "AYG", "RC7" => "HYG", "SUI" => "DG", "5ZA" => "TWG" )


	if (code == acid) and (not ["A","C","G","U","I"].include?(code))  # ribo- forms
			code = "X"	# unknown
	end

	return code
end