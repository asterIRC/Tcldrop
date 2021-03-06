# console/dcc --
#	Handles:
#		* Console related DCC commands.
#	Depends: console.
#
# $Id$
#
# Copyright (C) 2005,2006,2007 FireEgl (Philip Moore) <FireEgl@Tcldrop.US>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see gpl.txt); if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
# Or visit http://www.GNU.Org/licenses/gpl.html
#
# The author of this project can be reached at FireEgl@Tcldrop.US
# Or can be found on IRC (EFNet, OFTC, or FreeNode) as FireEgl.

namespace eval ::tcldrop::console::dcc {
	variable name {console::dcc}
	variable version {0.1}
	variable script [info script]
	regexp -- {^[_[:alpha:]][:_[:alnum:]]*-([[:digit:]].*)[.]tm$} [file tail $script] -> version
	package provide tcldrop::$name $version
	# This makes sure we're loading from a tcldrop environment:
	if {![info exists ::tcldrop]} { return }
	variable predepends {console}
	variable depends {console channels core::users core::conn core}
	variable author {Tcldrop-Dev}
	variable description {Console related DCC commands.}
	variable rcsid {$Id$}
	variable commands [list]
}

proc ::tcldrop::console::dcc::STORE {handle idx text} {
	# eggdrop doesn't log this command but I don't see a reason why not
	putcmdlog "#$handle# store"
	if {![store $idx]} {
		putdebuglog "Failed to save console settings for idx $idx"
		return 0
	} else {
		array set idxinfo [idxinfo $idx]
	}
	if {$idxinfo(console-echo) == 0} {
		set idxinfo(console-echo) [mc_handle $handle {no}]
	} else {
		set idxinfo(console-echo) [mc_handle $handle {yes}]
	}
	# Saved your Console Settings:
	putdcc $idx [mc_handle $handle {Saved your Console Settings}]:
	putdcc $idx "  [mc_handle $handle {Channel}]: $idxinfo(console-channel)"
	putdcc $idx "  [mc_handle $handle {Console flags}]: $idxinfo(console-levels), [mc_handle $handle {Strip flags}]: $idxinfo(console-strip), [mc_handle $handle {Echo}]: $idxinfo(console-echo)"
	putdcc $idx "  [mc_handle $handle {Page setting}]: $idxinfo(console-page), [mc_handle $handle {Console channel}]: $idxinfo(console-chan)"
	return 0
}

proc ::tcldrop::console::dcc::SETCONSOLE {handle idx text} {
	putcmdlog "#$handle# setconsole $text"
	setconsole $idx {*}$text
}

# eggdrop has this command in core, but we put it here (for now) since the console tcl command is in our console module
proc ::tcldrop::console::dcc::CONSOLE {handle idx text} {
	putcmdlog "#$handle# console $text"
	if {$text ne {}} {
		if {[validchan [set chan [lindex [split $text] 0]]]} {
			# console tcl command already checks for proper permissions to set these so we don't need to do it here
			console $idx $chan [lrange [split $text] 1 end]
		} else {
			console $idx $text
		}
	}
	array set idxinfo [idxinfo $idx]
	foreach level [split $idxinfo(console-levels) {}] {
		# if new console modes are added, they need to be added to the list in console-1.tm as well
		switch -exact -- $level {
			m { lappend ConsoleModes {msgs} }
			p { lappend ConsoleModes {public} }
			j { lappend ConsoleModes {joins} }
			k { lappend ConsoleModes {kicks/modes} }
			c { lappend ConsoleModes {cmds} }
			o { lappend ConsoleModes {misc} }
			b { lappend ConsoleModes {bots} }
			r { lappend ConsoleModes {raw} }
			x { lappend ConsoleModes {files} }
			s { lappend ConsoleModes {server} }
			d { lappend ConsoleModes {debug} }
			e { lappend ConsoleModes {errors} }
			w { lappend ConsoleModes {wallops} }
			v { lappend ConsoleModes {server output} }
			t { lappend ConsoleModes {botnet traffic} }
			h { lappend ConsoleModes {share traffic} }
			1 { lappend ConsoleModes {level 1} }
			2 { lappend ConsoleModes {level 2} }
			3 { lappend ConsoleModes {level 3} }
			4 { lappend ConsoleModes {level 4} }
			5 { lappend ConsoleModes {level 5} }
			6 { lappend ConsoleModes {level 6} }
			7 { lappend ConsoleModes {level 7} }
			8 { lappend ConsoleModes {level 8} }
			default { lappend ConsoleModes "$level (custom flag)" }
		}
	}
	if {$text eq {}} {
		putdcc $idx "[mc_handle $handle {Your console is %1$s: %2$s (%3$s)} $idxinfo(console-channel) $idxinfo(console-levels) [join $ConsoleModes {, }]]"
		return 0
	} else {
		putdcc $idx "[mc_handle $handle {Set your console to %1$s: %2$s (%3$s)} $idxinfo(console-channel) $idxinfo(console-levels) [join $ConsoleModes {, }]]"
		return 0
	}
}

::tcldrop::bind load - console::dcc ::tcldrop::console::dcc::LOAD -priority 0
proc ::tcldrop::console::dcc::LOAD {module} {
	bind dcc - store ::tcldrop::console::dcc::STORE -priority 1000
	bind dcc nmot|nmo console ::tcldrop::console::dcc::CONSOLE -priority 1000
	bind dcc - setconsole ::tcldrop::console::dcc::SETCONSOLE -priority 1000
	bind unld - console::dcc ::tcldrop::console::dcc::UNLD -priority 0
	loadhelp console.help
	loadhelp [file join set console.help]
}

proc ::tcldrop::console::dcc::UNLD {module} {
	unbind dcc * * ::tcldrop::console::dcc::*
	unloadhelp console.help
	unloadhelp [file join set console.help]
	unbind unld - console::dcc ::tcldrop::console::dcc::UNLD
	return 0
}
