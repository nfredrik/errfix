# Copyright (c) 2008 Peter Houghton 
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

require "rubygems"
require 'csv'
require 'ftools'

# =ErrFix - StateModelCreator
#
# Creates a FSM style model of software based on the contents of a CSV file.
#
# The model is based on data from a CSV file. Once created, the model can:
# - be exported into a GraphViz object. (Which in term can be exported as PostScript, GIF etc)
# - be traversed by the automatic generation of Random Walks. (For use in Test Drivers)
# 
# $Id$
#
class StateModelCreator
  
  # Position in csv file row array
	STATE1=0
	STATE2=2
	ACTION=1
	
	# GraphViz stuff
	STATE_SHAPE="ellipse"
	

	
	# Exceptions
  MISSING_CSV="Missing CSV file"
  EMPTY_CSV="State Table File is Empty"

	attr_accessor(:adjacency_matrix,:states_store,:the_dot_graph,:debug)

private

# 
# Internal method for debug
#
  def puts_debug(msg)
    if (self.debug) 
      puts msg
    end # end debug
  end # end msg

#
# Create list of states -only , from a list of transitions
#
  def extract_states_list(state_transition_list)
    list_of_states=Array.new
    state_transition_list.each do |transition|
  	  list_of_states.push transition.end_state	
  	  list_of_states.push transition.start_state
  	end # end each    		
    return list_of_states.uniq
  end # end extract state list



	# Read in the CSV file that contains state-action-state information
	#
	# This in fact forwards to correct parser, depending on dimensions of the table file
	#
	def read_csv_file(csv_table_path)
    
    table_dimensions = detect_state_table_dim(csv_table_path)
    
    if table_dimensions==:one_d
      return read_1d_csv_file(csv_table_path)
    elsif table_dimensions==:two_d
      return read_2d_csv_file(csv_table_path)
    else
      raise "Error: CSV File dimensions: #{table_dimensions}"
    end # end if else 
    
  end # end method
    
  # Read in data from a 1d file
  # 
  def read_1d_csv_file(state_table_path)  
    rows_read=0
		state_transition_list= Array.new
		ignore_first_row = true

		CSV::Reader.parse(File.open(state_table_path, 'r').read.gsub(/\r/,"\n")) do |row_array|
			# First row should be the header
			if ignore_first_row
				ignore_first_row=false
			else
				transition = TransitionHolder.new(row_array[STATE1].to_s,row_array[ACTION].to_s,row_array[STATE2].to_s)
				puts_debug "Read in transitions: #{transition}"
				state_transition_list.push transition 
			end # if first row
			rows_read +=1
		end # end csv block

    raise "CSV File Empty" if rows_read==0
    raise "Missing Data in CSV File" if rows_read==1
    
		# return state table, its a raw list of transition objects
		return state_transition_list

	end # end csv file load

  # Read in data from 2d file
  def read_2d_csv_file(state_table_path)  
    rows_read=0
		state_transition_list= Array.new
		grab_first_row = true
    too_states=Array.new
    row_trans_list=Array.new
    
		CSV::Reader.parse(File.open(state_table_path, 'r').read.gsub(/\r/,"\n") ) do |row_array|
		  
			# First row should contain state names
			if grab_first_row
				grab_first_row=false
				too_states = row_array
				too_states.shift
			else
			  row_trans_list=row_array
			  this_rows_start_state = row_trans_list.shift
			  
			  row_trans_list.each_index do |cell_index|
			    if row_trans_list[cell_index] != nil
			      # Remove leading, trailing and multiple spaces
			      cell_contents=row_trans_list[cell_index].strip.squeeze(" ")
			      puts_debug("Cell contents: #{cell_contents}")
			      cell_contents.split(/ /).each do |an_action|
			        transition = TransitionHolder.new(this_rows_start_state.to_s, an_action, too_states[cell_index].to_s)
		          puts_debug "Read in transition (from 2d state table): #{transition}"
				      # Store that transition
				      state_transition_list.push transition
		        end # end each

			    end # if nil
			  end # end each index
			  
			end # if first row
			rows_read +=1
		end # end csv block

    raise "CSV File Empty" if rows_read==0
    raise "Missing Data in CSV File" if rows_read==1
    
		# return state table, its a raw list of transition objects
		return state_transition_list
  end # end method


	def create_adjacency_matrix(raw_state_transition_list)

		adj_matrix=Hash.new

		# Compare raw list with Uniq'ed version
		# if shorter then there were duplicates in CSV file
		state_transition_list = raw_state_transition_list.uniq
		if (state_transition_list.length < raw_state_transition_list.length)
			puts_debug("Probable duplicate entries in CSV file.")
		end # end if

		# Use list of states to create key entries for hash table of states and actions
		self.states_store= extract_states_list(state_transition_list) 
		
		self.states_store.each do |a_state|
			adj_matrix[a_state] = Array.new
		end # end each state
		
		# Add each state pair and action to the hash of states and actions
		state_transition_list.each do |a_transition|
			adj_matrix[a_transition.start_state].push a_transition
		end # end state table

		return adj_matrix
	end # end def 

public 

#
# Creates a FSM style model of software based on the contents of a CSV file.
#
# debug_flag  - Optional, set to false to eliminate debug, true to show
	def initialize(debug_flag=false)

		# Output debug?
		self.debug= debug_flag

	end # end def

#
# Load the CSV file into memory
#
  def load_table(csv_state_table)
    
    # Detect dimensions of state table.
     #detect_state_table_dim(csv_state_table)
		# Read in the CSV data, and store in hash (adjacency matrix)
		the_state_machine = StateMachine.new
		the_state_machine.adjacency_matrix= create_adjacency_matrix(read_csv_file(csv_state_table))
		
		# Give the statemachine the statestore, its used in random walks etc
		the_state_machine.states_store=self.states_store
		
		return the_state_machine
		
  end # end method

  # Detect whether the CSV file contains a 1 or 2 dimensional State Table
  #
  # Returns :one_d , :two_d or :unknown 
  #
  def detect_state_table_dim(csv_state_table)
    raise MISSING_CSV unless File.exist?(csv_state_table)
    raise EMPTY_CSV unless File.size(csv_state_table)>0
    
    # What Type of State table do we think this is?
    cell_probable=:unknown
	  
	  csv_file = File.open(csv_state_table, 'r')
	  
	  puts_debug "Detecting on file: #{csv_state_table}"

    CSV::Reader.parse( csv_file.read.gsub(/\r/,"\n") ) do |row_array|
      puts_debug "Detecting State table: row length? #{row_array.length}"
      
		  top_left_cell = row_array[0]

		  if (top_left_cell.chomp.downcase=="Start/End".downcase)
		      cell_probable=:two_d
		      break
	      elsif (top_left_cell.chomp.downcase=="Start State".downcase)
		      cell_probable=:one_d
	        break
	      else
	        raise "Error: Type: #{cell_probable}: Unable to Detect whether this is a 1 or 2 Dimensional State Table"
	        break
		  end # end if  
    end # end CSV
    
    csv_file.close
    
    return cell_probable
  
  end # end method


	
end # class

#
# Class Walk holds details of a given walk, each step and its coverage statistics
#
class Walk
	RANDOM=1

	attr_accessor(:start_state , :end_state , :state_coverage , :transition_coverage )

	def initialize(type=RANDOM)
		@transitions_list=Array.new
	end # end init
	
	def length
	  return @transitions_list.length
	end # end length
	
	def transitions
		return @transitions_list
	end # end transitions

  alias :steps  :transitions

  # Returns an array of unique transisitons in a walk.
  def transitions_uniq
    trans_hash = Hash.new
    self.transitions.each do |transition|
      the_key="#{transition.start_state}  #{transition.action}  #{transition.end_state}"
      if trans_hash.has_key?(the_key)
        # ignore this one, its a duplicate
      else
        trans_hash[the_key]=transition
      end # not already stored
    end # end each transition in list
    
    # Return the transitions are not duplicated 
    return trans_hash.values
  
  end # end trans uniq

  # Drive Using
  # Directs -sut_driver- by calling methods related to States and Transitions in the Walk.
  # -sut_driver-  is the Page or system driver for the System Under Test.
  #
  # States in the Walk must correspond to methods in the sut_driver named: test_STATE_NAME
  # Transitions in the Walk must correspond to methods in the sut_driver named: ACTION_NAME
  # 
  # e.g.: If the system under test has the states LOGGED_OUT,LOGGED_IN and a action of 
  # 'enter_login_details' that forms a transition between these two states, then your -sut_driver-
  #  should have the methods:
  # test_LOGGED_OUT
  # test_LOGGED_IN
  # enter_login_details
  # 
  # The methods methods named 'test_XXX' should contain code designed to test that the state XXX 
  # has been successfully reached and is not actually any other state.
  # The other methods e.g. 'enter_login_details' are for driving functionality that drives the
  # system from one state to another, e.g from LOGGED_OUT to LOGGED_IN  in this case.
  #
  def drive_using(sut_driver)
    
    raise "String - Not be a SUT Driver: Error" if (sut_driver.class==String.new.class) 
    raise "Array - Not be a SUT Driver: Error" if (sut_driver.class==Array.new.class) 
    
    # Test/verify start state is valid
    sut_driver.send("test_" + self.start_state)
    
    # Loop through transitions
    self.transitions.each do |a_transition|
      
      # Run each action
      sut_driver.send(a_transition.action)
      # Test/verify arrival at resulting state
      sut_driver.send("test_" + a_transition.end_state)
      
    end # end Loop block
    
  end # end drive using

  def last_added
    return @transitions_list.last
  end # end last added

	def to_s
		out_str = "#{self.start_state},"
		self.transitions.each_index do |index|
			out_str << "#{self.transitions[index].action} => #{self.transitions[index].end_state},"
		end
		out_str << "#{self.end_state}\n"
		return out_str	
	end # end to_s

end # end class walk


#
# Used to hold details of a transition, start state, action and end state
#
class TransitionHolder
	def initialize(state_1=nil,action_1=nil,state_2=nil)
		self.start_state=state_1
		self.action=action_1
		self.end_state=state_2
	end # end init

  def to_s
    out_str="#{self.start_state},"
    out_str << "#{self.action} => "
    out_str << "#{self.end_state}"
    return out_str
  end # end to_s

  def ==(other)
    equality=false
    if self.start_state == other.start_state
      if self.end_state == other.end_state
        if self.action == other.action
          equality=true
        end
      end
    end
          
    return equality
  end # end if equal

	attr_accessor(:start_state , :end_state , :action)
end # end class




#
# Graph is used to construct Graphviz DOT language graphs.
# Graph negates the need for Ruby-graphviz to be installed.
#
class Graph
  
  attr_accessor(:name , :type , :node_style)
  def initialize
    @nodes=Array.new
    @edges=Array.new
  end # end init
  
 # def add_node(node_name)
  #  @nodes.push node_name
  #end # add node
  
  # add edge accepts 3 arguments From_node, Too_node and label
  def add_edge(*edge_details)
    if (edge_details.length !=3)
      raise "Error: Incorrect number of arguments in add_edge"
    end # end if length
    @edges.push edge_details
  end # end add edge
  
  def to_s
    if (self.name==nil || self.type==nil)
      raise "Graph Name or Type not set. Name:#{self.name} , Type:#{self.type}"
    end # end if not setup 
    
    txt = "#{self.type} #{self.name} {\n"
    txt << "  node [shape = #{self.node_style}];\n"
    @edges.each do |edge|
      txt << "  #{edge[0]} -> #{edge[1]} [ label = \"#{edge[2]}\" ];\n"
    end # nodes
    txt << "}\n"
    
    return txt
  end # end to_s
  
  def output(filename)
    outs = File.new(filename , "w")
    outs.puts self.to_s
    outs.close
  end # end output
  
end # class





class StateMachine
  
  # Walk related
	MAX_STEPS=20
  
  
  def initialize(debug_val=false)
    self.debug=debug_val
    @actions=Array.new
    @states=Array.new
  end # end init
  
  attr_accessor(:adjacency_matrix,:states_store,:the_dot_graph, :debug)
  
  
  # Internal method for debug
  #
    def puts_debug(msg)
      if (self.debug) 
        puts msg
      end # end debug
    end # end msg
  
  
  #
  # List on standard out each state and the actions associated with it
  #
  	def to_s
  		out_str ="States, and their Actions:"
  		self.adjacency_matrix.each_key do |a_state|
  			out_str << "\nState: #{a_state}\n"
  			out_str << "Actions:\n"
  			if self.adjacency_matrix[a_state].length == 0
  				out_str << "\t<No Actions>\n"
  			else
  				self.adjacency_matrix[a_state].each do |a_transition|
  					out_str << "\t#{a_transition.action}\n"
  				end # end each

  			end # end else
  		end # end each key
  		return out_str
  	end # end method
  
  
  
  
    #
    #  call-seq:
    #     statemodel.create_dot_graph -> Graph
    #
    #  Returns a Graph object, containing DOT language representations of the state model.
    #     
    #
    def create_dot_graph

    	# Create the base object, then add edges/nodes later etc
    	my_graph = Graph.new
    	my_graph.name= "State_Model"
    	my_graph.node_style= :ellipse
    	my_graph.type = :digraph

    	# For each entry in the Adjacency matrix extract the relationships and add the graph edges.
    	self.adjacency_matrix.each_key do |table_key|
    		transition_list=self.adjacency_matrix[table_key]
    		transition_list.each do |transition|
    			my_graph.add_edge(transition.start_state , transition.end_state , " #{transition.action} ")
    		end # end add transitions
    	end # end add nodes

    	return my_graph
    end # end create graph

    # 
    #  call-seq:
    #     statemodel.get_actions_for_state("A_STATE") -> Array
    #
    # Returns an array of Strings, representing each action available from the passed state.
    #
    def get_actions_for_state(a_state)
    	actions_list=Array.new	
    	self.adjacency_matrix[a_state].each do |a_transition|
    		actions_list.push a_transition.action	
    	end # end each
    	return actions_list	
    end # end state
  
  
    #
    #  call-seq:
    #     statemodel.calc_state_coverage(a_walk) -> float
    #
    #  Returns a float  representing the percentage of states covered by a given walk
    #     
    #
    def calc_state_coverage(a_walk)

      puts_debug("Calculating State Coverage")
      # Collate a list of states
      walk_states=Array.new
    	a_walk.transitions.each do |a_trans| 
      	walk_states.push a_trans.start_state
      	walk_states.push a_trans.end_state
      end # end a walk

      # Number of unique states in walk
      walk_states = walk_states.uniq

      puts_debug "Walk_states uniq: #{walk_states}"
      puts_debug "States Store:     #{states_store}"

  		# Calc the percentage 
  		return (walk_states.length.to_f/self.states_store.length.to_f)*100
    end # end calc

      #  call-seq:
      #     statemodel.calc_transition_coverage(a_walk) -> float
      #        #  Returns a float  representing the percentage of transitions covered by a given walk
       #     
      #
    def calc_transition_coverage(a_walk)
      puts_debug "\nCalculating Transition Coverage"
      num_walk_trans=a_walk.transitions_uniq.length
      puts_debug "Number of Unique Transitions in Walk: #{num_walk_trans}"

      all_transitions=extract_valid_transitions
      puts_debug "Number of Transitions in model: #{all_transitions.length}"

      return (num_walk_trans.to_f / all_transitions.length.to_f )*100

    end # end method

  

    def extract_valid_transitions
      # Find valid transitions
      # Adjacency matrix is keyed by State, and values are arrays of transitions.
      # Therefore to get Transitions you need to cull the dead-end states.
      transitions_in_model=Array.new
  		self.adjacency_matrix.each_key do |a_state|
			  if self.adjacency_matrix[a_state].length == 0
			      			    # Ignore if no actions, as this is not a transition, just a dead end
        else
    	    self.adjacency_matrix[a_state].each do |a_transition|
        	  transitions_in_model.push a_transition
        	end # end each 	
        end # end else
      end # end each key

      return transitions_in_model
    end # extract valid transitions

#  call-seq:
#     statemodel.random_walk("START_STATE") -> Walk
        #
        # Create a random walk over the model, starting at START_STATE
        #
        # Returns a Walk object containing each transition off the random walk.
        # Walk objects can then be used to 'drive' your System Under Test or framework driver code.
        # 
        # By default the walk will have a length of MAX_STEPS unless a dead end is reached first.
        # This can be overridden by passing a second Integer argument.
    def random_walk(start_state, steps_limit=MAX_STEPS)

      # Check Start State exists in model etc
      matches=0
      self.states_store.each do |a_state|
        if a_state==start_state
          matches += 1
        end # end if
      end # end each state
      raise "Missing Start State Exception" if matches==0
      raise "Duplicate Start States in States Store" if matches > 1

  	  raise "Step Limit is too low at #{steps_limit}" unless steps_limit > 2

  	  # transitions store is used to hold a unique list of 'walked' transitions and their states.
  		transitions_store = Hash.new

  		# Random walk create object to store the walk details	
  		a_walk=Walk.new(Walk::RANDOM)
  		a_walk.start_state=start_state

      # Call the random steps code to actually make the 'steps'
      complete_walk = random_steps(a_walk, steps_limit)


  		# Calculate state coverage for this walk	
  	  complete_walk.state_coverage=calc_state_coverage(a_walk)
  	  complete_walk.transition_coverage=calc_transition_coverage(a_walk)

  		puts_debug "This walk has coverage metrics of:"
  		if self.debug
  			printf "\tState coverage: %3.1f%\n" , complete_walk.state_coverage			
  		  printf "\tTransition coverage: %3.1f%\n" , complete_walk.transition_coverage
  		end # end if

  		return complete_walk
  	end # end def	

  
    def random_steps(the_walk, steps_limit)
      if (the_walk.length >= steps_limit)
        return the_walk
      else 

      # Get the 'current' state of the walk
      if (the_walk.length == 0)
        # If just started then its the start state
        current_state = the_walk.start_state
      else
        # Otherwise its the the end state of the last transition
        current_state = the_walk.last_added.end_state
      end
      actions = get_actions_for_state(current_state)

      if (actions.length==0)
        the_walk.end_state=current_state
        return the_walk
      else

        # Choose an option at random
        choice=rand(actions.length)
        next_state = self.adjacency_matrix[current_state][choice].end_state
        action = self.adjacency_matrix[current_state][choice].action

        the_walk.transitions.push TransitionHolder.new(current_state,action,next_state)

        # Make the next step
        random_steps(the_walk,steps_limit)

  		end # end actions
    end # else
  end # end method steps

  
  
  def actions
    return @actions
  end # end actions
  
  def attach_start_state(action_name)
    attach_state(:start)
  end # end attach
  
  def attach_states(action_name, start_state, end_state)
    if !@actions.include?(action_name)
      raise "Action not found"
    end # end if  
    transition = TransitionHolder.new(start_state,action_name,end_state)
  end # end action
  
  def states
    return @states
  end # end states
  
  def define_action(action_name)

    @actions.push action_name  
    self.class.send(:define_method , action_name) do 
      begin
        puts "Action: #{action_name}"
        yield
      rescue LocalJumpError 
        # ignore, this is just a plain action.
      end # end rescue
    end # end proc
    
  end # end add action
  
end # end class



